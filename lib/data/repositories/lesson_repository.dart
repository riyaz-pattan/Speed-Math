// lib/data/repositories/lesson_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/lesson_progress.dart';

/// Provider for [LessonRepository].
final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(DatabaseHelper.instance);
});

/// Async provider for all lesson progress records.
final allLessonProgressProvider = FutureProvider<List<LessonProgress>>((ref) async {
  return ref.watch(lessonRepositoryProvider).getAllProgress();
});

/// Async provider for a single lesson's progress.
final lessonProgressProvider = FutureProvider.family<LessonProgress, String>((ref, lessonId) async {
  return ref.watch(lessonRepositoryProvider).getProgress(lessonId);
});

/// Repository for reading and writing lesson progress to SQLite.
class LessonRepository {
  const LessonRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  /// Returns progress for [lessonId], or an empty record if none exists.
  Future<LessonProgress> getProgress(String lessonId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableLessonProgress,
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      limit: 1,
    );
    if (rows.isEmpty) return LessonProgress.empty(lessonId);
    return LessonProgress.fromMap(rows.first);
  }

  /// Returns all lesson progress records.
  Future<List<LessonProgress>> getAllProgress() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DatabaseHelper.tableLessonProgress);
    return rows.map(LessonProgress.fromMap).toList();
  }

  /// Inserts or replaces a lesson progress record.
  Future<void> saveProgress(LessonProgress progress) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableLessonProgress,
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns the total XP awarded for all completed lessons.
  Future<int> getLessonXp() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(xp_awarded), 0) AS total FROM ${DatabaseHelper.tableLessonProgress}',
    );
    return ((result.first['total'] as num?)?.toInt() ?? 0);
  }
}
