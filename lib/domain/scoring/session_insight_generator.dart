import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/enums/enums.dart';
import '../../data/models/attempt.dart';
import '../../data/models/session.dart';
import 'session_summary.dart';

/// Context data from past sessions needed to generate dynamic insights.
class SessionInsightContext {
  final int totalSessionsBefore;
  final double? historicalAvgTimeMs;
  final double? historicalAccuracy;
  final double? recentAvgTimeMs;
  final double? recentAccuracy;
  final int clearedMistakesCount;
  final int stillToPracticeCount;
  final bool isSimilarMistakes;

  const SessionInsightContext({
    this.totalSessionsBefore = 0,
    this.historicalAvgTimeMs,
    this.historicalAccuracy,
    this.recentAvgTimeMs,
    this.recentAccuracy,
    this.clearedMistakesCount = 0,
    this.stillToPracticeCount = 0,
    this.isSimilarMistakes = false,
  });
}

/// Pure Dart generator producing 1 to 2 short, grounded, professional sentences
/// for the Coach Insight card on the Results screen.
class SessionInsightGenerator {
  final Map<String, List<String>> _phrases;
  static final Map<String, int> _lastPickedIndex = {};

  SessionInsightGenerator({Map<String, List<String>>? phrases})
      : _phrases = phrases ?? _defaultPhrases;

