import 'dart:math';

import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/pattern_constants.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';
import 'package:speed_math_with_ai/domain/questions/question_generator.dart';

/// Question generator for Approximation questions.
///
/// Features:
/// - Generates realistic expressions containing decimal operands that round cleanly to friendly integers.
/// - Calculates answer using friendly rounded integers, guaranteeing whole positive answers.
/// - Ends with "≈ ?".
class ApproximationGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.approximation;

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
        Difficulty.easy => _generateEasy(random),
        Difficulty.medium => _generateMedium(random),
        Difficulty.hard => _generateHard(random),
        Difficulty.expert => _generateExpert(random),
        Difficulty.genius => _generateGenius(random),
        Difficulty.mixed => _generateEasy(random),
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

  /// Adds a small offset (e.g. ±0.01..0.04 or ±0.1..0.4) to a friendly integer.
  static String _near(int base, Random random) {
    final useHundredths = random.nextBool();
    if (useHundredths) {
      final delta = (1 + random.nextInt(4)) / 100.0;
      final val = random.nextBool() ? (base + delta) : (base - delta);
      return val.toStringAsFixed(2);
    } else {
      final delta = (1 + random.nextInt(3)) / 10.0;
      final val = random.nextBool() ? (base + delta) : (base - delta);
      return val.toStringAsFixed(1);
    }
  }

  static String _nearInt(int base, Random random) {
    final offset = (1 + random.nextInt(3)) * (random.nextBool() ? 1 : -1);
    return (base + offset).toString();
  }

  static String _nearSqrt(int root, Random random) {
    final sq = root * root;
    final delta = (1 + random.nextInt(3)) * (random.nextBool() ? 1 : -1);
    final dec = (1 + random.nextInt(8)) / 10.0;
    final val = sq + delta + dec;
    return '√${val.toStringAsFixed(1)}';
  }

  Question _generateEasy(Random random) {
    // 2 patterns:
    // 1: a x b (near numbers)
    // 2: a + b x c (near numbers)
    final type = 1 + random.nextInt(2);

    if (type == 1) {
      // Near product: a x b
      final friendlyA = 12 + random.nextInt(25);
      final friendlyB = 4 + random.nextInt(12);
      final answer = friendlyA * friendlyB;

      final strA = _near(friendlyA, random);
      final strB = _near(friendlyB, random);
      final text = '$strA × $strB ≈ ?';

      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.easy,
        displayText: text,
        operands: [friendlyA, friendlyB, answer, type],
        correctAnswer: answer,
      );
    } else {
      // a + b x c
      final friendlyA = 20 + random.nextInt(100);
      final friendlyB = 6 + random.nextInt(15);
      final friendlyC = 4 + random.nextInt(8);
      final answer = friendlyA + (friendlyB * friendlyC);

      final strA = _near(friendlyA, random);
      final strB = _near(friendlyB, random);
      final strC = _near(friendlyC, random);
      final text = '$strA + $strB × $strC ≈ ?';

      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.easy,
        displayText: text,
        operands: [friendlyA, friendlyB, friendlyC, answer, type],
        correctAnswer: answer,
      );
    }
  }

  Question _generateMedium(Random random) {
    // 3 patterns:
    // 1: Percentage of near number + near number (e.g. 19.8% of 2495 + 50.2)
    // 2: Sqrt of near perfect square x near number (e.g. √624.9 × 3.98)
    // 3: Friendly product and exact division (e.g. 49.98 × 19.9 ÷ 5.01)
    final type = 1 + random.nextInt(3);

    if (type == 1) {
      // Near percentage: x% of N + A
      final pList = [10, 20, 25, 50];
      final friendlyP = pList[random.nextInt(pList.length)];
      final friendlyN = (5 + random.nextInt(15)) * 100;
      final part = (friendlyP * friendlyN) ~/ 100;
      final friendlyA = 25 + random.nextInt(100);
      final answer = part + friendlyA;

      final strP = _near(friendlyP, random);
      final strN = (friendlyN - 2 + random.nextInt(5)).toString();
      final strA = _near(friendlyA, random);
      final text = '$strP% of $strN + $strA ≈ ?';

      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.medium,
        displayText: text,
        operands: [friendlyP, friendlyN, friendlyA, answer, type],
        correctAnswer: answer,
      );
    } else if (type == 2) {
      // Sqrt of near-perfect square: √(N^2 ± 0.3) x B
      final root = 15 + random.nextInt(15); // 15..29 -> 225..841
      final sq = root * root;
      final friendlyB = 3 + random.nextInt(6);
      final answer = root * friendlyB;

      final strSq = (sq - 0.2 + (random.nextInt(5) / 10.0)).toStringAsFixed(1);
      final strB = _near(friendlyB, random);
      final text = '√$strSq × $strB ≈ ?';

      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.medium,
        displayText: text,
        operands: [root, friendlyB, answer, type],
        correctAnswer: answer,
      );
    } else {
      // Friendly product and exact division: A × B ÷ C
      final friendlyC = 4 + random.nextInt(5);
      final quotient = 10 + random.nextInt(20);
      final friendlyA = quotient * friendlyC;
      final friendlyB = 8 + random.nextInt(15);
      final answer = (friendlyA ~/ friendlyC) * friendlyB;

      final strA = _near(friendlyA, random);
      final strB = _near(friendlyB, random);
      final strC = _near(friendlyC, random);
      final text = '$strA × $strB ÷ $strC ≈ ?';

      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.medium,
        displayText: text,
        operands: [friendlyA, friendlyB, friendlyC, answer, type],
        correctAnswer: answer,
      );
    }
  }

  Question _generateHard(Random random) {
    // 2 patterns:
    // 1: Multi-term with percentage, division, and sum: e.g. 49.98 × 19.9 ÷ 5.01 + 149.9
    // 2: Powers, exact division, and product: e.g. 23.9² + 120.2 ÷ 5.98 − 15.02 × 8.01
    final type = 1 + random.nextInt(2);

    if (type == 1) {
      // A x B / C + D
      final friendlyC = 5;
      final friendlyB = 20;
      final friendlyA = (10 + random.nextInt(15)) * 5;
      final friendlyD = 50 + random.nextInt(150);
      final answer = (friendlyA * friendlyB ~/ friendlyC) + friendlyD;

      final strA = _near(friendlyA, random);
      final strB = _near(friendlyB, random);
      final strC = _near(friendlyC, random);
      final strD = _near(friendlyD, random);
      final text = '$strA × $strB ÷ $strC + $strD ≈ ?';

      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.hard,
        displayText: text,
        operands: [friendlyA, friendlyB, friendlyC, friendlyD, answer, type],
        correctAnswer: answer,
      );
    } else {
      // A² + B ÷ C − D × E
      final friendlyA = 12 + random.nextInt(10);
      final friendlyC = 4 + random.nextInt(4);
      final friendlyB = (10 + random.nextInt(15)) * friendlyC;
      final friendlyD = 5 + random.nextInt(10);
      final friendlyE = 4 + random.nextInt(6);
      final answer = (friendlyA * friendlyA) + (friendlyB ~/ friendlyC) - (friendlyD * friendlyE);

      final strA = _near(friendlyA, random);
      final strB = _near(friendlyB, random);
      final strC = _near(friendlyC, random);
      final strD = _near(friendlyD, random);
      final strE = _near(friendlyE, random);
      final text = '$strA² + $strB ÷ $strC − $strD × $strE ≈ ?';

      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.hard,
        displayText: text,
        operands: [friendlyA, friendlyB, friendlyC, friendlyD, friendlyE, answer, type],
        correctAnswer: answer > 0 ? answer : 100,
      );
    }
  }

  Question _generateExpert(Random random) {
    // Expert: 5 to 6 term operations mixing decimals, near-percentages, and square roots of near-perfect squares (e.g. √145 ≈ 12, 19.8% of 498 ≈ 20% of 500 = 100). Result up to 500000.
    final form = 1 + random.nextInt(2);

    if (form == 1) {
      // 5 terms: √S + p% of N − a × b + c ÷ d
      final root = 12 + random.nextInt(25);
      const pctOptions = [10, 15, 20, 25, 30, 40, 50];
      final p = pctOptions[random.nextInt(pctOptions.length)];
      final n = (4 + random.nextInt(17)) * 100;
      final pPart = (p * n) ~/ 100;

      final a = 8 + random.nextInt(15);
      final b = 8 + random.nextInt(15);
      final prod = a * b;

      final d = 4 + random.nextInt(9);
      final q = 10 + random.nextInt(30);
      final c = q * d;

      final totalPositive = root + pPart + q;
      final isMinus = totalPositive > prod;
      final ans = isMinus ? (totalPositive - prod) : (totalPositive + prod);
      final op = isMinus ? '−' : '+';

      final strRoot = _nearSqrt(root, random);
      final strP = _near(p, random);
      final strN = _nearInt(n, random);
      final strA = _near(a, random);
      final strB = _near(b, random);
      final strC = _near(c, random);
      final strD = _near(d, random);

      final text = '$strRoot + $strP% of $strN $op $strA × $strB + $strC ÷ $strD ≈ ?';
      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [root, p, n, a, b, c, d, ans, 1],
        correctAnswer: ans,
      );
    } else {
      // 6 terms: p1% of N1 + p2% of N2 + √S − a × b ÷ c + d
      const p1Options = [15, 20, 25, 50];
      final p1 = p1Options[random.nextInt(p1Options.length)];
      final n1 = (5 + random.nextInt(20)) * 100;
      final part1 = (p1 * n1) ~/ 100;

      const p2Options = [10, 20, 30, 40];
      final p2 = p2Options[random.nextInt(p2Options.length)];
      final n2 = (3 + random.nextInt(13)) * 100;
      final part2 = (p2 * n2) ~/ 100;

      final root = 15 + random.nextInt(20);

      final c = 3 + random.nextInt(6);
      final k = 3 + random.nextInt(10);
      final b = k * c;
      final a = 8 + random.nextInt(18);
      final divProd = a * k;

      final d = 20 + random.nextInt(100);

      final totalPos = part1 + part2 + root + d;
      final isMinus = totalPos > divProd;
      final ans = isMinus ? (totalPos - divProd) : (totalPos + divProd);
      final op = isMinus ? '−' : '+';

      final strP1 = _near(p1, random);
      final strN1 = _nearInt(n1, random);
      final strP2 = _near(p2, random);
      final strN2 = _nearInt(n2, random);
      final strRoot = _nearSqrt(root, random);
      final strA = _near(a, random);
      final strB = _near(b, random);
      final strC = _near(c, random);
      final strD = _near(d, random);

      final text =
          '$strP1% of $strN1 + $strP2% of $strN2 + $strRoot $op $strA × $strB ÷ $strC + $strD ≈ ?';
      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [p1, n1, p2, n2, root, a, b, c, d, ans, 2],
        correctAnswer: ans,
      );
    }
  }

  Question _generateGenius(Random random) {
    // Genius: High-level banking exam approximation expressions with 6 terms, tricky roots, and large numbers up to 1000000.
    final form = 1 + random.nextInt(3);

    if (form == 1) {
      // (p1% of N1) × (p2% of N2) ÷ D + √S − a × b
      const p1Options = [10, 20, 25];
      final p1 = p1Options[random.nextInt(p1Options.length)];
      final n1 = (10 + random.nextInt(30)) * 100;
      final a1 = (p1 * n1) ~/ 100;

      const p2Options = [10, 20, 50];
      final p2 = p2Options[random.nextInt(p2Options.length)];
      final n2 = (10 + random.nextInt(30)) * 100;
      final a2 = (p2 * n2) ~/ 100;

      final prod = a1 * a2;
      final divisors = <int>[];
      for (int i = 20; i <= 200; i++) {
        if (prod % i == 0) divisors.add(i);
      }
      final divD = divisors.isNotEmpty ? divisors[random.nextInt(divisors.length)] : 50;
      final quotient = prod ~/ divD;

      final root = 40 + random.nextInt(60);
      final a = 15 + random.nextInt(30);
      final b = 15 + random.nextInt(30);
      final termProd = a * b;

      final total = quotient + root;
      final isMinus = total > termProd;
      final ans = isMinus ? (total - termProd) : (total + termProd);
      final op = isMinus ? '−' : '+';

      final strP1 = _near(p1, random);
      final strN1 = _nearInt(n1, random);
      final strP2 = _near(p2, random);
      final strN2 = _nearInt(n2, random);
      final strDivD = _near(divD, random);
      final strRoot = _nearSqrt(root, random);
      final strA = _near(a, random);
      final strB = _near(b, random);

      final text =
          '($strP1% of $strN1) × ($strP2% of $strN2) ÷ $strDivD + $strRoot $op $strA × $strB ≈ ?';
      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [p1, n1, p2, n2, divD, root, a, b, ans, 1],
        correctAnswer: ans,
      );
    } else if (form == 2) {
      // a² + b³ ÷ c + p% of N − √S × d
      final a = 80 + random.nextInt(120);
      final aSq = a * a;

      final c = 2 + random.nextInt(6); // 2..7
      final k = 2 + random.nextInt(4);
      final b = k * c; // b³ is guaranteed divisible by c
      final cubePart = (b * b * b) ~/ c;

      const pOptions = [15, 25, 35, 50];
      final p = pOptions[random.nextInt(pOptions.length)];
      final n = (20 + random.nextInt(80)) * 100;
      final pPart = (p * n) ~/ 100;

      final root = 30 + random.nextInt(40);
      final d = 4 + random.nextInt(12);
      final rootMult = root * d;

      final totalPos = aSq + cubePart + pPart;
      final isMinus = totalPos > rootMult;
      final ans = isMinus ? (totalPos - rootMult) : (totalPos + rootMult);
      final op = isMinus ? '−' : '+';

      final strA = _near(a, random);
      final strB = _near(b, random);
      final strC = _near(c, random);
      final strP = _near(p, random);
      final strN = _nearInt(n, random);
      final strRoot = _nearSqrt(root, random);
      final strD = _near(d, random);

      final text =
          '$strA² + $strB³ ÷ $strC + $strP% of $strN $op $strRoot × $strD ≈ ?';
      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [a, b, c, p, n, root, d, ans, 2],
        correctAnswer: ans,
      );
    } else {
      // 6 terms: p% of N + a × b − c ÷ d + √S + e²
      const pOptions = [12, 16, 24, 32];
      final p = pOptions[random.nextInt(pOptions.length)];
      final n = (50 + random.nextInt(150)) * 100;
      final pPart = (p * n) ~/ 100;

      final a = 30 + random.nextInt(50);
      final b = 25 + random.nextInt(45);
      final prod = a * b;

      final d = 8 + random.nextInt(12);
      final q = 20 + random.nextInt(50);
      final c = q * d;

      final root = 40 + random.nextInt(50);
      final e = 40 + random.nextInt(80);
      final eSq = e * e;

      final ans = pPart + prod - q + root + eSq;

      final strP = _near(p, random);
      final strN = _nearInt(n, random);
      final strA = _near(a, random);
      final strB = _near(b, random);
      final strC = _near(c, random);
      final strD = _near(d, random);
      final strRoot = _nearSqrt(root, random);
      final strE = _near(e, random);

      final text =
          '$strP% of $strN + $strA × $strB − $strC ÷ $strD + $strRoot + $strE² ≈ ?';
      return Question(
        topic: Topic.approximation,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [p, n, a, b, c, d, root, e, ans, 3],
        correctAnswer: ans,
      );
    }
  }
}
