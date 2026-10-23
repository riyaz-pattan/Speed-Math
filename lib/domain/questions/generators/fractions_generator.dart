import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for Fractions (standard & mixed fractions).
///
/// Features:
/// - Supports both standard fractions (e.g. "3/8 of 640") and mixed fractions (e.g. "3 1/4 + 2 3/4").
/// - Same-denominator addition and subtraction yielding whole integers.
/// - Fraction of fraction of N.
/// - Multi-term mixed fraction simplification with brackets.
/// - All answers are strictly positive whole integers.
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
    final useSameDenom = targetPattern == PatternConstants.fracESameDenom
        ? true
        : (random.nextInt(3) == 0);

    if (useSameDenom) {
      // Sum or difference of fractions with the same denominator yielding a whole number
      final d = 3 + random.nextInt(6); // 3..8
      final targetWhole = 1 + random.nextInt(3); // 1..3
      final totalNumerator = targetWhole * d;
      final isAdd = random.nextBool();

      if (isAdd) {
        final a = 1 + random.nextInt(totalNumerator - 1);
        final b = totalNumerator - a;
        final text = '$a/$d + $b/$d';
        return Question(
          topic: Topic.fractions,
          difficulty: Difficulty.easy,
          displayText: text,
          operands: [a, d, b, d, targetWhole, 3],
          correctAnswer: targetWhole,
        );
      } else {
        final b = 1 + random.nextInt(d * 2);
        final a = totalNumerator + b;
        final text = '$a/$d − $b/$d';
        return Question(
          topic: Topic.fractions,
          difficulty: Difficulty.easy,
          displayText: text,
          operands: [a, d, b, d, targetWhole, 3],
          correctAnswer: targetWhole,
        );
      }
    }

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
      operands: [a, b, n, 1],
      correctAnswer: ans,
    );
  }

  Question _generateMedium(Random random, {String? targetPattern}) {
    final subType = targetPattern == PatternConstants.fracMMixed
        ? 2
        : (targetPattern == PatternConstants.fracMFractionOfFraction
            ? 3
            : (1 + random.nextInt(3)));

    if (subType == 2) {
      // Mixed fractions with whole-number result: e.g. 3 1/4 + 2 3/4 = 6 or 2 1/2 × 4 = 10
      final isProduct = random.nextBool();
      if (isProduct) {
        // e.g. 2 1/2 × 4 = 5/2 × 4 = 10
        final d = [2, 4, 5][random.nextInt(3)];
        final whole = 1 + random.nextInt(4);
        final num = 1;
        final totalNum = whole * d + num;
        final mult = d * (1 + random.nextInt(3));
        final ans = (totalNum * mult) ~/ d;
        final text = '$whole $num/$d × $mult';
        return Question(
          topic: Topic.fractions,
          difficulty: Difficulty.medium,
          displayText: text,
          operands: [whole, num, d, mult, ans, 4],
          correctAnswer: ans,
        );
      } else {
        // e.g. 3 1/4 + 2 3/4 = 6
        final d = [3, 4, 5, 8][random.nextInt(4)];
        final numA = 1 + random.nextInt(d - 1);
        final numB = d - numA;
        final wholeA = 1 + random.nextInt(4);
        final wholeB = 1 + random.nextInt(4);
        final ans = wholeA + wholeB + 1;
        final text = '$wholeA $numA/$d + $wholeB $numB/$d';
        return Question(
          topic: Topic.fractions,
          difficulty: Difficulty.medium,
          displayText: text,
          operands: [wholeA, numA, d, wholeB, numB, d, ans, 4],
          correctAnswer: ans,
        );
      }
    } else if (subType == 3) {
      // a/b of c/d of N: e.g. 1/2 of 2/3 of 120 = 40
      final b = [2, 3, 4, 5][random.nextInt(4)];
      final d = [2, 3, 4, 5][random.nextInt(4)];
      final a = 1;
      final c = 1 + random.nextInt(d - 1);
      final denom = b * d;
      final mult = 10 + random.nextInt(20);
      final n = denom * mult;
      final ans = (a * c * n) ~/ denom;
      final text = '$a/$b of $c/$d of $n';
      return Question(
        topic: Topic.fractions,
        difficulty: Difficulty.medium,
        displayText: text,
        operands: [a, b, c, d, n, ans, 5],
        correctAnswer: ans,
      );
    }

    final int b = 4 + random.nextInt(7); // 4..10
    final coprimes = <int>[];
    for (int i = 1; i < b; i++) {
      if (gcd(i, b) == 1) coprimes.add(i);
    }
    final a = coprimes[random.nextInt(coprimes.length)];
    final k = 15 + random.nextInt(35);
    final n = k * b;
    final ans = a * k;

    return Question(
      topic: Topic.fractions,
      difficulty: Difficulty.medium,
      displayText: '$a/$b of $n',
      operands: [a, b, n, 1],
      correctAnswer: ans,
    );
  }

  Question _generateHard(Random random, {String? targetPattern}) {
    final useMixedSimp = targetPattern == PatternConstants.fracHMixedSimp
        ? true
        : random.nextBool();

    if (useMixedSimp) {
      // Mixed fraction simplification:
      // (3 1/2 × 2 2/7) + 5/6 of 180 − 1 1/4 × 8
      // (7/2 × 16/7) = 8
      // 5/6 of 180 = 150
      // 1 1/4 × 8 = 5/4 × 8 = 10
      // 8 + 150 - 10 = 148
      final prod1 = 8;
      final k = 20 + random.nextInt(20);
      final part2 = 5 * k;
      final part3 = 10;
      final ans = prod1 + part2 - part3;
      final text = '(3 1/2 × 2 2/7) + 5/6 of ${k * 6} − 1 1/4 × 8';

      return Question(
        topic: Topic.fractions,
        difficulty: Difficulty.hard,
        displayText: text,
        operands: [prod1, part2, part3, ans, 6],
        correctAnswer: ans,
      );
    }

    final bool isMinus = targetPattern == PatternConstants.fracHSubtraction
        ? true
        : (targetPattern == PatternConstants.fracHAddition
            ? false
            : random.nextBool());

    final b = 2 + random.nextInt(8); // 2..9
    final d = 2 + random.nextInt(8); // 2..9

    final a = 1 + random.nextInt(b - 1);
    final c = 1 + random.nextInt(d - 1);

    final kB = 15 + random.nextInt(30);
    int n = kB * b;
    int partA = a * kB;

    final kD = 10 + random.nextInt(20);
    int m = kD * d;
    int partB = c * kD;

    if (isMinus && partA <= partB) {
      final tempA = partA;
      partA = partB + 50;
      partB = tempA;
      n = (partA ~/ a) * b;
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
