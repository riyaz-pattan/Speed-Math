import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates percentage → non-unit fraction conversion questions.
/// e.g. "37.5% into fraction" → answer: "3/8"
class DerivedFractionsGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.derivedFractions;

  @override
  String patternOf(Difficulty difficulty, List<int> operands) =>
      PatternConstants.patternOf(topic, difficulty, operands);

  // [percentage_str, numerator, denominator]
  static const _easy = [
    ['75', 3, 4],
    ['40', 2, 5],
    ['60', 3, 5],
    ['80', 4, 5],
    ['30', 3, 10],
    ['70', 7, 10],
  ];

  static const _medium = [
    ['37.5', 3, 8],
    ['62.5', 5, 8],
    ['87.5', 7, 8],
    ['66.67', 2, 3],
    ['83.33', 5, 6],
    ['44.44', 4, 9],
    ['77.78', 7, 9],
  ];

  static const _hard = [
    ['28.57', 2, 7],
    ['42.86', 3, 7],
    ['57.14', 4, 7],
    ['71.43', 5, 7],
    ['85.71', 6, 7],
    ['41.67', 5, 12],
    ['58.33', 7, 12],
    ['26.67', 4, 15],
    ['46.67', 7, 15],
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

    return Question(
      topic: Topic.derivedFractions,
      difficulty: difficulty,
      displayText: '$pctStr% into fraction',
      operands: [num, den],
      correctAnswer: num,
      stringAnswer: '$num/$den',
      pattern: PatternConstants.patternOf(
          Topic.derivedFractions, difficulty, [num, den]),
    );
  }
}
