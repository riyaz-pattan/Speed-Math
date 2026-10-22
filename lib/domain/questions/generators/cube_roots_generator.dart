import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../question.dart';
import '../question_generator.dart';

class CubeRootsGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.cubeRoots;

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
  }) {
    final (min, max) = switch (difficulty) {
      Difficulty.easy => (
          DifficultyRanges.cubeRootsEasyMin,
          DifficultyRanges.cubeRootsEasyMax,
        ),
      Difficulty.medium => (
          DifficultyRanges.cubeRootsMediumMin,
          DifficultyRanges.cubeRootsMediumMax,
        ),
      Difficulty.hard => (
          DifficultyRanges.cubeRootsHardMin,
          DifficultyRanges.cubeRootsHardMax,
        ),
      Difficulty.mixed => throw ArgumentError('Cannot generate Difficulty.mixed directly'),
    };
    int n;
    do {
      n = min + random.nextInt(max - min + 1);
    } while (difficulty == Difficulty.hard && n % 10 == 0);
    return Question(
      topic: Topic.cubeRoots,
      difficulty: difficulty,
      displayText: '³√${n * n * n}',
      operands: [n * n * n, n],
      correctAnswer: n,
    );
  }
}
