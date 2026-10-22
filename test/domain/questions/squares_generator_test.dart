import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/squares_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late SquaresGenerator generator;

  setUp(() {
    generator = SquaresGenerator();
  });

  group('SquaresGenerator', () {
    group('Easy (1–20)', () {
      test('generates 1000 valid questions', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.squares);
          expect(q.difficulty, Difficulty.easy);
          expect(q.operands.length, 2);

          final n = q.operands[0];
          expect(n, inInclusiveRange(1, 20));
          expect(q.operands[1], n, reason: 'operandB should also be n');
          expect(q.correctAnswer, n * n);
          expect(q.displayText, '$n²');

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

    group('Medium (21–50)', () {
      test('generates 1000 valid questions', () {
        final random = Random(123);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.medium,
            random: random,
            previousQuestion: prev,
          );

          final n = q.operands[0];
          expect(n, inInclusiveRange(21, 50));
          expect(q.correctAnswer, n * n);
          expect(q.displayText, '$n²');

          prev = q;
        }
      });
    });

    group('Hard (51–99)', () {
      test('generates 1000 valid questions', () {
        final random = Random(456);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.hard,
            random: random,
            previousQuestion: prev,
          );

          final n = q.operands[0];
          expect(n, inInclusiveRange(51, 99));
          expect(n % 10, isNot(0), reason: 'Hard squares must not be multiples of 10');
          expect(q.correctAnswer, n * n);
          expect(q.displayText, '$n²');

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
