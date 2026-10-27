import 'dart:math';

import '../../../core/enums/enums.dart';
import '../difficulty_ranges.dart';
import '../pattern_constants.dart';
import '../question.dart';
import '../question_generator.dart';

/// Generates addition questions.
///
/// Easy:   2-digit + 2-digit
/// Medium: 3-digit + 3-digit
/// Hard:   three numbers, 3 to 4 digits each
/// Expert: four numbers, 4 digits each
/// Genius: four numbers, 4 to 5 digits each
class AdditionGenerator extends QuestionGenerator {
  @override
  Topic get topic => Topic.addition;

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
        Difficulty.mixed => throw ArgumentError(
            'Cannot generate questions with Difficulty.mixed directly'),
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

  Question _generateEasy(Random random) {
    int a, b;
    do {
      a = _randRange(random, DifficultyRanges.additionEasyMin,
          DifficultyRanges.additionEasyMax);
      b = _randRange(random, DifficultyRanges.additionEasyMin,
          DifficultyRanges.additionEasyMax);
    } while (_isTrivialAddend(a) || _isTrivialAddend(b));

    return Question(
      topic: Topic.addition,
      difficulty: Difficulty.easy,
      displayText: '$a + $b',
      operands: [a, b],
      correctAnswer: a + b,
    );
  }

  Question _generateMedium(Random random) {
    int a, b;
    do {
      a = _randRange(random, DifficultyRanges.additionMediumMin,
          DifficultyRanges.additionMediumMax);
      b = _randRange(random, DifficultyRanges.additionMediumMin,
          DifficultyRanges.additionMediumMax);
    } while (_isTrivialAddend(a) || _isTrivialAddend(b));

    return Question(
      topic: Topic.addition,
      difficulty: Difficulty.medium,
      displayText: '$a + $b',
      operands: [a, b],
      correctAnswer: a + b,
    );
  }

  Question _generateHard(Random random) {
    int a, b, c;
    do {
      a = _randRange(random, DifficultyRanges.additionHardMin,
          DifficultyRanges.additionHardMax);
      b = _randRange(random, DifficultyRanges.additionHardMin,
          DifficultyRanges.additionHardMax);
      c = _randRange(random, DifficultyRanges.additionHardMin,
          DifficultyRanges.additionHardMax);
    } while (_allEndInZero([a, b, c]) ||
        _isTrivialAddend(a) ||
        _isTrivialAddend(b) ||
        _isTrivialAddend(c));

    return Question(
      topic: Topic.addition,
      difficulty: Difficulty.hard,
      displayText: '$a + $b + $c',
      operands: [a, b, c],
      correctAnswer: a + b + c,
    );
  }

  Question _generateExpert(Random random) {
    int a, b, c, d;
    do {
      a = _randRange(random, DifficultyRanges.additionExpertMin,
          DifficultyRanges.additionExpertMax);
      b = _randRange(random, DifficultyRanges.additionExpertMin,
          DifficultyRanges.additionExpertMax);
      c = _randRange(random, DifficultyRanges.additionExpertMin,
          DifficultyRanges.additionExpertMax);
      d = _randRange(random, DifficultyRanges.additionExpertMin,
          DifficultyRanges.additionExpertMax);
    } while (_allEndInZero([a, b, c, d]) ||
        _isTrivialAddend(a) ||
        _isTrivialAddend(b) ||
        _isTrivialAddend(c) ||
        _isTrivialAddend(d));

    return Question(
      topic: Topic.addition,
      difficulty: Difficulty.expert,
      displayText: '$a + $b + $c + $d',
      operands: [a, b, c, d],
      correctAnswer: a + b + c + d,
    );
  }

  Question _generateGenius(Random random) {
    int a, b, c, d;
    do {
      a = _randRange(random, DifficultyRanges.additionGeniusMin,
          DifficultyRanges.additionGeniusMax);
      b = _randRange(random, DifficultyRanges.additionGeniusMin,
          DifficultyRanges.additionGeniusMax);
      c = _randRange(random, DifficultyRanges.additionGeniusMin,
          DifficultyRanges.additionGeniusMax);
      d = _randRange(random, DifficultyRanges.additionGeniusMin,
          DifficultyRanges.additionGeniusMax);
    } while (_allEndInZero([a, b, c, d]) ||
        _isTrivialAddend(a) ||
        _isTrivialAddend(b) ||
        _isTrivialAddend(c) ||
        _isTrivialAddend(d));

    return Question(
      topic: Topic.addition,
      difficulty: Difficulty.genius,
      displayText: '$a + $b + $c + $d',
      operands: [a, b, c, d],
      correctAnswer: a + b + c + d,
    );
  }

  bool _isTrivialAddend(int n) => n == 0;
  bool _allEndInZero(List<int> nums) => nums.every((n) => n % 10 == 0);

  int _randRange(Random random, int min, int max) =>
      min + random.nextInt(max - min + 1);
}
