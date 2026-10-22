import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'package:speed_math_with_ai/domain/scoring/badge_evaluator.dart';

void main() {
  const evaluator = BadgeEvaluator();

  group('BadgeEvaluator - Best Score', () {
    test('returns true when there are no previous completed sessions (first session)', () {
      final isNew = evaluator.isNewBestScore(
        completed: true,
        newScore: 120.0,
        previousBestScore: null,
      );
      expect(isNew, isTrue);
    });

    test('returns true when new score exceeds previous best score', () {
      final isNew = evaluator.isNewBestScore(
        completed: true,
        newScore: 250.0,
        previousBestScore: 200.0,
      );
      expect(isNew, isTrue);
    });

    test('returns false when new score is less than or equal to previous best score', () {
      final isLess = evaluator.isNewBestScore(
        completed: true,
        newScore: 180.0,
        previousBestScore: 200.0,
      );
      expect(isLess, isFalse);

      final isEqual = evaluator.isNewBestScore(
        completed: true,
        newScore: 200.0,
        previousBestScore: 200.0,
      );
      expect(isEqual, isFalse);
    });

    test('incomplete session (completed = false) is ignored and never earns best score', () {
      final isNew = evaluator.isNewBestScore(
        completed: false,
        newScore: 999.0,
        previousBestScore: 100.0,
      );
      expect(isNew, isFalse);
    });

    test('zero or negative score never earns best score', () {
      final isNew = evaluator.isNewBestScore(
        completed: true,
        newScore: 0.0,
        previousBestScore: null,
      );
      expect(isNew, isFalse);
    });
  });

  group('BadgeEvaluator - Top 3 Time', () {
    Session makeSession({
      required int durationMs,
      required double avgTimeMs,
      required double accuracy,
      int modeValue = 20,
      bool completed = true,
      PracticeMode mode = PracticeMode.questions,
    }) {
      return Session(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: mode,
        modeValue: modeValue,
        startedAt: DateTime.now(),
        durationMs: durationMs,
        avgTimeMs: avgTimeMs,
        accuracy: accuracy,
        completed: completed,
      );
    }

    test('qualifies automatically if fewer than 3 qualifying sessions exist', () {
      final isTop3 = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.85,
        mode: PracticeMode.questions,
        modeValue: 20,
        durationMs: 30000,
        avgTimeMs: 1500.0,
        existingTop3Sessions: [
          makeSession(durationMs: 20000, avgTimeMs: 1000.0, accuracy: 0.9),
        ],
      );
      expect(isTop3, isTrue);
    });

    test('80% accuracy rule: session with accuracy < 80% is disqualified', () {
      final isTop3 = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.79, // Disqualified: 79% < 80%
        mode: PracticeMode.questions,
        modeValue: 20,
        durationMs: 5000, // Very fast, but inaccurate!
        avgTimeMs: 250.0,
        existingTop3Sessions: [],
      );
      expect(isTop3, isFalse);
    });

    test('80% accuracy rule: session with accuracy exactly 80% qualifies', () {
      final isTop3 = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.80,
        mode: PracticeMode.questions,
        modeValue: 20,
        durationMs: 25000,
        avgTimeMs: 1250.0,
        existingTop3Sessions: [],
      );
      expect(isTop3, isTrue);
    });

    test('incomplete session (completed = false) is disqualified', () {
      final isTop3 = evaluator.isNewTop3Time(
        completed: false,
        accuracy: 1.0,
        mode: PracticeMode.questions,
        modeValue: 20,
        durationMs: 5000,
        avgTimeMs: 250.0,
        existingTop3Sessions: [],
      );
      expect(isTop3, isFalse);
    });

    test('incomplete sessions in existing database are ignored during comparison', () {
      final existingWithIncomplete = [
        makeSession(durationMs: 20000, avgTimeMs: 1000.0, accuracy: 0.9, completed: true),
        makeSession(durationMs: 10000, avgTimeMs: 500.0, accuracy: 0.9, completed: false), // Incomplete!
      ];

      // Since only 1 existing session is complete and qualifying, there are < 3
      final isTop3 = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.85,
        mode: PracticeMode.questions,
        modeValue: 20,
        durationMs: 35000,
        avgTimeMs: 1750.0,
        existingTop3Sessions: existingWithIncomplete,
      );
      expect(isTop3, isTrue);
    });

    test('separation by mode_value: sessions with different mode_value are ignored', () {
      // Suppose we have 3 fast sessions of 10-questions (modeValue: 10)
      final sessions10Q = [
        makeSession(durationMs: 10000, avgTimeMs: 1000.0, accuracy: 0.9, modeValue: 10),
        makeSession(durationMs: 12000, avgTimeMs: 1200.0, accuracy: 0.9, modeValue: 10),
        makeSession(durationMs: 14000, avgTimeMs: 1400.0, accuracy: 0.9, modeValue: 10),
      ];

      // A 50-question session (modeValue: 50) taking 45s must NOT be compared against 10-question sessions
      final isTop3For50Q = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.9,
        mode: PracticeMode.questions,
        modeValue: 50,
        durationMs: 45000,
        avgTimeMs: 900.0,
        existingTop3Sessions: sessions10Q, // All have modeValue: 10
      );
      // Since 0 sessions with modeValue 50 exist in existing list, it qualifies automatically!
      expect(isTop3For50Q, isTrue);
    });

    test('Question Mode: beats the 3rd fastest durationMs of same mode_value', () {
      final top3 = [
        makeSession(durationMs: 15000, avgTimeMs: 750.0, accuracy: 0.9, modeValue: 20), // 1st
        makeSession(durationMs: 20000, avgTimeMs: 1000.0, accuracy: 0.9, modeValue: 20), // 2nd
        makeSession(durationMs: 25000, avgTimeMs: 1250.0, accuracy: 0.9, modeValue: 20), // 3rd
      ];

      // Faster than 3rd (24000 < 25000)
      final qualifiesFaster = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.9,
        mode: PracticeMode.questions,
        modeValue: 20,
        durationMs: 24000,
        avgTimeMs: 1200.0,
        existingTop3Sessions: top3,
      );
      expect(qualifiesFaster, isTrue);

      // Slower than 3rd (26000 > 25000)
      final failsSlower = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.9,
        mode: PracticeMode.questions,
        modeValue: 20,
        durationMs: 26000,
        avgTimeMs: 1300.0,
        existingTop3Sessions: top3,
      );
      expect(failsSlower, isFalse);
    });

    test('Timer Mode: beats the 3rd lowest avgTimeMs of same mode_value', () {
      final top3 = [
        makeSession(durationMs: 60000, avgTimeMs: 1800.0, accuracy: 0.95, mode: PracticeMode.timer, modeValue: 60), // 1st
        makeSession(durationMs: 60000, avgTimeMs: 2200.0, accuracy: 0.90, mode: PracticeMode.timer, modeValue: 60), // 2nd
        makeSession(durationMs: 60000, avgTimeMs: 2600.0, accuracy: 0.85, mode: PracticeMode.timer, modeValue: 60), // 3rd
      ];

      // Lower avg time than 3rd (2500 < 2600)
      final qualifiesFaster = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.85,
        mode: PracticeMode.timer,
        modeValue: 60,
        durationMs: 60000,
        avgTimeMs: 2500.0,
        existingTop3Sessions: top3,
      );
      expect(qualifiesFaster, isTrue);

      // Higher avg time than 3rd (2700 > 2600)
      final failsSlower = evaluator.isNewTop3Time(
        completed: true,
        accuracy: 0.85,
        mode: PracticeMode.timer,
        modeValue: 60,
        durationMs: 60000,
        avgTimeMs: 2700.0,
        existingTop3Sessions: top3,
      );
      expect(failsSlower, isFalse);
    });
  });
}
