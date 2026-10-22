/// Immutable summary of a completed (or partial) practice session.
///
/// Pure Dart — no Flutter imports.
class SessionSummary {
  final double totalScore;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;

  /// Accuracy as a fraction (0.0 to 1.0).
  final double accuracy;

  /// Average time per correct answer in milliseconds.
  /// 0.0 if no correct answers.
  final double avgTimeMsPerCorrect;

  /// Total elapsed time for the session in milliseconds.
  final int totalTimeMs;

  const SessionSummary({
    required this.totalScore,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.accuracy,
    required this.avgTimeMsPerCorrect,
    required this.totalTimeMs,
  });

  @override
  String toString() =>
      'SessionSummary(score: $totalScore, total: $totalQuestions, '
      'correct: $correctCount, wrong: $wrongCount, skipped: $skippedCount, '
      'accuracy: ${(accuracy * 100).toStringAsFixed(1)}%, '
      'avgTime: ${avgTimeMsPerCorrect.toStringAsFixed(0)}ms, '
      'totalTime: ${totalTimeMs}ms)';
}

/// Result of a single answered question, used as input to the summary calculator.
class AttemptResult {
  final bool isCorrect;
  final bool isSkipped;
  final int timeMs;
  final double points;

  const AttemptResult({
    required this.isCorrect,
    required this.isSkipped,
    required this.timeMs,
    required this.points,
  });
}

/// Calculates a [SessionSummary] from a list of [AttemptResult]s.
///
/// Handles edge cases: zero questions, zero correct answers.
class SessionSummaryCalculator {
  const SessionSummaryCalculator();

  SessionSummary calculate(List<AttemptResult> attempts) {
    if (attempts.isEmpty) {
      return const SessionSummary(
        totalScore: 0.0,
        totalQuestions: 0,
        correctCount: 0,
        wrongCount: 0,
        skippedCount: 0,
        accuracy: 0.0,
        avgTimeMsPerCorrect: 0.0,
        totalTimeMs: 0,
      );
    }

    double totalScore = 0.0;
    int correctCount = 0;
    int wrongCount = 0;
    int skippedCount = 0;
    int totalTimeMs = 0;
    int correctTimeMs = 0;

    for (final attempt in attempts) {
      totalScore += attempt.points;
      totalTimeMs += attempt.timeMs;

      if (attempt.isSkipped) {
        skippedCount++;
      } else if (attempt.isCorrect) {
        correctCount++;
        correctTimeMs += attempt.timeMs;
      } else {
        wrongCount++;
      }
    }

    final totalQuestions = attempts.length;
    // Accuracy counts skipped questions against the user: correct / (correct + wrong + skipped)
    final accuracy = totalQuestions > 0 ? correctCount / totalQuestions : 0.0;
    final avgTimeMsPerCorrect =
        correctCount > 0 ? correctTimeMs / correctCount.toDouble() : 0.0;

    return SessionSummary(
      totalScore: totalScore,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      wrongCount: wrongCount,
      skippedCount: skippedCount,
      accuracy: accuracy,
      avgTimeMsPerCorrect: avgTimeMsPerCorrect,
      totalTimeMs: totalTimeMs,
    );
  }
}
