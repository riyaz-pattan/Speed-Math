import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/square_roots_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late SquareRootsGenerator generator;

  setUp(() {
    generator = SquareRootsGenerator();
  });

  group('SquareRootsGenerator', () {
    test('topic is Topic.squareRoots', () {
      expect(generator.topic, Topic.squareRoots);
    });

    group('Easy (up to 20² = 400)', () {
      test('generates 1000 valid questions, all perfect squares', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.squareRoots);
          expect(q.difficulty, Difficulty.easy);
          final root = q.correctAnswer;
          expect(root, inInclusiveRange(1, 20));
          final square = root * root;
          expect(q.displayText, '√$square');
          expect(sqrt(square).round(), root); // perfect square guarantee

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

    group('Medium (21² to 50²)', () {
      test('generates 1000 valid questions, all perfect squares', () {
        final random = Random(123);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.medium,
            random: random,
            previousQuestion: prev,
          );

          final root = q.correctAnswer;
          expect(root, inInclusiveRange(21, 50));
          final square = root * root;
          expect(q.displayText, '√$square');
          expect(sqrt(square).round(), root);

          prev = q;
        }
      });
    });

    group('Hard (51² to 99², no multiples of 10 for root)', () {
      test('generates 1000 valid questions, all perfect squares, no multiples of 10', () {
        final random = Random(456);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.hard,
            random: random,
            previousQuestion: prev,
          );

          final root = q.correctAnswer;
          expect(root, inInclusiveRange(51, 99));
          expect(root % 10, isNot(0), reason: 'Hard roots must not be multiples of 10');
          final square = root * root;
          expect(q.displayText, '√$square');
          expect(sqrt(square).round(), root);

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
