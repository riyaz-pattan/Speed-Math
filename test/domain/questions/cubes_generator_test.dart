import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/cubes_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late CubesGenerator generator;

  setUp(() {
    generator = CubesGenerator();
  });

  group('CubesGenerator', () {
    test('topic is Topic.cubes', () {
      expect(generator.topic, Topic.cubes);
    });

    group('Easy (2–10)', () {
      test('generates 1000 valid questions', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.cubes);
          expect(q.difficulty, Difficulty.easy);
          final n = q.operands[0];
          expect(n, inInclusiveRange(2, 10));
          expect(q.correctAnswer, n * n * n);
          expect(q.displayText, '$n³');

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

    group('Medium (11–20)', () {
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
          expect(n, inInclusiveRange(11, 20));
          expect(q.correctAnswer, n * n * n);
          expect(q.displayText, '$n³');

          prev = q;
        }
      });
    });

    group('Hard (21–35, no multiples of 10)', () {
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
          expect(n, inInclusiveRange(21, 35));
          expect(n % 10, isNot(0), reason: 'Hard cubes must not be multiples of 10');
          expect(q.correctAnswer, n * n * n);
          expect(q.displayText, '$n³');

          prev = q;
        }
      });
    });

    group('Expert (36–60, no multiples of 10)', () {
      test('generates 1000 valid questions', () {
        final random = Random(789);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.expert,
            random: random,
            previousQuestion: prev,
          );

          expect(q.difficulty, Difficulty.expert);
          final n = q.operands[0];
          expect(n, inInclusiveRange(36, 60));
          expect(n % 10, isNot(0), reason: 'Expert cubes must not be multiples of 10');
          expect(q.correctAnswer, n * n * n);
          expect(q.displayText, '$n³');

          prev = q;
        }
      });
    });

    group('Genius (61–100, no multiples of 10)', () {
      test('generates 1000 valid questions', () {
        final random = Random(101112);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.genius,
            random: random,
            previousQuestion: prev,
          );

          expect(q.difficulty, Difficulty.genius);
          final n = q.operands[0];
          expect(n, inInclusiveRange(61, 100));
          expect(n % 10, isNot(0), reason: 'Genius cubes must not be multiples of 10');
          expect(q.correctAnswer, n * n * n);
          expect(q.displayText, '$n³');

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
