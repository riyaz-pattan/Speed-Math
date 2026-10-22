import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_rating.dart';

void main() {
  group('SkillRating Model', () {
    test('toMap and fromMap serialization roundtrip', () {
      final now = DateTime(2026, 10, 15, 12, 30, 0);
      final rating = SkillRating(
        id: 42,
        topic: Topic.cubes,
        difficulty: Difficulty.hard,
        mastery: 0.85,
        attemptsCount: 15,
        accuracyEma: 0.92,
        avgTimeMsEma: 4500.0,
        lastPracticedAt: now,
      );

      final map = rating.toMap();
      expect(map['id'], 42);
      expect(map['topic'], 'cubes');
      expect(map['difficulty'], 'hard');
      expect(map['mastery'], 0.85);
      expect(map['attempts_count'], 15);
      expect(map['accuracy_ema'], 0.92);
      expect(map['avg_time_ms_ema'], 4500.0);
      expect(map['last_practiced_at'], now.toIso8601String());

      final fromMap = SkillRating.fromMap(map);
      expect(fromMap.id, rating.id);
      expect(fromMap.topic, rating.topic);
      expect(fromMap.difficulty, rating.difficulty);
      expect(fromMap.mastery, rating.mastery);
      expect(fromMap.attemptsCount, rating.attemptsCount);
      expect(fromMap.accuracyEma, rating.accuracyEma);
      expect(fromMap.avgTimeMsEma, rating.avgTimeMsEma);
      expect(fromMap.lastPracticedAt, rating.lastPracticedAt);
    });

    test('copyWith updates specified fields', () {
      const original = SkillRating(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mastery: 0.5,
      );

      final updated = original.copyWith(
        mastery: 0.75,
        attemptsCount: 10,
      );

      expect(updated.topic, Topic.addition);
      expect(updated.difficulty, Difficulty.easy);
      expect(updated.mastery, 0.75);
      expect(updated.attemptsCount, 10);
    });

    test('safely falls back if topic or difficulty is unknown string', () {
      final map = {
        'topic': 'future_unknown_topic',
        'difficulty': 'future_difficulty',
        'mastery': 0.6,
      };

      final parsed = SkillRating.fromMap(map);
      expect(parsed.topic, Topic.addition);
      expect(parsed.difficulty, Difficulty.easy);
      expect(parsed.mastery, 0.6);
    });
  });
}
