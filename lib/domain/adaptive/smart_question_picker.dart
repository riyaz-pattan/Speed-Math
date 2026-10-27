import 'dart:math';
import '../../core/enums/enums.dart';
import '../../features/practice_session/models/practice_models.dart';
import '../questions/question.dart';
import '../questions/question_generator_registry.dart';
import 'adaptive_constants.dart';
import 'mistake_entry.dart';
import 'pattern_picker.dart';
import 'pattern_skill.dart';
import 'skill_engine.dart';
import 'skill_rating.dart';

/// Result from [SmartQuestionPicker.nextQuestion].
class PickResult {
  final Question question;
  final bool isDueMistake;
  final int? mistakeId;

  const PickResult({
    required this.question,
    required this.isDueMistake,
    this.mistakeId,
  });
}

/// A candidate bucket representing a (topic, difficulty) pair with its skill rating.
class CandidateBucket {
  final Topic topic;
  final Difficulty difficulty;
  final SkillRating rating;
  final SkillBucketLevel level;

  const CandidateBucket({
    required this.topic,
    required this.difficulty,
    required this.rating,
    required this.level,
  });
}

/// Pure Dart adaptive question picker for Smart Practice sessions.
///
/// Implements:
/// - Candidate bucket unlock & cold start (Easy always; Medium/Hard unlocked via progress or prior history)
/// - 60% Weak / 30% Medium (inc. Not enough data) / 10% Strong distribution
/// - Proportional redistribution when bucket classes are empty
/// - Due mistake interleaving (first priority, <= 1/3 of session, never 2 in a row)
/// - Difficulty nudge for 70-80% target success rate (sublist of last 10 attempts)
/// - Deterministic sequence generation via injectable [Random]
/// - Strict no-repeat-previous-question rule
class SmartQuestionPicker {
  final List<Topic> selectedTopics;
  final Map<String, SkillRating> ratings;
  final List<MistakeEntry> dueMistakes;
  final int totalSessionQuestions;
  final Random random;
  final SkillEngine skillEngine;
  final Difficulty? fixedDifficulty;
  final bool focusOnWeakAreas;
  final Map<String, PatternSkill> patternSkills;

  int _dueMistakesServedCount = 0;
  bool _lastWasDueMistake = false;
  final Set<int> _servedMistakeIds = {};
  final Set<String> _sessionAskedDisplayTexts = {};

  SmartQuestionPicker({
    required List<Topic> selectedTopics,
    required this.ratings,
    this.dueMistakes = const [],
    this.totalSessionQuestions = 10,
    Random? random,
    this.skillEngine = const SkillEngine(),
    this.fixedDifficulty,
    this.focusOnWeakAreas = true,
    this.patternSkills = const {},
  })  : selectedTopics = selectedTopics.isEmpty
            ? Topic.standardTopics
            : selectedTopics.where((t) => t != Topic.mixed).toList(),
        random = random ?? Random();

  int get dueMistakesServedCount => _dueMistakesServedCount;
  bool get lastWasDueMistake => _lastWasDueMistake;

  /// Retrieves rating for [topic] and [difficulty], returning a default if not recorded.
  SkillRating getRating(Topic topic, Difficulty difficulty) {
    final key = '${topic.name}:${difficulty.name}';
    return ratings[key] ??
        SkillRating(
          topic: topic,
          difficulty: difficulty,
          mastery: AdaptiveConstants.initialMastery,
          attemptsCount: 0,
        );
  }

