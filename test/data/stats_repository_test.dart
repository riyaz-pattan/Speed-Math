import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'package:speed_math_with_ai/data/repositories/stats_repository.dart';
import 'package:sqflite/sqflite.dart';

/// In-memory fake database implementing query and rawQuery for stats tests.
class FakeDatabase implements Database {
  final List<Map<String, dynamic>> sessions = [];

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
    var filtered = List<Map<String, dynamic>>.from(sessions);

    if (whereArgs != null && whereArgs.length >= 4) {
      final topic = whereArgs[0] as String;
      final diff = whereArgs[1] as String;
      final mode = whereArgs[2] as String;
      final modeVal = whereArgs[3] as int;

      filtered = filtered.where((s) {
        final matchesKind = where?.contains("kind = 'drill'") == true &&
                where?.contains("kind = 'mixed'") != true
            ? (s['kind'] == 'drill' || s['kind'] == null)
            : (where?.contains("kind = 'mixed'") == true
                ? (s['kind'] == 'mixed' || s['kind'] == 'drill')
                : true);
        return s['topic'] == topic &&
            s['difficulty'] == diff &&
            s['mode'] == mode &&
            s['mode_value'] == modeVal &&
            s['completed'] == 1 &&
            matchesKind;
      }).toList();
    }

    if (orderBy != null) {
      if (orderBy.contains('score DESC')) {
        filtered.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));
      } else if (orderBy.contains('started_at ASC')) {
        filtered.sort((a, b) => (a['started_at'] as String).compareTo(b['started_at'] as String));
      } else if (orderBy.contains('started_at DESC')) {
        filtered.sort((a, b) => (b['started_at'] as String).compareTo(a['started_at'] as String));
      }
    }

    if (limit != null && filtered.length > limit) {
      filtered = filtered.sublist(0, limit);
    }

    return filtered;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    var filtered = List<Map<String, dynamic>>.from(sessions);

    if (arguments != null && arguments.length >= 4) {
      final topic = arguments[0] as String;
      final diff = arguments[1] as String;
      final mode = arguments[2] as String;
      final modeVal = arguments[3] as int;

      filtered = filtered.where((s) {
        final matchesKind = sql.contains("kind = 'drill'") &&
                !sql.contains("kind = 'mixed'")
            ? (s['kind'] == 'drill' || s['kind'] == null)
            : (sql.contains("kind = 'mixed'")
                ? (s['kind'] == 'mixed' || s['kind'] == 'drill')
                : true);
        return s['topic'] == topic &&
            s['difficulty'] == diff &&
            s['mode'] == mode &&
            s['mode_value'] == modeVal &&
            s['completed'] == 1 &&
            matchesKind;
      }).toList();
    }

    // Filter accuracy >= 80% if query specifies it
    if (sql.contains('accuracy >= 0.8')) {
      filtered = filtered.where((s) {
        final acc = (s['accuracy'] as num).toDouble();
        return acc >= 0.8;
      }).toList();
    }

    // Recent best score query
    if (sql.contains('MAX(score) as recent_best_score')) {
      final limit = arguments != null && arguments.length >= 5 ? arguments[arguments.length - 1] as int : 10;
      // Sort newest first
      filtered.sort((a, b) => (b['started_at'] as String).compareTo(a['started_at'] as String));
      if (filtered.length > limit) {
        filtered = filtered.sublist(0, limit);
      }
      if (filtered.isEmpty) {
        return [{'recent_best_score': null}];
      }
      final maxScore = filtered.map((e) => (e['score'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
      return [{'recent_best_score': maxScore}];
    }

    // Top best times query
    if (sql.contains('duration_ms ASC')) {
      filtered = filtered.where((s) => (s['duration_ms'] as num) > 0).toList();
      filtered.sort((a, b) => (a['duration_ms'] as num).compareTo(b['duration_ms'] as num));
    } else if (sql.contains('avg_time_ms ASC')) {
      filtered = filtered.where((s) => (s['avg_time_ms'] as num) > 0).toList();
      filtered.sort((a, b) => (a['avg_time_ms'] as num).compareTo(b['avg_time_ms'] as num));
    }

    final limit = arguments != null && arguments.isNotEmpty ? arguments.last as int : 3;
    if (filtered.length > limit) {
      filtered = filtered.sublist(0, limit);
    }

    return filtered;
  }
}

void main() {
  late FakeDatabase fakeDb;
  late DatabaseHelper dbHelper;
  late StatsRepository statsRepo;

  setUp(() {
    fakeDb = FakeDatabase();
    dbHelper = DatabaseHelper.withDatabase(fakeDb);
    statsRepo = StatsRepository(dbHelper: dbHelper);
  });

  Map<String, dynamic> createSessionMap({
    Topic topic = Topic.addition,
    Difficulty difficulty = Difficulty.easy,
    PracticeMode mode = PracticeMode.questions,
    int modeValue = 10,
    SessionKind kind = SessionKind.drill,
    required double score,
    required double accuracy,
    required int durationMs,
    required double avgTimeMs,
    required bool completed,
    DateTime? startedAt,
  }) {
    return Session(
      id: fakeDb.sessions.length + 1,
      topic: topic,
      difficulty: difficulty,
      mode: mode,
      modeValue: modeValue,
      kind: kind,
      startedAt: startedAt ?? DateTime.now(),
      score: score,
      accuracy: accuracy,
      durationMs: durationMs,
      avgTimeMs: avgTimeMs,
      completed: completed,
    ).toMap();
  }

  group('StatsRepository Queries & Business Rules', () {
    test('best score returns highest score from completed sessions of exact modeValue', () async {
      // 10-question sessions
      fakeDb.sessions.add(createSessionMap(modeValue: 10, score: 100.0, accuracy: 0.9, durationMs: 15000, avgTimeMs: 1500, completed: true));
      fakeDb.sessions.add(createSessionMap(modeValue: 10, score: 250.0, accuracy: 0.9, durationMs: 12000, avgTimeMs: 1200, completed: true));
      fakeDb.sessions.add(createSessionMap(modeValue: 10, score: 400.0, accuracy: 0.9, durationMs: 10000, avgTimeMs: 1000, completed: false)); // Incomplete!

      // 50-question session with massive score
      fakeDb.sessions.add(createSessionMap(modeValue: 50, score: 999.0, accuracy: 0.9, durationMs: 50000, avgTimeMs: 1000, completed: true));

      // 10-question best score must be 250.0 (incomplete 400.0 ignored, 50-question 999.0 ignored)
      final best10Q = await statsRepo.getBestScore(Topic.addition, Difficulty.easy, PracticeMode.questions, 10);
      expect(best10Q, 250.0);

      // 50-question best score is 999.0
      final best50Q = await statsRepo.getBestScore(Topic.addition, Difficulty.easy, PracticeMode.questions, 50);
      expect(best50Q, 999.0);
    });

    test('recent best score only looks at last 10 completed sessions of same modeValue', () async {
      final now = DateTime(2026, 10, 15, 12, 0);

      // Old session with a high score (older than 10 sessions)
      fakeDb.sessions.add(createSessionMap(
        modeValue: 60,
        mode: PracticeMode.timer,
        score: 500.0,
        accuracy: 0.95,
        durationMs: 60000,
        avgTimeMs: 2000,
        completed: true,
        startedAt: now.subtract(const Duration(days: 20)),
      ));

      // 10 newer sessions with lower scores (highest 180.0)
      for (var i = 1; i <= 10; i++) {
        fakeDb.sessions.add(createSessionMap(
          modeValue: 60,
          mode: PracticeMode.timer,
          score: 100.0 + i * 8.0, // max is 180.0
          accuracy: 0.9,
          durationMs: 60000,
          avgTimeMs: 2200,
          completed: true,
          startedAt: now.subtract(Duration(days: 15 - i)),
        ));
      }

      // Recent best score over the last 10 sessions should be 180.0
      final recentBest = await statsRepo.getRecentBestScore(
        Topic.addition,
        Difficulty.easy,
        PracticeMode.timer,
        60,
        limit: 10,
      );
      expect(recentBest, 180.0);

      // But overall best score is still 500.0
      final allTimeBest = await statsRepo.getBestScore(
        Topic.addition,
        Difficulty.easy,
        PracticeMode.timer,
        60,
      );
      expect(allTimeBest, 500.0);
    });

    test('top 3 best times enforces 80% accuracy rule and completed only', () async {
      // 4 completed 10-question sessions
      fakeDb.sessions.add(createSessionMap(modeValue: 10, durationMs: 12000, avgTimeMs: 1200, accuracy: 0.90, score: 100, completed: true)); // 1st
      fakeDb.sessions.add(createSessionMap(modeValue: 10, durationMs: 14000, avgTimeMs: 1400, accuracy: 0.85, score: 100, completed: true)); // 2nd
      fakeDb.sessions.add(createSessionMap(modeValue: 10, durationMs: 16000, avgTimeMs: 1600, accuracy: 0.80, score: 100, completed: true)); // 3rd
      fakeDb.sessions.add(createSessionMap(modeValue: 10, durationMs: 18000, avgTimeMs: 1800, accuracy: 0.90, score: 100, completed: true)); // 4th

      // Fast session with accuracy < 80% (disqualified!)
      fakeDb.sessions.add(createSessionMap(modeValue: 10, durationMs: 5000, avgTimeMs: 500, accuracy: 0.75, score: 100, completed: true));

      // Fast session but incomplete (disqualified!)
      fakeDb.sessions.add(createSessionMap(modeValue: 10, durationMs: 4000, avgTimeMs: 400, accuracy: 1.0, score: 100, completed: false));

      // Fast session but modeValue: 50 (must not affect modeValue: 10!)
      fakeDb.sessions.add(createSessionMap(modeValue: 50, durationMs: 8000, avgTimeMs: 800, accuracy: 0.95, score: 100, completed: true));

      final topTimes10Q = await statsRepo.getTopBestTimes(
        Topic.addition,
        Difficulty.easy,
        PracticeMode.questions,
        10,
        limit: 3,
      );

      expect(topTimes10Q.length, 3);
      expect(topTimes10Q[0].durationMs, 12000);
      expect(topTimes10Q[1].durationMs, 14000);
      expect(topTimes10Q[2].durationMs, 16000);
    });

    test('timer mode top 3 times ranked by lowest avg_time_ms', () async {
      // 3 completed 60s timer sessions
      fakeDb.sessions.add(createSessionMap(mode: PracticeMode.timer, modeValue: 60, durationMs: 60000, avgTimeMs: 2500, accuracy: 0.85, score: 150, completed: true)); // 2nd
      fakeDb.sessions.add(createSessionMap(mode: PracticeMode.timer, modeValue: 60, durationMs: 60000, avgTimeMs: 1900, accuracy: 0.90, score: 200, completed: true)); // 1st
      fakeDb.sessions.add(createSessionMap(mode: PracticeMode.timer, modeValue: 60, durationMs: 60000, avgTimeMs: 3100, accuracy: 0.80, score: 120, completed: true)); // 3rd

      // 5-minute timer session (modeValue: 300) must not affect 1-minute timer (modeValue: 60)
      fakeDb.sessions.add(createSessionMap(mode: PracticeMode.timer, modeValue: 300, durationMs: 300000, avgTimeMs: 1200, accuracy: 0.95, score: 500, completed: true));

      final topTimer60s = await statsRepo.getTopBestTimes(
        Topic.addition,
        Difficulty.easy,
        PracticeMode.timer,
        60,
        limit: 3,
      );

      expect(topTimer60s.length, 3);
      expect(topTimer60s[0].avgTimeMs, 1900);
      expect(topTimer60s[1].avgTimeMs, 2500);
      expect(topTimer60s[2].avgTimeMs, 3100);
    });

    test('mixed and mistake sessions are excluded from best score and history', () async {
      // Drill session with score 200
      fakeDb.sessions.add(createSessionMap(
        score: 200,
        accuracy: 0.9,
        durationMs: 15000,
        avgTimeMs: 1500,
        completed: true,
        kind: SessionKind.drill,
      ));
      // Mixed session with higher score 500
      fakeDb.sessions.add(createSessionMap(
        score: 500,
        accuracy: 0.95,
        durationMs: 10000,
        avgTimeMs: 1000,
        completed: true,
        kind: SessionKind.mixed,
      ));
      // Mistake session with score 300
      fakeDb.sessions.add(createSessionMap(
        score: 300,
        accuracy: 1.0,
        durationMs: 12000,
        avgTimeMs: 1200,
        completed: true,
        kind: SessionKind.mistakes,
      ));

      final best = await statsRepo.getBestScore(
        Topic.addition,
        Difficulty.easy,
        PracticeMode.questions,
        10,
      );
      // Best must be 200 (the drill), not 500 or 300
      expect(best, 200.0);

      final history = await statsRepo.getSessionHistory(
        Topic.addition,
        Difficulty.easy,
        PracticeMode.questions,
        10,
      );
      expect(history.length, 1);
      expect(history.first.score, 200.0);
    });

    test('auto difficulty mode sessions are queryable and returned in stats', () async {
      fakeDb.sessions.add(createSessionMap(
        topic: Topic.addition,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.questions,
        modeValue: 10,
        kind: SessionKind.mixed,
        score: 350.0,
        accuracy: 0.95,
        durationMs: 14000,
        avgTimeMs: 1400,
        completed: true,
      ));

      final bestAuto = await statsRepo.getBestScore(
        Topic.addition,
        Difficulty.mixed,
        PracticeMode.questions,
        10,
      );
      expect(bestAuto, 350.0);

      final historyAuto = await statsRepo.getSessionHistory(
        Topic.addition,
        Difficulty.mixed,
        PracticeMode.questions,
        10,
      );
      expect(historyAuto.length, 1);
      expect(historyAuto.first.score, 350.0);
    });

    test('expert and genius difficulty sessions are queryable and returned in stats', () async {
      fakeDb.sessions.add(createSessionMap(
        topic: Topic.multiplication,
        difficulty: Difficulty.expert,
        mode: PracticeMode.questions,
        modeValue: 20,
        kind: SessionKind.drill,
        score: 600.0,
        accuracy: 0.90,
        durationMs: 30000,
        avgTimeMs: 1500,
        completed: true,
      ));
      fakeDb.sessions.add(createSessionMap(
        topic: Topic.multiplication,
        difficulty: Difficulty.genius,
        mode: PracticeMode.questions,
        modeValue: 20,
        kind: SessionKind.drill,
        score: 950.0,
        accuracy: 0.95,
        durationMs: 28000,
        avgTimeMs: 1400,
        completed: true,
      ));

      final bestExpert = await statsRepo.getBestScore(
        Topic.multiplication,
        Difficulty.expert,
        PracticeMode.questions,
        20,
      );
      expect(bestExpert, 600.0);

      final bestGenius = await statsRepo.getBestScore(
        Topic.multiplication,
        Difficulty.genius,
        PracticeMode.questions,
        20,
      );
      expect(bestGenius, 950.0);
    });

    test('mixed topics practice sessions are queryable and returned in stats', () async {
      fakeDb.sessions.add(createSessionMap(
        topic: Topic.mixed,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.timer,
        modeValue: 60,
        kind: SessionKind.mixed,
        score: 420.0,
        accuracy: 0.88,
        durationMs: 60000,
        avgTimeMs: 1800,
        completed: true,
      ));
      fakeDb.sessions.add(createSessionMap(
        topic: Topic.mixed,
        difficulty: Difficulty.hard,
        mode: PracticeMode.timer,
        modeValue: 60,
        kind: SessionKind.mixed,
        score: 510.0,
        accuracy: 0.92,
        durationMs: 60000,
        avgTimeMs: 1600,
        completed: true,
      ));

      final bestMixedAuto = await statsRepo.getBestScore(
        Topic.mixed,
        Difficulty.mixed,
        PracticeMode.timer,
        60,
      );
      expect(bestMixedAuto, 420.0);

      final bestMixedHard = await statsRepo.getBestScore(
        Topic.mixed,
        Difficulty.hard,
        PracticeMode.timer,
        60,
      );
      expect(bestMixedHard, 510.0);

      final historyMixed = await statsRepo.getSessionHistory(
        Topic.mixed,
        Difficulty.hard,
        PracticeMode.timer,
        60,
      );
      expect(historyMixed.length, 1);
      expect(historyMixed.first.score, 510.0);
    });
  });
}
