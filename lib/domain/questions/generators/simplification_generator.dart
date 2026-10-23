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
      final d = 2 + random.nextInt(max(2, maxD));
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
}
