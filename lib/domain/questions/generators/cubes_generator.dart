import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../question.dart';
import '../question_generator.dart';

class CubesGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.cubes;

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
  }) {
    final (min, max) = switch (difficulty) {
      Difficulty.easy => (
          DifficultyRanges.cubesEasyMin,
          DifficultyRanges.cubesEasyMax,
        ),
      Difficulty.medium => (
          DifficultyRanges.cubesMediumMin,
          DifficultyRanges.cubesMediumMax,
        ),
      Difficulty.hard => (
          DifficultyRanges.cubesHardMin,
          DifficultyRanges.cubesHardMax,
        ),
      Difficulty.mixed => throw ArgumentError('Cannot generate Difficulty.mixed directly'),
    };
    int n;
    do {
      n = min + random.nextInt(max - min + 1);
    } while (difficulty == Difficulty.hard && n % 10 == 0);
    return Question(
      topic: Topic.cubes,
      difficulty: difficulty,
      displayText: '$n³',
      operands: [n, 3],
      correctAnswer: n * n * n,
    );
  }
}