  /// Evaluates cold start and returns all unlocked candidate buckets.
  List<CandidateBucket> getCandidateBuckets() {
    final List<CandidateBucket> candidates = [];

    // If a fixed difficulty is specified, all selected topics strictly stay in that difficulty.
    if (fixedDifficulty != null) {
      for (final topic in selectedTopics) {
        final rating = getRating(topic, fixedDifficulty!);
        candidates.add(
          CandidateBucket(
            topic: topic,
            difficulty: fixedDifficulty!,
            rating: rating,
            level: skillEngine.classifyBucket(rating),
          ),
        );
      }
      return candidates;
    }

    for (final topic in selectedTopics) {
      final easyRating = getRating(topic, Difficulty.easy);
      final mediumRating = getRating(topic, Difficulty.medium);
      final hardRating = getRating(topic, Difficulty.hard);

      // Easy is always unlocked
      candidates.add(
        CandidateBucket(
          topic: topic,
          difficulty: Difficulty.easy,
          rating: easyRating,
          level: skillEngine.classifyBucket(easyRating),
        ),
      );

      // Medium unlocks if Easy has >= 5 attempts and >= 0.50 mastery, OR user already practiced Medium
      final mediumUnlocked = (mediumRating.attemptsCount > 0) ||
          (easyRating.attemptsCount >= AdaptiveConstants.coldStartMinAttempts &&
              easyRating.mastery >= AdaptiveConstants.coldStartMinMastery);

      if (mediumUnlocked) {
        candidates.add(
          CandidateBucket(
            topic: topic,
            difficulty: Difficulty.medium,
            rating: mediumRating,
            level: skillEngine.classifyBucket(mediumRating),
          ),
        );

        // Hard unlocks if Medium has >= 5 attempts and >= 0.50 mastery, OR user already practiced Hard
        final hardUnlocked = (hardRating.attemptsCount > 0) ||
            (mediumRating.attemptsCount >=
                    AdaptiveConstants.coldStartMinAttempts &&
                mediumRating.mastery >= AdaptiveConstants.coldStartMinMastery);

        if (hardUnlocked) {
          candidates.add(
            CandidateBucket(
              topic: topic,
              difficulty: Difficulty.hard,
              rating: hardRating,
              level: skillEngine.classifyBucket(hardRating),
            ),
          );
        }
      }
    }

    return candidates;
  }

  /// Picks the next question in the Smart Practice session.
  PickResult nextQuestion({
    Question? previousQuestion,
    List<SessionAttempt>? recentAttempts,
  }) {
    // 1. Check if we should serve a due mistake
    final maxDueMistakes =
        (totalSessionQuestions * AdaptiveConstants.maxDueMistakesRatio).floor();

    if (_dueMistakesServedCount < maxDueMistakes && !_lastWasDueMistake) {
      final candidateMistake = dueMistakes.cast<MistakeEntry?>().firstWhere(
            (m) =>
                m != null &&
                !_servedMistakeIds.contains(m.id) &&
                m.questionText != previousQuestion?.displayText,
            orElse: () => null,
          );

      if (candidateMistake != null) {
        _lastWasDueMistake = true;
        _dueMistakesServedCount++;
        if (candidateMistake.id != null) {
          _servedMistakeIds.add(candidateMistake.id!);
        }

        return PickResult(
          question: candidateMistake.toQuestion(),
          isDueMistake: true,
          mistakeId: candidateMistake.id,
        );
      }
    }

    // 2. Not serving a due mistake -> generate using candidate buckets
    _lastWasDueMistake = false;
    final candidates = getCandidateBuckets();
    if (candidates.isEmpty) {
      // Fallback in case of unexpected state
      final gen = QuestionGeneratorRegistry.getGenerator(Topic.addition);
      final q = gen.generate(difficulty: Difficulty.easy, random: random);
      return PickResult(question: q, isDueMistake: false);
    }

    final CandidateBucket chosenBucket;
    if (!focusOnWeakAreas) {
      chosenBucket = candidates[random.nextInt(candidates.length)];
    } else {
      // Partition candidate buckets into Weak, Medium, and Strong
      final weakBuckets = <CandidateBucket>[];
      final mediumBuckets = <CandidateBucket>[];
      final strongBuckets = <CandidateBucket>[];

      for (final bucket in candidates) {
        switch (bucket.level) {
          case SkillBucketLevel.needsWork:
            weakBuckets.add(bucket);
          case SkillBucketLevel.gettingThere:
          case SkillBucketLevel.notEnoughData:
            // "Not enough data counts as medium"
            mediumBuckets.add(bucket);
          case SkillBucketLevel.strong:
            strongBuckets.add(bucket);
        }
      }

      // Calculate class weights and redistribute if any class is empty
      double wWeak =
          weakBuckets.isNotEmpty ? AdaptiveConstants.weakBucketWeight : 0.0;
      double wMedium =
          mediumBuckets.isNotEmpty ? AdaptiveConstants.mediumBucketWeight : 0.0;
      double wStrong =
          strongBuckets.isNotEmpty ? AdaptiveConstants.strongBucketWeight : 0.0;

      final totalWeight = wWeak + wMedium + wStrong;
      final List<CandidateBucket> chosenClass;

      if (totalWeight <= 0) {
        chosenClass = candidates;
      } else {
        final pWeak = wWeak / totalWeight;
        final pMedium = wMedium / totalWeight;
        final roll = random.nextDouble();

        if (roll < pWeak) {
          chosenClass = weakBuckets;
        } else if (roll < pWeak + pMedium) {
          chosenClass = mediumBuckets;
        } else {
          chosenClass = strongBuckets;
        }
      }

      // Inside the chosen class, lower mastery is more likely
      chosenBucket = _pickBucketByMastery(chosenClass);
    }

    // 3. Difficulty nudge for 70 to 80% success rate (ONLY if Auto difficulty!)
    final finalDifficulty = fixedDifficulty ?? _applyDifficultyNudge(
      chosenTopic: chosenBucket.topic,
      initialDifficulty: chosenBucket.difficulty,
      candidates: candidates,
      recentAttempts: recentAttempts,
    );

    // 4. Pick pattern using 60/40 rule and diversity constraint
    final recentPatterns = recentAttempts
        ?.map((a) => a.question.pattern)
        .whereType<String>()
        .toList();

    final targetPattern = PatternPicker.pickPattern(
      topic: chosenBucket.topic,
      difficulty: finalDifficulty,
      focusWeakAreas: focusOnWeakAreas,
      patternSkills: patternSkills,
      random: random,
      recentPatterns: recentPatterns,
    );

    // 5. Generate question, avoiding session repeats
    final generator =
        QuestionGeneratorRegistry.getGenerator(chosenBucket.topic);
    final askedInSession = <String>{
      if (previousQuestion != null) previousQuestion.displayText,
      if (recentAttempts != null)
        for (final a in recentAttempts) a.question.displayText,
      ..._sessionAskedDisplayTexts,
    };
    final newQuestion = generator.generateUnique(
      difficulty: finalDifficulty,
      random: random,
      previousQuestion: previousQuestion,
      excludedDisplayTexts: askedInSession,
      pattern: targetPattern,
    );
    _sessionAskedDisplayTexts.add(newQuestion.displayText);

    return PickResult(
      question: newQuestion,
      isDueMistake: false,
    );
  }

