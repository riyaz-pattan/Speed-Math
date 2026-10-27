import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/generators/base_percentages_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/derived_fractions_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/fraction_percentages_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/fraction_reciprocals_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/pattern_multiplication_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/power_of_five_generator.dart';
import 'package:speed_math_with_ai/domain/questions/generators/split_percentages_generator.dart';

void main() {
  group('PowerOfFiveGenerator Expert & Genius', () {
    final generator = PowerOfFiveGenerator();
    final random = Random(42);

    test('Expert generates x625 or /625 with difficulty.expert', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.displayText.contains('625'), isTrue);
        expect(q.correctAnswer, greaterThan(0));
      }
    });

    test('Genius generates x3125, /3125 or mixed powers with difficulty.genius', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.displayText.contains('3125') || q.displayText.contains('625'), isTrue);
        expect(q.correctAnswer, greaterThan(0));
      }
    });
  });

  group('PatternMultiplicationGenerator Expert & Genius', () {
    final generator = PatternMultiplicationGenerator();
    final random = Random(43);

    test('Expert generates 4-digit x 11, 3-digit x 101, 3-digit x 999 with difficulty.expert', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(
          q.displayText.contains('11 = ?') ||
              q.displayText.contains('101 = ?') ||
              q.displayText.contains('999 = ?'),
          isTrue,
        );
        expect(q.correctAnswer, greaterThan(0));
      }
    });

    test('Genius generates 4-digit x 1001, 4-digit x 999, 3-digit x 111 with difficulty.genius', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(
          q.displayText.contains('1001 = ?') ||
              q.displayText.contains('999 = ?') ||
              q.displayText.contains('111 = ?'),
          isTrue,
        );
        expect(q.correctAnswer, greaterThan(0));
      }
    });
  });

  group('SplitPercentagesGenerator Expert & Genius', () {
    final generator = SplitPercentagesGenerator();
    final random = Random(44);

    test('Expert generates 3-digit percentages of 3-digit numbers with difficulty.expert', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.correctAnswer, greaterThan(0));
      }
    });

    test('Genius generates composite split percentages with difficulty.genius', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.correctAnswer, greaterThan(0));
      }
    });
  });

  group('BasePercentagesGenerator Expert & Genius', () {
    final generator = BasePercentagesGenerator();
    final random = Random(45);

    test('Expert generates 200%+ percentages (e.g. 216.67%, 262.5%) with difficulty.expert', () {
      final seenPcts = <String>{};
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.correctAnswer, greaterThan(0));
        seenPcts.add(q.displayText.split('%').first);
      }
      expect(seenPcts.contains('216.67') || seenPcts.contains('262.5'), isTrue);
    });

    test('Genius generates 300%+ percentages (e.g. 337.5%) with difficulty.genius', () {
      final seenPcts = <String>{};
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.correctAnswer, greaterThan(0));
        seenPcts.add(q.displayText.split('%').first);
      }
      expect(seenPcts.contains('337.5'), isTrue);
    });
  });

  group('FractionReciprocalsGenerator Expert & Genius', () {
    final generator = FractionReciprocalsGenerator();
    final random = Random(46);

    test('Expert generates 13ths, 17ths, 19ths, etc. with difficulty.expert', () {
      final seenFracs = <String>{};
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.isFractionAnswer, isTrue);
        seenFracs.add(q.stringAnswer!);
      }
      expect(seenFracs.contains('1/13') || seenFracs.contains('1/17') || seenFracs.contains('1/19'), isTrue);
    });

    test('Genius generates higher reciprocals (23rds, 29ths, 37ths) with difficulty.genius', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.isFractionAnswer, isTrue);
      }
    });
  });

  group('DerivedFractionsGenerator Expert & Genius', () {
    final generator = DerivedFractionsGenerator();
    final random = Random(47);

    test('Expert generates derived fractions with difficulty.expert', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.isFractionAnswer, isTrue);
      }
    });

    test('Genius generates high derived fractions with difficulty.genius', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.isFractionAnswer, isTrue);
      }
    });
  });

  group('FractionPercentagesGenerator Expert & Genius', () {
    final generator = FractionPercentagesGenerator();
    final random = Random(48);

    test('Expert generates fraction percentages with difficulty.expert', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.expert, random: random);
        expect(q.difficulty, Difficulty.expert);
        expect(q.correctAnswer, greaterThan(0));
      }
    });

    test('Genius generates high percentages and larger denominators with difficulty.genius', () {
      for (var i = 0; i < 200; i++) {
        final q = generator.generate(difficulty: Difficulty.genius, random: random);
        expect(q.difficulty, Difficulty.genius);
        expect(q.correctAnswer, greaterThan(0));
      }
    });
  });
}