  /// Loads the insight phrases from the asset bundle.
  static Future<SessionInsightGenerator> loadFromBundle([
    String assetPath = 'assets/coach/insight_phrases.json',
  ]) async {
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final map = <String, List<String>>{};
      for (final entry in decoded.entries) {
        if (entry.value is List) {
          map[entry.key] =
              (entry.value as List).map((e) => e.toString()).toList();
        }
      }
      return SessionInsightGenerator(phrases: map);
    } catch (_) {
      return SessionInsightGenerator();
    }
  }

  /// Generates a dynamic insight sentence based on this session and user history.
  String generateInsight({
    required Session session,
    required List<Attempt> attempts,
    required SessionSummary summary,
    required SessionKind kind,
    required PracticeMode mode,
    required SessionInsightContext context,
  }) {
    // 1. First session ever
    if (context.totalSessionsBefore == 0 && summary.totalQuestions > 0) {
      final count = summary.totalQuestions.toString();
      final text = _pickPhrase('first_session', {'count': count});
      if (text != null) return text;
    }

    // 2. Mistakes practice session
    if (kind == SessionKind.mistakes || mode == PracticeMode.mistakes) {
      if (context.isSimilarMistakes) {
        final text = _pickPhrase('similar_mistakes_practice', {});
        if (text != null) return text;
      } else if (context.stillToPracticeCount == 0 && context.clearedMistakesCount > 0) {
        final text = _pickPhrase('mistakes_practice_all_mastered', {
          'mastered': context.clearedMistakesCount.toString(),
        });
        if (text != null) return text;
      } else if (context.clearedMistakesCount > 0 || context.stillToPracticeCount > 0) {
        final text = _pickPhrase('mistakes_practice', {
          'mastered': context.clearedMistakesCount.toString(),
          'remaining': context.stillToPracticeCount.toString(),
        });
        if (text != null) return text;
      }
    }

    // 3. Many skipped questions
    if (summary.skippedCount >= 3 &&
        summary.skippedCount >= (summary.totalQuestions * 0.25)) {
      final text = _pickPhrase('many_skips', {
        'skips': summary.skippedCount.toString(),
      });
      if (text != null) return text;
    }

    // 4. Recurring problem topic
    final wrongByTopic = <Topic, int>{};
    for (final a in attempts) {
      if (!a.isCorrect && !a.isSkipped) {
        wrongByTopic[a.topic] = (wrongByTopic[a.topic] ?? 0) + 1;
      }
    }
    if (wrongByTopic.isNotEmpty) {
      final worst = wrongByTopic.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (worst.value >= 2) {
        final text = _pickPhrase('recurring_problem', {
          'topic': worst.key.displayName,
          'wrong_count': worst.value.toString(),
        });
        if (text != null) return text;
      }
    }

    // 5. Fast streak (>= 4 correct answers in a row averaging < 3.0s)
    final streakInfo = _findFastStreak(attempts);
    if (streakInfo != null && streakInfo.streak >= 4) {
      final text = _pickPhrase('fast_streak', {
        'streak': streakInfo.streak.toString(),
        'streak_avg_time': '${(streakInfo.avgTimeMs / 1000).toStringAsFixed(1)}s',
      });
      if (text != null) return text;
    }

    // 6. Faster or slower than historical average
    if (context.historicalAvgTimeMs != null &&
        context.historicalAvgTimeMs! > 0 &&
        summary.correctCount >= 3 &&
        summary.avgTimeMsPerCorrect > 0) {
      final diffMs = summary.avgTimeMsPerCorrect - context.historicalAvgTimeMs!;
      if (diffMs <= -300) {
        // Faster by >= 300ms
        final text = _pickPhrase('faster_than_average', {
          'avg_time': '${(summary.avgTimeMsPerCorrect / 1000).toStringAsFixed(1)}s',
          'time_diff': '${((-diffMs) / 1000).toStringAsFixed(1)}s',
        });
        if (text != null) return text;
      } else if (diffMs >= 500) {
        // Slower by >= 500ms
        final text = _pickPhrase('slower_than_average', {
          'avg_time': '${(summary.avgTimeMsPerCorrect / 1000).toStringAsFixed(1)}s',
          'time_diff': '${(diffMs / 1000).toStringAsFixed(1)}s',
        });
        if (text != null) return text;
      }
    }

    // 7. Accuracy higher or lower than recent sessions
    if (context.recentAccuracy != null && summary.totalQuestions >= 5) {
      final diffPoints = ((summary.accuracy - context.recentAccuracy!) * 100).round();
      if (diffPoints >= 8) {
        final text = _pickPhrase('accuracy_higher', {
          'accuracy': (summary.accuracy * 100).round().toString(),
          'acc_diff': diffPoints.toString(),
        });
        if (text != null) return text;
      } else if (diffPoints <= -10) {
        final text = _pickPhrase('accuracy_lower', {
          'accuracy': (summary.accuracy * 100).round().toString(),
          'acc_diff': (-diffPoints).toString(),
        });
        if (text != null) return text;
      }
    }

    // 8. Slowest question type this session
    final topicTimes = <Topic, List<int>>{};
    for (final a in attempts) {
      if (a.isCorrect && a.timeMs > 0) {
        topicTimes.putIfAbsent(a.topic, () => []).add(a.timeMs);
      }
    }
    if (topicTimes.length >= 2) {
      Topic? slowest;
      double maxAvg = 0;
      topicTimes.forEach((t, times) {
        if (times.length >= 2) {
          final avg = times.reduce((a, b) => a + b) / times.length;
          if (avg > maxAvg) {
            maxAvg = avg;
            slowest = t;
          }
        }
      });
      if (slowest != null) {
        final text = _pickPhrase('slowest_type', {
          'topic': slowest!.displayName,
          'avg_time': '${(maxAvg / 1000).toStringAsFixed(1)}s',
        });
        if (text != null) return text;
      }
    }

    // Fallback encouraging line
    return _pickPhrase('thin_data_fallback', {}) ??
        'I looked at your answers. Solid work finishing this session! Every question you practice helps build automatic reflexes.';
  }

  _StreakInfo? _findFastStreak(List<Attempt> attempts) {
    int currentStreak = 0;
    int currentTotalTime = 0;
    int maxStreak = 0;
    int maxStreakTime = 0;

    for (final a in attempts) {
      if (a.isCorrect && a.timeMs < 4000) {
        currentStreak++;
        currentTotalTime += a.timeMs;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
          maxStreakTime = currentTotalTime;
        }
      } else {
        currentStreak = 0;
        currentTotalTime = 0;
      }
    }

    if (maxStreak >= 4 && maxStreakTime > 0) {
      return _StreakInfo(maxStreak, maxStreakTime / maxStreak);
    }
    return null;
  }

  String? _pickPhrase(String key, Map<String, String> replacements) {
    final list = _phrases[key];
    if (list == null || list.isEmpty) return null;

    final random = Random();
    int index;
    final lastIdx = _lastPickedIndex[key];
    if (list.length > 1 && lastIdx != null) {
      // Pick any except the last one
      index = random.nextInt(list.length - 1);
      if (index >= lastIdx) index++;
    } else {
      index = random.nextInt(list.length);
    }
    _lastPickedIndex[key] = index;

    var text = list[index];
    for (final entry in replacements.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }

    // If any unreplaced placeholder remains, do not use it
    if (RegExp(r'\{[a-zA-Z_]+\}').hasMatch(text)) {
      return null;
    }
    return text;
  }

  static const Map<String, List<String>> _defaultPhrases = {
    'first_session': [
      'I looked at your answers. Welcome to your first session! You answered {count} questions, giving us a baseline to build your speed from here.',
      'I noticed this is your very first practice session. Great start with {count} questions! Keep practicing regularly to see your numbers improve.',
      'I looked at your answers from your first session. With {count} questions completed, we now have our starting point to track your growth.',
      'This tells me you are ready to build real speed. That was your first session, and completing {count} questions is a solid start.',
      'I noticed this is where your journey begins. You finished {count} questions in your first session—consistency is what will make you fast.',
      'I looked at your first session. You answered {count} questions, and from here on, every practice will help sharpen your mental math.'
    ],
    'mistakes_practice': [
      'I looked at your answers during this review. You mastered {mastered} questions today, with {remaining} still waiting for your next practice.',
      'I noticed your persistence on these tricky questions. You fully cleared {mastered} of them, leaving {remaining} to work through.',
      'This tells me your review is paying off. You conquered {mastered} questions, and there are {remaining} remaining to practice.',
      'I looked at how you tackled these: {mastered} questions are now mastered, and {remaining} are left to revisit soon.',
      'I noticed solid progress here. You mastered {mastered} questions in this session, leaving {remaining} for upcoming reviews.',
      'I looked at your review results. You put away {mastered} questions, with {remaining} still on your practice list.'
    ],
    'mistakes_practice_all_mastered': [
      'I looked at your answers, and you mastered all {mastered} questions! Your review list is completely clear right now.',
      'I noticed something great: every single mistake in this session was conquered. You cleared all {mastered} of them!',
      'This tells me you have really nailed these. All {mastered} questions are now mastered—your list is completely clean.',
      'I looked at your review session: you mastered all {mastered} questions! Outstanding turnaround on your tricky spots.',
      'I noticed you finished off the entire review list. All {mastered} questions are mastered—keep up that momentum.',
      'This tells me your persistence paid off. Every one of the {mastered} questions you reviewed today is now mastered!'
    ],
    'similar_mistakes_practice': [
      'I looked at your practice: you tackled new questions targeting your recent slip-ups. Your skills and pattern mastery are updated!',
      'I noticed you practiced similar questions on your problem patterns. Reinforcing the underlying concepts builds real confidence.',
      'This tells me you are strengthening your weak spots. Practicing fresh variations of tricky questions trains your brain to spot the pattern.',
      'I looked at how you worked through these concept variations. Your skills and pattern ratings have been updated with this progress.',
      'I noticed good work on these similar questions. Tackling fresh numbers with the same tricky patterns prevents memorizing answers.',
      'This tells me your concept practice is on track. Working on similar questions solidifies the technique for your next regular drill.'
    ],
    'slowest_type': [
      'I looked at your answers across topics. {topic} took you the longest today at {avg_time} per answer on average.',
      'I noticed your pacing differed across types. You spent the most time on {topic}, averaging {avg_time} per question.',
      'This tells me where extra practice will help most: {topic} was your slowest area this session at {avg_time}.',
      'I looked at your response times. {topic} was your most deliberate topic today, averaging {avg_time}.',
      'I noticed you took extra care on {topic}, where answers averaged {avg_time} compared to your faster types.',
      'This tells me your main speed bottleneck today was {topic}, taking {avg_time} per question on average.'
    ],
    'faster_than_average': [
      'I looked at your speed today. You averaged {avg_time} per correct answer, which is {time_diff} faster than your usual pace!',
      'I noticed a nice pickup in tempo. At {avg_time} per answer, you were {time_diff} faster than your historical average.',
      'This tells me your reflexes are sharpening. You were {time_diff} faster than usual, completing correct answers in {avg_time}.',
      'I looked at your timing: your pace was {time_diff} faster than your overall average, coming in at {avg_time}.',
      'I noticed your rhythm was notably quick. You averaged {avg_time} per answer, beating your typical pace by {time_diff}.',
      'This tells me your confidence is growing. You finished correct answers in {avg_time}, a {time_diff} improvement over your usual speed.'
    ],
    'slower_than_average': [
      'I looked at your timing today. Your average of {avg_time} per answer was {time_diff} slower than your usual pace.',
      'I noticed you took a bit more time than usual today: {avg_time} per answer, which was {time_diff} slower than your average.',
      'This tells me you were more deliberate today. At {avg_time}, you were {time_diff} slower than your typical pace.',
      'I looked at your pace: answers took {avg_time} on average today, {time_diff} slower than your standard tempo.',
      'I noticed your pace relaxed a little. You averaged {avg_time} per answer, {time_diff} slower than your usual speed.',
      'This tells me you were thinking things through carefully today, averaging {avg_time}, {time_diff} slower than your baseline.'
    ],
    'accuracy_higher': [
      'I looked at your accuracy: you hit {accuracy}% this session, up {acc_diff} points from your recent average!',
      'I noticed sharp precision today. Your accuracy reached {accuracy}%, which is {acc_diff} points higher than recent sessions.',
      'This tells me your focus was locked in. You posted {accuracy}% accuracy, gaining {acc_diff} points over your recent average.',
      'I looked at your results and saw great control: {accuracy}% accuracy, up {acc_diff} points from your recent sessions.',
      'I noticed your precision climbed nicely. At {accuracy}%, you are {acc_diff} points higher than your previous average.',
      'This tells me you made fewer slips today. Your {accuracy}% accuracy is {acc_diff} points above your recent baseline.'
    ],
    'accuracy_lower': [
      'I looked at your answers: accuracy was {accuracy}% today, down {acc_diff} points from your recent average.',
      'I noticed a few more slips than usual. You landed at {accuracy}% accuracy, {acc_diff} points lower than recent sessions.',
      'This tells me some questions caught you off guard today. Your accuracy was {accuracy}%, down {acc_diff} points.',
      'I looked at the breakdown: accuracy dipped to {accuracy}%, {acc_diff} points below your recent average.',
      'I noticed you had a tougher run today. At {accuracy}% accuracy, you were {acc_diff} points below your recent pace.',
      'This tells me speed might have rushed your precision today. Accuracy was {accuracy}%, down {acc_diff} points from recent drills.'
    ],
    'recurring_problem': [
      'I looked at the questions that tripped you up. {topic} presented recurring trouble today with {wrong_count} incorrect tries.',
      'I noticed {topic} gave you some difficulty again today, with {wrong_count} slips during the session.',
      'This tells me {topic} needs a quick refresher: it accounted for {wrong_count} of your missed questions today.',
      'I looked at where points were lost. {topic} was your most challenging area today, leading to {wrong_count} missed answers.',
      'I noticed repeated hiccups on {topic} today. Giving it a focused drill will help iron out those {wrong_count} slips.',
      'This tells me you hit some friction on {topic} today with {wrong_count} mistakes—worth a short targeted review.'
    ],
    'improved_type': [
      'I looked at your performance on {topic}: your accuracy jumped to {accuracy}%, showing clear improvement!',
      'I noticed nice gains in {topic} today. You handled those questions with {accuracy}% accuracy and strong confidence.',
      'This tells me your practice on {topic} is working. You achieved {accuracy}% accuracy on it this session.',
      'I looked at {topic} specifically: you reached {accuracy}% accuracy today, a noticeable step forward.',
      'I noticed you felt much more comfortable with {topic} today, hitting {accuracy}% accuracy.',
      'This tells me {topic} is turning into a strength for you, with {accuracy}% accuracy in this session.'
    ],
    'fast_streak': [
      'I looked at your pacing: you hit a great streak of {streak} consecutive correct answers averaging just {streak_avg_time} each!',
      'I noticed a brilliant burst of speed: {streak} correct answers in a row, each taking under {streak_avg_time}.',
      'This tells me you were in the zone: a streak of {streak} fast correct answers averaging {streak_avg_time}.',
      'I looked at your fastest sequence: {streak} questions answered correctly in a row at a swift {streak_avg_time} each.',
      'I noticed strong momentum midway through: you chained together {streak} correct answers at {streak_avg_time} per question.',
      'This tells me your reflexes were firing quickly, producing a streak of {streak} fast correct answers averaging {streak_avg_time}.'
    ],
    'many_skips': [
      'I looked at your session: you skipped {skips} questions today. Even a slow guess helps us learn where to focus next.',
      'I noticed {skips} skipped questions this session. Taking an extra second to work through them builds lasting speed.',
      'This tells me you hesitated on {skips} questions. Try attempting them next time—every attempt gives us useful data.',
      'I looked at your answers: with {skips} questions skipped, remember that accuracy comes before raw speed.',
      'I noticed you bypassed {skips} questions today. Don\'t be afraid to take your time and answer instead of skipping.',
      'This tells me {skips} questions felt tricky. Working them out slowly will help turn those skips into quick answers.'
    ],
    'thin_data_fallback': [
      'I looked at your answers. Solid work finishing this session! Every question you practice helps build automatic reflexes.',
      'I noticed your steady effort today. Consistent practice is the secret to mental math speed—keep it up!',
      'This tells me you are putting in the work. Great job completing this practice, and look forward to seeing your numbers grow.',
      'I looked at your session. Nice job showing up to practice! Staying consistent day after day builds effortless calculation.',
      'I noticed another session in the books. Good focus throughout—regular practice will continue to sharpen your tempo.',
      'This tells me you are building a great habit. Every set of calculations trains your mind to spot patterns faster.'
    ],
  };
}

class _StreakInfo {
  final int streak;
  final double avgTimeMs;

  _StreakInfo(this.streak, this.avgTimeMs);
}
