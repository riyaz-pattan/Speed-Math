import 'dart:math';
import '../../core/enums/enums.dart';
import '../../features/practice_session/models/practice_models.dart';
import '../adaptive/mistake_entry.dart';
import '../adaptive/pattern_picker.dart';
import '../adaptive/pattern_skill.dart';
import '../adaptive/smart_question_picker.dart';
import 'pattern_constants.dart';
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
  final bool focusWeakAreas;
  final Map<String, PatternSkill> patternSkills;
  final Set<String> _sessionAskedDisplayTexts = {};

  GeneratorQuestionSource({
    required this.generator,
    required this.difficulty,
    required this.random,
    this.focusWeakAreas = true,
    this.patternSkills = const {},
  });

  factory GeneratorQuestionSource.forTopic({
    required Topic topic,
    required Difficulty difficulty,
    required Random random,
    bool focusWeakAreas = true,
    Map<String, PatternSkill> patternSkills = const {},
  }) {
    return GeneratorQuestionSource(
      generator: QuestionGeneratorRegistry.getGenerator(topic),
      difficulty: difficulty,
      random: random,
      focusWeakAreas: focusWeakAreas,
      patternSkills: patternSkills,
    );
  }

  @override
  QuestionNext next({
    Question? previousQuestion,
    List<SessionAttempt>? recentAttempts,
  }) {
    final recentPatterns = recentAttempts
        ?.map((a) => a.question.pattern)
        .whereType<String>()
        .toList();

    final targetPattern = PatternPicker.pickPattern(
      topic: generator.topic,
      difficulty: difficulty,
      focusWeakAreas: focusWeakAreas,
      patternSkills: patternSkills,
      random: random,
      recentPatterns: recentPatterns,
    );

    final askedInSession = <String>{
      if (previousQuestion != null) previousQuestion.displayText,
      if (recentAttempts != null)
        for (final a in recentAttempts) a.question.displayText,
      ..._sessionAskedDisplayTexts,
    };

    final q = generator.generateUnique(
      difficulty: difficulty,
      random: random,
      previousQuestion: previousQuestion,
      excludedDisplayTexts: askedInSession,
      pattern: targetPattern,
    );
    _sessionAskedDisplayTexts.add(q.displayText);
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

/// Question source for practicing concept-equivalent fresh questions of missed mistakes.
class SimilarMistakeQuestionSource implements QuestionSource {
  final List<MistakeEntry> mistakes;
  final Random random;
  int _index = 0;

  SimilarMistakeQuestionSource({
    required this.mistakes,
    required this.random,
  });

  @override
  QuestionNext next({
    Question? previousQuestion,
    List<SessionAttempt>? recentAttempts,
  }) {
    if (mistakes.isEmpty) {
      final gen = QuestionGeneratorRegistry.getGenerator(Topic.addition);
      final q = gen.generate(difficulty: Difficulty.easy, random: random);
      return QuestionNext(question: q, isReplayedMistake: false);
    }

    final entry = mistakes[_index % mistakes.length];
    _index++;

    final gen = QuestionGeneratorRegistry.getGenerator(entry.topic);
    final pattern = PatternConstants.patternOf(
      entry.topic,
      entry.difficulty,
      entry.operands,
    );

    final q = gen.generateUnique(
      difficulty: entry.difficulty,
      random: random,
      previousQuestion: previousQuestion,
      pattern: pattern,
    );

    return QuestionNext(
      question: q,
      isReplayedMistake: false,
      mistakeId: null,
    );
  }
}
