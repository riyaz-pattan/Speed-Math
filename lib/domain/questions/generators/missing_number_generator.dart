import 'dart:math';

import '../../../core/enums/enums.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Question generator for Missing Number.
///
/// Shows the unknown as "?". All answers are whole positive integers.
///
/// Easy: ? + a = b, ? − a = b, a × ? = b
/// Medium: ? × a = b, ? ÷ a = b, a − ? = b
/// Hard: ? × a ± b = c, (? ± a) × b = c
class MissingNumberGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.missingNumber;

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
    if (targetPattern == PatternConstants.misEAddition) {
      form = 1;
    } else if (targetPattern == PatternConstants.misESubtraction) {
      form = 2;
    } else if (targetPattern == PatternConstants.misEMultiplication) {
      form = 3;
    } else {
      form = 1 + random.nextInt(3);
    }

    if (form == 1) {
      // ? + a = b or a + ? = b
      final a = 10 + random.nextInt(55);
      final ans = 10 + random.nextInt(55);
      final b = a + ans;
      final qFirst = random.nextBool();
      final text = qFirst ? '? + $a = $b' : '$a + ? = $b';
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.easy,
        displayText: text,
        operands: [a, b, ans, 1],
        correctAnswer: ans,
      );
    } else if (form == 2) {
      // ? − a = b
      final a = 10 + random.nextInt(40);
      final b = 10 + random.nextInt(40);
      final ans = a + b;
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.easy,
        displayText: '? − $a = $b',
        operands: [a, b, ans, 2],
        correctAnswer: ans,
      );
    } else {
      // a × ? = b or ? × a = b
      final a = 2 + random.nextInt(8); // 2..9
      final ans = 2 + random.nextInt(11); // 2..12
      final b = a * ans;
      final qFirst = random.nextBool();
      final text = qFirst ? '? × $a = $b' : '$a × ? = $b';
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.easy,
        displayText: text,
        operands: [a, b, ans, 3],
        correctAnswer: ans,
      );
    }
  }

  Question _generateMedium(Random random, {String? targetPattern}) {
    final int form;
    if (targetPattern == PatternConstants.misMMultiplication) {
      form = 1;
    } else if (targetPattern == PatternConstants.misMDivision) {
      form = 2;
    } else if (targetPattern == PatternConstants.misMSubtraction) {
      form = 3;
    } else {
      form = 1 + random.nextInt(3);
    }

    if (form == 1) {
      // ? × a = b or a × ? = b (2-digit factor)
      final a = 11 + random.nextInt(15); // 11..25
      final ans = 11 + random.nextInt(15); // 11..25
      final b = a * ans;
      final qFirst = random.nextBool();
      final text = qFirst ? '? × $a = $b' : '$a × ? = $b';
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.medium,
        displayText: text,
        operands: [a, b, ans, 1],
        correctAnswer: ans,
      );
    } else if (form == 2) {
      // ? ÷ a = b
      final a = 11 + random.nextInt(15); // 11..25
      final b = 4 + random.nextInt(15); // 4..18
      final ans = a * b;
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.medium,
        displayText: '? ÷ $a = $b',
        operands: [a, b, ans, 2],
        correctAnswer: ans,
      );
    } else {
      // a − ? = b
      final a = 120 + random.nextInt(280); // 120..399
      final ans = 15 + random.nextInt(a - 30);
      final b = a - ans;
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.medium,
        displayText: '$a − ? = $b',
        operands: [a, b, ans, 3],
        correctAnswer: ans,
      );
    }
  }

  Question _generateHard(Random random, {String? targetPattern}) {
    final int form;
    if (targetPattern == PatternConstants.misHLinear) {
      form = 1;
    } else if (targetPattern == PatternConstants.misHBrackets) {
      form = 2;
    } else {
      form = random.nextBool() ? 1 : 2;
    }

    if (form == 1) {
      // ? × a ± b = c
      final isMinus = random.nextBool();
      final a = 11 + random.nextInt(12); // 11..22
      final ans = 10 + random.nextInt(21); // 10..30
      final b = 10 + random.nextInt(60);
      final c = isMinus ? (ans * a - b) : (ans * a + b);
      final opSymbol = isMinus ? '−' : '+';
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.hard,
        displayText: '? × $a $opSymbol $b = $c',
        operands: [a, b, c, ans, 1],
        correctAnswer: ans,
      );
    } else {
      // (? ± a) × b = c
      final isMinus = random.nextBool();
      final a = 5 + random.nextInt(20);
      final b = 3 + random.nextInt(7); // 3..9
      final ans = isMinus ? (a + 5 + random.nextInt(25)) : (10 + random.nextInt(30));
      final inner = isMinus ? (ans - a) : (ans + a);
      final c = inner * b;
      final opSymbol = isMinus ? '−' : '+';
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.hard,
        displayText: '(? $opSymbol $a) × $b = $c',
        operands: [a, b, c, ans, 2],
        correctAnswer: ans,
      );
    }
  }

  Question _generateExpert(Random random, {String? targetPattern}) {
    // Expert: Multi-operation missing numbers: (? × a + b) ÷ c = d or (?² - a) = b with clean integer answers.
    final form = 1 + random.nextInt(2);

    if (form == 1) {
      // (? × a ± b) ÷ c = d
      final isMinus = random.nextBool();
      final ans = 4 + random.nextInt(22); // 4..25
      final a = 4 + random.nextInt(13); // 4..16
      final c = 2 + random.nextInt(7); // 2..8

      final int b;
      final int d;
      final String opSymbol;

      if (isMinus) {
        final prod = ans * a;
        final maxK = max(1, (prod - 10) ~/ c);
        final k = 1 + random.nextInt(min(5, maxK));
        final rem = prod % c;
        b = rem + (k * c);
        if (prod > b) {
          d = (prod - b) ~/ c;
          opSymbol = '−';
        } else {
          final plusB = (c - ((ans * a) % c)) + (1 + random.nextInt(4)) * c;
          d = (ans * a + plusB) ~/ c;
          opSymbol = '+';
          return Question(
            topic: Topic.missingNumber,
            difficulty: Difficulty.expert,
            displayText: '(? × $a $opSymbol $plusB) ÷ $c = $d',
            operands: [a, plusB, c, d, ans, 1],
            correctAnswer: ans,
          );
        }
      } else {
        opSymbol = '+';
        final rem = (ans * a) % c;
        final base = rem == 0 ? 0 : (c - rem);
        b = base + ((1 + random.nextInt(4)) * c);
        d = (ans * a + b) ~/ c;
      }

      final text = '(? × $a $opSymbol $b) ÷ $c = $d';
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [a, b, c, d, ans, 1],
        correctAnswer: ans,
      );
    } else {
      // (?² − a) = b or (?² + a) = b
      final ans = 11 + random.nextInt(25); // 11..35 -> ?² in 121..1225
      final isMinus = random.nextBool();
      final a = 15 + random.nextInt(85); // 15..99
      final b = isMinus ? (ans * ans - a) : (ans * ans + a);
      final opSymbol = isMinus ? '−' : '+';

      final text = '(?² $opSymbol $a) = $b';
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.expert,
        displayText: text,
        operands: [a, b, ans, 2],
        correctAnswer: ans,
      );
    }
  }

  Question _generateGenius(Random random, {String? targetPattern}) {
    // Genius: Complex missing numbers with parentheses, powers, and division: ((? + a) × b - c) ÷ d = e.
    final form = 1 + random.nextInt(2);

    if (form == 1) {
      // ((? ± a) × b − c) ÷ d = e
      final isMinusInner = random.nextBool();
      final a = 5 + random.nextInt(20); // 5..24
      final ans = isMinusInner ? (a + 5 + random.nextInt(25)) : (10 + random.nextInt(30));
      final b = 3 + random.nextInt(7); // 3..9
      final inner = isMinusInner ? (ans - a) * b : (ans + a) * b;

      final c = 10 + random.nextInt(min(50, max(11, inner - 20)));
      final target = inner - c;

      final divisors = <int>[];
      for (int i = 2; i <= 12; i++) {
        if (target % i == 0) divisors.add(i);
      }
      final d = divisors.isNotEmpty ? divisors[random.nextInt(divisors.length)] : 2;
      final adjC = inner - (target ~/ d * d);
      final e = (inner - adjC) ~/ d;

      final innerOp = isMinusInner ? '−' : '+';
      final text = '((? $innerOp $a) × $b − $adjC) ÷ $d = $e';

      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [a, b, adjC, d, e, ans, 1],
        correctAnswer: ans,
      );
    } else {
      // Complex powers and division: (?² + a) ÷ b = c
      final ans = 12 + random.nextInt(24); // 12..35 -> ans² in 144..1225
      final b = 3 + random.nextInt(7); // 3..9
      final sq = ans * ans;
      final rem = sq % b;
      final baseA = rem == 0 ? 0 : (b - rem);
      final a = baseA + ((1 + random.nextInt(4)) * b);
      final c = (sq + a) ~/ b;

      final text = '(?² + $a) ÷ $b = $c';
      return Question(
        topic: Topic.missingNumber,
        difficulty: Difficulty.genius,
        displayText: text,
        operands: [a, b, c, ans, 2],
        correctAnswer: ans,
      );
    }
  }
}
