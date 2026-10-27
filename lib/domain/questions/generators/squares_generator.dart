import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates squaring questions (n²).
///
/// Easy:   n = 2 to 20
/// Medium: n = 21 to 50
/// Hard:   n = 51 to 99 (no multiples of 10)
class SquaresGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.squares;

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
          DifficultyRanges.squaresEasyMin,
          DifficultyRanges.squaresEasyMax,
        ),
      Difficulty.medium => (
          DifficultyRanges.squaresMediumMin,
          DifficultyRanges.squaresMediumMax,
        ),
      Difficulty.hard => (
          DifficultyRanges.squaresHardMin,
          DifficultyRanges.squaresHardMax,
        ),
      Difficulty.expert => (
          DifficultyRanges.squaresExpertMin,
          DifficultyRanges.squaresExpertMax,
        ),
      Difficulty.genius => (
          DifficultyRanges.squaresGeniusMin,
          DifficultyRanges.squaresGeniusMax,
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
        // Hard: exclude multiples of 10 (trivially easy to square)
      } while (difficulty == Difficulty.hard && n % 10 == 0);

      final pat = patternOf(difficulty, [n, n]);
      q = Question(
        topic: Topic.squares,
        difficulty: difficulty,
        displayText: '$n²',
        operands: [n, n],
        correctAnswer: n * n,
        pattern: pat,
      );
      tries++;
    } while (pattern != null && q.pattern != pattern && tries < 50);

    return q;
  }
}
