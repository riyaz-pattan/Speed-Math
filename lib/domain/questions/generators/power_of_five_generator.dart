import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates multiplication / division by 5, 25, 125 shortcut questions.
/// e.g. "48 × 25 = ?" → 1200,  "350 ÷ 25 = ?" → 14
class PowerOfFiveGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.powerOfFive;

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
    switch (difficulty) {
      case Difficulty.easy:
        // × 5 of even 2-digit, or ÷ 5 of multiples of 5
        final useDiv = random.nextBool();
        if (useDiv) {
          final m = 4 + random.nextInt(18); // result 4..21
          final n = m * 5;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n ÷ 5 = ?',
            operands: [n, 5],
            correctAnswer: m,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 5]),
          );
        } else {
          final n = 2 * (5 + random.nextInt(23)); // even 10..54
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n × 5 = ?',
            operands: [n, 5],
            correctAnswer: n * 5,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 5]),
          );
        }

      case Difficulty.medium:
        // × 25 of multiples of 4, or ÷ 25 of multiples of 25
        final useDiv = random.nextBool();
        if (useDiv) {
          final m = 2 + random.nextInt(18); // result 2..19
          final n = m * 25;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n ÷ 25 = ?',
            operands: [n, 25],
            correctAnswer: m,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 25]),
          );
        } else {
          final m = 1 + random.nextInt(40); // 1..40
          final n = m * 4;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n × 25 = ?',
            operands: [n, 25],
            correctAnswer: n * 25,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 25]),
          );
        }

      case Difficulty.hard:
        // × 125 of multiples of 8, or ÷ 125 of multiples of 125
        final useDiv = random.nextBool();
        if (useDiv) {
          final m = 2 + random.nextInt(28); // result 2..29
          final n = m * 125;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n ÷ 125 = ?',
            operands: [n, 125],
            correctAnswer: m,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 125]),
          );
        } else {
          final m = 1 + random.nextInt(30); // 1..30
          final n = m * 8;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n × 125 = ?',
            operands: [n, 125],
            correctAnswer: n * 125,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 125]),
          );
        }

      case Difficulty.mixed:
        throw ArgumentError('Cannot generate Difficulty.mixed directly');
    }
  }
}
