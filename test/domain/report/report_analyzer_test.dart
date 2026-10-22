import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/repositories/skill_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_rating.dart';
import 'package:speed_math_with_ai/domain/report/report_analyzer.dart';
import 'package:speed_math_with_ai/domain/report/report_data.dart';
import 'package:sqflite/sqflite.dart';

class _FakeReportDb implements Database {
  final List<Map<String, dynamic>> sessions = [];
  final List<Map<String, dynamic>> attempts = [];
  final List<Map<String, dynamic>> skillRatings = [];
  final List<Map<String, dynamic>> mistakeBank = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (table == SkillRepository.tableSkillRatings) {
      return List<Map<String, Object?>>.from(skillRatings);
    }
    if (table == DatabaseHelper.tableSessions) {
      return List<Map<String, Object?>>.from(sessions);
    }
    if (table == DatabaseHelper.tableAttempts) {
      return List<Map<String, Object?>>.from(attempts);
    }
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final cleanSql = sql.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Total questions all time
    if (cleanSql.startsWith('SELECT COUNT(*) as count FROM ${DatabaseHelper.tableAttempts}')) {
      return [{'count': attempts.length}];
    }

    // Mistake bank count
    if (cleanSql.startsWith('SELECT COUNT(*) as count FROM ${DatabaseHelper.tableMistakeBank}')) {
      return [{'count': mistakeBank.length}];
    }

    // Mistake bank top 3
    if (cleanSql.contains('GROUP BY topic') && cleanSql.contains(DatabaseHelper.tableMistakeBank)) {
      final Map<String, int> counts = {};
      for (final m in mistakeBank) {
        final t = m['topic'] as String;
        counts[t] = (counts[t] ?? 0) + 1;
      }
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(3).map((e) => {'topic': e.key, 'count': e.value}).toList();
    }

    // Window session aggregates
    if (cleanSql.contains('FROM ${DatabaseHelper.tableSessions}') && cleanSql.contains('started_at >=')) {
      final startIso = arguments![0] as String;
      final endIso = arguments[1] as String;

      final matching = sessions.where((s) {
        final st = s['started_at'] as String;
        final completed = (s['completed'] as num?)?.toInt() ?? 0;
        return completed == 1 && st.compareTo(startIso) >= 0 && st.compareTo(endIso) < 0;
      }).toList();

      int totalQ = 0;
      int totalC = 0;
      int totalW = 0;
      int totalS = 0;
      int totalDuration = 0;

      for (final s in matching) {
        totalQ += (s['total_questions'] as num?)?.toInt() ?? 0;
        totalC += (s['correct_count'] as num?)?.toInt() ?? 0;
        totalW += (s['wrong_count'] as num?)?.toInt() ?? 0;
        totalS += (s['skipped_count'] as num?)?.toInt() ?? 0;
        totalDuration += (s['duration_ms'] as num?)?.toInt() ?? 0;
      }

      return [
        {
          'session_count': matching.length,
          'total_q': totalQ,
          'total_c': totalC,
          'total_w': totalW,
          'total_s': totalS,
          'total_duration': totalDuration,
        }
      ];
    }

    // Window attempts aggregates (time_ms per correct)
    if (cleanSql.contains('FROM ${DatabaseHelper.tableAttempts}') &&
        cleanSql.contains('created_at >=') &&
        !cleanSql.contains('topic = ?')) {
      final startIso = arguments![0] as String;
      final endIso = arguments[1] as String;

      final matching = attempts.where((a) {
        final ct = a['created_at'] as String;
        final isCorrect = ((a['is_correct'] as num?)?.toInt() ?? 0) == 1;
        final isSkipped = ((a['is_skipped'] as num?)?.toInt() ?? 0) == 1;
        return isCorrect && !isSkipped && ct.compareTo(startIso) >= 0 && ct.compareTo(endIso) < 0;
      }).toList();

      int timeSum = 0;
      for (final a in matching) {
        timeSum += (a['time_ms'] as num?)?.toInt() ?? 0;
      }

      return [
        {
          'correct_count': matching.length,
          'total_time': timeSum,
        }
      ];
    }

