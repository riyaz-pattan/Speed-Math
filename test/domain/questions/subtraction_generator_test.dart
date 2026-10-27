import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/subtraction_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late SubtractionGenerator generator;

  setUp(() {
    generator = SubtractionGenerator();
  });

  group('SubtractionGenerator', () {
    group('Easy (2-digit − 2-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.subtraction);
          expect(q.difficulty, Difficulty.easy);
          expect(q.operands.length, 2);

          final a = q.operands[0];
          final b = q.operands[1];

          expect(a, inInclusiveRange(10, 99));
          expect(b, inInclusiveRange(10, 99));

          // Result is never negative
          expect(q.correctAnswer, greaterThanOrEqualTo(0),
              reason: '$a - $b = ${q.correctAnswer}');
          expect(q.correctAnswer, a - b);

          // a >= b
          expect(a, greaterThanOrEqualTo(b));

          // No trivial (b != 0, a != b to avoid zero result too often)
          expect(b, isNot(0));
          expect(a, isNot(b), reason: 'a == b gives trivial 0');

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

    group('Medium (3-digit − 3-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(123);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.medium,
            random: random,
            previousQuestion: prev,
          );

          final a = q.operands[0];
          final b = q.operands[1];

          expect(a, inInclusiveRange(100, 999));
          expect(b, inInclusiveRange(100, 999));
          expect(q.correctAnswer, greaterThanOrEqualTo(0));
          expect(q.correctAnswer, a - b);
          expect(b, isNot(0));

          prev = q;
        }
      });
    });

    group('Hard (4-digit − 4-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(456);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.hard,
            random: random,
            previousQuestion: prev,
          );

          final a = q.operands[0];
          final b = q.operands[1];

          expect(a, inInclusiveRange(1000, 9999));
          expect(b, inInclusiveRange(1000, 9999));
          expect(q.correctAnswer, greaterThanOrEqualTo(0));
          expect(q.correctAnswer, a - b);

          // Not all ending in 0
          expect(
            a % 10 == 0 && b % 10 == 0,
            isFalse,
            reason: 'All numbers end in 0: $a, $b',
          );

          prev = q;
        }
      });
    });

    group('Expert (5-digit − 5-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(789);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.expert,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.subtraction);
          expect(q.difficulty, Difficulty.expert);
          expect(q.operands.length, 2);

          final a = q.operands[0];
          final b = q.operands[1];

          expect(a, inInclusiveRange(10000, 99999));
          expect(b, inInclusiveRange(10000, 99999));
          expect(a, greaterThanOrEqualTo(b));
          expect(q.correctAnswer, greaterThanOrEqualTo(0));
          expect(q.correctAnswer, a - b);
          expect(q.displayText, '$a − $b');

          expect(
            a % 10 == 0 && b % 10 == 0,
            isFalse,
            reason: 'All numbers end in 0: $a, $b',
          );

          prev = q;
        }
      });
    });

    group('Genius (6-digit − 6-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(101112);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.genius,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.subtraction);
          expect(q.difficulty, Difficulty.genius);
          expect(q.operands.length, 2);

          final a = q.operands[0];
          final b = q.operands[1];

          expect(a, inInclusiveRange(100000, 999999));
          expect(b, inInclusiveRange(100000, 999999));
          expect(a, greaterThanOrEqualTo(b));
          expect(q.correctAnswer, greaterThanOrEqualTo(0));
          expect(q.correctAnswer, a - b);
          expect(q.displayText, '$a − $b');

          expect(
            a % 10 == 0 && b % 10 == 0,
            isFalse,
            reason: 'All numbers end in 0: $a, $b',
          );

          prev = q;
        }
      });
    });

    test('same seed produces same questions', () {
      final q1 = generator.generate(
        difficulty: Difficulty.medium,
        random: Random(999),
      );
      final q2 = generator.generate(
        difficulty: Difficulty.medium,
        random: Random(999),
      );
      expect(q1, equals(q2));
    });
  });
}
