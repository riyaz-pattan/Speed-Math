import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'package:speed_math_with_ai/features/stats/models/graph_models.dart';
import 'package:speed_math_with_ai/features/stats/services/graph_data_processor.dart';

void main() {
  const processor = GraphDataProcessor();
  final baseDate = DateTime(2026, 10, 15, 12, 0);

  Session createSession({
    required DateTime date,
    double score = 100.0,
    double accuracy = 0.9,
    double avgTimeMs = 3000.0,
    bool completed = true,
  }) {
    return Session(
      topic: Topic.addition,
      difficulty: Difficulty.easy,
      mode: PracticeMode.timer,
      modeValue: 60,
      startedAt: date,
      score: score,
      accuracy: accuracy,
      avgTimeMs: avgTimeMs,
      completed: completed,
    );
  }

  group('GraphDataProcessor - Empty and Edge Cases', () {
    test('returns empty data when sessions list is empty', () {
      final data = processor.process(
        sessions: [],
        measure: GraphMeasure.score,
        range: GraphRange.allTime,
      );

      expect(data.points, isEmpty);
      expect(data.trendNote, isNull);
      expect(data.hasEnoughData, isFalse);
    });

    test('ignores incomplete sessions', () {
      final sessions = [
        createSession(date: baseDate, completed: false),
        createSession(date: baseDate.add(const Duration(hours: 1)), completed: false),
      ];

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.allTime,
      );

      expect(data.points, isEmpty);
      expect(data.hasEnoughData, isFalse);
    });

    test('single session produces 1 point but hasEnoughData is false and trendNote is null', () {
      final sessions = [
        createSession(date: baseDate, score: 150.0),
      ];

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.allTime,
      );

      expect(data.points.length, 1);
      expect(data.hasEnoughData, isFalse);
      expect(data.trendNote, isNull);
      expect(data.points.first.value, 150.0);
    });
  });

  group('GraphDataProcessor - Range Filtering', () {
    test('filters sessions by 7 days, 30 days, and all time', () {
      final sessions = [
        createSession(date: baseDate.subtract(const Duration(days: 2))), // within 7 days
        createSession(date: baseDate.subtract(const Duration(days: 15))), // within 30 days
        createSession(date: baseDate.subtract(const Duration(days: 45))), // beyond 30 days
      ];

      final data7 = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.days7,
        now: baseDate,
      );
      expect(data7.points.length, 1);

      final data30 = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.days30,
        now: baseDate,
      );
      expect(data30.points.length, 2);

      final dataAll = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.allTime,
        now: baseDate,
      );
      expect(dataAll.points.length, 3);
    });
  });

  group('GraphDataProcessor - Measures', () {
    test('extracts avgTime in seconds', () {
      final sessions = [
        createSession(date: baseDate, avgTimeMs: 2500.0),
        createSession(date: baseDate.add(const Duration(hours: 1)), avgTimeMs: 4000.0),
      ];

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.avgTime,
        range: GraphRange.allTime,
      );

      expect(data.points[0].value, 2.5);
      expect(data.points[1].value, 4.0);
    });

    test('extracts accuracy in percentage (0 to 100)', () {
      final sessions = [
        createSession(date: baseDate, accuracy: 0.85),
        createSession(date: baseDate.add(const Duration(hours: 1)), accuracy: 1.0),
      ];

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.accuracy,
        range: GraphRange.allTime,
      );

      expect(data.points[0].value, 85.0);
      expect(data.points[1].value, 100.0);
    });

    test('extracts score', () {
      final sessions = [
        createSession(date: baseDate, score: 120.0),
        createSession(date: baseDate.add(const Duration(hours: 1)), score: 180.0),
      ];

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.allTime,
      );

      expect(data.points[0].value, 120.0);
      expect(data.points[1].value, 180.0);
    });
  });

  group('GraphDataProcessor - Grouping by Day', () {
    test('groups by day when there are more than 30 points', () {
      // 40 sessions spread over 10 days (4 per day)
      final sessions = <Session>[];
      for (var day = 0; day < 10; day++) {
        for (var s = 0; s < 4; s++) {
          sessions.add(createSession(
            date: baseDate.subtract(Duration(days: 10 - day, hours: s)),
            score: (day + 1) * 10.0,
          ));
        }
      }

      expect(sessions.length, 40); // > 30 points

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.allTime,
        now: baseDate,
      );

      // Should be grouped into 10 daily points!
      expect(data.points.length, 10);
    });
  });

  group('GraphDataProcessor - Trends', () {
    test('trend for avgTime: improvement when time decreases', () {
      final sessions = [
        createSession(date: baseDate, avgTimeMs: 4000.0), // older
        createSession(date: baseDate.add(const Duration(days: 1)), avgTimeMs: 2000.0), // newer (50% decrease)
      ];

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.avgTime,
        range: GraphRange.allTime,
      );

      expect(data.trendNote, contains('improved by 50%'));
    });

    test('trend for score: improvement when score increases', () {
      final sessions = [
        createSession(date: baseDate, score: 100.0),
        createSession(date: baseDate.add(const Duration(days: 1)), score: 125.0), // 25% increase
      ];

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.allTime,
      );

      expect(data.trendNote, contains('improved by 25%'));
    });

    test('steady trend when change is under 2%', () {
      final sessions = [
        createSession(date: baseDate, score: 100.0),
        createSession(date: baseDate.add(const Duration(days: 1)), score: 101.0), // 1% increase
      ];

      final data = processor.process(
        sessions: sessions,
        measure: GraphMeasure.score,
        range: GraphRange.allTime,
      );

      expect(data.trendNote, equals('Steady, no big change'));
    });
  });
}
