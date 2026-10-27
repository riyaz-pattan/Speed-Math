import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/approximation_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/averages_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/fractions_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/missing_number_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/number_series_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/percentages_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/simplification_generator.dart';

void main() {
  final random = Random(42);

  group('PercentagesGenerator Expert & Genius', () {
    final generator = PercentagesGenerator();

    test('generates valid Expert questions with correct difficulty and positive answer', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.topic, Topic.percentages);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, isNotEmpty);
      }
    });

    test('generates valid Genius questions with correct difficulty and positive answer', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.topic, Topic.percentages);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, isNotEmpty);
      }
    });
  });

  group('FractionsGenerator Expert & Genius', () {
    final generator = FractionsGenerator();

    test('generates valid Expert questions with correct difficulty and positive answer', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.topic, Topic.fractions);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, isNotEmpty);
        expect(q.displayText, contains('of'));
      }
    });

    test('generates valid Genius questions with correct difficulty and positive answer', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.topic, Topic.fractions);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, isNotEmpty);
      }
    });
  });

  group('SimplificationGenerator Expert & Genius', () {
    final generator = SimplificationGenerator();

    test('generates valid Expert questions with correct difficulty and result <= 50000', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.topic, Topic.simplification);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.correctAnswer, lessThanOrEqualTo(50000));
        expect(q.displayText, isNotEmpty);
      }
    });

    test('generates valid Genius questions with correct difficulty and result <= 200000', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.topic, Topic.simplification);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.correctAnswer, lessThanOrEqualTo(200000));
        expect(q.displayText, isNotEmpty);
      }
    });
  });

  group('AveragesGenerator Expert & Genius', () {
    final generator = AveragesGenerator();

    test('generates valid Expert questions with correct difficulty and positive answer', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.topic, Topic.averages);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, isNotEmpty);
      }
    });

    test('generates valid Genius questions with correct difficulty and positive answer', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.topic, Topic.averages);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, isNotEmpty);
      }
    });
  });

  group('MissingNumberGenerator Expert & Genius', () {
    final generator = MissingNumberGenerator();

    test('generates valid Expert questions with clean integer answer', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.topic, Topic.missingNumber);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, contains('?'));
      }
    });

    test('generates valid Genius questions with clean integer answer', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.topic, Topic.missingNumber);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, contains('?'));
      }
    });
  });

  group('NumberSeriesGenerator Expert & Genius', () {
    final generator = NumberSeriesGenerator();

    test('generates valid Expert questions with correct difficulty', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.topic, Topic.numberSeries);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.displayText, contains('?'));
      }
    });

    test('generates valid Genius questions with correct difficulty and answer <= 500000', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.topic, Topic.numberSeries);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.correctAnswer, lessThanOrEqualTo(500000));
        expect(q.displayText, contains('?'));
      }
    });
  });

  group('ApproximationGenerator Expert & Genius', () {
    final generator = ApproximationGenerator();

    test('generates valid Expert questions with result <= 500000', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.topic, Topic.approximation);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.correctAnswer, lessThanOrEqualTo(500000));
        expect(q.displayText, contains('≈ ?'));
      }
    });

    test('generates valid Genius questions with result <= 1000000', () {
      for (int i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.topic, Topic.approximation);
        expect(q.correctAnswer, greaterThan(0));
        expect(q.correctAnswer, lessThanOrEqualTo(1000000));
        expect(q.displayText, contains('≈ ?'));
      }
    });
  });
}
