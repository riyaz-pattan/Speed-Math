import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for Simplification (BODMAS / Order of Operations).
///
/// Easy: a + b × c, a × b − c, a + b ÷ c
/// Medium: (a + b) × c − d, a × b ± c × d
/// Hard: n² − a ÷ b + c × d, n² + a × b − c ÷ d (includes square and exact division)
class SimplificationGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.simplification;

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
    final int form;
    if (targetPattern == PatternConstants.simpEAddMul) {
      form = 1;
    } else if (targetPattern == PatternConstants.simpEMulSub) {
      form = 2;
    } else if (targetPattern == PatternConstants.simpEDiv) {
      form = 3;
    } else {
      form = 1 + random.nextInt(3);
    }

    if (form == 1) {
      // a + b × c
      final a = 5 + random.nextInt(40);
      final b = 2 + random.nextInt(10);
      final c = 2 + random.nextInt(10);
      final ans = a + b * c;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.easy,
        displayText: '$a + $b × $c',
        operands: [a, b, c, 1],
        correctAnswer: ans,
      );
    } else if (form == 2) {
      // a × b − c
      final a = 3 + random.nextInt(10);
      final b = 3 + random.nextInt(10);
      final prod = a * b;
      final c = 1 + random.nextInt(prod - 1);
      final ans = prod - c;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.easy,
        displayText: '$a × $b − $c',
        operands: [a, b, c, 2],
        correctAnswer: ans,
      );
    } else {
      // a + b ÷ c (exact division)
      final c = 2 + random.nextInt(8);
      final q = 2 + random.nextInt(10);
      final b = q * c;
      final a = 5 + random.nextInt(40);
      final ans = a + q;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.easy,
        displayText: '$a + $b ÷ $c',
        operands: [a, b, c, 3],
        correctAnswer: ans,
      );
    }
  }

  Question _generateMedium(Random random, {String? targetPattern}) {
    final int form;
    if (targetPattern == PatternConstants.simpMBrackets) {
      form = random.nextBool() ? 1 : 2;
    } else if (targetPattern == PatternConstants.simpMTwoOps) {
      form = random.nextBool() ? 3 : 4;
    } else {
      form = 1 + random.nextInt(4);
    }

    if (form == 1) {
      // (a + b) × c − d
      final a = 5 + random.nextInt(25);
      final b = 5 + random.nextInt(25);
      final c = 3 + random.nextInt(8);
      final sum = a + b;
      final prod = sum * c;
      final d = 5 + random.nextInt(max(6, min(50, prod - 1)));
      final ans = prod - d;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.medium,
        displayText: '($a + $b) × $c − $d',
        operands: [a, b, c, d, 1],
        correctAnswer: ans,
      );
    } else if (form == 2) {
      // (a − b) × c + d
      final b = 3 + random.nextInt(15);
      final a = b + 4 + random.nextInt(25);
      final c = 3 + random.nextInt(8);
      final d = 5 + random.nextInt(40);
      final ans = (a - b) * c + d;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.medium,
        displayText: '($a − $b) × $c + $d',
        operands: [a, b, c, d, 2],
        correctAnswer: ans,
      );
    } else if (form == 3) {
      // a × b + c × d
      final a = 4 + random.nextInt(18);
      final b = 4 + random.nextInt(18);
      final c = 4 + random.nextInt(18);
      final d = 4 + random.nextInt(18);
      final ans = a * b + c * d;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.medium,
        displayText: '$a × $b + $c × $d',
        operands: [a, b, c, d, 3],
        correctAnswer: ans,
      );
    } else {
      // a × b − c × d
      final a = 8 + random.nextInt(18);
      final b = 8 + random.nextInt(18);
      final prod1 = a * b;
      final c = 3 + random.nextInt(12);
      final maxD = min(15, (prod1 - 1) ~/ c);
      final d = maxD <= 1 ? 1 : 1 + random.nextInt(maxD);
      final ans = prod1 - c * d;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.medium,
        displayText: '$a × $b − $c × $d',
        operands: [a, b, c, d, 4],
        correctAnswer: ans,
      );
    }
  }

  Question _generateHard(Random random, {String? targetPattern}) {
    final int form;
    if (targetPattern == PatternConstants.simpHSquareDivMul) {
      form = 1;
    } else if (targetPattern == PatternConstants.simpHSquareAddSub) {
      form = 2;
    } else {
      form = random.nextBool() ? 1 : 2;
    }

    if (form == 1) {
      // n² − a ÷ b + c × d
      final n = DifficultyRanges.simplificationHardSquareBaseMin +
          random.nextInt(DifficultyRanges.simplificationHardSquareBaseMax -
              DifficultyRanges.simplificationHardSquareBaseMin +
              1);
      final b = 3 + random.nextInt(10);
      final q = 2 + random.nextInt(18);
      final a = q * b;
      final c = 3 + random.nextInt(12);
      final d = 3 + random.nextInt(12);

      final ans = n * n - q + c * d;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.hard,
        displayText: '$n² − $a ÷ $b + $c × $d',
        operands: [n, a, b, c, d, 1],
        correctAnswer: ans,
      );
    } else {
      // n² + a × b − c ÷ d
      final n = DifficultyRanges.simplificationHardSquareBaseMin +
          random.nextInt(DifficultyRanges.simplificationHardSquareBaseMax -
              DifficultyRanges.simplificationHardSquareBaseMin +
              1);
      final a = 3 + random.nextInt(12);
      final b = 3 + random.nextInt(12);
      final d = 3 + random.nextInt(10);
      final q = 2 + random.nextInt(18);
      final c = q * d;

      final ans = n * n + a * b - q;
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.hard,
        displayText: '$n² + $a × $b − $c ÷ $d',
        operands: [n, a, b, c, d, 2],
        correctAnswer: ans,
      );
    }
  }

  Question _generateExpert(Random random, {String? targetPattern}) {
    // Expert: Expressions with parentheses, powers (e.g. 15² - 12 × 8 + 144 ÷ 12), and nested operations. Result up to 50000.
    final form = 1 + random.nextInt(3);

    if (form == 1) {
      // (a ± b) × c² − d ÷ e
      final isMinus = random.nextBool();
      final a = 12 + random.nextInt(25);
      final b = 2 + random.nextInt(10);
      final c = 4 + random.nextInt(10); // c in 4..13, c² in 16..169
      final inner = isMinus ? (a - b) : (a + b);
      final mult = inner * c * c;

      final e = 3 + random.nextInt(10);
      final q = 2 + random.nextInt(min(20, max(2, mult ~/ 2)));
      final d = q * e;

      final ans = mult - q;
      final opInner = isMinus ? '−' : '+';
      final text = '($a $opInner $b) × $c² − $d ÷ $e';

      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [a, b, c, d, e, 1],
        correctAnswer: ans,
      );
    } else if (form == 2) {
      // n² − a × b + c ÷ d (e.g. 15² − 12 × 8 + 144 ÷ 12)
      final n = 15 + random.nextInt(35); // 15..49, n² in 225..2401
      final a = 6 + random.nextInt(15);
      final b = 5 + random.nextInt(15);
      final prod = a * b;

      final d = 3 + random.nextInt(10);
      final q = 3 + random.nextInt(25);
      final c = q * d;

      final isMinus = random.nextBool();
      final String op1;
      final int ans;

      if (isMinus && (n * n + q > prod)) {
        op1 = '−';
        ans = n * n - prod + q;
      } else {
        op1 = '+';
        ans = n * n + prod - q;
      }

      final op2 = op1 == '−' ? '+' : '−';
      final text = '$n² $op1 $a × $b $op2 $c ÷ $d';

      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [n, a, b, c, d, 2],
        correctAnswer: ans,
      );
    } else {
      // Nested operations: (n² − a × b) × c + d ÷ e
      final n = 15 + random.nextInt(25); // n² in 225..1521
      final sq = n * n;
      final a = 6 + random.nextInt(12);
      final maxB = min(20, (sq - 20) ~/ a);
      final b = 3 + random.nextInt(max(2, maxB));
      final inner = sq - (a * b);

      final c = 2 + random.nextInt(6);
      final e = 3 + random.nextInt(8);
      final q = 2 + random.nextInt(20);
      final d = q * e;

      final ans = inner * c + q;
      final text = '($n² − $a × $b) × $c + $d ÷ $e';

      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [n, a, b, c, d, e, 3],
        correctAnswer: ans,
      );
    }
  }

  Question _generateGenius(Random random, {String? targetPattern}) {
    // Genius: Multi-layer BODMAS expressions with cubes or multiple squares: (a² - b²) ÷ c + (d × e) - f, result up to 200000.
    final form = 1 + random.nextInt(3);

    if (form == 1) {
      // (a² − b²) ÷ c + (d × e) − f
      final b = 10 + random.nextInt(25); // 10..34
      final a = b + 10 + random.nextInt(40); // 20..84
      final diff = a * a - b * b;

      // Pick c as a divisor of diff: a - b is always a clean factor!
      final c = a - b;
      final q1 = diff ~/ c; // which is a + b

      final d = 25 + random.nextInt(75);
      final e = 20 + random.nextInt(60);
      final prod = d * e;

      final f = 10 + random.nextInt(min(150, q1 + prod - 10));
      final ans = q1 + prod - f;

      final text = '($a² − $b²) ÷ $c + ($d × $e) − $f';
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [a, b, c, d, e, f, 1],
        correctAnswer: ans,
      );
    } else if (form == 2) {
      // Multi-layer BODMAS with cubes: n³ + (a² × b) ÷ c − (d × e)
      final n = 8 + random.nextInt(18); // 8..25, n³ in 512..15625
      final a = 12 + random.nextInt(25);
      final c = 3 + random.nextInt(8);
      final k = 2 + random.nextInt(8);
      final b = k * c;
      final term2 = a * a * k;

      final d = 10 + random.nextInt(30);
      final e = 10 + random.nextInt(30);
      final prod = d * e;

      final total = n * n * n + term2;
      final ans = total > prod ? (total - prod) : (total + prod);
      final op = total > prod ? '−' : '+';

      final text = '$n³ + ($a² × $b) ÷ $c $op ($d × $e)';
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [n, a, b, c, d, e, 2],
        correctAnswer: ans,
      );
    } else {
      // (a² + b²) × c − d³ ÷ e
      final a = 15 + random.nextInt(25);
      final b = 15 + random.nextInt(25);
      final c = 3 + random.nextInt(7);
      final mult = (a * a + b * b) * c;

      // Pick d and e such that d³ % e == 0
      final d = 6 + random.nextInt(12);
      final d3 = d * d * d;
      final divisors = <int>[];
      for (int i = 2; i <= 20; i++) {
        if (d3 % i == 0) divisors.add(i);
      }
      final e = divisors[random.nextInt(divisors.length)];
      final q = d3 ~/ e;

      final ans = mult > q ? (mult - q) : (mult + q);
      final op = mult > q ? '−' : '+';

      final text = '($a² + $b²) × $c $op $d³ ÷ $e';
      return Question(
        topic: Topic.simplification,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [a, b, c, d, e, 3],
        correctAnswer: ans,
      );
    }
  }
}
