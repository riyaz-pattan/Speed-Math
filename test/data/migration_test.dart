import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/repositories/skill_repository.dart';
import 'package:sqflite/sqflite.dart';

class _FakeMigrationTransaction implements Transaction {
  final _FakeMigrationDatabase parent;

  _FakeMigrationTransaction(this.parent);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    return parent.insert(table, values,
        nullColumnHack: nullColumnHack, conflictAlgorithm: conflictAlgorithm);
  }

  @override
  Future<int> update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) async {
    return parent.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
  }

  @override
  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    return parent.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }
}

class _FakeMigrationDatabase implements Database {
  final List<String> executedStatements = [];
  final List<Map<String, dynamic>> sessions = [
    {
      'id': 1,
      'topic': 'addition',
      'difficulty': 'medium',
      'mode': 'timer',
      'mode_value': 120,
      'started_at': '2026-10-15T12:00:00.000Z',
      'duration_ms': 120000,
      'total_questions': 25,
      'correct_count': 22,
      'wrong_count': 2,
      'skipped_count': 1,
      'accuracy': 0.88,
      'avg_time_ms': 4800.0,
      'score': 210.0,
      'completed': 1,
    },
  ];
  final List<Map<String, dynamic>> attempts = [
    {
      'id': 1,
      'session_id': 1,
      'topic': 'addition',
      'difficulty': 'medium',
      'question_text': '45 + 56',
      'operand_a': '45',
      'operand_b': '56',
      'correct_answer': 101,
      'user_answer': 101,
      'is_correct': 1,
      'is_skipped': 0,
      'time_ms': 3200,
      'created_at': '2026-10-15T12:00:05.000Z',
    },
    {
      'id': 2,
      'session_id': 1,
      'topic': 'addition',
      'difficulty': 'medium',
      'question_text': '12 + 34',
      'operand_a': '12',
      'operand_b': '34',
      'correct_answer': 46,
      'user_answer': 46,
      'is_correct': 1,
      'is_skipped': 0,
      'time_ms': 2500,
      'created_at': '2026-10-15T12:00:10.000Z',
    },
  ];
  final List<Map<String, dynamic>> insertedSkillRatings = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
    if (sql.contains('ALTER TABLE sessions ADD COLUMN kind')) {
      for (final s in sessions) {
        s['kind'] = 'drill';
      }
    } else if (sql.contains("UPDATE sessions SET mode = 'questions', kind = 'mixed' WHERE mode = 'smart'")) {
      for (final s in sessions) {
        if (s['mode'] == 'smart') {
          s['mode'] = 'questions';
          s['kind'] = 'mixed';
        }
      }
    } else if (sql.contains("UPDATE sessions SET mode = 'questions', kind = 'mistakes' WHERE mode = 'mistakes'")) {
      for (final s in sessions) {
        if (s['mode'] == 'mistakes') {
          s['mode'] = 'questions';
          s['kind'] = 'mistakes';
        }
      }
    }
  }

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
    if (table == DatabaseHelper.tableSessions) return List.from(sessions);
    if (table == DatabaseHelper.tableAttempts) return List.from(attempts);
    if (table == SkillRepository.tableSkillRatings) {
      return List.from(insertedSkillRatings);
    }
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]) async {
    if (sql.contains('FROM attempts')) {
      final limit = (arguments?[0] as num?)?.toInt() ?? attempts.length;
      final offset = (arguments?[1] as num?)?.toInt() ?? 0;
      if (offset >= attempts.length) return [];
      return attempts.skip(offset).take(limit).toList();
    }
    return [];
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool? exclusive}) async {
    return await action(_FakeMigrationTransaction(this));
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    if (table == SkillRepository.tableSkillRatings) {
      insertedSkillRatings.add(Map.from(values));
      return insertedSkillRatings.length;
    }
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) async {
    return 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Database Migration v1 -> v2', () {
    test('upgrades from version 1 to 2 by creating composite index', () async {
      final fakeDb = _FakeMigrationDatabase();
      final helper = DatabaseHelper.instance;

      expect(fakeDb.executedStatements, isEmpty);

      // Perform migration from v1 to v2
      await helper.onUpgrade(fakeDb, 1, 2);

      // Verify the composite index statement was executed
      expect(fakeDb.executedStatements, hasLength(1));
      expect(
        fakeDb.executedStatements.first,
        contains('idx_sessions_topic_diff_mode_val'),
      );
      expect(
        fakeDb.executedStatements.first,
        contains('sessions(topic, difficulty, mode, mode_value)'),
      );

      // Verify existing data is completely preserved
      final sessions = await fakeDb.query(DatabaseHelper.tableSessions);
      expect(sessions, hasLength(1));
      expect(sessions.first['topic'], 'addition');
      expect(sessions.first['score'], 210.0);
      expect(sessions.first['accuracy'], 0.88);

      final attempts = await fakeDb.query(DatabaseHelper.tableAttempts);
      expect(attempts, hasLength(2));
      expect(attempts.first['correct_answer'], 101);
      expect(attempts.first['user_answer'], 101);
    });

    test('no migration queries run when already at or above version 2 for v2 target', () async {
      final fakeDb = _FakeMigrationDatabase();
      final helper = DatabaseHelper.instance;

      await helper.onUpgrade(fakeDb, 2, 2);

      expect(fakeDb.executedStatements, isEmpty);
    });
  });

  group('Database Migration to v3', () {
    test('creates skill_ratings table and backfills existing attempts', () async {
      final fakeDb = _FakeMigrationDatabase();
      final helper = DatabaseHelper.instance;

      await helper.onUpgrade(fakeDb, 2, 3);

      // Table and index created
      expect(
        fakeDb.executedStatements.any((s) => s.contains('skill_ratings')),
        isTrue,
      );

      // Backfilled skill rating for addition medium
      expect(fakeDb.insertedSkillRatings, isNotEmpty);
      final rating = fakeDb.insertedSkillRatings.first;
      expect(rating['topic'], 'addition');
      expect(rating['difficulty'], 'medium');
      expect(rating['attempts_count'], 2);
      expect(rating['accuracy_ema'], greaterThan(0.0));
      expect(rating['avg_time_ms_ema'], greaterThan(0.0));
    });

    test('no migration queries run when already at version 3', () async {
      final fakeDb = _FakeMigrationDatabase();
      final helper = DatabaseHelper.instance;

      await helper.onUpgrade(fakeDb, 3, 3);

      expect(fakeDb.executedStatements, isEmpty);
      expect(fakeDb.insertedSkillRatings, isEmpty);
    });
  });

  group('Database Migration to v4', () {
    test('creates mistake_bank table and index on upgraded to v4', () async {
      final fakeDb = _FakeMigrationDatabase();
      final helper = DatabaseHelper.instance;

      await helper.onUpgrade(fakeDb, 3, 4);

      // Table and index created
      expect(
        fakeDb.executedStatements.any((s) => s.contains('mistake_bank')),
        isTrue,
      );
      expect(
        fakeDb.executedStatements.any((s) => s.contains('idx_mistake_bank_due')),
        isTrue,
      );
    });

    test('no migration queries run when already at version 4', () async {
      final fakeDb = _FakeMigrationDatabase();
      final helper = DatabaseHelper.instance;

      await helper.onUpgrade(fakeDb, 4, 4);

      expect(fakeDb.executedStatements, isEmpty);
    });
  });

  group('Database Migration to v5 (Phase 7A.2)', () {
    test('adds kind column and migrates smart/mistakes rows while preserving existing data', () async {
      final fakeDb = _FakeMigrationDatabase();
      // Setup rows with different modes
      fakeDb.sessions.clear();
      fakeDb.sessions.addAll([
        {
          'id': 1,
          'topic': 'addition',
          'difficulty': 'medium',
          'mode': 'timer',
          'mode_value': 120,
          'started_at': '2026-10-15T12:00:00.000Z',
          'duration_ms': 120000,
          'total_questions': 25,
          'correct_count': 22,
          'wrong_count': 2,
          'skipped_count': 1,
          'accuracy': 0.88,
          'avg_time_ms': 4800.0,
          'score': 210.0,
          'completed': 1,
        },
        {
          'id': 2,
          'topic': 'mixed',
          'difficulty': 'mixed',
          'mode': 'smart',
          'mode_value': 20,
          'started_at': '2026-10-16T12:00:00.000Z',
          'duration_ms': 60000,
          'total_questions': 20,
          'correct_count': 18,
          'wrong_count': 2,
          'skipped_count': 0,
          'accuracy': 0.90,
          'avg_time_ms': 3000.0,
          'score': 180.0,
          'completed': 1,
        },
        {
          'id': 3,
          'topic': 'mixed',
          'difficulty': 'mixed',
          'mode': 'mistakes',
          'mode_value': 10,
          'started_at': '2026-10-17T12:00:00.000Z',
          'duration_ms': 30000,
          'total_questions': 10,
          'correct_count': 10,
          'wrong_count': 0,
          'skipped_count': 0,
          'accuracy': 1.0,
          'avg_time_ms': 2500.0,
          'score': 100.0,
          'completed': 1,
        },
        {
          'id': 4,
          'topic': 'cubes',
          'difficulty': 'hard',
          'mode': 'questions',
          'mode_value': 20,
          'started_at': '2026-10-18T12:00:00.000Z',
          'duration_ms': 80000,
          'total_questions': 20,
          'correct_count': 19,
          'wrong_count': 1,
          'skipped_count': 0,
          'accuracy': 0.95,
          'avg_time_ms': 4000.0,
          'score': 190.0,
          'completed': 1,
        },
      ]);

      final helper = DatabaseHelper.instance;
      await helper.onUpgrade(fakeDb, 4, 5);

      // Verify statements executed
      expect(
        fakeDb.executedStatements.any((s) => s.contains('ALTER TABLE sessions ADD COLUMN kind')),
        isTrue,
      );
      expect(
        fakeDb.executedStatements.any((s) => s.contains("kind = 'mixed' WHERE mode = 'smart'")),
        isTrue,
      );
      expect(
        fakeDb.executedStatements.any((s) => s.contains("kind = 'mistakes' WHERE mode = 'mistakes'")),
        isTrue,
      );

      // Check migrated sessions
      final s1 = fakeDb.sessions[0];
      expect(s1['mode'], 'timer');
      expect(s1['kind'], 'drill');
      expect(s1['score'], 210.0);

      final s2 = fakeDb.sessions[1];
      expect(s2['mode'], 'questions');
      expect(s2['kind'], 'mixed');
      expect(s2['score'], 180.0);

      final s3 = fakeDb.sessions[2];
      expect(s3['mode'], 'questions');
      expect(s3['kind'], 'mistakes');
      expect(s3['score'], 100.0);

      final s4 = fakeDb.sessions[3];
      expect(s4['mode'], 'questions');
      expect(s4['kind'], 'drill');
      expect(s4['score'], 190.0);
    });

    test('no migration queries run when already at version 5', () async {
      final fakeDb = _FakeMigrationDatabase();
      final helper = DatabaseHelper.instance;

      await helper.onUpgrade(fakeDb, 5, 5);

      expect(fakeDb.executedStatements, isEmpty);
    });
  });
}
