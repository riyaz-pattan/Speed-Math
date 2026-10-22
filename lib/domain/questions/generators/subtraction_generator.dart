import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates subtraction questions. Result is never negative.
///
/// Easy:   2-digit − 2-digit
/// Medium: 3-digit − 3-digit
/// Hard:   4-digit − 4-digit
class SubtractionGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.subtraction;

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
  }) {
    switch (difficulty) {
      case Difficulty.easy:
        return _generate(random, DifficultyRanges.subtractionEasyMin, DifficultyRanges.subtractionEasyMax, Difficulty.easy);
      case Difficulty.medium:
        return _generate(random, DifficultyRanges.subtractionMediumMin, DifficultyRanges.subtractionMediumMax, Difficulty.medium);
      case Difficulty.hard:
        return _generateHard(random);
      case Difficulty.mixed:
        throw ArgumentError('Cannot generate questions with Difficulty.mixed directly');
    }
  }

  Question _generate(Random random, int min, int max, Difficulty difficulty) {
    int a, b;
    do {
      a = _randRange(random, min, max);
      b = _randRange(random, min, max);
      // Ensure a >= b so the result is non-negative
      if (a < b) {
        final temp = a;
        a = b;
        b = temp;
      }
    } while (b == 0 || a == b);

    return Question(
      topic: Topic.subtraction,
      difficulty: difficulty,
      displayText: '$a − $b',
      operands: [a, b],
      correctAnswer: a - b,
    );
  }

  Question _generateHard(Random random) {
    int a, b;
    do {
      a = _randRange(random, DifficultyRanges.subtractionHardMin, DifficultyRanges.subtractionHardMax);
      b = _randRange(random, DifficultyRanges.subtractionHardMin, DifficultyRanges.subtractionHardMax);
      if (a < b) {
        final temp = a;
        a = b;
        b = temp;
      }
    } while (b == 0 || a == b || _allEndInZero([a, b]));

    return Question(
      topic: Topic.subtraction,
      difficulty: Difficulty.hard,
      displayText: '$a − $b',
      operands: [a, b],
      correctAnswer: a - b,
    );
  }

  bool _allEndInZero(List<int> nums) => nums.every((n) => n % 10 == 0);

  int _randRange(Random random, int min, int max) =>
      min + random.nextInt(max - min + 1);
}
