import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates split-percentage decomposition questions.
/// e.g. "55% of 840 = ?" → 462  (50% + 5% = 420 + 42)
class SplitPercentagesGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.splitPercentages;

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
    int pct;
    int base;

    switch (difficulty) {
      case Difficulty.easy:
        // multiples of 5 that are not 0,25,50,75,100 — base divisible by 20
        final pcts = [15, 35, 45, 55, 65, 85, 95];
        pct = pcts[random.nextInt(pcts.length)];
        final m = 2 + random.nextInt(9); // 2..10
        base = m * 20;
      case Difficulty.medium:
        // two-digit %, base divisible by 10
        final pcts = [26, 51, 74, 19, 21, 48, 76, 99, 49, 31];
        pct = pcts[random.nextInt(pcts.length)];
        final m = 2 + random.nextInt(19); // 2..20
        base = m * 10;
      case Difficulty.hard:
        // non-round %, base divisible by 100
        final pcts = [32, 64, 72, 88, 36, 56, 84, 68, 44];
        pct = pcts[random.nextInt(pcts.length)];
        final m = 1 + random.nextInt(9); // 1..9
        base = m * 100;
      case Difficulty.mixed:
        throw ArgumentError('Cannot generate Difficulty.mixed directly');
    }

    final ans = base * pct ~/ 100;

    return Question(
      topic: Topic.splitPercentages,
      difficulty: difficulty,
      displayText: '$pct% of $base = ?',
      operands: [base, pct],
      correctAnswer: ans,
      pattern: PatternConstants.patternOf(
          Topic.splitPercentages, difficulty, [base, pct]),
    );
  }
}
