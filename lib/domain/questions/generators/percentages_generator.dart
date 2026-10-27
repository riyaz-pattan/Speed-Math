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
        Difficulty.expert => _generateExpert(random, targetPattern: pattern),
        Difficulty.genius => _generateGenius(random, targetPattern: pattern),
        Difficulty.mixed =>
          throw ArgumentError('Cannot generate Difficulty.mixed directly'),
      };

      final pat = patternOf(difficulty, raw.operands);
      q = Question(
        topic: raw.topic,
        difficulty: difficulty,
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

  Question _generateExpert(Random random, {String? targetPattern}) {
    final useFractional = random.nextBool();

    if (useFractional) {
      // Fractional percentages like 12.5%, 37.5%, 16.67%, 83.33%, 33.33%, 66.67%
      const fractions = [
        ('12.5%', 1, 8),
        ('37.5%', 3, 8),
        ('62.5%', 5, 8),
        ('87.5%', 7, 8),
        ('16.67%', 1, 6),
        ('83.33%', 5, 6),
        ('33.33%', 1, 3),
        ('66.67%', 2, 3),
      ];

      final f1 = fractions[random.nextInt(fractions.length)];
      final f2 = fractions[random.nextInt(fractions.length)];

      final k1 = 15 + random.nextInt(85);
      final k2 = 15 + random.nextInt(85);

      var base1 = f1.$3 * k1;
      var base2 = f2.$3 * k2;

      var part1 = f1.$2 * k1;
      var part2 = f2.$2 * k2;

      var lbl1 = f1.$1;
      var lbl2 = f2.$1;

      final isMinus = random.nextBool();
      if (isMinus && part1 <= part2) {
        final tmpBase = base1; base1 = base2; base2 = tmpBase;
        final tmpPart = part1; part1 = part2; part2 = tmpPart;
        final tmpLbl = lbl1; lbl1 = lbl2; lbl2 = tmpLbl;
      }

      final opSymbol = (isMinus && part1 > part2) ? '−' : '+';
      final ans = opSymbol == '−' ? part1 - part2 : part1 + part2;
      final text = '$lbl1 of $base1 $opSymbol $lbl2 of $base2';

      return Question(
        topic: Topic.percentages,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [base1, base2, ans],
        correctAnswer: ans,
      );
    } else {
      // 3-term percentage expressions: x% of A + y% of B - z% of C (multiples of 5 or 10, bases 100..2000)
      final a = (5 + random.nextInt(96)) * 20; // 100..2000
      final b = (5 + random.nextInt(96)) * 20;
      final c = (5 + random.nextInt(96)) * 20;

      final x = 5 * (1 + random.nextInt(19)); // 5..95
      final y = 5 * (1 + random.nextInt(19));
      final z = 5 * (1 + random.nextInt(19));

      final partA = (x * a) ~/ 100;
      final partB = (y * b) ~/ 100;
      final partC = (z * c) ~/ 100;

      final isMinus = random.nextBool();
      final String opSymbol;
      final int ans;

      if (isMinus && (partA + partB > partC)) {
        opSymbol = '−';
        ans = partA + partB - partC;
      } else {
        opSymbol = '+';
        ans = partA + partB + partC;
      }

      final text = '$x% of $a + $y% of $b $opSymbol $z% of $c';
      return Question(
        topic: Topic.percentages,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [x, a, y, b, z, c, ans],
        correctAnswer: ans,
      );
    }
  }

  Question _generateGenius(Random random, {String? targetPattern}) {
    final type = random.nextInt(2);

    if (type == 0) {
      // Complex multi-term combination: (x% of A) * (y% of B) / C
      final c1 = 2 + random.nextInt(7); // 2..8
      final c2 = 2 + random.nextInt(7); // 2..8
      final c = c1 * c2;

      final k1 = 3 + random.nextInt(12);
      final k2 = 3 + random.nextInt(12);

      final partA = k1 * c1;
      final partB = k2 * c2;

      const pctOptions = [10, 20, 25, 40, 50];
      final x = pctOptions[random.nextInt(pctOptions.length)];
      final a = (partA * 100) ~/ x;

      final y = pctOptions[random.nextInt(pctOptions.length)];
      final b = (partB * 100) ~/ y;

      final ans = k1 * k2;
      final text = '($x% of $a) × ($y% of $b) ÷ $c';

      return Question(
        topic: Topic.percentages,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [x, a, y, b, c, ans],
        correctAnswer: ans,
      );
    } else {
      // 3-term tricky percentage arithmetic with bases up to 5000
      final a = (20 + random.nextInt(81)) * 50; // 1000..5000
      final b = (20 + random.nextInt(81)) * 50;
      final c = (20 + random.nextInt(81)) * 50;

      final x = 5 * (1 + random.nextInt(19));
      final y = 5 * (1 + random.nextInt(19));
      final z = 5 * (1 + random.nextInt(19));

      final partA = (x * a) ~/ 100;
      final partB = (y * b) ~/ 100;
      final partC = (z * c) ~/ 100;

      final isMinus = random.nextBool();
      final String opSymbol;
      final int ans;

      if (isMinus && (partA + partB > partC)) {
        opSymbol = '−';
        ans = partA + partB - partC;
      } else {
        opSymbol = '+';
        ans = partA + partB + partC;
      }

      final text = '$x% of $a + $y% of $b $opSymbol $z% of $c';
      return Question(
        topic: Topic.percentages,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [x, a, y, b, z, c, ans],
        correctAnswer: ans,
      );
    }
  }
}
