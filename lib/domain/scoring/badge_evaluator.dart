import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../data/models/session.dart';

/// Evaluates qualification for "New Best Score" and "New Top-3 Time" badges.
///
/// Rules from Section 6 of master prompt:
/// - Incomplete sessions (completed = 0) do NOT qualify for best scores or best times.
/// - Top 3 best times only apply to sessions with accuracy of 80% or more (minAccuracyForBestTimes).
/// - Question mode: based on fastest total completion times.
/// - Timer mode: based on lowest average time per correct answer.
/// - Comparison is strictly separated by Topic, Difficulty, Mode, AND mode_value.
class BadgeEvaluator {
  const BadgeEvaluator();

  /// Checks if [newScore] qualifies as a New Best Score.
  bool isNewBestScore({
    required bool completed,
    required double newScore,
    required double? previousBestScore,
  }) {
    if (!completed || newScore <= 0) return false;
    if (previousBestScore == null) return true;
    return newScore > previousBestScore;
  }

  /// Checks if a session qualifies as a New Top-3 Time.
  bool isNewTop3Time({
    required bool completed,
    required double accuracy,
    required PracticeMode mode,
    required int modeValue,
    required int durationMs,
    required double avgTimeMs,
    required List<Session> existingTop3Sessions,
  }) {
    if (!completed) return false;
    if (accuracy < AppConstants.minAccuracyForBestTimes) return false;

    // Only completed sessions matching modeValue with >= 80% accuracy count
    final qualifying = existingTop3Sessions.where((s) {
      if (!s.completed) return false;
      if (s.modeValue != modeValue) return false;
      return s.accuracy >= AppConstants.minAccuracyForBestTimes;
    }).toList();

    if (qualifying.length < 3) return true;

    if (mode == PracticeMode.questions) {
      qualifying.sort((a, b) => a.durationMs.compareTo(b.durationMs));
      return durationMs < qualifying[2].durationMs;
    } else {
      qualifying.sort((a, b) => a.avgTimeMs.compareTo(b.avgTimeMs));
      return avgTimeMs < qualifying[2].avgTimeMs;
    }
  }
}
