import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/division_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late DivisionGenerator generator;

  setUp(() {
    generator = DivisionGenerator();
  });

  group('DivisionGenerator', () {
    group('Easy (2-digit ÷ 1-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.division);
          expect(q.difficulty, Difficulty.easy);
          expect(q.operands.length, 2);

          final dividend = q.operands[0];
          final divisor = q.operands[1];

          // Dividend is 2-digit
          expect(dividend, inInclusiveRange(10, 99),
              reason: 'dividend=$dividend');

          // Divisor is 1-digit, not 0 or 1
          expect(divisor, inInclusiveRange(2, 9),
              reason: 'divisor=$divisor');

          // Divisor is not 10 (trivial)
          expect(divisor, isNot(10));

          // Exact whole-number answer
          expect(dividend % divisor, 0,
              reason: '$dividend ÷ $divisor has remainder');
          expect(q.correctAnswer, dividend ~/ divisor);

          // Answer is positive
          expect(q.correctAnswer, greaterThan(0));

          prev = q;
        }
      });

      test('no back-to-back duplicates', () {
        final random = Random(42);
        Question? prev;
        int duplicates = 0;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );
          if (prev != null && q == prev) duplicates++;
          prev = q;
        }
        expect(duplicates, 0);
      });
    });

    group('Medium (3-digit ÷ 1-digit or 2-digit ÷ 2-digit)', () {
      test('generates 1000 valid questions with correct ranges', () {
        final random = Random(123);
        Question? prev;
        int threeByOne = 0;
        int twoByTwo = 0;

        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.medium,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.division);
          expect(q.difficulty, Difficulty.medium);

          final dividend = q.operands[0];
          final divisor = q.operands[1];

          // Divisor is never 0 or 1
          expect(divisor, greaterThan(1));

          // Exact division
          expect(dividend % divisor, 0,
              reason: '$dividend ÷ $divisor has remainder');
          expect(q.correctAnswer, dividend ~/ divisor);
          expect(q.correctAnswer, greaterThan(0));

          // Track subtypes and check ranges
          if (divisor < 10) {
            // 3-digit ÷ 1-digit: divisor 3-9, quotient 30-150
            expect(dividend, inInclusiveRange(100, 999));
            expect(divisor, inInclusiveRange(3, 9));
            expect(q.correctAnswer, inInclusiveRange(30, 150));
            threeByOne++;
          } else {
            // 2-digit ÷ 2-digit: divisor 11-25, quotient 3-9
            expect(dividend, inInclusiveRange(10, 99));
            expect(divisor, inInclusiveRange(11, 25));
            expect(q.correctAnswer, inInclusiveRange(3, 9));
            twoByTwo++;
          }

          prev = q;
        }

        // Both subtypes should appear
        expect(threeByOne, greaterThan(0),
            reason: 'No 3÷1 questions generated');
        expect(twoByTwo, greaterThan(0),
            reason: 'No 2÷2 questions generated');
      });

      test('answer variety: at least 20 distinct answers, none >10%', () {
        final random = Random(77);
        final answerCounts = <int, int>{};
        Question? prev;

        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.medium,
            random: random,
            previousQuestion: prev,
          );
          answerCounts[q.correctAnswer] =
              (answerCounts[q.correctAnswer] ?? 0) + 1;
          prev = q;
        }

        expect(answerCounts.keys.length, greaterThanOrEqualTo(20),
            reason: 'Only ${answerCounts.keys.length} distinct answers');

        for (final entry in answerCounts.entries) {
          expect(entry.value, lessThanOrEqualTo(100),
              reason: 'Answer ${entry.key} appeared ${entry.value}/1000 '
                  '(${(entry.value / 10).toStringAsFixed(1)}%), exceeds 10%');
        }
      });
    });

    group('Hard (4-digit ÷ 2-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(456);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.hard,
            random: random,
            previousQuestion: prev,
          );

          final dividend = q.operands[0];
          final divisor = q.operands[1];

          // Dividend is 4-digit
          expect(dividend, inInclusiveRange(1000, 9999));

          // Divisor is 2-digit, not 10
          expect(divisor, inInclusiveRange(11, 99));
          expect(divisor, isNot(10));

          // Not all ending in 0
          expect(
            dividend % 10 == 0 && divisor % 10 == 0,
            isFalse,
            reason: 'All numbers end in 0: $dividend, $divisor',
          );

          // Exact division
          expect(dividend % divisor, 0);
          expect(q.correctAnswer, dividend ~/ divisor);
          expect(q.correctAnswer, greaterThan(0));

          prev = q;
        }
      });
    });

    group('Expert (5-digit ÷ 2-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(789);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.expert,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.division);
          expect(q.difficulty, Difficulty.expert);
          expect(q.operands.length, 2);

          final dividend = q.operands[0];
          final divisor = q.operands[1];

          expect(dividend, inInclusiveRange(10000, 99999));
          expect(divisor, inInclusiveRange(15, 99));

          expect(
            dividend % 10 == 0 && divisor % 10 == 0,
            isFalse,
            reason: 'All numbers end in 0: $dividend, $divisor',
          );

          expect(dividend % divisor, 0);
          expect(q.correctAnswer, dividend ~/ divisor);
          expect(q.correctAnswer, greaterThan(0));
          expect(q.displayText, '$dividend ÷ $divisor');

          prev = q;
        }
      });
    });

    group('Genius (5-to-6 digit ÷ 3-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(101112);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.genius,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.division);
          expect(q.difficulty, Difficulty.genius);
          expect(q.operands.length, 2);

          final dividend = q.operands[0];
          final divisor = q.operands[1];

          expect(dividend, inInclusiveRange(10000, 999999));
          expect(divisor, inInclusiveRange(100, 999));

          expect(
            dividend % 10 == 0 && divisor % 10 == 0,
            isFalse,
            reason: 'All numbers end in 0: $dividend, $divisor',
          );

          expect(dividend % divisor, 0);
          expect(q.correctAnswer, dividend ~/ divisor);
          expect(q.correctAnswer, greaterThan(0));
          expect(q.displayText, '$dividend ÷ $divisor');

          prev = q;
        }
      });
    });

    test('same seed produces same questions', () {
      final q1 = generator.generate(
        difficulty: Difficulty.easy,
        random: Random(999),
      );
      final q2 = generator.generate(
        difficulty: Difficulty.easy,
        random: Random(999),
      );
      expect(q1, equals(q2));
    });
  });
}
