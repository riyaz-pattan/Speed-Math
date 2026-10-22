import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_engine.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_rating.dart';

void main() {
  const engine = SkillEngine();

  group('SkillEngine', () {
    group('calculateOutcomeScore', () {
      const targetTimeMs = 4000;

      test('wrong answer returns 0.0', () {
        final score = engine.calculateOutcomeScore(
          isCorrect: false,
          isSkipped: false,
          timeMs: 2000,
          targetTimeMs: targetTimeMs,
        );
        expect(score, 0.0);
      });

      test('skipped answer returns 0.0', () {
        final score = engine.calculateOutcomeScore(
          isCorrect: false,
          isSkipped: true,
          timeMs: 1000,
          targetTimeMs: targetTimeMs,
        );
        expect(score, 0.0);
      });

      test('correct answer with t <= 0.5 returns 1.0', () {
        // target is 4000, 50% is 2000
        final score1 = engine.calculateOutcomeScore(
          isCorrect: true,
          isSkipped: false,
          timeMs: 2000,
          targetTimeMs: targetTimeMs,
        );
        expect(score1, 1.0);

        final score2 = engine.calculateOutcomeScore(
          isCorrect: true,
          isSkipped: false,
          timeMs: 1200,
          targetTimeMs: targetTimeMs,
        );
        expect(score2, 1.0);
      });

      test('correct answer with t >= 2.0 returns 0.5', () {
        // target is 4000, 200% is 8000
        final score1 = engine.calculateOutcomeScore(
          isCorrect: true,
          isSkipped: false,
          timeMs: 8000,
          targetTimeMs: targetTimeMs,
        );
        expect(score1, 0.5);

        final score2 = engine.calculateOutcomeScore(
          isCorrect: true,
          isSkipped: false,
          timeMs: 15000,
          targetTimeMs: targetTimeMs,
        );
        expect(score2, 0.5);
      });

      test('correct answer falls linearly from 1.0 to 0.5 between 0.5 and 2.0', () {
        // midpoint is t = 1.25 -> 5000ms
        final score = engine.calculateOutcomeScore(
          isCorrect: true,
          isSkipped: false,
          timeMs: 5000,
          targetTimeMs: targetTimeMs,
        );
        expect(score, closeTo(0.75, 0.001));

        // t = 1.0 (exact target time: 4000ms)
        // ratio = (1.0 - 0.5) / 1.5 = 0.5 / 1.5 = 1/3
        // score = 1.0 - (1/3)*0.5 = 1.0 - 0.16666 = 0.83333
        final scoreTarget = engine.calculateOutcomeScore(
          isCorrect: true,
          isSkipped: false,
          timeMs: 4000,
          targetTimeMs: targetTimeMs,
        );
        expect(scoreTarget, closeTo(0.8333, 0.001));
      });
    });

    group('updateRating', () {
      test('uses alpha = 0.20 for first 10 attempts', () {
        var rating = const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
        );
        expect(rating.mastery, 0.5);
        expect(rating.attemptsCount, 0);

        // First attempt with score 1.0
        // newMastery = 0.5 + 0.2 * (1.0 - 0.5) = 0.60
        rating = engine.updateRating(rating, 1.0, timeMsIfCorrect: 2000);
        expect(rating.mastery, closeTo(0.60, 0.001));
        expect(rating.attemptsCount, 1);
        expect(rating.accuracyEma, closeTo(0.20, 0.001));
        expect(rating.avgTimeMsEma, closeTo(2000.0, 0.001));
      });

      test('switches to alpha = 0.08 after 10 attempts', () {
        var rating = const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          attemptsCount: 10,
          mastery: 0.60,
          accuracyEma: 0.70,
          avgTimeMsEma: 2500.0,
        );

        // 11th attempt with score 1.0
        // newMastery = 0.60 + 0.08 * (1.0 - 0.60) = 0.60 + 0.032 = 0.632
        rating = engine.updateRating(rating, 1.0, timeMsIfCorrect: 2000);
        expect(rating.mastery, closeTo(0.632, 0.001));
        expect(rating.attemptsCount, 11);
      });

      test('wrong answer (score 0.0) does not update avgTimeMsEma', () {
        var rating = const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          attemptsCount: 2,
          mastery: 0.60,
          accuracyEma: 0.80,
          avgTimeMsEma: 3000.0,
        );

        rating = engine.updateRating(rating, 0.0, timeMsIfCorrect: null);
        expect(rating.avgTimeMsEma, 3000.0, reason: 'avgTimeMsEma should only update for correct');
        expect(rating.attemptsCount, 3);
        expect(rating.mastery, closeTo(0.60 + 0.20 * (0.0 - 0.60), 0.001)); // 0.48
      });
    });

    group('classifyBucket', () {
      test('attempts < 5 returns notEnoughData', () {
        for (var count = 0; count < 5; count++) {
          final rating = SkillRating(
            topic: Topic.addition,
            difficulty: Difficulty.easy,
            attemptsCount: count,
            mastery: 0.95, // Even with high mastery!
          );
          expect(engine.classifyBucket(rating), SkillBucketLevel.notEnoughData);
        }
      });

      test('attempts >= 5 and mastery < 0.5 returns needsWork', () {
        final rating = const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          attemptsCount: 5,
          mastery: 0.49,
        );
        expect(engine.classifyBucket(rating), SkillBucketLevel.needsWork);
      });

      test('attempts >= 5 and mastery between 0.5 and 0.8 returns gettingThere', () {
        final rating1 = const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          attemptsCount: 5,
          mastery: 0.50,
        );
        expect(engine.classifyBucket(rating1), SkillBucketLevel.gettingThere);

        final rating2 = const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          attemptsCount: 10,
          mastery: 0.79,
        );
        expect(engine.classifyBucket(rating2), SkillBucketLevel.gettingThere);
      });

      test('attempts >= 5 and mastery >= 0.8 returns strong', () {
        final rating1 = const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          attemptsCount: 5,
          mastery: 0.80,
        );
        expect(engine.classifyBucket(rating1), SkillBucketLevel.strong);

        final rating2 = const SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          attemptsCount: 20,
          mastery: 0.95,
        );
        expect(engine.classifyBucket(rating2), SkillBucketLevel.strong);
      });
    });
  });
}
