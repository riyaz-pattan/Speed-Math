import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates base 100+ percentage questions using decomposition.
/// e.g. "125% of 80 = ?" → 100  (= 80 + 80×1/4)
class BasePercentagesGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.basePercentages;

  @override
  String patternOf(Difficulty difficulty, List<int> operands) =>
      PatternConstants.patternOf(topic, difficulty, operands);

  // [pct_str, extra_num, extra_den, list_of_bases]
  static const _easy = [
    ['120', 1, 5, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]],
    ['125', 1, 4, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
    ['150', 1, 2, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]],
    ['200', 1, 1, [10, 15, 20, 25, 30, 35, 40, 45, 50, 60]],
  ];

  static const _medium = [
    ['112.5', 1, 8, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
    ['137.5', 3, 8, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
    ['162.5', 5, 8, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
    ['133.33', 1, 3, [6, 12, 18, 24, 30, 36, 42, 48, 54, 60]],
    ['166.67', 2, 3, [6, 12, 18, 24, 30, 36, 42, 48, 54, 60]],
  ];

  static const _hard = [
    ['114.28', 1, 7, [7, 14, 21, 28, 35, 42, 49, 56, 63, 70]],
    ['141.67', 5, 12, [12, 24, 36, 48, 60, 72, 84, 96, 108, 120]],
    ['158.33', 7, 12, [12, 24, 36, 48, 60, 72, 84, 96, 108, 120]],
    ['187.5', 7, 8, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
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
    final extraNum = entry[1] as int;
    final extraDen = entry[2] as int;
    final bases = entry[3] as List<dynamic>;
    final base = bases[random.nextInt(bases.length)] as int;

    final extra = base * extraNum ~/ extraDen;
    final ans = base + extra;

    return Question(
      topic: Topic.basePercentages,
      difficulty: difficulty,
      displayText: '$pctStr% of $base = ?',
      operands: [base, extraNum, extraDen],
      correctAnswer: ans,
      pattern: PatternConstants.patternOf(
          Topic.basePercentages, difficulty, [base]),
    );
  }
}
