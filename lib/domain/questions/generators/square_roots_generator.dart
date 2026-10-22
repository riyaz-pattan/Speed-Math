import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../question.dart';
import '../question_generator.dart';

class SquareRootsGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.squareRoots;

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
  }) {
    final (min, max) = switch (difficulty) {
      Difficulty.easy => (
          DifficultyRanges.squareRootsEasyMin,
          DifficultyRanges.squareRootsEasyMax,
        ),
      Difficulty.medium => (
          DifficultyRanges.squareRootsMediumMin,
          DifficultyRanges.squareRootsMediumMax,
        ),
      Difficulty.hard => (
          DifficultyRanges.squareRootsHardMin,
          DifficultyRanges.squareRootsHardMax,
        ),
      Difficulty.mixed => throw ArgumentError('Cannot generate Difficulty.mixed directly'),
    };
    int n;
    do {
      n = min + random.nextInt(max - min + 1);
    } while (difficulty == Difficulty.hard && n % 10 == 0);
    return Question(
      topic: Topic.squareRoots,
      difficulty: difficulty,
      displayText: '√${n * n}',
      operands: [n * n, n],
      correctAnswer: n,
    );
  }
}
