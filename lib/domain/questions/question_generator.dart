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
  /// [random] is the random number generator (seeded for tests).
  /// [previousQuestion] is the last question generated in this session,
  /// used to prevent back-to-back duplicate questions.
  Question generate({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
  });

  /// Generates a question, retrying if it matches [previousQuestion].
  /// Gives up after [maxRetries] to avoid infinite loops.
  Question generateUnique({
    required Difficulty difficulty,
    required Random random,
    Question? previousQuestion,
    int maxRetries = 20,
  }) {
    for (var i = 0; i < maxRetries; i++) {
      final q = generate(
        difficulty: difficulty,
        random: random,
        previousQuestion: previousQuestion,
      );
      if (previousQuestion == null || q != previousQuestion) {
        return q;
      }
    }
    // After max retries, return whatever we get
    return generate(
      difficulty: difficulty,
      random: random,
      previousQuestion: null,
    );
  }
}
