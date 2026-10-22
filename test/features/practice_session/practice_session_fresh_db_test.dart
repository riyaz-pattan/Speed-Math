import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/repositories/attempt_repository.dart';
import 'package:speed_math_with_ai/data/repositories/mistake_repository.dart';
import 'package:speed_math_with_ai/data/repositories/session_repository.dart';
import 'package:speed_math_with_ai/data/repositories/skill_repository.dart';
import 'package:speed_math_with_ai/data/repositories/stats_repository.dart';
import 'package:speed_math_with_ai/features/practice_session/controllers/practice_session_controller.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';
import 'package:sqflite/sqflite.dart';

class _FakeBatch implements Batch {
  final _FakeFreshDb _db;
  final List<Future<dynamic> Function()> _operations = [];

  _FakeBatch(this._db);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {
    _operations.add(() => _db.insert(
          table,
          values,
          nullColumnHack: nullColumnHack,
          conflictAlgorithm: conflictAlgorithm,
        ));
  }

  @override
  Future<List<dynamic>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async {
    final results = <dynamic>[];
    for (final op in _operations) {
      final res = await op();
      if (noResult != true) {
        results.add(res);
      }
    }
    return results;
  }
}

class _FakeFreshDb implements Database {
  final List<Map<String, dynamic>> sessions = [];
  final List<Map<String, dynamic>> attempts = [];
  final List<Map<String, dynamic>> skillRatings = [];
  final List<Map<String, dynamic>> mistakeBank = [];
  int _nextId = 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Batch batch() => _FakeBatch(this);

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final copy = Map<String, dynamic>.from(values);
    if (!copy.containsKey('id') || copy['id'] == null) {
      copy['id'] = _nextId++;
    }
    final id = copy['id'] as int;

    if (table == DatabaseHelper.tableSessions) {
      sessions.add(copy);
    } else if (table == DatabaseHelper.tableAttempts) {
      attempts.add(copy);
    } else if (table == SkillRepository.tableSkillRatings) {
      final idx = skillRatings.indexWhere(
        (r) => r['topic'] == copy['topic'] && r['difficulty'] == copy['difficulty'],
      );
      if (idx >= 0) {
        skillRatings[idx] = copy;
      } else {
        skillRatings.add(copy);
      }
    } else if (table == DatabaseHelper.tableMistakeBank) {
      final idx = mistakeBank.indexWhere((r) => r['question_text'] == copy['question_text']);
      if (idx >= 0 && conflictAlgorithm == ConflictAlgorithm.replace) {
        mistakeBank[idx] = copy;
      } else {
        mistakeBank.add(copy);
      }
    }
    return id;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    List<Map<String, dynamic>> targetList;
    if (table == DatabaseHelper.tableSessions) {
      targetList = sessions;
    } else if (table == SkillRepository.tableSkillRatings) {
      targetList = skillRatings;
    } else if (table == DatabaseHelper.tableMistakeBank) {
      targetList = mistakeBank;
    } else {
      targetList = attempts;
    }

    int count = 0;
    for (int i = 0; i < targetList.length; i++) {
      bool matches = true;
      if (where != null && whereArgs != null) {
        if (where == 'id = ?') {
          matches = targetList[i]['id'] == whereArgs[0];
        } else if (where == 'topic = ? AND difficulty = ?') {
          matches = targetList[i]['topic'] == whereArgs[0] &&
              targetList[i]['difficulty'] == whereArgs[1];
        } else if (where == 'question_text = ?') {
          matches = targetList[i]['question_text'] == whereArgs[0];
        }
      }
      if (matches) {
        targetList[i].addAll(values);
        count++;
      }
    }
    return count;
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
    List<Map<String, dynamic>> targetList;
    if (table == DatabaseHelper.tableSessions) {
      targetList = sessions;
    } else if (table == DatabaseHelper.tableAttempts) {
      targetList = attempts;
    } else if (table == SkillRepository.tableSkillRatings) {
      targetList = skillRatings;
    } else if (table == DatabaseHelper.tableMistakeBank) {
      targetList = mistakeBank;
    } else {
      targetList = [];
    }

