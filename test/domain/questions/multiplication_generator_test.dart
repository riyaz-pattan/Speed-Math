import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/multiplication_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late MultiplicationGenerator generator;

  setUp(() {
    generator = MultiplicationGenerator();
  });

  group('MultiplicationGenerator', () {
    group('Easy (2-digit × 1-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.multiplication);
          expect(q.difficulty, Difficulty.easy);
          expect(q.operands.length, 2);

          final a = q.operands[0];
          final b = q.operands[1];

          expect(a, inInclusiveRange(10, 99));
          expect(b, inInclusiveRange(2, 9));

          // No trivial factors
          expect(a, isNot(0));
          expect(a, isNot(1));
          expect(a, isNot(10));
          expect(b, isNot(0));
          expect(b, isNot(1));

          expect(q.correctAnswer, a * b);
          expect(q.displayText, '$a × $b');

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

    group('Medium (2-digit × 2-digit)', () {
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

          expect(a, inInclusiveRange(10, 99));
          expect(b, inInclusiveRange(10, 99));

          // No trivial factors
          expect(a, isNot(0));
          expect(a, isNot(1));
          expect(a, isNot(10));
          expect(b, isNot(0));
          expect(b, isNot(1));
          expect(b, isNot(10));

          expect(q.correctAnswer, a * b);

          prev = q;
        }
      });
    });

    group('Hard (3-digit × 2-digit)', () {
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

          expect(a, inInclusiveRange(100, 999));
          expect(b, inInclusiveRange(10, 99));

          // No trivial factors
          expect(a, isNot(0));
          expect(a, isNot(1));
          expect(a, isNot(10));
          expect(b, isNot(0));
          expect(b, isNot(1));
          expect(b, isNot(10));

          // Not all ending in 0
          expect(
            a % 10 == 0 && b % 10 == 0,
            isFalse,
            reason: 'All numbers end in 0: $a, $b',
          );

          expect(q.correctAnswer, a * b);

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
