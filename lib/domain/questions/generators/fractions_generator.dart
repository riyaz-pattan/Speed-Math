import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for Fractions.
///
/// Fractions are formatted in displayText as "a/b of N" (e.g. "3/8 of 640").
/// The shared question widget renders them as stacked fractions.
/// All answers are whole positive integers.
class FractionsGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.fractions;

  @override
  String patternOf(Difficulty difficulty, List<int> operands) =>
      PatternConstants.patternOf(topic, difficulty, operands);

  static int gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

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
    final int b;
    if (targetPattern == PatternConstants.fracESmallDenom) {
      const small = [2, 3, 4];
      b = small[random.nextInt(small.length)];
    } else if (targetPattern == PatternConstants.fracEMidDenom) {
      const mid = [5, 6, 8, 10];
      b = mid[random.nextInt(mid.length)];
    } else {
      const options = DifficultyRanges.fractionsEasyDenominators;
      b = options[random.nextInt(options.length)];
    }

    // Pick a < b such that gcd(a, b) == 1
    final coprimes = <int>[];
    for (int i = 1; i < b; i++) {
      if (gcd(i, b) == 1) coprimes.add(i);
    }
    final a = coprimes[random.nextInt(coprimes.length)];

    final maxK = DifficultyRanges.fractionsEasyNMax ~/ b;
    final minK = max(2, 20 ~/ b);
    final k = minK <= maxK ? (minK + random.nextInt(maxK - minK + 1)) : maxK;
    final n = k * b;
    final ans = a * k;

    return Question(
      topic: Topic.fractions,
      difficulty: Difficulty.easy,
      displayText: '$a/$b of $n',
      operands: [a, b, n],
      correctAnswer: ans,
    );
  }

  Question _generateMedium(Random random, {String? targetPattern}) {
    final int b;
    if (targetPattern == PatternConstants.fracMBandSmall) {
      b = 2 + random.nextInt(4); // 2..5
    } else if (targetPattern == PatternConstants.fracMBandMid) {
      b = 6 + random.nextInt(3); // 6..8
    } else if (targetPattern == PatternConstants.fracMBandLarge) {
      b = 9 + random.nextInt(4); // 9..12
    } else {
      b = DifficultyRanges.fractionsMediumDenomMin +
          random.nextInt(DifficultyRanges.fractionsMediumDenomMax -
              DifficultyRanges.fractionsMediumDenomMin +
              1);
    }

    final coprimes = <int>[];
    for (int i = 1; i < b; i++) {
      if (gcd(i, b) == 1) coprimes.add(i);
    }
    final a = coprimes[random.nextInt(coprimes.length)];

    final minK = (DifficultyRanges.fractionsMediumNMin + b - 1) ~/ b;
    final maxK = DifficultyRanges.fractionsMediumNMax ~/ b;
    final k = minK + random.nextInt(maxK - minK + 1);
    final n = k * b;
    final ans = a * k;

    return Question(
      topic: Topic.fractions,
      difficulty: Difficulty.medium,
      displayText: '$a/$b of $n',
      operands: [a, b, n],
      correctAnswer: ans,
    );
  }

  Question _generateHard(Random random, {String? targetPattern}) {
    final bool isMinus;
    if (targetPattern == PatternConstants.fracHSubtraction) {
      isMinus = true;
    } else if (targetPattern == PatternConstants.fracHAddition) {
      isMinus = false;
    } else {
      isMinus = random.nextBool();
    }

    final b = 2 + random.nextInt(11); // 2..12
    final d = 2 + random.nextInt(11); // 2..12

    final coprimesB = <int>[];
    for (int i = 1; i < b; i++) {
      if (gcd(i, b) == 1) coprimesB.add(i);
    }
    final a = coprimesB[random.nextInt(coprimesB.length)];

    final coprimesD = <int>[];
    for (int i = 1; i < d; i++) {
      if (gcd(i, d) == 1) coprimesD.add(i);
    }
    final c = coprimesD[random.nextInt(coprimesD.length)];

    final minKB = (DifficultyRanges.fractionsHardNMin + b - 1) ~/ b;
    final maxKB = DifficultyRanges.fractionsHardNMax ~/ b;
    final kB = minKB + random.nextInt(maxKB - minKB + 1);
    int n = kB * b;
    int partA = a * kB;

    final minKD = (DifficultyRanges.fractionsHardNMin + d - 1) ~/ d;
    final maxKD = DifficultyRanges.fractionsHardNMax ~/ d;
    final kD = minKD + random.nextInt(maxKD - minKD + 1);
    int m = kD * d;
    int partB = c * kD;

    if (isMinus && partA <= partB) {
      // Ensure positive result: partA must exceed partB
      final tempA = partA;
      partA = partB;
      partB = tempA;
      final tempN = n;
      n = m;
      m = tempN;
      if (partA <= partB) {
        n = (partB + 50) * b;
        partA = (a * n) ~/ b;
      }
    }

    final ans = isMinus ? partA - partB : partA + partB;
    final opSymbol = isMinus ? '−' : '+';

    return Question(
      topic: Topic.fractions,
      difficulty: Difficulty.hard,
      displayText: '$a/$b of $n $opSymbol $c/$d of $m',
      operands: [a, b, n, c, d, m, isMinus ? 1 : 0],
      correctAnswer: ans,
    );
  }
}
