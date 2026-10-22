import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates multiplication questions. Avoids trivial multipliers (0, 1, 10).
///
/// Easy:   2-digit × 1-digit
/// Medium: 2-digit × 2-digit
/// Hard:   3-digit × 2-digit
class MultiplicationGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.multiplication;

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
        Difficulty.medium => _generateMedium(random),
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

  Question _generateEasy(Random random) {
    int a, b;
    do {
      a = _randRange(random, DifficultyRanges.multiplicationEasyAMin,
          DifficultyRanges.multiplicationEasyAMax);
      b = _randRange(random, DifficultyRanges.multiplicationEasyBMin,
          DifficultyRanges.multiplicationEasyBMax);
    } while (_isTrivialFactor(a) || _isTrivialFactor(b));

    return Question(
      topic: Topic.multiplication,
      difficulty: Difficulty.easy,
      displayText: '$a × $b',
      operands: [a, b],
      correctAnswer: a * b,
    );
  }

  Question _generateMedium(Random random) {
    int a, b;
    do {
      a = _randRange(random, DifficultyRanges.multiplicationMediumMin,
          DifficultyRanges.multiplicationMediumMax);
      b = _randRange(random, DifficultyRanges.multiplicationMediumMin,
          DifficultyRanges.multiplicationMediumMax);
    } while (_isTrivialFactor(a) || _isTrivialFactor(b));

    return Question(
      topic: Topic.multiplication,
      difficulty: Difficulty.medium,
      displayText: '$a × $b',
      operands: [a, b],
      correctAnswer: a * b,
    );
  }

  Question _generateHard(Random random) {
    int a, b;
    do {
      a = _randRange(random, DifficultyRanges.multiplicationHardAMin,
          DifficultyRanges.multiplicationHardAMax);
      b = _randRange(random, DifficultyRanges.multiplicationHardBMin,
          DifficultyRanges.multiplicationHardBMax);
    } while (
        _isTrivialFactor(a) || _isTrivialFactor(b) || _allEndInZero([a, b]));

    return Question(
      topic: Topic.multiplication,
      difficulty: Difficulty.hard,
      displayText: '$a × $b',
      operands: [a, b],
      correctAnswer: a * b,
    );
  }

  /// A factor is trivial if it's 0, 1, or exactly 10.
  bool _isTrivialFactor(int n) => n == 0 || n == 1 || n == 10;

  bool _allEndInZero(List<int> nums) => nums.every((n) => n % 10 == 0);

  int _randRange(Random random, int min, int max) =>
      min + random.nextInt(max - min + 1);
}
