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
    switch (difficulty) {
      case Difficulty.easy:
        // multiples of 5 that are not 0,25,50,75,100 — base divisible by 20
        final pcts = [15, 35, 45, 55, 65, 85, 95];
        final pct = pcts[random.nextInt(pcts.length)];
        final m = 2 + random.nextInt(9); // 2..10
        final base = m * 20;
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

      case Difficulty.medium:
        // two-digit %, base divisible by 10
        final pcts = [26, 51, 74, 19, 21, 48, 76, 99, 49, 31];
        final pct = pcts[random.nextInt(pcts.length)];
        final m = 2 + random.nextInt(19); // 2..20
        final base = m * 10;
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

      case Difficulty.hard:
        // non-round %, base divisible by 100
        final pcts = [32, 64, 72, 88, 36, 56, 84, 68, 44, 28, 52, 96];
        final pct = pcts[random.nextInt(pcts.length)];
        final m = 1 + random.nextInt(9); // 1..9
        final base = m * 100;
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

      case Difficulty.expert:
        // 3-digit % or percentages like 115%, 135%, 175% of non-trivial 3-digit numbers
        final pcts = [115, 125, 135, 145, 155, 165, 175, 185, 215, 225, 235, 245];
        final pct = pcts[random.nextInt(pcts.length)];
        final m = 6 + random.nextInt(44); // 6..49 -> base 120..980 (divisible by 20)
        final base = m * 20;
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

      case Difficulty.genius:
        // Composite split percentages (e.g. 137.5% of 640 = 100% + 25% + 12.5% = 640 + 160 + 80 = 880)
        const compositeSplits = [
          ['112.5', 9, 8], // 100% + 12.5%
          ['137.5', 11, 8], // 100% + 25% + 12.5%
          ['162.5', 13, 8], // 100% + 50% + 12.5%
          ['187.5', 15, 8], // 200% - 12.5%
          ['212.5', 17, 8], // 200% + 12.5%
          ['237.5', 19, 8], // 200% + 25% + 12.5%
          ['262.5', 21, 8], // 200% + 50% + 12.5%
          ['116.67', 7, 6], // 100% + 16.67%
          ['183.33', 11, 6], // 200% - 16.67%
          ['216.67', 13, 6], // 200% + 16.67%
          ['142.86', 10, 7], // 100% + 42.86%
          ['157.14', 11, 7], // 100% + 57.14%
        ];
        final entry = compositeSplits[random.nextInt(compositeSplits.length)];
        final pctStr = entry[0] as String;
        final numMult = entry[1] as int;
        final denMult = entry[2] as int;

        final minM = (100 / denMult).ceil();
        final maxM = (990 / denMult).floor();
        final m = minM + random.nextInt(maxM - minM + 1);
        final base = m * denMult;
        final ans = m * numMult;

        return Question(
          topic: Topic.splitPercentages,
          difficulty: difficulty,
          displayText: '$pctStr% of $base = ?',
          operands: [base, (double.tryParse(pctStr) ?? 0).toInt()],
          correctAnswer: ans,
          pattern: PatternConstants.patternOf(
              Topic.splitPercentages, difficulty, [base, ans]),
        );

      case Difficulty.mixed:
        throw ArgumentError('Cannot generate Difficulty.mixed directly');
    }
  }
}
