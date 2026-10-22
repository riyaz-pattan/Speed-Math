import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/addition_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late AdditionGenerator generator;

  setUp(() {
    generator = AdditionGenerator();
  });

  group('AdditionGenerator', () {
    group('Easy (2-digit + 2-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.addition);
          expect(q.difficulty, Difficulty.easy);
          expect(q.operands.length, 2);

          final a = q.operands[0];
          final b = q.operands[1];

          // Both operands are 2-digit
          expect(a, inInclusiveRange(10, 99), reason: 'a=$a out of range');
          expect(b, inInclusiveRange(10, 99), reason: 'b=$b out of range');

          // No trivial addends (0)
          expect(a, isNot(0));
          expect(b, isNot(0));

          // Correct answer
          expect(q.correctAnswer, a + b);

          // Display text matches
          expect(q.displayText, '$a + $b');

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

    group('Medium (3-digit + 3-digit)', () {
      test('generates 1000 valid questions', () {
        final random = Random(123);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.medium,
            random: random,
            previousQuestion: prev,
          );

          expect(q.operands.length, 2);
          final a = q.operands[0];
          final b = q.operands[1];

          expect(a, inInclusiveRange(100, 999));
          expect(b, inInclusiveRange(100, 999));
          expect(a, isNot(0));
          expect(b, isNot(0));
          expect(q.correctAnswer, a + b);

          prev = q;
        }
      });
    });

    group('Hard (three 3-4 digit numbers)', () {
      test('generates 1000 valid questions', () {
        final random = Random(456);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.hard,
            random: random,
            previousQuestion: prev,
          );

          expect(q.operands.length, 3);
          final a = q.operands[0];
          final b = q.operands[1];
          final c = q.operands[2];

          expect(a, inInclusiveRange(100, 9999));
          expect(b, inInclusiveRange(100, 9999));
          expect(c, inInclusiveRange(100, 9999));

          // Not all ending in 0
          expect(
            a % 10 == 0 && b % 10 == 0 && c % 10 == 0,
            isFalse,
            reason: 'All numbers end in 0: $a, $b, $c',
          );

          expect(q.correctAnswer, a + b + c);
          expect(q.displayText, '$a + $b + $c');

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
