import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
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

  static final List<(int base, int power, int result)> _expertValidPairs = () {
    final pairs = <(int, int, int)>[];
    void addRange(int bMin, int bMax, int pMin, int pMax) {
      for (var b = bMin; b <= bMax; b++) {
        if (b == 1 || b == 10) continue;
        for (var p = pMin; p <= pMax; p++) {
          var r = 1;
          for (var i = 0; i < p; i++) {
            r *= b;
          }
          if (r <= DifficultyRanges.exponentsExpertMaxResult) {
            pairs.add((b, p, r));
          }
        }
      }
    }

    addRange(2, 2, 7, 12);
    addRange(3, 3, 5, 7);
    addRange(4, 7, 4, 6);
    addRange(11, 16, 3, 4);

    return pairs;
  }();

  static final List<(int base, int power, int result)> _geniusValidPairs = () {
    final pairs = <(int, int, int)>[];
    void addRange(int bMin, int bMax, int pMin, int pMax) {
      for (var b = bMin; b <= bMax; b++) {
        if (b == 1 || b == 10) continue;
        for (var p = pMin; p <= pMax; p++) {
          var r = 1;
          for (var i = 0; i < p; i++) {
            r *= b;
          }
          if (r <= DifficultyRanges.exponentsGeniusMaxResult) {
            pairs.add((b, p, r));
          }
        }
      }
    }

    addRange(2, 2, 12, 16);
    addRange(3, 3, 7, 10);
    addRange(5, 5, 5, 7);
    addRange(6, 9, 4, 6);
    addRange(12, 25, 3, 5);

    return pairs;
  }();

  @override
  Topic get topic => Topic.exponents;

  @override
  String patternOf(Difficulty difficulty, List<int> operands) =>
      PatternConstants.patternOf(topic, difficulty, operands);

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
    String? pattern,
  }) {
    Question q;
    int tries = 0;
    do {
      final raw = _generateRaw(difficulty, random);
      final pat = patternOf(difficulty, raw.operands);
      q = Question(
        topic: raw.topic,
        difficulty: raw.difficulty,
        displayText: raw.displayText,
        operands: raw.operands,
        correctAnswer: raw.correctAnswer,
        pattern: pat,
      );
      tries++;
    } while (pattern != null && q.pattern != pattern && tries < 50);

    return q;
  }

  Question _generateRaw(Difficulty difficulty, Random random) {
    if (difficulty == Difficulty.hard) {
      final pair = _hardValidPairs[random.nextInt(_hardValidPairs.length)];
      return Question(
        topic: Topic.exponents,
        difficulty: difficulty,
        displayText: '${pair.$1}^${pair.$2}',
        operands: [pair.$1, pair.$2],
        correctAnswer: pair.$3,
      );
    }
    if (difficulty == Difficulty.expert) {
      return _generateExpert(random);
    }
    if (difficulty == Difficulty.genius) {
      return _generateGenius(random);
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
      Difficulty.hard ||
      Difficulty.expert ||
      Difficulty.genius =>
        throw StateError('Handled above'),
      Difficulty.mixed =>
        throw ArgumentError('Cannot generate Difficulty.mixed directly'),
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
    } while (base == 1 ||
        base == 10 ||
        result > DifficultyRanges.exponentsHardMaxResult);

    return Question(
      topic: Topic.exponents,
      difficulty: difficulty,
      displayText: '$base^$power',
      operands: [base, power],
      correctAnswer: result,
    );
  }

  Question _generateExpert(Random random) {
    final pair = _expertValidPairs[random.nextInt(_expertValidPairs.length)];
    return Question(
      topic: Topic.exponents,
      difficulty: Difficulty.expert,
      displayText: '${pair.$1}^${pair.$2}',
      operands: [pair.$1, pair.$2],
      correctAnswer: pair.$3,
    );
  }

  Question _generateGenius(Random random) {
    final pair = _geniusValidPairs[random.nextInt(_geniusValidPairs.length)];
    return Question(
      topic: Topic.exponents,
      difficulty: Difficulty.genius,
      displayText: '${pair.$1}^${pair.$2}',
      operands: [pair.$1, pair.$2],
      correctAnswer: pair.$3,
    );
  }
}
