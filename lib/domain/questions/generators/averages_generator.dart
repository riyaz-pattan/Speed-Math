import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for Averages.
///
/// Easy: "Average of a, b, c = ?" (3 two-digit numbers, sum divisible by 3)
/// Medium: "Average of a, b, c, d, e = ?" (5 numbers of 2 to 3 digits, sum divisible by 5)
/// Hard: "Average of 5 numbers is A. Four of them are w, x, y, z. Find the fifth."
class AveragesGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.averages;

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
    Question q;
    int tries = 0;
    do {
      final raw = switch (difficulty) {
        Difficulty.easy => _generateEasy(random, targetPattern: pattern),
        Difficulty.medium => _generateMedium(random, targetPattern: pattern),
        Difficulty.hard => _generateHard(random, targetPattern: pattern),
        Difficulty.mixed =>
          throw ArgumentError('Cannot generate Difficulty.mixed directly'),
      };

      final pat = patternOf(difficulty, raw.operands);
      q = Question(
        topic: raw.topic,
        difficulty: raw.difficulty,
        displayText: raw.displayText,
        operands: raw.operands,
        correctAnswer: raw.correctAnswer,
        pattern: pat,
      );
      tries++;
    } while (pattern != null && q.pattern != pattern && tries < 50);

    return q;
  }

  Question _generateEasy(Random random, {String? targetPattern}) {
    final isClose = targetPattern == PatternConstants.avgECloseSpread
        ? true
        : (targetPattern == PatternConstants.avgEWideSpread
            ? false
            : random.nextBool());

    final maxSpread = isClose ? 12 : 28;
    final avg = 25 + random.nextInt(60); // 25..84

    int d1 = (random.nextInt(maxSpread) + 1) * (random.nextBool() ? 1 : -1);
    int d2 = (random.nextInt(maxSpread) + 1) * (random.nextBool() ? 1 : -1);
    int d3 = -(d1 + d2);

    int a = (avg + d1).clamp(10, 99);
    int b = (avg + d2).clamp(10, 99);
    int c = (avg + d3).clamp(10, 99);

    // Adjust c to guarantee exact divisibility
    final sum = a + b + c;
    final rem = sum % 3;
    if (rem != 0) {
      c += (3 - rem);
      if (c > 99) c -= 3;
    }

    final realAvg = (a + b + c) ~/ 3;

    return Question(
      topic: Topic.averages,
      difficulty: Difficulty.easy,
      displayText: 'Average of $a, $b, $c = ?',
      operands: [a, b, c],
      correctAnswer: realAvg,
    );
  }

  Question _generateMedium(Random random, {String? targetPattern}) {
    final has3Digits = targetPattern == PatternConstants.avgMMixedDigits
        ? true
        : (targetPattern == PatternConstants.avgMTwoDigit
            ? false
            : random.nextBool());

    final avg = has3Digits ? (70 + random.nextInt(120)) : (30 + random.nextInt(45));

    final deltas = <int>[];
    int sumDeltas = 0;
    for (int i = 0; i < 4; i++) {
      final spread = has3Digits ? 35 : 18;
      final d = (random.nextInt(spread) + 1) * (random.nextBool() ? 1 : -1);
      deltas.add(d);
      sumDeltas += d;
    }
    deltas.add(-sumDeltas);

    final nums = deltas.map((d) => (avg + d).clamp(20, 295)).toList();
    final totalSum = nums.reduce((v, e) => v + e);
    final rem = totalSum % 5;
    if (rem != 0) {
      nums[4] += (5 - rem);
    }

    final realAvg = nums.reduce((v, e) => v + e) ~/ 5;

    return Question(
      topic: Topic.averages,
      difficulty: Difficulty.medium,
      displayText:
          'Average of ${nums[0]}, ${nums[1]}, ${nums[2]}, ${nums[3]}, ${nums[4]} = ?',
      operands: nums,
      correctAnswer: realAvg,
    );
  }

  Question _generateHard(Random random, {String? targetPattern}) {
    final avg = 25 + random.nextInt(95); // 25..119
    final targetTotal = avg * 5;

    final given = <int>[];
    int currentSum = 0;
    for (int i = 0; i < 4; i++) {
      final spread = 20;
      final offset = (random.nextInt(spread) + 1) * (random.nextBool() ? 1 : -1);
      final n = max(5, avg + offset);
      given.add(n);
      currentSum += n;
    }

    int fifth = targetTotal - currentSum;
    if (fifth <= 0) {
      final diff = (10 - fifth);
      given[0] = max(5, given[0] - diff);
      currentSum = given.reduce((v, e) => v + e);
      fifth = targetTotal - currentSum;
    }

    return Question(
      topic: Topic.averages,
      difficulty: Difficulty.hard,
      displayText:
          'Average of 5 numbers is $avg. Four of them are ${given[0]}, ${given[1]}, ${given[2]}, ${given[3]}. Find the fifth.',
      operands: [avg, given[0], given[1], given[2], given[3], fifth],
      correctAnswer: fifth,
    );
  }
}
