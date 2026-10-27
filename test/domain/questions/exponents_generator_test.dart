import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/exponents_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late ExponentsGenerator generator;

  setUp(() {
    generator = ExponentsGenerator();
  });

  group('ExponentsGenerator', () {
    test('topic is Topic.exponents', () {
      expect(generator.topic, Topic.exponents);
    });

    group('Easy (base 2..9, pow 2..3)', () {
      test('generates 1000 valid questions', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.exponents);
          expect(q.difficulty, Difficulty.easy);
          final base = q.operands[0];
          final power = q.operands[1];

          expect(base, inInclusiveRange(2, 9));
          expect(power, inInclusiveRange(2, 3));
          expect(base, isNot(1));
          expect(base, isNot(10));

          int expected = 1;
          for (var p = 0; p < power; p++) {
            expected *= base;
          }
          expect(q.correctAnswer, expected);
          expect(q.correctAnswer, lessThanOrEqualTo(1000000));
          expect(q.displayText, '$base^$power');

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

    group('Medium (base 2..9, pow 2..5)', () {
      test('generates 1000 valid questions', () {
        final random = Random(123);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.medium,
            random: random,
            previousQuestion: prev,
          );

          final base = q.operands[0];
          final power = q.operands[1];

          expect(base, inInclusiveRange(2, 9));
          expect(power, inInclusiveRange(2, 5));
          expect(base, isNot(1));
          expect(base, isNot(10));

          int expected = 1;
          for (var p = 0; p < power; p++) {
            expected *= base;
          }
          expect(q.correctAnswer, expected);
          expect(q.correctAnswer, lessThanOrEqualTo(1000000));
          expect(q.displayText, '$base^$power');

          prev = q;
        }
      });
    });

    group('Hard (base 2..15, pow 3..6, result <= 1,000,000)', () {
      test('generates 1000 valid questions, never >1,000,000, never base 1 or 10', () {
        final random = Random(456);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.hard,
            random: random,
            previousQuestion: prev,
          );

          final base = q.operands[0];
          final power = q.operands[1];

          expect(base, inInclusiveRange(2, 15));
          expect(power, inInclusiveRange(3, 6));
          expect(base, isNot(1), reason: 'Exponents must never use base 1');
          expect(base, isNot(10), reason: 'Exponents must never use base 10');

          int expected = 1;
          for (var p = 0; p < power; p++) {
            expected *= base;
          }
          expect(q.correctAnswer, expected);
          expect(q.correctAnswer, lessThanOrEqualTo(1000000),
              reason: 'Result must never exceed 1,000,000');
          expect(q.displayText, '$base^$power');

          prev = q;
        }
      });
    });

    group('Expert (higher powers and bases, result <= 5,000,000)', () {
      test('generates 1000 valid questions, never >5,000,000, never base 1 or 10', () {
        final random = Random(789);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.expert,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.exponents);
          expect(q.difficulty, Difficulty.expert);
          final base = q.operands[0];
          final power = q.operands[1];

          expect(base, isNot(1), reason: 'Exponents must never use base 1');
          expect(base, isNot(10), reason: 'Exponents must never use base 10');

          int expected = 1;
          for (var p = 0; p < power; p++) {
            expected *= base;
          }
          expect(q.correctAnswer, expected);
          expect(q.correctAnswer, lessThanOrEqualTo(5000000),
              reason: 'Result must never exceed 5,000,000');
          expect(q.displayText, '$base^$power');

          prev = q;
        }
      });
    });

    group('Genius (peak mental powers, result <= 50,000,000)', () {
      test('generates 1000 valid questions, never >50,000,000, never base 1 or 10', () {
        final random = Random(101112);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.genius,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.exponents);
          expect(q.difficulty, Difficulty.genius);
          final base = q.operands[0];
          final power = q.operands[1];

          expect(base, isNot(1), reason: 'Exponents must never use base 1');
          expect(base, isNot(10), reason: 'Exponents must never use base 10');

          int expected = 1;
          for (var p = 0; p < power; p++) {
            expected *= base;
          }
          expect(q.correctAnswer, expected);
          expect(q.correctAnswer, lessThanOrEqualTo(50000000),
              reason: 'Result must never exceed 50,000,000');
          expect(q.displayText, '$base^$power');

          prev = q;
        }
      });
    });

    test('same seed produces same questions', () {
      final q1 = generator.generate(
        difficulty: Difficulty.hard,
        random: Random(999),
      );
      final q2 = generator.generate(
        difficulty: Difficulty.hard,
        random: Random(999),
      );
      expect(q1, equals(q2));
    });
  });
}
