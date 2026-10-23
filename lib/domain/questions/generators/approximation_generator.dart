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
        Difficulty.mixed => _generateEasy(random),
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
}