    // Topic overall attempts
    if (cleanSql.contains('FROM ${DatabaseHelper.tableAttempts}') &&
        cleanSql.contains('WHERE topic = ?') &&
        !cleanSql.contains('created_at >=')) {
      final topicName = arguments![0] as String;
      final matching = attempts.where((a) => a['topic'] == topicName).toList();

      int correctC = 0;
      int correctTime = 0;
      String? latest;

      for (final a in matching) {
        final isCorrect = ((a['is_correct'] as num?)?.toInt() ?? 0) == 1;
        final isSkipped = ((a['is_skipped'] as num?)?.toInt() ?? 0) == 1;
        if (isCorrect && !isSkipped) {
          correctC++;
          correctTime += (a['time_ms'] as num?)?.toInt() ?? 0;
        }
        final created = a['created_at'] as String?;
        if (created != null && (latest == null || created.compareTo(latest) > 0)) {
          latest = created;
        }
      }

      return [
        {
          'total_attempts': matching.length,
          'correct_c': correctC,
          'correct_time': correctTime,
          'last_attempt_at': latest,
        }
      ];
    }

    // Topic window attempts (trend calculation)
    if (cleanSql.contains('FROM ${DatabaseHelper.tableAttempts}') &&
        cleanSql.contains('WHERE topic = ?') &&
        cleanSql.contains('created_at >=')) {
      final topicName = arguments![0] as String;
      final startIso = arguments[1] as String;
      final endIso = arguments[2] as String;

      final matching = attempts.where((a) {
        final ct = a['created_at'] as String;
        return a['topic'] == topicName && ct.compareTo(startIso) >= 0 && ct.compareTo(endIso) < 0;
      }).toList();

      int correctC = 0;
      int correctTime = 0;

      for (final a in matching) {
        final isCorrect = ((a['is_correct'] as num?)?.toInt() ?? 0) == 1;
        final isSkipped = ((a['is_skipped'] as num?)?.toInt() ?? 0) == 1;
        if (isCorrect && !isSkipped) {
          correctC++;
          correctTime += (a['time_ms'] as num?)?.toInt() ?? 0;
        }
      }

      return [
        {
          'total_q': matching.length,
          'correct_c': correctC,
          'correct_time': correctTime,
        }
      ];
    }

    return [];
  }
}

