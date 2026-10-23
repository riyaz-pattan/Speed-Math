import 'adaptive_constants.dart';
import 'pattern_skill.dart';
import 'skill_rating.dart';

/// Classification of a user's skill bucket.
enum SkillBucketLevel {
  notEnoughData,
  needsWork,
  gettingThere,
  strong;

  String get displayName => switch (this) {
    SkillBucketLevel.notEnoughData => 'Not enough data',
    SkillBucketLevel.needsWork => 'Needs work',
    SkillBucketLevel.gettingThere => 'Getting there',
    SkillBucketLevel.strong => 'Strong',
  };
}

/// Pure Dart engine for skill tracking and mastery updates.
///
/// No Flutter imports — can be unit tested easily.
class SkillEngine {
  const SkillEngine();

  /// Calculates the outcome score for a single answered question.
  ///
  /// - wrong / skipped → 0.0
  /// - correct: score based on speed relative to target time.
  ///   * t <= 0.5 → 1.0
  ///   * t >= 2.0 → 0.5
  ///   * in between → linear from 1.0 to 0.5
  double calculateOutcomeScore({
    required bool isCorrect,
    required bool isSkipped,
    required int timeMs,
    required int targetTimeMs,
  }) {
    if (!isCorrect || isSkipped) return AdaptiveConstants.wrongOutcomeScore;
    if (targetTimeMs <= 0) return AdaptiveConstants.maxOutcomeScore;

    final t = timeMs / targetTimeMs;

    if (t <= AdaptiveConstants.fastThreshold) {
      return AdaptiveConstants.maxOutcomeScore;
    }
    if (t >= AdaptiveConstants.slowThreshold) {
      return AdaptiveConstants.minOutcomeScore;
    }

    // Linear interpolation: at fastThreshold → 1.0, at slowThreshold → 0.5
    final range = AdaptiveConstants.slowThreshold - AdaptiveConstants.fastThreshold;
    final ratio = (t - AdaptiveConstants.fastThreshold) / range;
    return AdaptiveConstants.maxOutcomeScore -
        ratio * (AdaptiveConstants.maxOutcomeScore - AdaptiveConstants.minOutcomeScore);
  }

  /// Updates a [SkillRating] with a new outcome.
  ///
  /// [outcomeScore] is the result of [calculateOutcomeScore].
  /// [timeMsIfCorrect] is set only for correct answers (used for avg time EMA).
  /// [now] can be injected for testing.
  SkillRating updateRating(
    SkillRating current,
    double outcomeScore, {
    int? timeMsIfCorrect,
    DateTime? now,
  }) {
    final alpha = current.attemptsCount < AdaptiveConstants.earlyAttemptThreshold
        ? AdaptiveConstants.alphaEarly
        : AdaptiveConstants.alphaLate;

    final newMastery = current.mastery + alpha * (outcomeScore - current.mastery);

    // Accuracy EMA: 1.0 if correct (score > 0), 0.0 if wrong/skipped
    final accuracyInput = outcomeScore > 0 ? 1.0 : 0.0;
    final newAccuracyEma = current.accuracyEma + alpha * (accuracyInput - current.accuracyEma);

    // Avg time EMA: only update for correct answers
    double newAvgTimeMsEma = current.avgTimeMsEma;
    if (timeMsIfCorrect != null) {
      if (current.avgTimeMsEma == 0.0) {
        newAvgTimeMsEma = timeMsIfCorrect.toDouble();
      } else {
        newAvgTimeMsEma = current.avgTimeMsEma +
            alpha * (timeMsIfCorrect.toDouble() - current.avgTimeMsEma);
      }
    }

    return current.copyWith(
      mastery: newMastery.clamp(0.0, 1.0),
      attemptsCount: current.attemptsCount + 1,
      accuracyEma: newAccuracyEma.clamp(0.0, 1.0),
      avgTimeMsEma: newAvgTimeMsEma,
      lastPracticedAt: now ?? DateTime.now(),
    );
  }

  /// Updates a [PatternSkill] with a new outcome using identical moving-average rules.
  PatternSkill updatePatternSkill(
    PatternSkill current,
    double outcomeScore, {
    int? timeMsIfCorrect,
    DateTime? now,
  }) {
    final alpha = current.attemptsCount < AdaptiveConstants.earlyAttemptThreshold
        ? AdaptiveConstants.alphaEarly
        : AdaptiveConstants.alphaLate;

    final newMastery =
        current.mastery + alpha * (outcomeScore - current.mastery);

    final accuracyInput = outcomeScore > 0 ? 1.0 : 0.0;
    final newAccuracyEma =
        current.accuracyEma + alpha * (accuracyInput - current.accuracyEma);

    double newAvgTimeMsEma = current.avgTimeMsEma;
    if (timeMsIfCorrect != null) {
      if (current.avgTimeMsEma == 0.0) {
        newAvgTimeMsEma = timeMsIfCorrect.toDouble();
      } else {
        newAvgTimeMsEma = current.avgTimeMsEma +
            alpha * (timeMsIfCorrect.toDouble() - current.avgTimeMsEma);
      }
    }

    return current.copyWith(
      mastery: newMastery.clamp(0.0, 1.0),
      attemptsCount: current.attemptsCount + 1,
      accuracyEma: newAccuracyEma.clamp(0.0, 1.0),
      avgTimeMsEma: newAvgTimeMsEma,
      lastPracticedAt: now ?? DateTime.now(),
    );
  }

  /// Classifies a skill bucket based on attempts count and mastery level.
  SkillBucketLevel classifyBucket(SkillRating rating) {
    if (rating.attemptsCount < AdaptiveConstants.minAttemptsForClassification) {
      return SkillBucketLevel.notEnoughData;
    }
    if (rating.mastery < AdaptiveConstants.needsWorkThreshold) {
      return SkillBucketLevel.needsWork;
    }
    if (rating.mastery < AdaptiveConstants.strongThreshold) {
      return SkillBucketLevel.gettingThere;
    }
    return SkillBucketLevel.strong;
  }
}
