import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';

/// Pure Dart score calculator. No Flutter imports.
///
/// Calculates points and speed bonus for individual answers.
class ScoreCalculator {
  const ScoreCalculator();

  /// Calculates the total points for a single correct answer.
  ///
  /// Returns 0 for wrong or skipped answers.
  /// Points = base (10) × difficulty multiplier + speed bonus.
  double calculatePoints({
    required bool isCorrect,
    required bool isSkipped,
    required Difficulty difficulty,
    required Topic topic,
    required int timeMs,
  }) {
    if (!isCorrect || isSkipped) return 0.0;

    final baseScore =
        AppConstants.basePoints * (AppConstants.difficultyMultipliers[difficulty] ?? 1.0);
    final bonus = calculateSpeedBonus(
      topic: topic,
      difficulty: difficulty,
      timeMs: timeMs,
    );

    return baseScore + bonus;
  }

  /// Calculates the speed bonus for a correct answer.
  ///
  /// Full bonus ([AppConstants.maxSpeedBonus]) if answered at or below 50%
  /// of the target time. No bonus at or above the target time.
  /// Scales linearly in between.
  double calculateSpeedBonus({
    required Topic topic,
    required Difficulty difficulty,
    required int timeMs,
  }) {
    final targetMs = AppConstants.getTargetTimeMs(topic, difficulty);
    final halfTarget = targetMs * 0.5;
    final maxBonus = AppConstants.maxSpeedBonus.toDouble();

    if (timeMs <= halfTarget) {
      return maxBonus;
    }
    if (timeMs >= targetMs) {
      return 0.0;
    }

    // Linear interpolation between halfTarget and targetMs
    // At halfTarget → maxBonus, at targetMs → 0
    final ratio = (targetMs - timeMs) / (targetMs - halfTarget);
    return (maxBonus * ratio).clamp(0.0, maxBonus);
  }
}
