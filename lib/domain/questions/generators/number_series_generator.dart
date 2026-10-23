import 'dart:math';

import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/questions/pattern_constants.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';
import 'package:speed_math_with_ai/domain/questions/question_generator.dart';

/// Question generator for Number Series.
///
/// Features:
/// - Generates clean progressions of 5 to 6 terms with exactly one unknown term marked as '?'.
/// - Follows mathematically unambiguous rules producing whole positive numbers (< 100,000).
/// - Categorizes patterns for adaptive weakness tracking.
class NumberSeriesGenerator extends QuestionGenerator {
  static const List<int> _primes = [
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
    73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149,
  ];

  @override
  Topic get topic => Topic.numberSeries;

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

  Question _generateEasy(Random random) {
    // 5 rules:
    // 1: Constant difference (arithmetic, ascending or descending)
    // 2: Multiply by 2 or 3
    // 3: Consecutive squares
    // 4: Consecutive cubes
    // 5: Consecutive odd or even
    final rule = 1 + random.nextInt(5);
    final List<int> series = [];

    switch (rule) {
      case 1:
        // Constant difference
        final diff = 2 + random.nextInt(12);
        final isDescending = random.nextBool();
        if (isDescending) {
          final start = (diff * 5) + 5 + random.nextInt(40);
          for (int i = 0; i < 5; i++) {
            series.add(start - (i * diff));
          }
        } else {
          final start = 2 + random.nextInt(30);
          for (int i = 0; i < 5; i++) {
            series.add(start + (i * diff));
          }
        }
        break;

      case 2:
        // Multiply by 2 or 3
        final mult = random.nextBool() ? 2 : 3;
        final start = mult == 2 ? 1 + random.nextInt(8) : 1 + random.nextInt(4);
        int cur = start;
        for (int i = 0; i < 5; i++) {
          series.add(cur);
          cur *= mult;
        }
        break;

      case 3:
        // Consecutive squares
        final startN = 1 + random.nextInt(10);
        for (int i = 0; i < 5; i++) {
          final n = startN + i;
          series.add(n * n);
        }
        break;

      case 4:
        // Consecutive cubes
        final startN = 1 + random.nextInt(5);
        for (int i = 0; i < 5; i++) {
          final n = startN + i;
          series.add(n * n * n);
        }
        break;

      default:
        // Consecutive odd or even
        final isOdd = random.nextBool();
        final start = (1 + random.nextInt(25)) * 2 + (isOdd ? 1 : 0);
        for (int i = 0; i < 5; i++) {
          series.add(start + (i * 2));
        }
        break;
    }

    // In Easy: missing term at position 2, 3, or 4 (0-indexed)
    final missingIndex = 2 + random.nextInt(3);
    final answer = series[missingIndex];

    final displayTokens = List<String>.generate(series.length, (i) {
      return i == missingIndex ? '?' : series[i].toString();
    });
    final text = displayTokens.join(', ');

    return Question(
      topic: Topic.numberSeries,
      difficulty: Difficulty.easy,
      displayText: text,
      operands: [...series, rule],
      correctAnswer: answer,
    );
  }

