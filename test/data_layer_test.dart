import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/models/attempt.dart';
import 'package:speed_math_with_ai/data/models/session.dart';

void main() {
  group('Session Model', () {
    test('toMap and fromMap serialization roundtrip', () {
      final now = DateTime(2026, 10, 15, 12, 0, 0);
      final session = Session(
        id: 1,
        topic: Topic.addition,
        difficulty: Difficulty.hard,
        mode: PracticeMode.timer,
        modeValue: 60,
        startedAt: now,
        durationMs: 60000,
        totalQuestions: 25,
        correctCount: 22,
        wrongCount: 2,
        skippedCount: 1,
        accuracy: 0.88,
        avgTimeMs: 2400.0,
        score: 310.5,
        completed: true,
      );

      final map = session.toMap();
      expect(map['topic'], 'addition');
      expect(map['difficulty'], 'hard');
      expect(map['mode'], 'timer');
      expect(map['mode_value'], 60);
      expect(map['completed'], 1);
      expect(map['accuracy'], 0.88);

      final parsed = Session.fromMap(map);
      expect(parsed.id, session.id);
      expect(parsed.topic, session.topic);
      expect(parsed.difficulty, session.difficulty);
      expect(parsed.mode, session.mode);
      expect(parsed.modeValue, session.modeValue);
      expect(parsed.startedAt, session.startedAt);
      expect(parsed.durationMs, session.durationMs);
      expect(parsed.totalQuestions, session.totalQuestions);
      expect(parsed.correctCount, session.correctCount);
      expect(parsed.wrongCount, session.wrongCount);
      expect(parsed.skippedCount, session.skippedCount);
      expect(parsed.accuracy, session.accuracy);
      expect(parsed.avgTimeMs, session.avgTimeMs);
      expect(parsed.score, session.score);
      expect(parsed.completed, session.completed);
    });

    test('copyWith works correctly', () {
      final now = DateTime(2026, 10, 15, 12, 0, 0);
      final session = Session(
        id: 1,
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 20,
        startedAt: now,
      );

      final updated = session.copyWith(
        completed: true,
        correctCount: 18,
        accuracy: 0.9,
      );

      expect(updated.id, 1);
      expect(updated.topic, Topic.addition);
      expect(updated.completed, true);
      expect(updated.correctCount, 18);
      expect(updated.accuracy, 0.9);
      expect(session.completed, false);
    });
  });

  group('Attempt Model', () {
    test('toMap and fromMap serialization roundtrip', () {
      final now = DateTime(2026, 10, 15, 12, 1, 0);
      final attempt = Attempt(
        id: 10,
        sessionId: 1,
        topic: Topic.multiplication,
        difficulty: Difficulty.medium,
        questionText: '12 × 15 = ?',
        operandA: '12',
        operandB: '15',
        correctAnswer: 180,
        userAnswer: 180,
        isCorrect: true,
        isSkipped: false,
        timeMs: 1450,
        createdAt: now,
      );

      final map = attempt.toMap();
      expect(map['topic'], 'multiplication');
      expect(map['difficulty'], 'medium');
      expect(map['is_correct'], 1);
      expect(map['is_skipped'], 0);
      expect(map['time_ms'], 1450);

      final parsed = Attempt.fromMap(map);
      expect(parsed.id, attempt.id);
      expect(parsed.sessionId, attempt.sessionId);
      expect(parsed.topic, attempt.topic);
      expect(parsed.difficulty, attempt.difficulty);
      expect(parsed.questionText, attempt.questionText);
      expect(parsed.operandA, attempt.operandA);
      expect(parsed.operandB, attempt.operandB);
      expect(parsed.correctAnswer, attempt.correctAnswer);
      expect(parsed.userAnswer, attempt.userAnswer);
      expect(parsed.isCorrect, attempt.isCorrect);
      expect(parsed.isSkipped, attempt.isSkipped);
      expect(parsed.timeMs, attempt.timeMs);
      expect(parsed.createdAt, attempt.createdAt);
    });

    test('copyWith works correctly', () {
      final now = DateTime(2026, 10, 15, 12, 1, 0);
      final attempt = Attempt(
        sessionId: 1,
        topic: Topic.squares,
        difficulty: Difficulty.hard,
        questionText: '25²',
        operandA: '25',
        operandB: '2',
        correctAnswer: 625,
        createdAt: now,
      );

      final updated = attempt.copyWith(
        id: 5,
        userAnswer: 625,
        isCorrect: true,
        timeMs: 2300,
      );

      expect(updated.id, 5);
      expect(updated.userAnswer, 625);
      expect(updated.isCorrect, true);
      expect(updated.timeMs, 2300);
      expect(attempt.id, null);
    });
  });
}
