import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/adaptive/mistake_entry.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_rating.dart';
import 'package:speed_math_with_ai/domain/adaptive/smart_question_picker.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';

void main() {
  group('SmartQuestionPicker', () {
    test('Easy is always unlocked, Medium and Hard follow cold start threshold', () {
      final ratings = <String, SkillRating>{
        'addition:easy': const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          mastery: 0.70,
          attemptsCount: 6,
        ),
        // addition:medium not practiced yet
        'subtraction:easy': const SkillRating(
          topic: Topic.subtraction,
          difficulty: Difficulty.easy,
          mastery: 0.40,
          attemptsCount: 3, // Not yet unlocked medium
        ),
      };

      final picker = SmartQuestionPicker(
        selectedTopics: [Topic.addition, Topic.subtraction],
        ratings: ratings,
      );

      final buckets = picker.getCandidateBuckets();

      // addition:easy and addition:medium should be unlocked
      expect(buckets.any((b) => b.topic == Topic.addition && b.difficulty == Difficulty.easy), isTrue);
      expect(buckets.any((b) => b.topic == Topic.addition && b.difficulty == Difficulty.medium), isTrue);
      expect(buckets.any((b) => b.topic == Topic.addition && b.difficulty == Difficulty.hard), isFalse);

      // subtraction:easy is unlocked, but medium is not (attempts < 5, mastery < 0.50)
      expect(buckets.any((b) => b.topic == Topic.subtraction && b.difficulty == Difficulty.easy), isTrue);
      expect(buckets.any((b) => b.topic == Topic.subtraction && b.difficulty == Difficulty.medium), isFalse);
    });

    test('10,000 picks follow 60% weak / 30% medium / 10% strong distribution within tolerance', () {
      // Ensure all candidate buckets for each topic map cleanly to one class
      final ratings = <String, SkillRating>{
        // addition: only easy unlocked, weak
        'addition:easy': const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          mastery: 0.35, // weak
          attemptsCount: 15,
        ),
        // subtraction: easy, medium, hard all medium
        'subtraction:easy': const SkillRating(
          topic: Topic.subtraction,
          difficulty: Difficulty.easy,
          mastery: 0.65, // medium
          attemptsCount: 15,
        ),
        'subtraction:medium': const SkillRating(
          topic: Topic.subtraction,
          difficulty: Difficulty.medium,
          mastery: 0.65, // medium
          attemptsCount: 15,
        ),
        'subtraction:hard': const SkillRating(
          topic: Topic.subtraction,
          difficulty: Difficulty.hard,
          mastery: 0.65, // medium
          attemptsCount: 15,
        ),
        // multiplication: easy, medium, hard all strong
        'multiplication:easy': const SkillRating(
          topic: Topic.multiplication,
          difficulty: Difficulty.easy,
          mastery: 0.90, // strong
          attemptsCount: 15,
        ),
        'multiplication:medium': const SkillRating(
          topic: Topic.multiplication,
          difficulty: Difficulty.medium,
          mastery: 0.90, // strong
          attemptsCount: 15,
        ),
        'multiplication:hard': const SkillRating(
          topic: Topic.multiplication,
          difficulty: Difficulty.hard,
          mastery: 0.90, // strong
          attemptsCount: 15,
        ),
      };

      final picker = SmartQuestionPicker(
        selectedTopics: [Topic.addition, Topic.subtraction, Topic.multiplication],
        ratings: ratings,
        totalSessionQuestions: 10000,
        random: Random(42),
      );

      int weakCount = 0;
      int mediumCount = 0;
      int strongCount = 0;

      for (int i = 0; i < 10000; i++) {
        final res = picker.nextQuestion();
        final topic = res.question.topic;
        if (topic == Topic.addition) {
          weakCount++;
        } else if (topic == Topic.subtraction) {
          mediumCount++;
        } else if (topic == Topic.multiplication) {
          strongCount++;
        }
      }

      final weakPct = weakCount / 10000.0;
      final mediumPct = mediumCount / 10000.0;
      final strongPct = strongCount / 10000.0;

      // Expect ~60% weak, ~30% medium, ~10% strong within 3.5% statistical tolerance
      expect(weakPct, closeTo(0.60, 0.035));
      expect(mediumPct, closeTo(0.30, 0.035));
      expect(strongPct, closeTo(0.10, 0.035));
    });

    test('proportional redistribution when a class is empty', () {
      // Only medium (subtraction) and strong (multiplication) present, no weak
      final ratings = <String, SkillRating>{
        'subtraction:easy': const SkillRating(
          topic: Topic.subtraction,
          difficulty: Difficulty.easy,
          mastery: 0.65, // medium
          attemptsCount: 15,
        ),
        'subtraction:medium': const SkillRating(
          topic: Topic.subtraction,
          difficulty: Difficulty.medium,
          mastery: 0.65, // medium
          attemptsCount: 15,
        ),
        'subtraction:hard': const SkillRating(
          topic: Topic.subtraction,
          difficulty: Difficulty.hard,
          mastery: 0.65, // medium
          attemptsCount: 15,
        ),
        'multiplication:easy': const SkillRating(
          topic: Topic.multiplication,
          difficulty: Difficulty.easy,
          mastery: 0.90, // strong
          attemptsCount: 15,
        ),
        'multiplication:medium': const SkillRating(
          topic: Topic.multiplication,
          difficulty: Difficulty.medium,
          mastery: 0.90, // strong
          attemptsCount: 15,
        ),
        'multiplication:hard': const SkillRating(
          topic: Topic.multiplication,
          difficulty: Difficulty.hard,
          mastery: 0.90, // strong
          attemptsCount: 15,
        ),
      };

      final picker = SmartQuestionPicker(
        selectedTopics: [Topic.subtraction, Topic.multiplication],
        ratings: ratings,
        totalSessionQuestions: 5000,
        random: Random(123),
      );

      int mediumCount = 0;
      int strongCount = 0;

      for (int i = 0; i < 5000; i++) {
        final res = picker.nextQuestion();
        if (res.question.topic == Topic.subtraction) {
          mediumCount++;
        } else if (res.question.topic == Topic.multiplication) {
          strongCount++;
        }
      }

      // Medium (30) / Strong (10) -> 30/40 = 75% medium, 10/40 = 25% strong
      final mediumPct = mediumCount / 5000.0;
      final strongPct = strongCount / 5000.0;

      expect(mediumPct, closeTo(0.75, 0.035));
      expect(strongPct, closeTo(0.25, 0.035));
    });

    test('mastery weighting inside class favors lower mastery', () {
      // Two weak buckets: addition (mastery 0.10) vs subtraction (mastery 0.45)
      final ratings = <String, SkillRating>{
        'addition:easy': const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          mastery: 0.10, // weight = 1.05 - 0.10 = 0.95
          attemptsCount: 15,
        ),
        'subtraction:easy': const SkillRating(
          topic: Topic.subtraction,
          difficulty: Difficulty.easy,
          mastery: 0.45, // weight = 1.05 - 0.45 = 0.60
          attemptsCount: 15,
        ),
      };

      final picker = SmartQuestionPicker(
        selectedTopics: [Topic.addition, Topic.subtraction],
        ratings: ratings,
        totalSessionQuestions: 5000,
        random: Random(999),
      );

      int addCount = 0;
      int subCount = 0;

      for (int i = 0; i < 5000; i++) {
        final res = picker.nextQuestion();
        if (res.question.topic == Topic.addition) addCount++;
        if (res.question.topic == Topic.subtraction) subCount++;
      }

      // addition (lower mastery) should be picked significantly more often than subtraction
      expect(addCount, greaterThan(subCount));
      final addRatio = addCount / (addCount + subCount).toDouble();
      // Theoretical: 0.95 / (0.95 + 0.60) = 0.6129
      expect(addRatio, closeTo(0.613, 0.04));
    });

    test('difficulty nudge: 10-window with >= 85% accuracy nudges up, <= 60% nudges down', () {
      final ratings = <String, SkillRating>{
        'addition:easy': const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          mastery: 0.75,
          attemptsCount: 10,
        ),
        'addition:medium': const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.medium,
          mastery: 0.30, // weak bucket, so picker selects it by default
          attemptsCount: 2,
        ),
      };

      final picker = SmartQuestionPicker(
        selectedTopics: [Topic.addition],
        ratings: ratings,
        random: Random(42),
      );

      // 10 recent correct attempts (100% accuracy >= 85%) -> nudge up
      final highAccuracyAttempts = List<SessionAttempt>.generate(
        10,
        (i) => SessionAttempt(
          question: Question(
            topic: Topic.addition,
            difficulty: Difficulty.easy,
            displayText: '1 + $i',
            operands: [1, i],
            correctAnswer: 1 + i,
          ),
          userAnswer: 1 + i,
          isCorrect: true,
          isSkipped: false,
          timeMs: 2000,
          points: 10.0,
        ),
      );

      final nudgeUpResult = picker.nextQuestion(recentAttempts: highAccuracyAttempts);
      // Nudged from Easy to Medium
      expect(nudgeUpResult.question.difficulty, Difficulty.medium);

      // 10 recent attempts with 4 correct (40% accuracy <= 60%) -> nudge down
      final lowAccuracyAttempts = List<SessionAttempt>.generate(
        10,
        (i) => SessionAttempt(
          question: Question(
            topic: Topic.addition,
            difficulty: Difficulty.medium,
            displayText: '10 + $i',
            operands: [10, i],
            correctAnswer: 10 + i,
          ),
          userAnswer: i < 4 ? 10 + i : 999,
          isCorrect: i < 4,
          isSkipped: false,
          timeMs: 4000,
          points: i < 4 ? 10.0 : 0.0,
        ),
      );

      final nudgeDownResult = picker.nextQuestion(recentAttempts: lowAccuracyAttempts);
      // Nudged down to Easy
      expect(nudgeDownResult.question.difficulty, Difficulty.easy);
    });

    test('due mistakes are interleaved up to 1/3 of session and never 2 in a row', () {
      final now = DateTime.now();
      final mistakes = List.generate(
        5,
        (i) => MistakeEntry(
          id: i + 1,
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          questionText: '${i + 10} + 5',
          operands: [i + 10, 5],
          correctAnswer: i + 15,
          source: MistakeSource.wrong,
          addedAt: now,
          dueCounter: 0,
        ),
      );

      // Session of 9 questions -> max due mistakes = 9 ~/ 3 = 3
      final picker = SmartQuestionPicker(
        selectedTopics: [Topic.addition],
        ratings: {},
        dueMistakes: mistakes,
        totalSessionQuestions: 9,
        random: Random(42),
      );

      final results = <PickResult>[];
      for (int i = 0; i < 9; i++) {
        final res = picker.nextQuestion(
          previousQuestion: results.isNotEmpty ? results.last.question : null,
        );
        results.add(res);
      }

      final dueMistakePicks = results.where((r) => r.isDueMistake).toList();
      // Must not exceed 1/3 of 9 = 3
      expect(dueMistakePicks.length, lessThanOrEqualTo(3));

      // Never 2 due mistakes in a row
      for (int i = 0; i < results.length - 1; i++) {
        if (results[i].isDueMistake) {
          expect(results[i + 1].isDueMistake, isFalse,
              reason: 'Due mistakes must never be served consecutively at steps $i and ${i + 1}');
        }
      }
    });

    test('no back-to-back repeats for consecutive questions', () {
      final picker = SmartQuestionPicker(
        selectedTopics: [Topic.addition],
        ratings: {},
        totalSessionQuestions: 50,
        random: Random(42),
      );

      Question? prev;
      for (int i = 0; i < 50; i++) {
        final res = picker.nextQuestion(previousQuestion: prev);
        if (prev != null) {
          expect(res.question.displayText, isNot(equals(prev.displayText)));
        }
        prev = res.question;
      }
    });
  });
}
