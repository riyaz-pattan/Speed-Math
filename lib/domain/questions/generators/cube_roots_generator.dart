import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

class CubeRootsGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.cubeRoots;

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
      Difficulty.mixed =>
        throw ArgumentError('Cannot generate Difficulty.mixed directly'),
    };

    Question q;
    int tries = 0;
    do {
      int n;
      do {
        n = min + random.nextInt(max - min + 1);
      } while (difficulty == Difficulty.hard && n % 10 == 0);

      final pat = patternOf(difficulty, [n * n * n, n]);
      q = Question(
        topic: Topic.cubeRoots,
        difficulty: difficulty,
        displayText: '³√${n * n * n}',
        operands: [n * n * n, n],
        correctAnswer: n,
        pattern: pat,
      );
      tries++;
    } while (pattern != null && q.pattern != pattern && tries < 50);

    return q;
  }
}
