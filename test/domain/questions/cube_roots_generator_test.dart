import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/cube_roots_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  late CubeRootsGenerator generator;

  setUp(() {
    generator = CubeRootsGenerator();
  });

  group('CubeRootsGenerator', () {
    test('topic is Topic.cubeRoots', () {
      expect(generator.topic, Topic.cubeRoots);
    });

    group('Easy (2 to 10)', () {
      test('generates 1000 valid questions, all perfect cubes', () {
        final random = Random(42);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.easy,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.cubeRoots);
          expect(q.difficulty, Difficulty.easy);
          final root = q.correctAnswer;
          expect(root, inInclusiveRange(2, 10));
          final cube = root * root * root;
          expect(q.displayText, '³√$cube');

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

    group('Medium (11 to 20)', () {
      test('generates 1000 valid questions, all perfect cubes', () {
        final random = Random(123);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.medium,
            random: random,
            previousQuestion: prev,
          );

          final root = q.correctAnswer;
          expect(root, inInclusiveRange(11, 20));
          final cube = root * root * root;
          expect(q.displayText, '³√$cube');

          prev = q;
        }
      });
    });

    group('Hard (21 to 35, no multiples of 10 for root)', () {
      test('generates 1000 valid questions, all perfect cubes, no multiples of 10', () {
        final random = Random(456);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.hard,
            random: random,
            previousQuestion: prev,
          );

          final root = q.correctAnswer;
          expect(root, inInclusiveRange(21, 35));
          expect(root % 10, isNot(0), reason: 'Hard cube roots must not be multiples of 10');
          final cube = root * root * root;
          expect(q.displayText, '³√$cube');

          prev = q;
        }
      });
    });

    group('Expert (36 to 60, no multiples of 10 for root)', () {
      test('generates 1000 valid questions, all perfect cubes, no multiples of 10', () {
        final random = Random(789);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.expert,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.cubeRoots);
          expect(q.difficulty, Difficulty.expert);
          final root = q.correctAnswer;
          expect(root, inInclusiveRange(36, 60));
          expect(root % 10, isNot(0), reason: 'Expert cube roots must not be multiples of 10');
          final cube = root * root * root;
          expect(q.displayText, '³√$cube');

          prev = q;
        }
      });
    });

    group('Genius (61 to 100, no multiples of 10 for root)', () {
      test('generates 1000 valid questions, all perfect cubes, no multiples of 10', () {
        final random = Random(101112);
        Question? prev;
        for (var i = 0; i < 1000; i++) {
          final q = generator.generateUnique(
            difficulty: Difficulty.genius,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.cubeRoots);
          expect(q.difficulty, Difficulty.genius);
          final root = q.correctAnswer;
          expect(root, inInclusiveRange(61, 100));
          expect(root % 10, isNot(0), reason: 'Genius cube roots must not be multiples of 10');
          final cube = root * root * root;
          expect(q.displayText, '³√$cube');

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
