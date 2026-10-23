import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/enums.dart';
import '../../domain/adaptive/pattern_skill.dart';
import '../../domain/adaptive/skill_rating.dart';
import '../db/database_helper.dart';
import 'settings_repository.dart';

/// Riverpod provider for [SkillRepository].
final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  return SkillRepository(ref: ref);
});

/// Repository for reading and writing skill ratings to the database.
class SkillRepository {
  final DatabaseHelper _dbHelper;
  final Ref? _ref;

  static const String tableSkillRatings = 'skill_ratings';
  static const String tablePatternSkills = 'pattern_skills';

  SkillRepository({DatabaseHelper? dbHelper, Ref? ref})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _ref = ref;

  /// Returns the skill rating for a specific topic + difficulty, or null.
  Future<SkillRating?> getRating(Topic topic, Difficulty difficulty) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      tableSkillRatings,
      where: 'topic = ? AND difficulty = ?',
      whereArgs: [topic.name, difficulty.name],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SkillRating.fromMap(results.first);
  }

  /// Returns the skill rating for a specific topic + difficulty,
  /// creating a default one if it doesn't exist.
  Future<SkillRating> getOrCreateRating(Topic topic, Difficulty difficulty) async {
    final existing = await getRating(topic, difficulty);
    if (existing != null) return existing;

    final newRating = SkillRating(topic: topic, difficulty: difficulty);
    final db = await _dbHelper.database;
    final id = await db.insert(tableSkillRatings, newRating.toMap());
    return newRating.copyWith(id: id);
  }

  /// Upserts a single skill rating.
  Future<void> saveRating(SkillRating rating) async {
    final db = await _dbHelper.database;
    if (rating.id != null) {
      await db.update(
        tableSkillRatings,
        rating.toMap(),
        where: 'id = ?',
        whereArgs: [rating.id],
      );
    } else {
      // Check if exists by topic + difficulty
      final existing = await getRating(rating.topic, rating.difficulty);
      if (existing != null) {
        await db.update(
          tableSkillRatings,
          rating.toMap(),
          where: 'topic = ? AND difficulty = ?',
          whereArgs: [rating.topic.name, rating.difficulty.name],
        );
      } else {
        await db.insert(tableSkillRatings, rating.toMap());
      }
    }
    _ref?.read(dataRevisionProvider.notifier).state++;
  }

  /// Batch upsert skill ratings in a single transaction.
  Future<void> saveRatings(List<SkillRating> ratings) async {
    if (ratings.isEmpty) return;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final rating in ratings) {
        final existing = await txn.query(
          tableSkillRatings,
          where: 'topic = ? AND difficulty = ?',
          whereArgs: [rating.topic.name, rating.difficulty.name],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          await txn.update(
            tableSkillRatings,
            rating.toMap(),
            where: 'topic = ? AND difficulty = ?',
            whereArgs: [rating.topic.name, rating.difficulty.name],
          );
        } else {
          await txn.insert(tableSkillRatings, rating.toMap());
        }
      }
    });
    _ref?.read(dataRevisionProvider.notifier).state++;
  }

  /// Returns all skill ratings.
  Future<List<SkillRating>> getAllRatings() async {
    final db = await _dbHelper.database;
    final results = await db.query(tableSkillRatings);
    return results.map((m) => SkillRating.fromMap(m)).toList();
  }

  /// Returns a map of "${topic.name}:${difficulty.name}" -> SkillRating for fast lookups.
  Future<Map<String, SkillRating>> getAllRatingsMap() async {
    final list = await getAllRatings();
    return {
      for (final r in list) '${r.topic.name}:${r.difficulty.name}': r,
    };
  }

  /// Returns skill ratings for a given topic (Easy, Medium, Hard).
  Future<List<SkillRating>> getRatingsForTopic(Topic topic) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      tableSkillRatings,
      where: 'topic = ?',
      whereArgs: [topic.name],
      orderBy: 'difficulty ASC',
    );
    return results.map((m) => SkillRating.fromMap(m)).toList();
  }

  /// Returns all pattern skills.
  Future<List<PatternSkill>> getAllPatternSkills() async {
    final db = await _dbHelper.database;
    final results = await db.query(tablePatternSkills);
    return results.map((m) => PatternSkill.fromMap(m)).toList();
  }

  /// Returns a map of "${topic.name}:${difficulty.name}:${pattern}" -> PatternSkill.
  Future<Map<String, PatternSkill>> getAllPatternSkillsMap() async {
    final list = await getAllPatternSkills();
    return {
      for (final p in list) '${p.topic.name}:${p.difficulty.name}:${p.pattern}': p,
    };
  }

  /// Returns pattern skills for a specific topic and difficulty.
  Future<List<PatternSkill>> getPatternSkills(
    Topic topic,
    Difficulty difficulty,
  ) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      tablePatternSkills,
      where: 'topic = ? AND difficulty = ?',
      whereArgs: [topic.name, difficulty.name],
    );
    return results.map((m) => PatternSkill.fromMap(m)).toList();
  }

  /// Atomically saves both skill ratings and pattern skills in ONE transaction.
  Future<void> saveRatingsAndPatternSkills(
    List<SkillRating> ratings,
    List<PatternSkill> patternSkills,
  ) async {
    if (ratings.isEmpty && patternSkills.isEmpty) return;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final rating in ratings) {
        final existing = await txn.query(
          tableSkillRatings,
          where: 'topic = ? AND difficulty = ?',
          whereArgs: [rating.topic.name, rating.difficulty.name],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          await txn.update(
            tableSkillRatings,
            rating.toMap(),
            where: 'topic = ? AND difficulty = ?',
            whereArgs: [rating.topic.name, rating.difficulty.name],
          );
        } else {
          await txn.insert(tableSkillRatings, rating.toMap());
        }
      }

      for (final skill in patternSkills) {
        final existing = await txn.query(
          tablePatternSkills,
          where: 'topic = ? AND difficulty = ? AND pattern = ?',
          whereArgs: [skill.topic.name, skill.difficulty.name, skill.pattern],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          await txn.update(
            tablePatternSkills,
            skill.toMap(),
            where: 'topic = ? AND difficulty = ? AND pattern = ?',
            whereArgs: [skill.topic.name, skill.difficulty.name, skill.pattern],
          );
        } else {
          await txn.insert(tablePatternSkills, skill.toMap());
        }
      }
    });
    _ref?.read(dataRevisionProvider.notifier).state++;
  }

  /// Deletes all skill ratings and pattern skills (used by Reset All Data).
  Future<void> deleteAll() async {
    final db = await _dbHelper.database;
    await db.delete(tableSkillRatings);
    await db.delete(tablePatternSkills);
  }
}
