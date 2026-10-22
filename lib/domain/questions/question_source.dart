import 'dart:math';
import '../../core/enums/enums.dart';
import '../../features/practice_session/models/practice_models.dart';
import '../adaptive/mistake_entry.dart';
import '../adaptive/smart_question_picker.dart';
import 'question.dart';
import 'question_generator.dart';
import 'question_generator_registry.dart';

/// Container for the question payload produced by a [QuestionSource].
class QuestionNext {
  final Question question;
  final bool isReplayedMistake;
  final int? mistakeId;

  const QuestionNext({
    required this.question,
    this.isReplayedMistake = false,
    this.mistakeId,
  });
}

/// Abstract interface for serving questions to a practice session.
abstract class QuestionSource {
  QuestionNext next({
    Question? previousQuestion,
    List<SessionAttempt>? recentAttempts,
  });
}

/// Standard generator source used for Timer and Question modes of single topics.
class GeneratorQuestionSource implements QuestionSource {
  final QuestionGenerator generator;
  final Difficulty difficulty;
  final Random random;

  GeneratorQuestionSource({
    required this.generator,
    required this.difficulty,
    required this.random,
  });

  factory GeneratorQuestionSource.forTopic({
    required Topic topic,
    required Difficulty difficulty,
    required Random random,
  }) {
    return GeneratorQuestionSource(
      generator: QuestionGeneratorRegistry.getGenerator(topic),
      difficulty: difficulty,
      random: random,
    );
  }

  @override
  QuestionNext next({
    Question? previousQuestion,
    List<SessionAttempt>? recentAttempts,
  }) {
    final q = generator.generateUnique(
      difficulty: difficulty,
      random: random,
      previousQuestion: previousQuestion,
    );
    return QuestionNext(question: q, isReplayedMistake: false);
  }
}

/// Adaptive source used for Smart Practice mode.
class SmartQuestionSource implements QuestionSource {
  final SmartQuestionPicker picker;

  SmartQuestionSource({required this.picker});

  @override
  QuestionNext next({
    Question? previousQuestion,
    List<SessionAttempt>? recentAttempts,
  }) {
    final pick = picker.nextQuestion(
      previousQuestion: previousQuestion,
      recentAttempts: recentAttempts,
    );
    return QuestionNext(
      question: pick.question,
      isReplayedMistake: pick.isDueMistake,
      mistakeId: pick.mistakeId,
    );
  }
}

/// Mistake replay source used for Mistake Practice mode.
class MistakeQuestionSource implements QuestionSource {
  final List<MistakeEntry> mistakes;
  int _index = 0;

  MistakeQuestionSource({required this.mistakes});

  @override
  QuestionNext next({
    Question? previousQuestion,
    List<SessionAttempt>? recentAttempts,
  }) {
    if (mistakes.isEmpty) {
      // Fallback in case of empty list
      final gen = QuestionGeneratorRegistry.getGenerator(Topic.addition);
      final q = gen.generate(difficulty: Difficulty.easy, random: Random());
      return QuestionNext(question: q, isReplayedMistake: false);
    }

    final entry = mistakes[_index % mistakes.length];
    _index++;

    return QuestionNext(
      question: entry.toQuestion(),
      isReplayedMistake: true,
      mistakeId: entry.id,
    );
  }
}