    var results = List<Map<String, dynamic>>.from(targetList);
    if (where != null && whereArgs != null) {
      if (where == 'id = ?') {
        results = results.where((r) => r['id'] == whereArgs[0]).toList();
      } else if (where == 'session_id = ?') {
        results = results.where((r) => r['session_id'] == whereArgs[0]).toList();
      } else if (where == 'topic = ? AND difficulty = ?') {
        results = results
            .where((r) =>
                r['topic'] == whereArgs[0] && r['difficulty'] == whereArgs[1])
            .toList();
      } else if (where.contains('question_text = ?')) {
        results = results.where((r) => r['question_text'] == whereArgs[0]).toList();
      } else if (where.contains('due_counter <= ?')) {
        final maxDue = whereArgs[0] as int;
        results = results.where((r) => (r['due_counter'] as int? ?? 0) <= maxDue).toList();
      }
    }
    return results;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final cleanSql = sql.replaceAll(RegExp(r'\s+'), ' ').trim();
    final upperSql = cleanSql.toUpperCase();

    if (upperSql.contains('COUNT(*)') || upperSql.contains('COUNT(1)')) {
      if (cleanSql.contains(DatabaseHelper.tableSessions)) {
        return [{'c': sessions.length, 'count': sessions.length}];
      }
      if (cleanSql.contains(DatabaseHelper.tableAttempts)) {
        return [{'c': attempts.length, 'count': attempts.length}];
      }
      if (cleanSql.contains(SkillRepository.tableSkillRatings)) {
        return [{'c': skillRatings.length, 'count': skillRatings.length}];
      }
      if (cleanSql.contains(DatabaseHelper.tableMistakeBank)) {
        return [{'c': mistakeBank.length, 'count': mistakeBank.length}];
      }
    }
    if (cleanSql.startsWith('SELECT * FROM ${DatabaseHelper.tableSessions}')) {
      return List<Map<String, Object?>>.from(sessions);
    }
    if (cleanSql.startsWith('SELECT * FROM ${DatabaseHelper.tableAttempts}')) {
      return List<Map<String, Object?>>.from(attempts);
    }
    if (cleanSql.startsWith('SELECT * FROM ${SkillRepository.tableSkillRatings}')) {
      return List<Map<String, Object?>>.from(skillRatings);
    }
    if (cleanSql.startsWith('SELECT * FROM ${DatabaseHelper.tableMistakeBank}')) {
      return List<Map<String, Object?>>.from(mistakeBank);
    }
    return [];
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('First Session on Fresh Database Tests (Phase 7A.1)', () {
    late _FakeFreshDb db;
    late DatabaseHelper dbHelper;
    late SessionRepository sessionRepo;
    late AttemptRepository attemptRepo;
    late StatsRepository statsRepo;
    late SkillRepository skillRepo;
    late MistakeRepository mistakeRepo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      db = _FakeFreshDb();
      dbHelper = DatabaseHelper.withDatabase(db);
      sessionRepo = SessionRepository(dbHelper: dbHelper);
      attemptRepo = AttemptRepository(dbHelper: dbHelper);
      statsRepo = StatsRepository(dbHelper: dbHelper);
      skillRepo = SkillRepository(dbHelper: dbHelper);
      mistakeRepo = MistakeRepository(dbHelper: dbHelper, prefs: prefs);
    });

    tearDown(() async {
      await db.close();
    });

