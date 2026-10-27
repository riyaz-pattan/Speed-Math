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
        final useDivHard = random.nextBool();
        if (useDivHard) {
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

      case Difficulty.expert:
        // × 625 (clean numbers divisible by 16) or ÷ 625 (5⁴ = 625: n × 625 = n × 10000 / 16)
        final useDivExp = random.nextBool();
        if (useDivExp) {
          final m = 2 + random.nextInt(25); // result 2..26
          final n = m * 625;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n ÷ 625 = ?',
            operands: [n, 625],
            correctAnswer: m,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 625]),
          );
        } else {
          final m = 1 + random.nextInt(25); // 1..25
          final n = m * 16;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n × 625 = ?',
            operands: [n, 625],
            correctAnswer: n * 625,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 625]),
          );
        }

      case Difficulty.genius:
        // × 3125 (n × 100000 / 32, divisible by 32) or ÷ 3125, or mixed powers of 5
        final type = random.nextInt(3);
        if (type == 0) {
          final m = 1 + random.nextInt(20); // 1..20
          final n = m * 32;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n × 3125 = ?',
            operands: [n, 3125],
            correctAnswer: n * 3125,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 3125]),
          );
        } else if (type == 1) {
          final m = 2 + random.nextInt(20); // 2..21
          final n = m * 3125;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n ÷ 3125 = ?',
            operands: [n, 3125],
            correctAnswer: m,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 3125]),
          );
        } else {
          // Mixed powers: larger multiples of 625
          final m = 26 + random.nextInt(35); // 26..60
          final n = m * 16;
          return Question(
            topic: Topic.powerOfFive,
            difficulty: difficulty,
            displayText: '$n × 625 = ?',
            operands: [n, 625],
            correctAnswer: n * 625,
            pattern: PatternConstants.patternOf(
                Topic.powerOfFive, difficulty, [n, 625]),
          );
        }

      case Difficulty.mixed:
        throw ArgumentError('Cannot generate Difficulty.mixed directly');
    }
  }
}
