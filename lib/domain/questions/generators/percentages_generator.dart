import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for Percentages.
///
/// All results are whole positive integers (no decimal answers).
class PercentagesGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.percentages;

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
    final int x;
    if (targetPattern == PatternConstants.pctETenFifty) {
      x = random.nextBool() ? 10 : 50;
    } else if (targetPattern == PatternConstants.pctETwentyTwentyfive) {
      x = random.nextBool() ? 20 : 25;
    } else {
      const options = DifficultyRanges.percentagesEasyPercentages;
      x = options[random.nextInt(options.length)];
    }

    final maxK = DifficultyRanges.percentagesEasyNMax ~/
        DifficultyRanges.percentagesEasyNMultiple;
    final k = 1 + random.nextInt(maxK);
    final n = k * DifficultyRanges.percentagesEasyNMultiple;
    final ans = (x * n) ~/ 100;

    return Question(
      topic: Topic.percentages,
      difficulty: Difficulty.easy,
      displayText: '$x% of $n',
      operands: [x, n],
      correctAnswer: ans,
    );
  }

  Question _generateMedium(Random random, {String? targetPattern}) {
    final int x;
    if (targetPattern == PatternConstants.pctMQuarterMult) {
      x = random.nextBool() ? 25 : 75;
    } else if (targetPattern == PatternConstants.pctMTenthMult) {
      const tenths = [10, 20, 30, 40, 50, 60, 70, 80, 90];
      x = tenths[random.nextInt(tenths.length)];
    } else if (targetPattern == PatternConstants.pctMFifthMult) {
      const fifths = [5, 15, 35, 45, 55, 65, 85, 95];
      x = fifths[random.nextInt(fifths.length)];
    } else {
      // Any multiple of 5 between 5 and 95
      x = 5 * (1 + random.nextInt(19));
    }

    final minK = DifficultyRanges.percentagesMediumNMin ~/
        DifficultyRanges.percentagesMediumNMultiple;
    final maxK = DifficultyRanges.percentagesMediumNMax ~/
        DifficultyRanges.percentagesMediumNMultiple;
    final k = minK + random.nextInt(maxK - minK + 1);
    final n = k * DifficultyRanges.percentagesMediumNMultiple;
    final ans = (x * n) ~/ 100;

    return Question(
      topic: Topic.percentages,
      difficulty: Difficulty.medium,
      displayText: '$x% of $n',
      operands: [x, n],
      correctAnswer: ans,
    );
  }

  Question _generateHard(Random random, {String? targetPattern}) {
    final bool isMinus;
    if (targetPattern == PatternConstants.pctHSubtraction) {
      isMinus = true;
    } else if (targetPattern == PatternConstants.pctHAddition) {
      isMinus = false;
    } else {
      isMinus = random.nextBool();
    }

    final minK = DifficultyRanges.percentagesHardNMin ~/
        DifficultyRanges.percentagesHardNMultiple;
    final maxK = DifficultyRanges.percentagesHardNMax ~/
        DifficultyRanges.percentagesHardNMultiple;

    int x = 5 * (1 + random.nextInt(19));
    int y = 5 * (1 + random.nextInt(19));
    int k1 = minK + random.nextInt(maxK - minK + 1);
    int k2 = minK + random.nextInt(maxK - minK + 1);

    int a = k1 * DifficultyRanges.percentagesHardNMultiple;
    int b = k2 * DifficultyRanges.percentagesHardNMultiple;
    int partA = (x * a) ~/ 100;
    int partB = (y * b) ~/ 100;

    if (isMinus) {
      // Ensure positive result: partA must be strictly greater than partB
      if (partA <= partB) {
        final tempX = x;
        x = y;
        y = tempX;
        final tempA = a;
        a = b;
        b = tempA;
        final tempPart = partA;
        partA = partB;
        partB = tempPart;

        if (partA <= partB) {
          // Adjust a so partA > partB
          a = b + 100;
          x = max(x, y + 10);
          partA = (x * a) ~/ 100;
        }
      }
    }

    final ans = isMinus ? partA - partB : partA + partB;
    final opSymbol = isMinus ? '−' : '+';

    return Question(
      topic: Topic.percentages,
      difficulty: Difficulty.hard,
      displayText: '$x% of $a $opSymbol $y% of $b',
      operands: [x, a, y, b, isMinus ? 1 : 0],
      correctAnswer: ans,
    );
  }
}
