import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates "X% of N = ?" questions using fraction shortcuts.
/// e.g. "37.5% of 640 = ?" → 240
class FractionPercentagesGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.fractionPercentages;

  @override
  String patternOf(Difficulty difficulty, List<int> operands) =>
      PatternConstants.patternOf(topic, difficulty, operands);

  // [pct_str, numerator, denominator, min_multiples, denominator_step]
  // base = randomly picked multiple of den in range [minMult*den .. maxMult*den]
  static const _easy = [
    ['25', 1, 4, 2, 10],  // 25% = 1/4, base = 4k (k in 2..10), e.g. 8,12..40
    ['50', 1, 2, 2, 20],  // 50% = 1/2, base = 2k (k in 2..20), e.g. 4..40
    ['75', 3, 4, 1, 10],  // 75% = 3/4, base = 4k (k in 1..10)
    ['20', 1, 5, 2, 10],  // 20% = 1/5, base = 5k (k in 2..10)
  ];

  static const _medium = [
    ['12.5', 1, 8, 1, 10],   // base = 8k (k 1..10)
    ['37.5', 3, 8, 1, 10],
    ['62.5', 5, 8, 1, 10],
    ['16.67', 1, 6, 1, 10],  // base = 6k (k 1..10)
    ['33.33', 1, 3, 2, 10],
    ['83.33', 5, 6, 1, 10],
  ];

  static const _hard = [
    ['14.28', 1, 7, 1, 10],  // base = 7k
    ['28.57', 2, 7, 1, 10],
    ['8.33', 1, 12, 1, 8],   // base = 12k
    ['41.67', 5, 12, 1, 8],
    ['9.09', 1, 11, 1, 8],   // base = 11k
    ['6.25', 1, 16, 1, 6],   // base = 16k
  ];

  @override
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
    String? pattern,
  }) {
    final pool = switch (difficulty) {
      Difficulty.easy => _easy,
      Difficulty.medium => _medium,
      Difficulty.hard => _hard,
      Difficulty.mixed =>
        throw ArgumentError('Cannot generate Difficulty.mixed directly'),
    };

    final entry = pool[random.nextInt(pool.length)];
    final pctStr = entry[0] as String;
    final num = entry[1] as int;
    final den = entry[2] as int;
    final minK = entry[3] as int;
    final maxK = entry[4] as int;

    final k = minK + random.nextInt(maxK - minK + 1);
    final base = k * den;
    final ans = base * num ~/ den;

    return Question(
      topic: Topic.fractionPercentages,
      difficulty: difficulty,
      displayText: '$pctStr% of $base = ?',
      operands: [base, num, den],
      correctAnswer: ans,
      pattern: PatternConstants.patternOf(
          Topic.fractionPercentages, difficulty, [base]),
    );
  }
}
