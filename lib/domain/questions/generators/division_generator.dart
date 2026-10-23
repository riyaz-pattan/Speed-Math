import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates division questions with exact whole-number answers.
/// Never divides by 0 or 1. Constructs questions via multiplication
/// (quotient × divisor = dividend) to guarantee exact results.
///
/// Easy:   2-digit ÷ 1-digit
/// Medium: 3-digit ÷ 1-digit, or 2-digit ÷ 2-digit (randomly chosen)
/// Hard:   4-digit ÷ 2-digit
class DivisionGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.division;

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
      final raw = switch (difficulty) {
        Difficulty.easy => _generateEasy(random),
        Difficulty.medium => _generateMedium(random, pattern: pattern),
        Difficulty.hard => _generateHard(random),
        Difficulty.mixed => throw ArgumentError(
            'Cannot generate questions with Difficulty.mixed directly'),
      };
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

  /// Easy: 2-digit ÷ 1-digit (divisor 2-9)
  Question _generateEasy(Random random) {
    while (true) {
      final divisor = _randRange(random, DifficultyRanges.divisionEasyDivisorMin,
          DifficultyRanges.divisionEasyDivisorMax);
      final minQ = (DifficultyRanges.divisionEasyDividendMin / divisor).ceil();
      final maxQ = (DifficultyRanges.divisionEasyDividendMax / divisor).floor();
      if (minQ > maxQ) continue;
      final quotient = _randRange(random, minQ, maxQ);
      final dividend = quotient * divisor;
      if (dividend < DifficultyRanges.divisionEasyDividendMin ||
          dividend > DifficultyRanges.divisionEasyDividendMax) {
        continue;
      }
      if (_isTrivialDivision(dividend, divisor)) {
        continue;
      }

      return Question(
        topic: Topic.division,
        difficulty: Difficulty.easy,
        displayText: '$dividend ÷ $divisor',
        operands: [dividend, divisor],
        correctAnswer: quotient,
      );
    }
  }

  /// Medium: randomly pick between 3-digit ÷ 1-digit and 2-digit ÷ 2-digit
  Question _generateMedium(Random random, {String? pattern}) {
    if (pattern == PatternConstants.divMSingleDigit) {
      return _generateMedium3by1(random);
    } else if (pattern == PatternConstants.divMTwoDigit) {
      return _generateMedium2by2(random);
    }

    if (random.nextBool()) {
      return _generateMedium3by1(random);
    } else {
      return _generateMedium2by2(random);
    }
  }

  /// 3-digit ÷ 1-digit: divisor 3-9, quotient 30-150
  Question _generateMedium3by1(Random random) {
    final quotient = _randRange(
      random,
      DifficultyRanges.divisionMedium3by1QuotientMin,
      DifficultyRanges.divisionMedium3by1QuotientMax,
    );
    final minDivisor = max(
      DifficultyRanges.divisionMedium3by1DivisorMin,
      (DifficultyRanges.divisionMedium3by1DividendMin / quotient).ceil(),
    );
    final maxDivisor = min(
      DifficultyRanges.divisionMedium3by1DivisorMax,
      DifficultyRanges.divisionMedium3by1DividendMax ~/ quotient,
    );
    final divisor = _randRange(random, minDivisor, maxDivisor);
    final dividend = quotient * divisor;

    return Question(
      topic: Topic.division,
      difficulty: Difficulty.medium,
      displayText: '$dividend ÷ $divisor',
      operands: [dividend, divisor],
      correctAnswer: quotient,
    );
  }

  /// 2-digit ÷ 2-digit: divisor 11-25, quotient 3-9
  Question _generateMedium2by2(Random random) {
    final quotient = _randRange(
      random,
      DifficultyRanges.divisionMedium2by2QuotientMin,
      DifficultyRanges.divisionMedium2by2QuotientMax,
    );
    final maxDivisor = min(
      DifficultyRanges.divisionMedium2by2DivisorMax,
      DifficultyRanges.divisionMedium2by2DividendMax ~/ quotient,
    );
    final divisor = _randRange(
        random, DifficultyRanges.divisionMedium2by2DivisorMin, maxDivisor);
    final dividend = quotient * divisor;

    return Question(
      topic: Topic.division,
      difficulty: Difficulty.medium,
      displayText: '$dividend ÷ $divisor',
      operands: [dividend, divisor],
      correctAnswer: quotient,
    );
  }

  /// Hard: 4-digit ÷ 2-digit (divisor 10-99)
  Question _generateHard(Random random) {
    while (true) {
      final divisor = _randRange(random, DifficultyRanges.divisionHardDivisorMin,
          DifficultyRanges.divisionHardDivisorMax);
      if (divisor == 10) continue;
      final minQ = (DifficultyRanges.divisionHardDividendMin / divisor).ceil();
      final maxQ = (DifficultyRanges.divisionHardDividendMax / divisor).floor();
      if (minQ > maxQ) continue;
      final quotient = _randRange(random, minQ, maxQ);
      final dividend = quotient * divisor;
      if (dividend < DifficultyRanges.divisionHardDividendMin ||
          dividend > DifficultyRanges.divisionHardDividendMax) {
        continue;
      }
      if (_isTrivialDivision(dividend, divisor)) {
        continue;
      }
      if (_allEndInZero([dividend, divisor])) {
        continue;
      }

      return Question(
        topic: Topic.division,
        difficulty: Difficulty.hard,
        displayText: '$dividend ÷ $divisor',
        operands: [dividend, divisor],
        correctAnswer: quotient,
      );
    }
  }

  /// Division is trivial if divisor is 0, 1, or 10.
  bool _isTrivialDivision(int dividend, int divisor) =>
      divisor <= 1 || divisor == 10;

  bool _allEndInZero(List<int> nums) => nums.every((n) => n % 10 == 0);

  int _randRange(Random random, int min, int max) =>
      min + random.nextInt(max - min + 1);
}
