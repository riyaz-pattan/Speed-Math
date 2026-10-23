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
}
