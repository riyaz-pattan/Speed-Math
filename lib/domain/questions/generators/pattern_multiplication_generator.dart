import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates pattern multiplication questions: × 11, × 99, × 101.
/// e.g. "63 × 11 = ?" → 693,  "47 × 99 = ?" → 4653
class PatternMultiplicationGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.patternMultiplication;

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
        // 2-digit × 11 without carry (tens + units < 10), or single-digit × 99
        final useNinety = random.nextBool();
        if (useNinety) {
          final n = 2 + random.nextInt(8); // 2..9
          return Question(
            topic: Topic.patternMultiplication,
            difficulty: difficulty,
            displayText: '$n × 99 = ?',
            operands: [n, 99],
            correctAnswer: n * 99,
            pattern: PatternConstants.patternOf(
                Topic.patternMultiplication, difficulty, [n, 99]),
          );
        } else {
          int a, b;
          int tries = 0;
          do {
            a = 1 + random.nextInt(4); // tens 1..4
            b = 1 + random.nextInt(4); // units 1..4
            tries++;
          } while (a + b >= 10 && tries < 50);
          final n = a * 10 + b;
          return Question(
            topic: Topic.patternMultiplication,
            difficulty: difficulty,
            displayText: '$n × 11 = ?',
            operands: [n, 11],
            correctAnswer: n * 11,
            pattern: PatternConstants.patternOf(
                Topic.patternMultiplication, difficulty, [n, 11]),
          );
        }

      case Difficulty.medium:
        // 2-digit × 11 with carry, or 2-digit × 99
        final useNinety = random.nextBool();
        if (useNinety) {
          final n = 12 + random.nextInt(88); // 12..99
          return Question(
            topic: Topic.patternMultiplication,
            difficulty: difficulty,
            displayText: '$n × 99 = ?',
            operands: [n, 99],
            correctAnswer: n * 99,
            pattern: PatternConstants.patternOf(
                Topic.patternMultiplication, difficulty, [n, 99]),
          );
        } else {
          // with carry: tens + units >= 10
          int a, b;
          int tries = 0;
          do {
            a = 1 + random.nextInt(9);
            b = 1 + random.nextInt(9);
            tries++;
          } while (a + b < 10 && tries < 50);
          final n = a * 10 + b;
          return Question(
            topic: Topic.patternMultiplication,
            difficulty: difficulty,
            displayText: '$n × 11 = ?',
            operands: [n, 11],
            correctAnswer: n * 11,
            pattern: PatternConstants.patternOf(
                Topic.patternMultiplication, difficulty, [n, 11]),
          );
        }

      case Difficulty.hard:
        // 3-digit × 11, or 2-digit × 101, or 2-digit × 99 (larger range)
        final choice = random.nextInt(3);
        if (choice == 0) {
          final n = 100 + random.nextInt(800); // 100..899
          return Question(
            topic: Topic.patternMultiplication,
            difficulty: difficulty,
            displayText: '$n × 11 = ?',
            operands: [n, 11],
            correctAnswer: n * 11,
            pattern: PatternConstants.patternOf(
                Topic.patternMultiplication, difficulty, [n, 11]),
          );
        } else if (choice == 1) {
          final n = 10 + random.nextInt(90); // 10..99
          return Question(
            topic: Topic.patternMultiplication,
            difficulty: difficulty,
            displayText: '$n × 101 = ?',
            operands: [n, 101],
            correctAnswer: n * 101,
            pattern: PatternConstants.patternOf(
                Topic.patternMultiplication, difficulty, [n, 101]),
          );
        } else {
          final n = 100 + random.nextInt(200); // 100..299
          return Question(
            topic: Topic.patternMultiplication,
            difficulty: difficulty,
            displayText: '$n × 99 = ?',
            operands: [n, 99],
            correctAnswer: n * 99,
            pattern: PatternConstants.patternOf(
                Topic.patternMultiplication, difficulty, [n, 99]),
          );
        }

      case Difficulty.mixed:
        throw ArgumentError('Cannot generate Difficulty.mixed directly');
    }
  }
}
