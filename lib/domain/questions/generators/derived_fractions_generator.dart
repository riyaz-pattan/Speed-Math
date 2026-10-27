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

  static const _expert = [
    ['27.27', 3, 11],
    ['45.45', 5, 11],
    ['63.64', 7, 11],
    ['72.73', 8, 11],
    ['81.82', 9, 11],
    ['91.67', 11, 12],
    ['15.38', 2, 13],
    ['23.08', 3, 13],
    ['30.77', 4, 13],
    ['21.43', 3, 14],
    ['35.71', 5, 14],
    ['64.29', 9, 14],
    ['78.57', 11, 14],
    ['18.75', 3, 16],
    ['31.25', 5, 16],
    ['43.75', 7, 16],
    ['56.25', 9, 16],
    ['68.75', 11, 16],
    ['81.25', 13, 16],
    ['93.75', 15, 16],
  ];

  static const _genius = [
    ['38.46', 5, 13],
    ['46.15', 6, 13],
    ['53.85', 7, 13],
    ['61.54', 8, 13],
    ['69.23', 9, 13],
    ['76.92', 10, 13],
    ['11.76', 2, 17],
    ['17.65', 3, 17],
    ['23.53', 4, 17],
    ['29.41', 5, 17],
    ['10.53', 2, 19],
    ['15.79', 3, 19],
    ['21.05', 4, 19],
    ['26.32', 5, 19],
    ['27.78', 5, 18],
    ['38.89', 7, 18],
    ['61.11', 11, 18],
    ['20.83', 5, 24],
    ['29.17', 7, 24],
    ['45.83', 11, 24],
    ['54.17', 13, 24],
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
