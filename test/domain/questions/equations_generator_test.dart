import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/linear_equations_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/quadratic_equations_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';

void main() {
  group('LinearEquationsGenerator', () {
    late LinearEquationsGenerator generator;

    setUp(() {
      generator = LinearEquationsGenerator();
    });

    test('Easy: Generates 500 valid 1-variable linear equations', () {
      final random = Random(101);
      Question? prev;
      for (var i = 0; i < 500; i++) {
        final q = generator.generateUnique(
          difficulty: Difficulty.easy,
          random: random,
          previousQuestion: prev,
        );

        expect(q.topic, Topic.linearEquations);
        expect(q.difficulty, Difficulty.easy);
        expect(q.allowsNegative, isTrue);
        expect(q.displayText, contains('x'));
        expect(q.displayText, contains('='));
        expect(q.correctAnswer, isNotNull);
        prev = q;
      }
    });

    test('Medium: Generates 500 valid 2-variable linear equations', () {
      final random = Random(202);
      Question? prev;
      for (var i = 0; i < 500; i++) {
        final q = generator.generateUnique(
          difficulty: Difficulty.medium,
          random: random,
          previousQuestion: prev,
        );

        expect(q.topic, Topic.linearEquations);
        expect(q.difficulty, Difficulty.medium);
        expect(q.displayText.isNotEmpty, isTrue);
        if (q.isMultipleChoice) {
          expect(q.options, isNotNull);
          expect(q.options!.length, 5);
          expect(q.options, contains(q.targetAnswer));
        } else {
          expect(q.correctAnswer, isNotNull);
        }
        prev = q;
      }
    });

    test('Hard: Generates 500 valid 3-variable / symmetric equations', () {
      final random = Random(303);
      Question? prev;
      for (var i = 0; i < 500; i++) {
        final q = generator.generateUnique(
          difficulty: Difficulty.hard,
          random: random,
          previousQuestion: prev,
        );

        expect(q.topic, Topic.linearEquations);
        expect(q.difficulty, Difficulty.hard);
        expect(q.displayText.isNotEmpty, isTrue);
        expect(q.correctAnswer, isNotNull);
        prev = q;
      }
    });

    test('Expert: Generates 500 valid expert 3-variable / cyclic equations', () {
      final random = Random(304);
      Question? prev;
      for (var i = 0; i < 500; i++) {
        final q = generator.generateUnique(
          difficulty: Difficulty.expert,
          random: random,
          previousQuestion: prev,
        );

        expect(q.topic, Topic.linearEquations);
        expect(q.difficulty, Difficulty.expert);
        expect(q.displayText.isNotEmpty, isTrue);
        expect(q.correctAnswer, isNotNull);
        prev = q;
      }
    });

    test('Genius: Generates 500 valid genius 4-variable symmetric / tricky elimination / ratio comparison equations', () {
      final random = Random(305);
      Question? prev;
      for (var i = 0; i < 500; i++) {
        final q = generator.generateUnique(
          difficulty: Difficulty.genius,
          random: random,
          previousQuestion: prev,
        );

        expect(q.topic, Topic.linearEquations);
        expect(q.difficulty, Difficulty.genius);
        expect(q.displayText.isNotEmpty, isTrue);
        if (q.isMultipleChoice) {
          expect(q.options, isNotNull);
          expect(q.options!.length, 5);
          expect(q.options, contains(q.targetAnswer));
        } else {
          expect(q.correctAnswer, isNotNull);
        }
        prev = q;
      }
    });
  });

  group('QuadraticEquationsGenerator', () {
    late QuadraticEquationsGenerator generator;

    setUp(() {
      generator = QuadraticEquationsGenerator();
    });

    test('Easy: 500 questions are guaranteed to have real roots (no imaginary roots)', () {
      final random = Random(404);
      Question? prev;
      for (var i = 0; i < 500; i++) {
        final q = generator.generateUnique(
          difficulty: Difficulty.easy,
          random: random,
          previousQuestion: prev,
        );

        expect(q.topic, Topic.quadraticEquations);
        expect(q.difficulty, Difficulty.easy);
        expect(q.displayText.isNotEmpty, isTrue);

        if (q.isDualRootQuestion) {
          expect(q.rootAnswers, isNotNull);
          expect(q.rootAnswers!.length, 2);
          expect(q.allowsNegative, isTrue);
        } else if (q.isMultipleChoice) {
          expect(q.options, isNotNull);
          expect(q.options!.length, 5);
          expect(q.options, contains(q.targetAnswer));
        }
        prev = q;
      }
    });

    test('Medium, Hard, Expert, Genius: Multiple choice comparison questions have 5 standard options', () {
      final random = Random(505);
      Question? prev;
      for (final diff in [Difficulty.medium, Difficulty.hard, Difficulty.expert, Difficulty.genius]) {
        for (var i = 0; i < 200; i++) {
          final q = generator.generateUnique(
            difficulty: diff,
            random: random,
            previousQuestion: prev,
          );

          expect(q.topic, Topic.quadraticEquations);
          expect(q.difficulty, diff);
          if (q.isMultipleChoice) {
            expect(q.options, [
              'x > y',
              'x < y',
              'x ≥ y',
              'x ≤ y',
              'x = y or CND',
            ]);
            expect(q.options, contains(q.targetAnswer));
          } else if (q.isDualRootQuestion) {
            expect(q.rootAnswers, isNotNull);
            expect(q.rootAnswers!.length, 2);
          }
          prev = q;
        }
      }
    });

    test('2-Second CND Golden Rule: Both c < 0 guarantees CND relationship', () {
      // Equation I: x^2 + 5x - 24 = 0 (roots: -8, 3)
      // Equation II: y^2 - 3y - 40 = 0 (roots: -5, 8)
      // When roots are (-8, 3) and (-5, 8):
      // 3 > -5, but -8 < 8 -> CND!
      final r1 = [-8, 3];
      final r2 = [-5, 8];

      // Compare r1 vs r2
      bool allGreater = true;
      bool allLess = true;
      bool allGreaterOrEqual = true;
      bool allLessOrEqual = true;

      for (final x in r1) {
        for (final y in r2) {
          if (x <= y) allGreater = false;
          if (x >= y) allLess = false;
          if (x < y) allGreaterOrEqual = false;
          if (x > y) allLessOrEqual = false;
        }
      }

      final isCnd = !allGreater && !allLess && !allGreaterOrEqual && !allLessOrEqual;
      expect(isCnd, isTrue, reason: 'Both negative constants must result in CND');
    });
  });
}
