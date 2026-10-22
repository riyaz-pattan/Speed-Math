import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/domain/scoring/session_summary.dart';

void main() {
  late SessionSummaryCalculator calculator;

  setUp(() {
    calculator = const SessionSummaryCalculator();
  });

  group('SessionSummaryCalculator', () {
    test('empty attempts list returns zero summary', () {
      final summary = calculator.calculate([]);

      expect(summary.totalScore, 0.0);
      expect(summary.totalQuestions, 0);
      expect(summary.correctCount, 0);
      expect(summary.wrongCount, 0);
      expect(summary.skippedCount, 0);
      expect(summary.accuracy, 0.0);
      expect(summary.avgTimeMsPerCorrect, 0.0);
      expect(summary.totalTimeMs, 0);
    });

    test('all correct answers', () {
      final attempts = [
        const AttemptResult(isCorrect: true, isSkipped: false, timeMs: 3000, points: 15.0),
        const AttemptResult(isCorrect: true, isSkipped: false, timeMs: 2000, points: 12.5),
        const AttemptResult(isCorrect: true, isSkipped: false, timeMs: 4000, points: 10.0),
      ];

      final summary = calculator.calculate(attempts);

      expect(summary.totalScore, 37.5);
      expect(summary.totalQuestions, 3);
      expect(summary.correctCount, 3);
      expect(summary.wrongCount, 0);
      expect(summary.skippedCount, 0);
      expect(summary.accuracy, 1.0);
      expect(summary.avgTimeMsPerCorrect, 3000.0); // (3000+2000+4000)/3
      expect(summary.totalTimeMs, 9000);
    });

    test('mixed correct, wrong, and skipped', () {
      final attempts = [
        const AttemptResult(isCorrect: true, isSkipped: false, timeMs: 2000, points: 15.0),
        const AttemptResult(isCorrect: false, isSkipped: false, timeMs: 5000, points: 0.0),
        const AttemptResult(isCorrect: false, isSkipped: true, timeMs: 1000, points: 0.0),
        const AttemptResult(isCorrect: true, isSkipped: false, timeMs: 3000, points: 10.0),
      ];

      final summary = calculator.calculate(attempts);

      expect(summary.totalScore, 25.0);
      expect(summary.totalQuestions, 4);
      expect(summary.correctCount, 2);
      expect(summary.wrongCount, 1);
      expect(summary.skippedCount, 1);
      // accuracy = correct / (correct + wrong + skipped) = 2 / 4 = 0.5
      expect(summary.accuracy, 0.5);
      // avgTime for correct = (2000+3000)/2 = 2500
      expect(summary.avgTimeMsPerCorrect, 2500.0);
      expect(summary.totalTimeMs, 11000);
    });

    test('skipped questions count against accuracy', () {
      final attempts = [
        const AttemptResult(isCorrect: true, isSkipped: false, timeMs: 1000, points: 10.0),
        const AttemptResult(isCorrect: false, isSkipped: true, timeMs: 500, points: 0.0),
      ];

      final summary = calculator.calculate(attempts);
      // 1 correct out of 2 total (1 correct + 1 skipped) = 50%
      expect(summary.accuracy, 0.5);
    });

    test('all wrong answers — no divide-by-zero', () {
      final attempts = [
        const AttemptResult(isCorrect: false, isSkipped: false, timeMs: 5000, points: 0.0),
        const AttemptResult(isCorrect: false, isSkipped: false, timeMs: 3000, points: 0.0),
      ];

      final summary = calculator.calculate(attempts);

      expect(summary.totalScore, 0.0);
      expect(summary.totalQuestions, 2);
      expect(summary.correctCount, 0);
      expect(summary.wrongCount, 2);
      expect(summary.skippedCount, 0);
      expect(summary.accuracy, 0.0);
      expect(summary.avgTimeMsPerCorrect, 0.0); // no divide by zero
      expect(summary.totalTimeMs, 8000);
    });

    test('all skipped answers — no divide-by-zero', () {
      final attempts = [
        const AttemptResult(isCorrect: false, isSkipped: true, timeMs: 500, points: 0.0),
        const AttemptResult(isCorrect: false, isSkipped: true, timeMs: 300, points: 0.0),
      ];

      final summary = calculator.calculate(attempts);

      expect(summary.totalScore, 0.0);
      expect(summary.totalQuestions, 2);
      expect(summary.correctCount, 0);
      expect(summary.wrongCount, 0);
      expect(summary.skippedCount, 2);
      // No answered questions → accuracy 0
      expect(summary.accuracy, 0.0);
      expect(summary.avgTimeMsPerCorrect, 0.0);
      expect(summary.totalTimeMs, 800);
    });

    test('single correct answer', () {
      final attempts = [
        const AttemptResult(isCorrect: true, isSkipped: false, timeMs: 4500, points: 20.0),
      ];

      final summary = calculator.calculate(attempts);

      expect(summary.totalScore, 20.0);
      expect(summary.totalQuestions, 1);
      expect(summary.correctCount, 1);
      expect(summary.accuracy, 1.0);
      expect(summary.avgTimeMsPerCorrect, 4500.0);
    });

    test('large session', () {
      final attempts = List.generate(
        50,
        (i) => AttemptResult(
          isCorrect: i % 3 != 0, // 2/3 correct
          isSkipped: false,
          timeMs: 2000 + i * 100,
          points: i % 3 != 0 ? 10.0 : 0.0,
        ),
      );

      final summary = calculator.calculate(attempts);

      expect(summary.totalQuestions, 50);
      expect(summary.correctCount + summary.wrongCount, 50);
      expect(summary.totalScore, greaterThan(0));
      expect(summary.accuracy, greaterThan(0));
      expect(summary.accuracy, lessThanOrEqualTo(1.0));
      expect(summary.avgTimeMsPerCorrect, greaterThan(0));
    });
  });
}
