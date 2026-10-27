import 'dart:math';

import '../../core/enums/enums.dart';
import 'question.dart';

/// Abstract interface for all question generators.
///
/// Each topic implements this interface. Generators are pure Dart (no Flutter)
/// and accept a [Random] instance for testability with seeded randomness.
abstract class QuestionGenerator {
  /// The topic this generator produces questions for.
  Topic get topic;

  /// Generates a single question at the given [difficulty].
  ///
  /// [pattern] optionally requests a specific question pattern.
  /// [random] is the random number generator (seeded for tests).
  /// [previousQuestion] is the last question generated in this session,
  /// used to prevent back-to-back duplicate questions.
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
    String? pattern,
  });

  /// Pure function that recomputes the pattern from operands.
  String patternOf(Difficulty difficulty, List<int> operands);

  /// Generates a question, retrying if it matches [previousQuestion] or any in [excludedDisplayTexts].
  /// Gives up after retries to avoid infinite loops if the pool of questions is exhausted.
  Question generateUnique({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
    Set<String>? excludedDisplayTexts,
    String? pattern,
    int maxRetries = 25,
  }) {
    final effectiveExclusions = <String>{
      if (previousQuestion != null) previousQuestion.displayText,
      if (excludedDisplayTexts != null) ...excludedDisplayTexts,
    };

    // 1. Try with the requested pattern and excluding session questions
    for (var i = 0; i < maxRetries; i++) {
      final q = generate(
        difficulty: difficulty,
        random: random,
        previousQuestion: previousQuestion,
        pattern: pattern,
      );
      if (!effectiveExclusions.contains(q.displayText)) {
        return q;
      }
    }

    // 2. If pattern had very few questions (e.g. sq_e_ends_in_5 only has 5 and 15),
    // drop the pattern filter so the user doesn't get repetitive questions!
    if (pattern != null) {
      for (var i = 0; i < maxRetries; i++) {
        final q = generate(
          difficulty: difficulty,
          random: random,
          previousQuestion: previousQuestion,
          pattern: null,
        );
        if (!effectiveExclusions.contains(q.displayText)) {
          return q;
        }
      }
    }

    // 3. If entire question pool for this difficulty was exhausted in this session,
    // allow recycling but strictly prevent back-to-back immediate repeat.
    for (var i = 0; i < maxRetries; i++) {
      final q = generate(
        difficulty: difficulty,
        random: random,
        previousQuestion: previousQuestion,
        pattern: null,
      );
      if (previousQuestion == null || q.displayText != previousQuestion.displayText) {
        return q;
      }
    }

    // Ultimate fallback
    return generate(
      difficulty: difficulty,
      random: random,
      previousQuestion: null,
      pattern: null,
    );
  }
}
