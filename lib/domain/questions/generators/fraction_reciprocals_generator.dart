import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates percentage → unit-fraction conversion questions.
/// e.g. "12.5% into fraction" → answer: "1/8"
class FractionReciprocalsGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.fractionReciprocals;

  @override
  String patternOf(Difficulty difficulty, List<int> operands) =>
      PatternConstants.patternOf(topic, difficulty, operands);

  // [percentage_str, numerator, denominator]
  static const _easy = [
    ['50', 1, 2],
    ['25', 1, 4],
    ['20', 1, 5],
    ['10', 1, 10],
    ['5', 1, 20],
  ];

  static const _medium = [
    ['33.33', 1, 3],
    ['16.67', 1, 6],
    ['12.5', 1, 8],
    ['11.11', 1, 9],
    ['9.09', 1, 11],
    ['8.33', 1, 12],
  ];

  static const _hard = [
    ['14.28', 1, 7],
    ['7.69', 1, 13],
    ['7.14', 1, 14],
    ['6.67', 1, 15],
    ['6.25', 1, 16],
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
      topic: Topic.fractionReciprocals,
      difficulty: difficulty,
      displayText: '$pctStr% into fraction',
      operands: [num, den],
      correctAnswer: num,
      stringAnswer: '$num/$den',
      pattern:
          PatternConstants.patternOf(Topic.fractionReciprocals, difficulty, [num, den]),
    );
  }
}
