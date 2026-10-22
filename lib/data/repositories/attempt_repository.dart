import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/models/attempt.dart';
import 'settings_repository.dart';

/// Riverpod provider for [AttemptRepository].
final attemptRepositoryProvider = Provider<AttemptRepository>((ref) {
  return AttemptRepository(ref: ref);
});

/// Repository for handling persistence and retrieval of [Attempt] entities.
class AttemptRepository {
  final DatabaseHelper _dbHelper;
  final Ref? _ref;

  AttemptRepository({DatabaseHelper? dbHelper, Ref? ref})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _ref = ref;

  /// Inserts a single attempt record into the database.
  /// Returns the generated primary key id.
  Future<int> insertAttempt(Attempt attempt) async {
    final db = await _dbHelper.database;
    final id = await db.insert(
      DatabaseHelper.tableAttempts,
      attempt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _ref?.read(dataRevisionProvider.notifier).state++;
    return id;
  }

  /// Inserts multiple attempt records atomically using a database batch.
  /// Returns the list of generated ids.
  Future<List<int>> insertAttempts(List<Attempt> attempts) async {
    if (attempts.isEmpty) return [];
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final attempt in attempts) {
      batch.insert(
        DatabaseHelper.tableAttempts,
        attempt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    final results = await batch.commit(noResult: false);
    _ref?.read(dataRevisionProvider.notifier).state++;
    return results.cast<int>();
  }

  /// ONE shared method for "answered questions, all time, all session kinds"
  /// (answered = not skipped, includes questions answered wrongly).
  Future<int> getTotalAnsweredQuestionsAllTime() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableAttempts} WHERE COALESCE(is_skipped, 0) = 0',
    );
    if (result.isNotEmpty) {
      return (result.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  /// Retrieves all attempts associated with a specific [sessionId],
  /// ordered by id ascending (chronological attempt order).
  Future<List<Attempt>> getAttemptsBySessionId(int sessionId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableAttempts,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
    return results.map((map) => Attempt.fromMap(map)).toList();
  }

  /// Retrieves all attempts matching [topic] and [difficulty],
  /// ordered newest first.
  Future<List<Attempt>> getAttemptsByTopicDifficulty(
    Topic topic,
    Difficulty difficulty,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseHelper.tableAttempts,
      where: 'topic = ? AND difficulty = ?',
      whereArgs: [topic.name, difficulty.name],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => Attempt.fromMap(map)).toList();
  }
}
