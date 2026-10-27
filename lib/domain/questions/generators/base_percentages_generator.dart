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

  // [pct_str, whole_mult, extra_num, extra_den, list_of_bases]
  static const _easy = [
    ['120', 1, 1, 5, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]],
    ['125', 1, 1, 4, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
    ['150', 1, 1, 2, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]],
    ['200', 2, 0, 1, [10, 15, 20, 25, 30, 35, 40, 45, 50, 60]],
  ];

  static const _medium = [
    ['112.5', 1, 1, 8, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
    ['137.5', 1, 3, 8, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
    ['162.5', 1, 5, 8, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
    ['133.33', 1, 1, 3, [6, 12, 18, 24, 30, 36, 42, 48, 54, 60]],
    ['166.67', 1, 2, 3, [6, 12, 18, 24, 30, 36, 42, 48, 54, 60]],
  ];

  static const _hard = [
    ['114.28', 1, 1, 7, [7, 14, 21, 28, 35, 42, 49, 56, 63, 70]],
    ['141.67', 1, 5, 12, [12, 24, 36, 48, 60, 72, 84, 96, 108, 120]],
    ['158.33', 1, 7, 12, [12, 24, 36, 48, 60, 72, 84, 96, 108, 120]],
    ['187.5', 1, 7, 8, [8, 16, 24, 32, 40, 48, 56, 64, 72, 80]],
  ];

  static const _expert = [
    ['212.5', 2, 1, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
    ['216.67', 2, 1, 6, [12, 18, 24, 30, 36, 42, 48, 54, 60, 72, 90, 120]],
    ['225', 2, 1, 4, [12, 16, 20, 24, 28, 32, 36, 40, 48, 60, 80, 100]],
    ['233.33', 2, 1, 3, [12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 75, 90]],
    ['237.5', 2, 3, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
    ['250', 2, 1, 2, [14, 18, 22, 26, 30, 34, 38, 42, 46, 50, 60, 80]],
    ['262.5', 2, 5, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
    ['283.33', 2, 5, 6, [12, 18, 24, 30, 36, 42, 48, 54, 60, 72, 90, 120]],
    ['287.5', 2, 7, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
  ];

  static const _genius = [
    ['312.5', 3, 1, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
    ['314.28', 3, 1, 7, [14, 21, 28, 35, 42, 49, 56, 63, 70, 77, 84, 98]],
    ['316.67', 3, 1, 6, [12, 18, 24, 30, 36, 42, 48, 54, 60, 72, 90, 120]],
    ['325', 3, 1, 4, [12, 16, 20, 24, 28, 32, 36, 40, 48, 60, 80, 100]],
    ['333.33', 3, 1, 3, [12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 75, 90]],
    ['337.5', 3, 3, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
    ['341.67', 3, 5, 12, [12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 144]],
    ['362.5', 3, 5, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
    ['366.67', 3, 2, 3, [12, 18, 24, 30, 36, 42, 48, 54, 60, 66, 75, 90]],
    ['387.5', 3, 7, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
    ['416.67', 4, 1, 6, [12, 18, 24, 30, 36, 42, 48, 54, 60, 72, 90, 120]],
    ['437.5', 4, 3, 8, [16, 24, 32, 40, 48, 56, 64, 72, 80, 96, 120, 160]],
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
      Difficulty.expert => _expert,
      Difficulty.genius => _genius,
      Difficulty.mixed =>
        throw ArgumentError('Cannot generate Difficulty.mixed directly'),
    };

    final entry = pool[random.nextInt(pool.length)];
    final pctStr = entry[0] as String;
    final whole = entry[1] as int;
    final extraNum = entry[2] as int;
    final extraDen = entry[3] as int;
    final bases = entry[4] as List<dynamic>;
    final base = bases[random.nextInt(bases.length)] as int;

    final extra = extraNum > 0 ? base * extraNum ~/ extraDen : 0;
    final ans = whole * base + extra;

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
