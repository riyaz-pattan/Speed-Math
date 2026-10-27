import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/enums.dart';
import '../db/database_helper.dart';
import '../models/session.dart';

/// Riverpod provider for [StatsRepository].
final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository();
});

/// Repository for aggregating session statistics, high scores, best times,
/// and graph performance history.
class StatsRepository {
  final DatabaseHelper _dbHelper;

  StatsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Returns the completed session with the highest score for the specified
  /// combination of [topic], [difficulty], [mode], and [modeValue].
  Future<Session?> getBestScoreSession(
    Topic topic,
    Difficulty difficulty,
    PracticeMode mode,
    int modeValue,
  ) async {
    if (topic == Topic.mixed || difficulty == Difficulty.mixed) return null;
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableSessions,
      where:
          "topic = ? AND difficulty = ? AND mode = ? AND mode_value = ? AND completed = 1 AND kind = 'drill'",
      whereArgs: [topic.name, difficulty.name, mode.name, modeValue],
      orderBy: 'score DESC, started_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Session.fromMap(results.first);
  }

  /// Returns the highest score recorded from completed sessions for the specified
  /// combination of [topic], [difficulty], [mode], and [modeValue].
  Future<double?> getBestScore(
    Topic topic,
    Difficulty difficulty,
    PracticeMode mode,
    int modeValue,
  ) async {
    final bestSession =
        await getBestScoreSession(topic, difficulty, mode, modeValue);
    return bestSession?.score;
  }

  /// Returns the highest score among the last [limit] completed sessions for
  /// the specified combination of [topic], [difficulty], [mode], and [modeValue].
  Future<double?> getRecentBestScore(
    Topic topic,
    Difficulty difficulty,
    PracticeMode mode,
    int modeValue, {
    int limit = 10,
  }) async {
    if (topic == Topic.mixed || difficulty == Difficulty.mixed) return null;
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      '''
      SELECT MAX(score) as recent_best_score FROM (
        SELECT score FROM ${DatabaseHelper.tableSessions}
        WHERE topic = ? 
          AND difficulty = ? 
          AND mode = ? 
          AND mode_value = ?
          AND completed = 1
          AND kind = 'drill'
        ORDER BY started_at DESC
        LIMIT ?
      )
      ''',
      [topic.name, difficulty.name, mode.name, modeValue, limit],
    );

    if (results.isEmpty || results.first['recent_best_score'] == null) {
      return null;
    }
    return (results.first['recent_best_score'] as num?)?.toDouble();
  }

  /// Returns top best performing sessions (up to [limit]) with accuracy >= 80%.
  /// - For [PracticeMode.questions]: ranked by fastest total times (`duration_ms` ASC).
  /// - For [PracticeMode.timer]: ranked by lowest average time per correct answer (`avg_time_ms` ASC).
  Future<List<Session>> getTopBestTimes(
    Topic topic,
    Difficulty difficulty,
    PracticeMode mode,
    int modeValue, {
    int limit = 3,
  }) async {
    if (topic == Topic.mixed || difficulty == Difficulty.mixed) return [];
    final db = await _dbHelper.database;
    final String orderClause;
    final String conditionClause;

    if (mode == PracticeMode.questions) {
      orderClause = 'duration_ms ASC';
      conditionClause = 'duration_ms > 0';
    } else {
      orderClause = 'avg_time_ms ASC';
      conditionClause = 'avg_time_ms > 0';
    }

    final results = await db.rawQuery(
      '''
      SELECT * FROM ${DatabaseHelper.tableSessions}
      WHERE topic = ? 
        AND difficulty = ? 
        AND mode = ? 
        AND mode_value = ?
        AND completed = 1
        AND kind = 'drill'
        AND ((accuracy >= 0.8 AND accuracy <= 1.0) OR accuracy >= 80.0)
        AND $conditionClause
      ORDER BY $orderClause
      LIMIT ?
      ''',
      [topic.name, difficulty.name, mode.name, modeValue, limit],
    );

    final sessions = results.map((map) => Session.fromMap(map)).toList();
    // Ensure distinct sessions by startedAt timestamp so accidental duplicates never repeat
    final seen = <String>{};
    final uniqueSessions = <Session>[];
    for (final s in sessions) {
      final key = s.startedAt.toIso8601String();
      if (seen.add(key)) {
        uniqueSessions.add(s);
      }
    }
    return uniqueSessions;
  }

  /// Retrieves chronological session history for the specified combination of
  /// [topic], [difficulty], [mode], and [modeValue] for rendering line charts.
  Future<List<Session>> getSessionHistory(
    Topic topic,
    Difficulty difficulty,
    PracticeMode mode,
    int modeValue, {
    int? limit,
    DateTime? since,
  }) async {
    if (topic == Topic.mixed || difficulty == Difficulty.mixed) return [];
    final db = await _dbHelper.database;
    String whereClause =
        "topic = ? AND difficulty = ? AND mode = ? AND mode_value = ? AND completed = 1 AND kind = 'drill'";
    final List<dynamic> whereArgs = [
      topic.name,
      difficulty.name,
      mode.name,
      modeValue
    ];

    if (since != null) {
      whereClause += ' AND started_at >= ?';
      whereArgs.add(since.toIso8601String());
    }

    final List<Map<String, dynamic>> results;
    if (limit != null) {
      results = await db.rawQuery(
        '''
        SELECT * FROM (
          SELECT * FROM ${DatabaseHelper.tableSessions}
          WHERE $whereClause
          ORDER BY started_at DESC
          LIMIT ?
        ) ORDER BY started_at ASC
        ''',
        [...whereArgs, limit],
      );
    } else {
      results = await db.query(
        DatabaseHelper.tableSessions,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'started_at ASC',
      );
    }

    final sessions = results.map((map) => Session.fromMap(map)).toList();
    final seen = <String>{};
    final uniqueSessions = <Session>[];
    for (final s in sessions) {
      final key = s.startedAt.toIso8601String();
      if (seen.add(key)) {
        uniqueSessions.add(s);
      }
    }
    return uniqueSessions;
  }
}
