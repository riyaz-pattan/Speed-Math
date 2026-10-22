import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/scoring/score_calculator.dart';

void main() {
  late ScoreCalculator calculator;

  setUp(() {
    calculator = const ScoreCalculator();
  });

  group('ScoreCalculator', () {
    group('calculatePoints', () {
      test('correct easy answer gets 10 × 1.0 = 10 base points', () {
        final points = calculator.calculatePoints(
          isCorrect: true,
          isSkipped: false,
          difficulty: Difficulty.easy,
          topic: Topic.addition,
          timeMs: 10000, // at target time, no speed bonus
        );
        // At or above target time → 0 speed bonus
        expect(points, 10.0);
      });

      test('correct medium answer gets 10 × 1.5 = 15 base points', () {
        final points = calculator.calculatePoints(
          isCorrect: true,
          isSkipped: false,
          difficulty: Difficulty.medium,
          topic: Topic.addition,
          timeMs: 20000, // well above target
        );
        expect(points, 15.0);
      });

      test('correct hard answer gets 10 × 2.0 = 20 base points', () {
        final points = calculator.calculatePoints(
          isCorrect: true,
          isSkipped: false,
          difficulty: Difficulty.hard,
          topic: Topic.addition,
          timeMs: 20000,
        );
        expect(points, 20.0);
      });

      test('wrong answer gets 0 points', () {
        final points = calculator.calculatePoints(
          isCorrect: false,
          isSkipped: false,
          difficulty: Difficulty.easy,
          topic: Topic.addition,
          timeMs: 1000,
        );
        expect(points, 0.0);
      });

      test('skipped answer gets 0 points', () {
        final points = calculator.calculatePoints(
          isCorrect: false,
          isSkipped: true,
          difficulty: Difficulty.hard,
          topic: Topic.multiplication,
          timeMs: 500,
        );
        expect(points, 0.0);
      });

      test('correct + skipped still gets 0 (skipped takes priority)', () {
        final points = calculator.calculatePoints(
          isCorrect: true,
          isSkipped: true,
          difficulty: Difficulty.easy,
          topic: Topic.addition,
          timeMs: 500,
        );
        expect(points, 0.0);
      });
    });

    group('calculateSpeedBonus', () {
      // Addition easy target = 4000ms, half = 2000ms

      test('full bonus at or below 50% of target time', () {
        final bonus = calculator.calculateSpeedBonus(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          timeMs: 2000, // exactly 50% of 4000ms
        );
        expect(bonus, 5.0);
      });

      test('full bonus well below 50% of target time', () {
        final bonus = calculator.calculateSpeedBonus(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          timeMs: 500,
        );
        expect(bonus, 5.0);
      });

      test('zero bonus at target time', () {
        final bonus = calculator.calculateSpeedBonus(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          timeMs: 4000,
        );
        expect(bonus, 0.0);
      });

      test('zero bonus above target time', () {
        final bonus = calculator.calculateSpeedBonus(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          timeMs: 10000,
        );
        expect(bonus, 0.0);
      });

      test('half bonus at 75% of target time (midpoint)', () {
        // Target 4000, half 2000. Midpoint of [2000, 4000] is 3000ms.
        // Linear: at 3000, ratio = (4000-3000)/(4000-2000) = 0.5
        // Bonus = 5 * 0.5 = 2.5
        final bonus = calculator.calculateSpeedBonus(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          timeMs: 3000,
        );
        expect(bonus, closeTo(2.5, 0.01));
      });

      test('quarter bonus at 87.5% of target time', () {
        // At 3500ms: ratio = (4000-3500)/(4000-2000) = 0.25
        // Bonus = 5 * 0.25 = 1.25
        final bonus = calculator.calculateSpeedBonus(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          timeMs: 3500,
        );
        expect(bonus, closeTo(1.25, 0.01));
      });

      test('works for different topics and difficulties', () {
        // Multiplication hard target = 15000, half = 7500
        final bonus = calculator.calculateSpeedBonus(
          topic: Topic.multiplication,
          difficulty: Difficulty.hard,
          timeMs: 7500,
        );
        expect(bonus, 5.0);

        final bonusMid = calculator.calculateSpeedBonus(
          topic: Topic.multiplication,
          difficulty: Difficulty.hard,
          timeMs: 11250, // midpoint
        );
        expect(bonusMid, closeTo(2.5, 0.01));
      });
    });

    group('full points with speed bonus', () {
      test('fast correct easy answer includes speed bonus', () {
        final points = calculator.calculatePoints(
          isCorrect: true,
          isSkipped: false,
          difficulty: Difficulty.easy,
          topic: Topic.addition,
          timeMs: 1000, // well below half target → full 5.0 bonus
        );
        expect(points, 15.0); // 10 + 5
      });

      test('fast correct hard answer includes speed bonus', () {
        final points = calculator.calculatePoints(
          isCorrect: true,
          isSkipped: false,
          difficulty: Difficulty.hard,
          topic: Topic.addition,
          timeMs: 1000,
        );
        expect(points, 25.0); // 20 + 5
      });
    });
  });
}