  Question _generateMedium(Random random) {
    // 5 rules:
    // 1: Growing differences (+d, +(d+k), +(d+2k)...)
    // 2: Fibonacci-style (each term is sum of previous two)
    // 3: Multiply by n then add/subtract k
    // 4: n^2 ± k or n^3 ± k
    // 5: Primes in order
    final rule = 1 + random.nextInt(5);
    final List<int> series = [];

    switch (rule) {
      case 1:
        // Growing difference: e.g. +3, +5, +7, +9, +11
        final start = 2 + random.nextInt(20);
        int cur = start;
        int diff = 2 + random.nextInt(4);
        final step = 2 + random.nextInt(3);
        series.add(cur);
        for (int i = 0; i < 5; i++) {
          cur += diff;
          series.add(cur);
          diff += step;
        }
        break;

      case 2:
        // Fibonacci-style
        final a = 1 + random.nextInt(5);
        final b = a + 1 + random.nextInt(4);
        series.add(a);
        series.add(b);
        for (int i = 2; i < 6; i++) {
          series.add(series[i - 1] + series[i - 2]);
        }
        break;

      case 3:
        // Multiply by n then add/subtract k: x2 + 1, x2 + 2, etc.
        final mult = 2;
        final k = 1 + random.nextInt(3);
        final isAdd = random.nextBool();
        int cur = 2 + random.nextInt(5);
        series.add(cur);
        for (int i = 0; i < 5; i++) {
          cur = isAdd ? (cur * mult + k) : (cur * mult - k);
          series.add(cur);
        }
        break;

      case 4:
        // n^2 ± k
        final startN = 2 + random.nextInt(8);
        final k = 1 + random.nextInt(4);
        final isAdd = random.nextBool();
        for (int i = 0; i < 5; i++) {
          final n = startN + i;
          series.add(isAdd ? (n * n + k) : (n * n - k));
        }
        break;

      default:
        // Primes in order
        final maxStart = _primes.length - 6;
        final startIdx = random.nextInt(maxStart);
        for (int i = 0; i < 6; i++) {
          series.add(_primes[startIdx + i]);
        }
        break;
    }

    final missingIndex = 2 + random.nextInt(series.length - 2);
    final answer = series[missingIndex];

    final displayTokens = List<String>.generate(series.length, (i) {
      return i == missingIndex ? '?' : series[i].toString();
    });
    final text = displayTokens.join(', ');

    return Question(
      topic: Topic.numberSeries,
      difficulty: Difficulty.medium,
      displayText: text,
      operands: [...series, rule],
      correctAnswer: answer,
    );
  }

  Question _generateHard(Random random) {
    // 4 rules:
    // 1: Interleaved series (odd and even indices follow separate rules)
    // 2: Growing multipliers (x1, x2, x3, x4...)
    // 3: Differences that are squares or cubes (+1, +4, +9, +16...)
    // 4: Alternating operations (+a, x b, +a, x b...)
    final rule = 1 + random.nextInt(4);
    final List<int> series = [];

    switch (rule) {
      case 1:
        // Interleaved: e.g. A has +2, B has +5 (6 terms total)
        final startA = 2 + random.nextInt(15);
        final startB = 10 + random.nextInt(20);
        final diffA = 2 + random.nextInt(4);
        final diffB = 3 + random.nextInt(6);
        for (int i = 0; i < 3; i++) {
          series.add(startA + (i * diffA));
          series.add(startB + (i * diffB));
        }
        break;

      case 2:
        // Growing multipliers: x1, x2, x3, x4, x5
        int cur = 2 + random.nextInt(4);
        series.add(cur);
        for (int i = 1; i <= 5; i++) {
          cur *= i;
          series.add(cur);
        }
        break;

      case 3:
        // Differences that are squares: +1, +4, +9, +16, +25
        int cur = 3 + random.nextInt(20);
        series.add(cur);
        for (int i = 1; i <= 5; i++) {
          cur += (i * i);
          series.add(cur);
        }
        break;

      default:
        // Alternating operations: +3, x2, +3, x2...
        final addVal = 2 + random.nextInt(4);
        final mulVal = 2;
        int cur = 2 + random.nextInt(5);
        series.add(cur);
        for (int i = 0; i < 5; i++) {
          if (i % 2 == 0) {
            cur += addVal;
          } else {
            cur *= mulVal;
          }
          series.add(cur);
        }
        break;
    }

    // On Hard, prefer missing term near middle or at the end
    final candidateIndices = [series.length - 1, series.length - 2, series.length ~/ 2];
    final missingIndex = candidateIndices[random.nextInt(candidateIndices.length)];
    final answer = series[missingIndex];

    final displayTokens = List<String>.generate(series.length, (i) {
      return i == missingIndex ? '?' : series[i].toString();
    });
    final text = displayTokens.join(', ');

    return Question(
      topic: Topic.numberSeries,
      difficulty: Difficulty.hard,
      displayText: text,
      operands: [...series, rule],
      correctAnswer: answer,
    );
  }
}
