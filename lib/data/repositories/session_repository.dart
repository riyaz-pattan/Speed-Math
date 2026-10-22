import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'settings_repository.dart';

/// Riverpod provider for [SessionRepository].
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref: ref);
});

/// Repository for handling persistence and retrieval of [Session] entities.
class SessionRepository {
  final DatabaseHelper _dbHelper;
  final Ref? _ref;

  SessionRepository({DatabaseHelper? dbHelper, Ref? ref})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _ref = ref;

  /// Inserts a new session record into the database.
  /// Returns the generated primary key id.
  Future<int> insertSession(Session session) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      DatabaseHelper.tableSessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _ref?.read(dataRevisionProvider.notifier).state++;
    return id;
  }

  /// Updates an existing session record in the database.
  /// Returns the number of rows affected.
  Future<int> updateSession(Session session) async {
    final id = session.id;
    if (id == null) {
      throw ArgumentError('Cannot update session without an id');
    }
    final db = await _dbHelper.database;
    final rows = await db.update(
      DatabaseHelper.tableSessions,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    _ref?.read(dataRevisionProvider.notifier).state++;
    return rows;
  }

  /// Retrieves a session by its unique [id].
  /// Returns null if not found.
  Future<Session?> getSessionById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableSessions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Session.fromMap(results.first);
  }

  /// Retrieves all sessions, sorted by newest start time first.
  Future<List<Session>> getAllSessions() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableSessions,
      orderBy: 'started_at DESC',
    );
    return results.map((map) => Session.fromMap(map)).toList();
  }

  /// Retrieves sessions matching specific [topic], [difficulty], and [mode],
  /// sorted by newest start time first.
  Future<List<Session>> getSessionsByTopicDifficultyMode(
    Topic topic,
    Difficulty difficulty,
    PracticeMode mode,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableSessions,
      where: 'topic = ? AND difficulty = ? AND mode = ?',
      whereArgs: [topic.name, difficulty.name, mode.name],
      orderBy: 'started_at DESC',
    );
    return results.map((map) => Session.fromMap(map)).toList();
  }

  /// Retrieves all completed sessions (`completed = 1`), sorted by newest start time first.
  Future<List<Session>> getCompletedSessions() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableSessions,
      where: 'completed = 1',
      orderBy: 'started_at DESC',
    );
    return results.map((map) => Session.fromMap(map)).toList();
  }

  /// Retrieves the most recent sessions up to [limit], sorted by newest start time first.
  Future<List<Session>> getRecentSessions(int limit) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableSessions,
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return results.map((map) => Session.fromMap(map)).toList();
  }

  /// Retrieves sessions optionally filtered by [topic], [modes], and/or [kinds] with [limit] and [offset] pagination.
  Future<List<Session>> getSessionsFiltered({
    Topic? topic,
    List<PracticeMode>? modes,
    List<SessionKind>? kinds,
    int? limit,
    int? offset,
  }) async {
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (topic != null) {
      whereClauses.add('topic = ?');
      whereArgs.add(topic.name);
    }
    if (modes != null && modes.isNotEmpty) {
      final placeholders = List.filled(modes.length, '?').join(', ');
      whereClauses.add('mode IN ($placeholders)');
      whereArgs.addAll(modes.map((m) => m.name));
    }
    if (kinds != null && kinds.isNotEmpty) {
      final placeholders = List.filled(kinds.length, '?').join(', ');
      whereClauses.add('kind IN ($placeholders)');
      whereArgs.addAll(kinds.map((k) => k.name));
    }

    final results = await db.query(
      DatabaseHelper.tableSessions,
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'started_at DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((map) => Session.fromMap(map)).toList();
  }
}