    test('first session on completely empty DB: dual finish triggers saves exactly 1 session and 1 attempt set', () async {
      // Confirm fresh database is 100% empty
      final initialSessions = await db.rawQuery('SELECT count(*) as c FROM ${DatabaseHelper.tableSessions}');
      expect(initialSessions.first['c'], 0);
      final initialAttempts = await db.rawQuery('SELECT count(*) as c FROM ${DatabaseHelper.tableAttempts}');
      expect(initialAttempts.first['c'], 0);
      final initialSkills = await db.rawQuery('SELECT count(*) as c FROM ${SkillRepository.tableSkillRatings}');
      expect(initialSkills.first['c'], 0);

      const config = PracticeConfig(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 1,
        sessionSeed: 42,
      );

      final controller = PracticeSessionController(
        config: config,
        sessionRepository: sessionRepo,
        attemptRepository: attemptRepo,
        statsRepository: statsRepo,
        skillRepository: skillRepo,
        mistakeRepository: mistakeRepo,
      );

      controller.start();

      // Answer question 1 correctly (finishes session internally)
      final q = controller.state.currentQuestion;
      for (final ch in q.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      // Simulate simultaneous/subsequent finish triggers from UI listener and button
      final results = await Future.wait([
        controller.finishSession(),
        controller.finishSession(),
        controller.finishSession(),
      ]);

      // All returned results must match
      expect(results[0].savedSession?.id, isNotNull);
      expect(results[0].savedSession?.id, results[1].savedSession?.id);
      expect(results[1].savedSession?.id, results[2].savedSession?.id);

      // Verify database tables: exactly 1 session, exactly 1 attempt, exactly 1 skill rating!
      final dbSessions = await db.rawQuery('SELECT * FROM ${DatabaseHelper.tableSessions}');
      expect(dbSessions.length, 1, reason: 'Must have exactly 1 session row in database');
      expect(dbSessions.first['completed'], 1);

      final dbAttempts = await db.rawQuery('SELECT * FROM ${DatabaseHelper.tableAttempts}');
      expect(dbAttempts.length, 1, reason: 'Must have exactly 1 attempt row in database');
      expect(dbAttempts.first['session_id'], dbSessions.first['id']);

      final dbSkills = await db.rawQuery('SELECT * FROM ${SkillRepository.tableSkillRatings}');
      expect(dbSkills.length, 1, reason: 'Must have exactly 1 skill rating row');
      expect(dbSkills.first['topic'], Topic.addition.name);
    });

    test('first session on empty DB with Smart Practice: counter and mistakes recorded exactly once', () async {
      const config = PracticeConfig(
        topic: Topic.mixed,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.smart,
        modeValue: 2,
        sessionSeed: 99,
        selectedTopics: [Topic.addition, Topic.subtraction],
      );

      final controller = PracticeSessionController(
        config: config,
        sessionRepository: sessionRepo,
        attemptRepository: attemptRepo,
        statsRepository: statsRepo,
        skillRepository: skillRepo,
        mistakeRepository: mistakeRepo,
      );

      controller.start();

      // Question 1: correct
      final q1 = controller.state.currentQuestion;
      for (final ch in q1.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      // Question 2: wrong try then skip (auto finishes 2Q mode)
      controller.inputDigit('9');
      controller.skip();

      // Dual triggers calling finishSession
      final r1 = await controller.finishSession();
      final r2 = await controller.finishSession();

      expect(r1.savedSession?.id, r2.savedSession?.id);

      // Verify SQLite tables
      final dbSessions = await db.rawQuery('SELECT * FROM ${DatabaseHelper.tableSessions}');
      expect(dbSessions.length, 1);

      final dbAttempts = await db.rawQuery('SELECT * FROM ${DatabaseHelper.tableAttempts}');
      expect(dbAttempts.length, 2);

      // Mistake bank should have exactly 1 entry
      final dbMistakes = await db.rawQuery('SELECT * FROM ${DatabaseHelper.tableMistakeBank}');
      expect(dbMistakes.length, 1);

      // Global smart question counter should be 2, NOT 4 or 6
      expect(mistakeRepo.getSmartQuestionCounter(), 2);
    });

    test('first session early quit: saves exactly 1 abandoned session', () async {
      const config = PracticeConfig(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 10,
        sessionSeed: 123,
      );

      final controller = PracticeSessionController(
        config: config,
        sessionRepository: sessionRepo,
        attemptRepository: attemptRepo,
        statsRepository: statsRepo,
        skillRepository: skillRepo,
        mistakeRepository: mistakeRepo,
      );

      controller.start();

      // Answer 1 question then quit early
      final q = controller.state.currentQuestion;
      for (final ch in q.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      final r1 = await controller.quit();
      final r2 = await controller.quit();

      expect(r1?.savedSession?.id, isNotNull);
      expect(r1?.savedSession?.id, r2?.savedSession?.id);

      final dbSessions = await db.rawQuery('SELECT * FROM ${DatabaseHelper.tableSessions}');
      expect(dbSessions.length, 1);
      expect(dbSessions.first['completed'], 0);
    });
  });
}
