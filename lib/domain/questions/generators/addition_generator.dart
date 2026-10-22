import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates addition questions.
///
/// Easy:   2-digit + 2-digit
/// Medium: 3-digit + 3-digit
/// Hard:   three numbers, 3 to 4 digits each
class AdditionGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.addition;

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
  }) {
    switch (difficulty) {
      case Difficulty.easy:
        return _generateEasy(random);
      case Difficulty.medium:
        return _generateMedium(random);
      case Difficulty.hard:
        return _generateHard(random);
      case Difficulty.mixed:
        throw ArgumentError('Cannot generate questions with Difficulty.mixed directly');
    }
  }

  Question _generateEasy(Random random) {
    int a, b;
    do {
      a = _randRange(random, DifficultyRanges.additionEasyMin, DifficultyRanges.additionEasyMax);
      b = _randRange(random, DifficultyRanges.additionEasyMin, DifficultyRanges.additionEasyMax);
    } while (_isTrivialAddend(a) || _isTrivialAddend(b));

    return Question(
      topic: Topic.addition,
      difficulty: Difficulty.easy,
      displayText: '$a + $b',
      operands: [a, b],
      correctAnswer: a + b,
    );
  }

  Question _generateMedium(Random random) {
    int a, b;
    do {
      a = _randRange(random, DifficultyRanges.additionMediumMin, DifficultyRanges.additionMediumMax);
      b = _randRange(random, DifficultyRanges.additionMediumMin, DifficultyRanges.additionMediumMax);
    } while (_isTrivialAddend(a) || _isTrivialAddend(b));

    return Question(
      topic: Topic.addition,
      difficulty: Difficulty.medium,
      displayText: '$a + $b',
      operands: [a, b],
      correctAnswer: a + b,
    );
  }

  Question _generateHard(Random random) {
    int a, b, c;
    do {
      a = _randRange(random, DifficultyRanges.additionHardMin, DifficultyRanges.additionHardMax);
      b = _randRange(random, DifficultyRanges.additionHardMin, DifficultyRanges.additionHardMax);
      c = _randRange(random, DifficultyRanges.additionHardMin, DifficultyRanges.additionHardMax);
    } while (
        _allEndInZero([a, b, c]) ||
        _isTrivialAddend(a) ||
        _isTrivialAddend(b) ||
        _isTrivialAddend(c));

    return Question(
      topic: Topic.addition,
      difficulty: Difficulty.hard,
      displayText: '$a + $b + $c',
      operands: [a, b, c],
      correctAnswer: a + b + c,
    );
  }

  bool _isTrivialAddend(int n) => n == 0;
  bool _allEndInZero(List<int> nums) => nums.every((n) => n % 10 == 0);

  int _randRange(Random random, int min, int max) =>
      min + random.nextInt(max - min + 1);
}