  /// Weighted selection inside a bucket class where lower mastery is more likely.
  CandidateBucket _pickBucketByMastery(List<CandidateBucket> buckets) {
    if (buckets.length == 1) return buckets.first;

    // Weight inversely proportional to mastery: (1.05 - mastery)
    double sumWeights = 0.0;
    final weights = <double>[];
    for (final b in buckets) {
      final w = (1.05 - b.rating.mastery).clamp(0.05, 1.05);
      weights.add(w);
      sumWeights += w;
    }

    double roll = random.nextDouble() * sumWeights;
    for (int i = 0; i < buckets.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        return buckets[i];
      }
    }

    return buckets.last;
  }

  /// Evaluates first-try accuracy on the last 10 attempts to nudge difficulty.
  Difficulty _applyDifficultyNudge({
    required Topic chosenTopic,
    required Difficulty initialDifficulty,
    required List<CandidateBucket> candidates,
    required List<SessionAttempt>? recentAttempts,
  }) {
    if (recentAttempts == null ||
        recentAttempts.length < AdaptiveConstants.nudgeWindowSize) {
      return initialDifficulty;
    }

    final last10 = recentAttempts.sublist(
      recentAttempts.length - AdaptiveConstants.nudgeWindowSize,
    );
    final correctCount = last10.where((a) => a.isCorrect).length;
    final accuracy = correctCount / AdaptiveConstants.nudgeWindowSize.toDouble();

    final topicCandidates = candidates
        .where((c) => c.topic == chosenTopic)
        .map((c) => c.difficulty)
        .toSet();

    if (accuracy >= AdaptiveConstants.nudgeAccuracyHigh) {
      // Move up one level if candidate exists
      if (initialDifficulty == Difficulty.easy &&
          topicCandidates.contains(Difficulty.medium)) {
        return Difficulty.medium;
      } else if (initialDifficulty == Difficulty.medium &&
          topicCandidates.contains(Difficulty.hard)) {
        return Difficulty.hard;
      }
    } else if (accuracy <= AdaptiveConstants.nudgeAccuracyLow) {
      // Move down one level (Easy is minimum)
      if (initialDifficulty == Difficulty.hard) {
        return Difficulty.medium;
      } else if (initialDifficulty == Difficulty.medium) {
        return Difficulty.easy;
      }
    }

    return initialDifficulty;
  }
}