void main() {
  late _FakeReportDb fakeDb;
  late ReportAnalyzer analyzer;
  final testToday = DateTime(2026, 10, 16);

  setUp(() {
    fakeDb = _FakeReportDb();
    analyzer = ReportAnalyzer(
      dbHelper: DatabaseHelper.withDatabase(fakeDb),
    );
  });

  group('Speed Score and Labels', () {
    test('returns null when no buckets have at least 5 attempts', () async {
      fakeDb.skillRatings.addAll([
        SkillRating(topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.8, attemptsCount: 3).toMap(),
        SkillRating(topic: Topic.subtraction, difficulty: Difficulty.easy, mastery: 0.9, attemptsCount: 4).toMap(),
      ]);

      final report = await analyzer.generateReport(today: testToday);
      expect(report.overallSpeedScore, isNull);
      expect(report.speedScoreLabel, isNull);
    });

    test('calculates weighted score and Beginner label (< 40)', () async {
      fakeDb.skillRatings.add(
        SkillRating(topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.35, attemptsCount: 10).toMap(),
      );

      final report = await analyzer.generateReport(today: testToday);
      expect(report.overallSpeedScore, isNotNull);
      expect(report.overallSpeedScore!, closeTo(35.0, 0.1));
      expect(report.speedScoreLabel, equals(SpeedScoreLabel.beginner));
    });

    test('calculates Building label (40 <= score < 60)', () async {
      fakeDb.skillRatings.add(
        SkillRating(topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.52, attemptsCount: 15).toMap(),
      );

      final report = await analyzer.generateReport(today: testToday);
      expect(report.overallSpeedScore!, closeTo(52.0, 0.1));
      expect(report.speedScoreLabel, equals(SpeedScoreLabel.building));
    });

    test('calculates Strong label (60 <= score < 80)', () async {
      fakeDb.skillRatings.add(
        SkillRating(topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.72, attemptsCount: 20).toMap(),
      );

      final report = await analyzer.generateReport(today: testToday);
      expect(report.overallSpeedScore!, closeTo(72.0, 0.1));
      expect(report.speedScoreLabel, equals(SpeedScoreLabel.strong));
    });

    test('calculates Elite label (score >= 80)', () async {
      fakeDb.skillRatings.add(
        SkillRating(topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.88, attemptsCount: 40).toMap(),
      );

      final report = await analyzer.generateReport(today: testToday);
      expect(report.overallSpeedScore!, closeTo(88.0, 0.1));
      expect(report.speedScoreLabel, equals(SpeedScoreLabel.elite));
    });

    test('weight caps at 50 attempts for weighted average', () async {
      // Bucket A: 0.80 mastery, 50 attempts -> weight 50
      // Bucket B: 0.60 mastery, 200 attempts -> weight 50 (capped at 50)
      // Weighted average: (0.80*50 + 0.60*50) / 100 = 0.70 -> 70.0 (Strong)
      fakeDb.skillRatings.addAll([
        SkillRating(topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.80, attemptsCount: 50).toMap(),
        SkillRating(topic: Topic.multiplication, difficulty: Difficulty.medium, mastery: 0.60, attemptsCount: 200).toMap(),
      ]);

      final report = await analyzer.generateReport(today: testToday);
      expect(report.overallSpeedScore!, closeTo(70.0, 0.01));
      expect(report.speedScoreLabel, equals(SpeedScoreLabel.strong));
    });
  });

  group('Strong and Weak Areas Selection', () {
    test('selects up to 3 strong areas with mastery >= 0.80 ordered by mastery DESC', () async {
      fakeDb.skillRatings.addAll([
        SkillRating(topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.95, attemptsCount: 20).toMap(),
        SkillRating(topic: Topic.subtraction, difficulty: Difficulty.easy, mastery: 0.88, attemptsCount: 15).toMap(),
        SkillRating(topic: Topic.multiplication, difficulty: Difficulty.easy, mastery: 0.82, attemptsCount: 10).toMap(),
        SkillRating(topic: Topic.division, difficulty: Difficulty.easy, mastery: 0.81, attemptsCount: 10).toMap(), // 4th
        SkillRating(topic: Topic.squares, difficulty: Difficulty.easy, mastery: 0.75, attemptsCount: 30).toMap(), // < 0.80
      ]);

      final report = await analyzer.generateReport(today: testToday);
      expect(report.strongAreas.length, equals(3));
      expect(report.strongAreas[0].topic, equals(Topic.addition));
      expect(report.strongAreas[1].topic, equals(Topic.subtraction));
      expect(report.strongAreas[2].topic, equals(Topic.multiplication));
    });

    test('selects up to 3 weak areas with attempts >= 5 and mastery < 0.65 ordered by mastery ASC', () async {
      fakeDb.skillRatings.addAll([
        SkillRating(topic: Topic.cubes, difficulty: Difficulty.hard, mastery: 0.35, attemptsCount: 8).toMap(),
        SkillRating(topic: Topic.division, difficulty: Difficulty.hard, mastery: 0.45, attemptsCount: 10).toMap(),
        SkillRating(topic: Topic.exponents, difficulty: Difficulty.medium, mastery: 0.60, attemptsCount: 6).toMap(),
        SkillRating(topic: Topic.squareRoots, difficulty: Difficulty.hard, mastery: 0.64, attemptsCount: 12).toMap(), // 4th
        SkillRating(topic: Topic.multiplication, difficulty: Difficulty.hard, mastery: 0.30, attemptsCount: 2).toMap(), // < 5 attempts ignored
        SkillRating(topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.70, attemptsCount: 20).toMap(), // >= 0.65
      ]);

      final report = await analyzer.generateReport(today: testToday);
      expect(report.weakAreas.length, equals(3));
      expect(report.weakAreas[0].topic, equals(Topic.cubes)); // 0.35
      expect(report.weakAreas[1].topic, equals(Topic.division)); // 0.45
      expect(report.weakAreas[2].topic, equals(Topic.exponents)); // 0.60
    });
  });

  group('Trend Rules', () {
    test('evaluates Not enough data if either window has < 15 answered questions', () async {
      // 14 questions in current window, 16 in previous
      final currStart = testToday.subtract(const Duration(days: 7));
      final prevStart = currStart.subtract(const Duration(days: 7));

      for (int i = 0; i < 14; i++) {
        fakeDb.attempts.add({
          'topic': Topic.addition.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': 1,
          'is_skipped': 0,
          'time_ms': 2000,
          'created_at': testToday.subtract(const Duration(days: 2)).toIso8601String(),
        });
      }
      for (int i = 0; i < 16; i++) {
        fakeDb.attempts.add({
          'topic': Topic.addition.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': 1,
          'is_skipped': 0,
          'time_ms': 2000,
          'created_at': prevStart.add(const Duration(days: 2)).toIso8601String(),
        });
      }

      final report = await analyzer.generateReport(today: testToday);
      final addPerf = report.topicPerformances.firstWhere((t) => t.topic == Topic.addition);
      expect(addPerf.trend, equals(TopicTrend.notEnoughData));
    });

    test('evaluates Improving when avg time falls by 8% or more', () async {
      final currDate = testToday.subtract(const Duration(days: 2));
      final prevDate = testToday.subtract(const Duration(days: 10));

      // Prev: 20 questions, 3000ms each, 100% acc
      for (int i = 0; i < 20; i++) {
        fakeDb.attempts.add({
          'topic': Topic.multiplication.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': 1,
          'is_skipped': 0,
          'time_ms': 3000,
          'created_at': prevDate.toIso8601String(),
        });
      }
      // Curr: 20 questions, 2600ms each (13.3% faster > 8%), 100% acc
      for (int i = 0; i < 20; i++) {
        fakeDb.attempts.add({
          'topic': Topic.multiplication.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': 1,
          'is_skipped': 0,
          'time_ms': 2600,
          'created_at': currDate.toIso8601String(),
        });
      }

      final report = await analyzer.generateReport(today: testToday);
      final perf = report.topicPerformances.firstWhere((t) => t.topic == Topic.multiplication);
      expect(perf.trend, equals(TopicTrend.improving));
    });

    test('evaluates Improving when accuracy rises by 5 points or more', () async {
      final currDate = testToday.subtract(const Duration(days: 2));
      final prevDate = testToday.subtract(const Duration(days: 10));

      // Prev: 20 questions, 15 correct (75% acc), 2500ms
      for (int i = 0; i < 20; i++) {
        fakeDb.attempts.add({
          'topic': Topic.subtraction.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': i < 15 ? 1 : 0,
          'is_skipped': 0,
          'time_ms': 2500,
          'created_at': prevDate.toIso8601String(),
        });
      }
      // Curr: 20 questions, 18 correct (90% acc, +15 points), 2500ms
      for (int i = 0; i < 20; i++) {
        fakeDb.attempts.add({
          'topic': Topic.subtraction.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': i < 18 ? 1 : 0,
          'is_skipped': 0,
          'time_ms': 2500,
          'created_at': currDate.toIso8601String(),
        });
      }

      final report = await analyzer.generateReport(today: testToday);
      final perf = report.topicPerformances.firstWhere((t) => t.topic == Topic.subtraction);
      expect(perf.trend, equals(TopicTrend.improving));
    });

    test('evaluates Slipping when avg time rises by 8% or more', () async {
      final currDate = testToday.subtract(const Duration(days: 2));
      final prevDate = testToday.subtract(const Duration(days: 10));

      // Prev: 20 questions, 2000ms each
      for (int i = 0; i < 20; i++) {
        fakeDb.attempts.add({
          'topic': Topic.division.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': 1,
          'is_skipped': 0,
          'time_ms': 2000,
          'created_at': prevDate.toIso8601String(),
        });
      }
      // Curr: 20 questions, 2300ms each (15% slower > 8%)
      for (int i = 0; i < 20; i++) {
        fakeDb.attempts.add({
          'topic': Topic.division.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': 1,
          'is_skipped': 0,
          'time_ms': 2300,
          'created_at': currDate.toIso8601String(),
        });
      }

      final report = await analyzer.generateReport(today: testToday);
      final perf = report.topicPerformances.firstWhere((t) => t.topic == Topic.division);
      expect(perf.trend, equals(TopicTrend.slipping));
    });

    test('evaluates Steady when changes are within 8% and 5 points', () async {
      final currDate = testToday.subtract(const Duration(days: 2));
      final prevDate = testToday.subtract(const Duration(days: 10));

      // Prev: 20 questions, 2000ms, 100%
      for (int i = 0; i < 20; i++) {
        fakeDb.attempts.add({
          'topic': Topic.squares.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': 1,
          'is_skipped': 0,
          'time_ms': 2000,
          'created_at': prevDate.toIso8601String(),
        });
      }
      // Curr: 20 questions, 2040ms (2% change < 8%), 100%
      for (int i = 0; i < 20; i++) {
        fakeDb.attempts.add({
          'topic': Topic.squares.name,
          'difficulty': Difficulty.easy.name,
          'is_correct': 1,
          'is_skipped': 0,
          'time_ms': 2040,
          'created_at': currDate.toIso8601String(),
        });
      }

      final report = await analyzer.generateReport(today: testToday);
      final perf = report.topicPerformances.firstWhere((t) => t.topic == Topic.squares);
      expect(perf.trend, equals(TopicTrend.steady));
    });
  });

  group('Neglected and Never Practiced Topics', () {
    test('classifies topics with 0 attempts as never practiced', () async {
      final report = await analyzer.generateReport(today: testToday);
      // All 9 topics have 0 attempts initially
      expect(report.neverPracticedTopics.length, equals(9));
      expect(report.neglectedTopics, isEmpty);
    });

    test('classifies topic practiced 8 days ago as neglected', () async {
      final eightDaysAgo = testToday.subtract(const Duration(days: 8));
      fakeDb.attempts.add({
        'topic': Topic.addition.name,
        'difficulty': Difficulty.easy.name,
        'is_correct': 1,
        'is_skipped': 0,
        'time_ms': 2000,
        'created_at': eightDaysAgo.toIso8601String(),
      });
      fakeDb.skillRatings.add(
        SkillRating(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          attemptsCount: 1,
          lastPracticedAt: eightDaysAgo,
        ).toMap(),
      );

      final report = await analyzer.generateReport(today: testToday);
      expect(report.neglectedTopics, contains(Topic.addition));
      expect(report.neverPracticedTopics, isNot(contains(Topic.addition)));
    });
  });

  group('Mistake Bank Summary', () {
    test('aggregates total mistakes and top 3 topics', () async {
      fakeDb.mistakeBank.addAll([
        {'topic': Topic.division.name},
        {'topic': Topic.division.name},
        {'topic': Topic.division.name},
        {'topic': Topic.multiplication.name},
        {'topic': Topic.multiplication.name},
        {'topic': Topic.squares.name},
        {'topic': Topic.addition.name}, // 4th
      ]);

      final report = await analyzer.generateReport(today: testToday);
      expect(report.mistakeSummary.totalMistakes, equals(7));
      expect(report.mistakeSummary.topMistakeTopics.length, equals(3));
      expect(report.mistakeSummary.topMistakeTopics[0].topic, equals(Topic.division));
      expect(report.mistakeSummary.topMistakeTopics[0].count, equals(3));
      expect(report.mistakeSummary.topMistakeTopics[1].topic, equals(Topic.multiplication));
      expect(report.mistakeSummary.topMistakeTopics[1].count, equals(2));
      expect(report.mistakeSummary.topMistakeTopics[2].topic, equals(Topic.squares));
      expect(report.mistakeSummary.topMistakeTopics[2].count, equals(1));
    });
  });
}
