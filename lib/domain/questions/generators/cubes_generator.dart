import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

class CubesGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.cubes;

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
      Difficulty.expert => (
          DifficultyRanges.cubesExpertMin,
          DifficultyRanges.cubesExpertMax,
        ),
      Difficulty.genius => (
          DifficultyRanges.cubesGeniusMin,
          DifficultyRanges.cubesGeniusMax,
        ),
      Difficulty.mixed =>
        throw ArgumentError('Cannot generate Difficulty.mixed directly'),
    };

    final excludeMultiplesOfTen = difficulty == Difficulty.hard ||
        difficulty == Difficulty.expert ||
        difficulty == Difficulty.genius;

    Question q;
    int tries = 0;
    do {
      int n;
      do {
        n = min + random.nextInt(max - min + 1);
      } while (excludeMultiplesOfTen && n % 10 == 0);

      final pat = patternOf(difficulty, [n, 3]);
      q = Question(
        topic: Topic.cubes,
        difficulty: difficulty,
        displayText: '$n³',
        operands: [n, 3],
        correctAnswer: n * n * n,
        pattern: pat,
      );
      tries++;
    } while (pattern != null && q.pattern != pattern && tries < 50);

    return q;
  }
}
