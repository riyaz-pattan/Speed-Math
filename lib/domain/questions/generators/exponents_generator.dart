import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../question.dart';
import '../question_generator.dart';

class ExponentsGenerator extends QuestionGenerator {
  static final List<(int base, int power, int result)> _hardValidPairs = () {
    final pairs = <(int, int, int)>[];
    for (var b = DifficultyRanges.exponentsHardBaseMin;
        b <= DifficultyRanges.exponentsHardBaseMax;
        b++) {
      if (b == 1 || b == 10) continue;
      for (var p = DifficultyRanges.exponentsHardPowMin;
          p <= DifficultyRanges.exponentsHardPowMax;
          p++) {
        var r = 1;
        for (var i = 0; i < p; i++) {
          r *= b;
        }
        if (r <= DifficultyRanges.exponentsHardMaxResult) {
          pairs.add((b, p, r));
        }
      }
    }
    return pairs;
  }();

  @override
  Topic get topic => Topic.exponents;

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
  }) {
    if (difficulty == Difficulty.hard) {
      final pair = _hardValidPairs[random.nextInt(_hardValidPairs.length)];
      return Question(
        topic: Topic.exponents,
        difficulty: Difficulty.hard,
        displayText: '${pair.$1}^${pair.$2}',
        operands: [pair.$1, pair.$2],
        correctAnswer: pair.$3,
      );
    }

    final (baseMin, baseMax, powMin, powMax) = switch (difficulty) {
      Difficulty.easy => (
          DifficultyRanges.exponentsEasyBaseMin,
          DifficultyRanges.exponentsEasyBaseMax,
          DifficultyRanges.exponentsEasyPowMin,
          DifficultyRanges.exponentsEasyPowMax,
        ),
      Difficulty.medium => (
          DifficultyRanges.exponentsMediumBaseMin,
          DifficultyRanges.exponentsMediumBaseMax,
          DifficultyRanges.exponentsMediumPowMin,
          DifficultyRanges.exponentsMediumPowMax,
        ),
      Difficulty.hard => throw StateError('Handled above'),
      Difficulty.mixed => throw ArgumentError('Cannot generate Difficulty.mixed directly'),
    };

    int base;
    int power;
    int result;
    do {
      base = baseMin + random.nextInt(baseMax - baseMin + 1);
      power = powMin + random.nextInt(powMax - powMin + 1);
      result = 1;
      for (var i = 0; i < power; i++) {
        result *= base;
      }
    } while (base == 1 || base == 10 || result > DifficultyRanges.exponentsHardMaxResult);

    return Question(
      topic: Topic.exponents,
      difficulty: difficulty,
      displayText: '$base^$power',
      operands: [base, power],
      correctAnswer: result,
    );
  }
}
