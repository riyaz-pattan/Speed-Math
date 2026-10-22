import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'report_data.dart';
import 'todays_plan.dart';

/// Structured natural language text generated for the Performance Report.
class ReportText {
  final String headline;
  final String weeklyActivity;
  final String? weeklyAccuracy;
  final String? weeklySpeed;
  final String strengths;
  final String weakAreas;
  final String? improving;
  final String? slipping;
  final String? neglected;
  final String? neverPracticed;
  final String mistakes;
  final String closingPush;

  const ReportText({
    required this.headline,
    required this.weeklyActivity,
    this.weeklyAccuracy,
    this.weeklySpeed,
    required this.strengths,
    required this.weakAreas,
    this.improving,
    this.slipping,
    this.neglected,
    this.neverPracticed,
    required this.mistakes,
    required this.closingPush,
  });
}

/// Pure Dart writer that converts [ReportData] into friendly, encouraging,
/// honest natural-language insights using a date-seeded phrase bank.
class ReportWriter {
  final Map<String, List<String>> _phrases;

  ReportWriter({Map<String, List<String>>? phrases})
      : _phrases = phrases ?? _defaultPhrases;

  /// Loads the phrase bank from the app assets bundle.
  static Future<ReportWriter> loadFromBundle([
    String assetPath = 'assets/coach/phrases.json',
  ]) async {
    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final map = <String, List<String>>{};
      for (final entry in decoded.entries) {
        if (entry.value is List) {
          map[entry.key] = (entry.value as List).map((e) => e.toString()).toList();
        }
      }
      return ReportWriter(phrases: map);
    } catch (_) {
      return ReportWriter();
    }
  }

  /// Generates the complete [ReportText] from [reportData] and optional [plan].
  ///
  /// [date] determines the deterministic phrase choice seed.
  ReportText writeReport(
    ReportData reportData, {
    TodayPlan? plan,
    DateTime? date,
  }) {
    final effectiveDate = date ?? reportData.generatedAt;

    if (!reportData.hasEnoughData) {
      final emptyText = _pickPhrase('empty_report', effectiveDate, {});
      return ReportText(
        headline: emptyText,
        weeklyActivity: emptyText,
        strengths: emptyText,
        weakAreas: emptyText,
        mistakes: emptyText,
        closingPush: emptyText,
      );
    }

    // 1. Headline sentence
    final String headline;
    if (reportData.overallSpeedScore != null &&
        reportData.speedScoreLabel != null) {
      final scoreVal = reportData.overallSpeedScore!.round().toString();
      final labelStr = reportData.speedScoreLabel!.displayName;
      final situation = switch (reportData.speedScoreLabel!) {
        SpeedScoreLabel.elite => 'headline_elite',
        SpeedScoreLabel.strong => 'headline_strong',
        SpeedScoreLabel.building => 'headline_building',
        SpeedScoreLabel.beginner => 'headline_beginner',
      };
      headline = _pickPhrase(situation, effectiveDate, {
        'score': scoreVal,
        'label': labelStr,
      });
    } else {
      headline = _pickPhrase('headline_no_score', effectiveDate, {});
    }

    // 2. Weekly Activity
    final curr = reportData.weeklyComparison.currentWindow;
    final prev = reportData.weeklyComparison.previousWindow;
    final activitySituation = curr.sessionsCount > prev.sessionsCount
        ? 'weekly_active_more'
        : (curr.sessionsCount < prev.sessionsCount
            ? 'weekly_active_less'
            : 'weekly_active_steady');

    final weeklyActivity = _pickPhrase(activitySituation, effectiveDate, {
      'sessions': curr.sessionsCount.toString(),
      'questions': curr.questionsAnswered.toString(),
      'minutes': curr.practiceMinutes.round().toString(),
    });

    // Weekly Accuracy & Speed changes
    String? weeklyAccuracy;
    if (prev.questionsAnswered > 0 && curr.questionsAnswered > 0) {
      final accDelta = curr.accuracy - prev.accuracy;
      final accDeltaPts = (accDelta.abs() * 100).round();
      final currAccPct = '${(curr.accuracy * 100).round()}%';
      final pointWord = accDeltaPts == 1 ? 'point' : 'points';
      final accDiffStr = '$accDeltaPts $pointWord';

      if (accDelta >= 0.02) {
        weeklyAccuracy = _pickPhrase('weekly_accuracy_up', effectiveDate, {
          'accuracy_pct': currAccPct,
          'accuracy_diff': accDiffStr,
        });
      } else if (accDelta <= -0.02) {
        weeklyAccuracy = _pickPhrase('weekly_accuracy_down', effectiveDate, {
          'accuracy_pct': currAccPct,
          'accuracy_diff': accDiffStr,
        });
      }
    }

    String? weeklySpeed;
    if (prev.avgTimeMsPerCorrect > 0 && curr.avgTimeMsPerCorrect > 0) {
      final speedDiffPct = ((prev.avgTimeMsPerCorrect - curr.avgTimeMsPerCorrect) /
              prev.avgTimeMsPerCorrect *
              100)
          .round();
      final avgTimeStr = '${(curr.avgTimeMsPerCorrect / 1000).toStringAsFixed(1)}s';

      if (speedDiffPct >= 5) {
        weeklySpeed = _pickPhrase('weekly_speed_up', effectiveDate, {
          'avg_time': avgTimeStr,
          'speed_diff': '${speedDiffPct.abs()}%',
        });
      } else if (speedDiffPct <= -5) {
        weeklySpeed = _pickPhrase('weekly_speed_down', effectiveDate, {
          'avg_time': avgTimeStr,
          'speed_diff': '${speedDiffPct.abs()}%',
        });
      }
    }

    // 3. Strengths
    final String strengths;
    if (reportData.strongAreas.isEmpty) {
      strengths = _pickPhrase('strengths_none', effectiveDate, {});
    } else {
      final details = reportData.strongAreas
          .map((s) => '${s.topic.displayName} (${s.difficulty.displayName})')
          .join(', ');
      final situation = reportData.strongAreas.length == 1
          ? 'strengths_single'
          : 'strengths_multiple';
      strengths = _pickPhrase(situation, effectiveDate, {
        'topic_details': details,
      });
    }

    // 4. Weak Areas
    final String weakAreas;
    if (reportData.weakAreas.isEmpty) {
      weakAreas = _pickPhrase('weakness_none', effectiveDate, {});
    } else {
      final details = reportData.weakAreas
          .map((w) => '${w.topic.displayName} (${w.difficulty.displayName})')
          .join(', ');
      final situation = reportData.weakAreas.length == 1
          ? 'weakness_single'
          : 'weakness_multiple';
      weakAreas = _pickPhrase(situation, effectiveDate, {
        'topic_details': details,
      });
    }

    // 5. Improving / Slipping topics
    final improvingTopics = reportData.topicPerformances
        .where((t) => t.trend == TopicTrend.improving)
        .map((t) => t.topic.displayName)
        .toList();
    final String? improving = improvingTopics.isNotEmpty
        ? _pickPhrase('topics_improving', effectiveDate, {
            'topics': _formatList(improvingTopics),
          })
        : null;

    final slippingTopics = reportData.topicPerformances
        .where((t) => t.trend == TopicTrend.slipping)
        .map((t) => t.topic.displayName)
        .toList();
    final String? slipping = slippingTopics.isNotEmpty
        ? _pickPhrase('topics_slipping', effectiveDate, {
            'topics': _formatList(slippingTopics),
          })
        : null;

    // 6. Neglected and Never Practiced
    final neglectedNames =
        reportData.neglectedTopics.map((t) => t.displayName).toList();
    final String? neglected = neglectedNames.isNotEmpty
        ? _pickPhrase('topics_neglected', effectiveDate, {
            'topics': _formatList(neglectedNames),
          })
        : null;

    final neverNames =
        reportData.neverPracticedTopics.map((t) => t.displayName).toList();
    final String? neverPracticed = neverNames.isNotEmpty
        ? _pickPhrase('topics_never_practiced', effectiveDate, {
            'topics': _formatList(neverNames),
          })
        : null;

    // 7. Mistakes Summary
    final String mistakes;
    if (reportData.mistakeSummary.totalMistakes > 0) {
      final topTopic = reportData.mistakeSummary.topMistakeTopics.isNotEmpty
          ? reportData.mistakeSummary.topMistakeTopics.first.topic.displayName
          : 'all topics';
      mistakes = _pickPhrase('mistakes_active', effectiveDate, {
        'count': reportData.mistakeSummary.totalMistakes.toString(),
        'top_mistake_topic': topTopic,
      });
    } else {
      mistakes = _pickPhrase('mistakes_empty', effectiveDate, {});
    }

    // 8. Closing Push
    final String closingPush;
    if (plan != null && plan.isAllCompleted) {
      closingPush = _pickPhrase('closing_push_all_done', effectiveDate, {
        'total_count': plan.totalCount.toString(),
      });
    } else {
      final count = plan?.totalCount ?? 3;
      closingPush = _pickPhrase('closing_push_ready', effectiveDate, {
        'total_count': count.toString(),
      });
    }

    return ReportText(
      headline: headline,
      weeklyActivity: weeklyActivity,
      weeklyAccuracy: weeklyAccuracy,
      weeklySpeed: weeklySpeed,
      strengths: strengths,
      weakAreas: weakAreas,
      improving: improving,
      slipping: slipping,
      neglected: neglected,
      neverPracticed: neverPracticed,
      mistakes: mistakes,
      closingPush: closingPush,
    );
  }

  /// Picks a phrase variation deterministically seeded by date and situation key,
  /// and substitutes all placeholders.
  String _pickPhrase(
    String situationKey,
    DateTime date,
    Map<String, String> replacements,
  ) {
    final list = _phrases[situationKey] ?? _defaultPhrases[situationKey];
    if (list == null || list.isEmpty) {
      return '';
    }

    // Deterministic seed computation: date + situationKey
    final dateSeed = date.year * 10000 + date.month * 100 + date.day;
    int hash = 17;
    hash = 37 * hash + dateSeed;
    for (int i = 0; i < situationKey.length; i++) {
      hash = 37 * hash + situationKey.codeUnitAt(i);
    }

    final index = hash.abs() % list.length;
    String template = list[index];

    // Replace placeholders
    replacements.forEach((key, value) {
      template = template.replaceAll('{$key}', value);
    });

    // Safety check: ensure no unreplaced placeholders remain
    final unreplaced = RegExp(r'\{[a-zA-Z0-9_]+\}').allMatches(template);
    if (unreplaced.isNotEmpty) {
      // Remove any lingering unknown placeholder cleanly
      template = template.replaceAll(RegExp(r'\{[a-zA-Z0-9_]+\}'), '');
    }

    return template;
  }

  String _formatList(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')}, and ${items.last}';
  }

  /// Embedded fallback phrase bank so tests and offline executions always have phrases.
  static const Map<String, List<String>> _defaultPhrases = {
    'headline_elite': [
      'Outstanding pace! Your Speed Score is {score} ({label}), ranking among the highest tiers.',
      'Remarkable mental sharpness! You hold an Elite Speed Score of {score}.',
      'Elite calculation speed: your overall rating stands at {score} ({label}).',
      'Lightning calculations! You scored {score} ({label}) across your core practice buckets.',
    ],
    'headline_strong': [
      'Solid performance! Your Speed Score is {score} ({label}), showing firm calculation confidence.',
      'Great work this week! You are maintaining a Strong Speed Score of {score}.',
      'Strong mental foundation: your overall rating reached {score} ({label}).',
      'Consistently quick answers keep your Speed Score at {score} ({label}).',
    ],
    'headline_building': [
      'Good momentum! Your Speed Score is {score} ({label}) as your recall quickens.',
      'Steady progress! You are currently at {score} ({label}) on your speed journey.',
      'Your calculation base is growing: current Speed Score is {score} ({label}).',
      'Building solid daily speed! Your overall score is {score} ({label}).',
    ],
    'headline_beginner': [
      'Welcome to daily training! Your Speed Score is {score} ({label}).',
      'Every session counts: you are starting strong at {score} ({label}).',
      'Early stages of speed training: your initial score is {score} ({label}).',
      'Focus on accuracy first: your current score is {score} ({label}).',
    ],
    'headline_no_score': [
      'Complete at least 5 attempts in any topic difficulty to generate your Speed Score.',
      'A few more practice sessions will unlock your overall Speed Score.',
      'Keep practicing across topics to compute your first Speed Score.',
      'Practice any topic 5 times to reveal your official Speed Score.',
    ],
    'weekly_active_more': [
      'You increased your practice to {sessions} sessions and {questions} questions over {minutes} minutes this week.',
      'High engagement: {sessions} sessions completed with {questions} questions answered across {minutes} minutes.',
      'Your practice grew this week to {sessions} sessions, answering {questions} questions in {minutes} minutes.',
      'Great discipline: you logged {sessions} sessions and tackled {questions} questions over {minutes} minutes.',
    ],
    'weekly_active_less': [
      'You completed {sessions} sessions and {questions} questions over {minutes} minutes this week.',
      'This week saw {sessions} sessions with {questions} questions answered in {minutes} minutes.',
      'You spent {minutes} minutes across {sessions} sessions, answering {questions} questions.',
      'Logged {sessions} sessions and {questions} questions this week over {minutes} minutes.',
    ],
    'weekly_active_steady': [
      'Consistent pace: you finished {sessions} sessions and {questions} questions across {minutes} minutes this week.',
      'You maintained a steady rhythm of {sessions} sessions and {questions} questions over {minutes} minutes.',
      'Steady practice volume with {sessions} sessions, {questions} questions, and {minutes} minutes logged.',
      'Your weekly routine held firm at {sessions} sessions and {questions} questions in {minutes} minutes.',
    ],
    'weekly_accuracy_up': [
      'Your overall accuracy rose to {accuracy_pct}, up {accuracy_diff} compared to last week.',
      'Accuracy climbed to {accuracy_pct}, gaining {accuracy_diff} over your previous week.',
      'Sharper precision: weekly accuracy improved by {accuracy_diff} to reach {accuracy_pct}.',
      'Fewer mistakes this week: accuracy gained {accuracy_diff}, reaching {accuracy_pct}.',
    ],
    'weekly_accuracy_down': [
      'Weekly accuracy was {accuracy_pct}, down {accuracy_diff} compared to last week.',
      'Accuracy stood at {accuracy_pct} this week, dropping {accuracy_diff} from last week.',
      'Precision dipped by {accuracy_diff} to {accuracy_pct}; focus on clean inputs during timed drills.',
      'Your weekly accuracy was {accuracy_pct}, down {accuracy_diff} from the prior 7 days.',
    ],
    'weekly_speed_up': [
      'Your average time per correct answer fell by {speed_diff}, now {avg_time}.',
      'Faster recall: you are {speed_diff} faster, averaging {avg_time} per correct answer.',
      'Speed improvement: your average answer time dropped by {speed_diff} to {avg_time}.',
      'Noticeable speed boost: you are {speed_diff} faster this week, now {avg_time} per correct answer.',
    ],
    'weekly_speed_down': [
      'Your average time per correct answer rose by {speed_diff}, now {avg_time}.',
      'Average time per correct answer shifted to {avg_time} ({speed_diff} slower).',
      'Calculations were {speed_diff} slower this week, averaging {avg_time} per correct answer.',
      'Your average answer time was {avg_time}, slowing by {speed_diff} compared to last week.',
    ],
    'strengths_single': [
      'Your strongest area is {topic_details}.',
      'High mastery achieved in {topic_details}.',
      'You have demonstrated strong command over {topic_details}.',
      'Peak speed and precision found in {topic_details}.',
    ],
    'strengths_multiple': [
      'Your top strengths are in {topic_details}.',
      'You have achieved high mastery across {topic_details}.',
      'Strongest calculation areas right now: {topic_details}.',
      'Commanding performance and rapid recall in {topic_details}.',
    ],
    'strengths_none': [
      'Keep practicing to bring your top topics above 80% mastery.',
      'No topics have reached 80% mastery yet; daily drills will unlock your first strength.',
      'Continue regular drills to build your first strong calculation bucket.',
      'Consistent daily practice will push your best topics into the strong category.',
    ],
    'weakness_single': [
      'The primary area needing attention is {topic_details}.',
      'Focus your practice on {topic_details} to boost overall speed.',
      'Target {topic_details} to eliminate hesitation.',
      'Your main growth opportunity is {topic_details}.',
    ],
    'weakness_multiple': [
      'Areas needing more practice: {topic_details}.',
      'Prioritize short drills in {topic_details} to raise mastery.',
      'Your slowest calculation areas: {topic_details}.',
      'Focus targeted sessions on {topic_details} for maximum gains.',
    ],
    'weakness_none': [
      'No weak areas detected! All your practiced buckets maintain solid mastery.',
      'Great job: none of your practiced topics are falling behind.',
      'Zero problem areas: your mastery remains balanced across practiced topics.',
      'All tested areas show reliable mastery and calculation confidence.',
    ],
    'topics_improving': [
      'Great acceleration: {topics} showed clear improvement this week.',
      'Noticeable speed gains in {topics} over the last 7 days.',
      '{topics} is improving with faster correct answers.',
      'Your hard work paid off: {topics} improved significantly this week.',
    ],
    'topics_slipping': [
      'Pace slowed slightly in {topics}; consider a short refresher drill.',
      '{topics} showed a dip in speed or accuracy this week.',
      'Watch out for hesitation in {topics}; quick drills will help restore your speed.',
      'Performance in {topics} slipped recently; run a quick timed session.',
    ],
    'topics_steady': [
      'Pace and precision held steady across your practiced topics.',
      'Consistent performance across your standard topics this week.',
      'Calculations in your main topics remained steady and reliable.',
      'Your practiced topics showed solid, consistent recall times.',
    ],
    'topics_neglected': [
      'It has been a week or more since you practiced {topics}.',
      '{topics} has not been practiced in 7 or more days.',
      'Keep skills sharp: revisit {topics} to prevent recall fade.',
      "Don't lose momentum in {topics}; it has been at least 7 days.",
    ],
    'topics_never_practiced': [
      "You haven't practiced {topics} yet. Try a session to establish your baseline.",
      '{topics} is still unpracticed. Give it a try to build full exam readiness.',
      'Expand your skills by trying {topics} for the first time.',
      'Complete a quick drill in {topics} to unlock tracking for it.',
    ],
    'mistakes_active': [
      'You have {count} mistakes to revise, with the most in {top_mistake_topic}.',
      '{count} mistakes are ready for spaced review, especially in {top_mistake_topic}.',
      'You have {count} mistakes waiting to be revised. Primary topic: {top_mistake_topic}.',
      'Review {count} mistakes to turn errors into fast instincts ({top_mistake_topic}).',
    ],
    'mistakes_empty': [
      'You have zero pending mistakes to revise!',
      'All caught up! No unresolved mistakes waiting.',
      'Clean sheet: you have zero mistakes waiting.',
      'No mistakes to revise. Keep practicing to maintain your edge.',
    ],
    'closing_push_ready': [
      'Today\'s plan is ready with {total_count} targeted blocks (~15 minutes). Tap Start to begin.',
      'Tackle your {total_count} daily practice blocks to build lasting mental speed.',
      'Complete today\'s {total_count} focused practice blocks to keep advancing.',
      'Jump into today\'s {total_count} blocks to reinforce your weakest calculation areas.',
    ],
    'closing_push_all_done': [
      'Fantastic effort! You completed all {total_count} daily plan blocks today.',
      'Daily plan completed! All {total_count} blocks finished for today.',
      'You completed your practice goals for today. Rest up and return tomorrow!',
      'All {total_count} blocks checked off today! Great dedication to mental math mastery.',
    ],
    'empty_report': [
      'Complete at least 20 questions to generate your full performance report.',
      'Your personalized performance report unlocks after answering 20 questions.',
      'Start practicing to unlock your Speed Score, strengths, and daily plan.',
      'Just a little practice needed: 20 answered questions unlock your report.',
    ],
  };
}
