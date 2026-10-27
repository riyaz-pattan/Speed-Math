import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

class SquareRootsGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.squareRoots;

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
      Difficulty.expert => (
          DifficultyRanges.squareRootsExpertMin,
          DifficultyRanges.squareRootsExpertMax,
        ),
      Difficulty.genius => (
          DifficultyRanges.squareRootsGeniusMin,
          DifficultyRanges.squareRootsGeniusMax,
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

      final pat = patternOf(difficulty, [n * n, n]);
      q = Question(
        topic: Topic.squareRoots,
        difficulty: difficulty,
        displayText: '√${n * n}',
        operands: [n * n, n],
        correctAnswer: n,
        pattern: pat,
      );
      tries++;
    } while (pattern != null && q.pattern != pattern && tries < 50);

    return q;
  }
}
