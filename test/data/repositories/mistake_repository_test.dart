import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/repositories/mistake_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/adaptive_constants.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';
import 'package:sqflite/sqflite.dart';

class _FakeMistakeDatabase implements Database {
  final List<Map<String, dynamic>> bank = [];
  int _nextId = 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
    // Handle conflict replace on question_text
    final existingIdx = bank.indexWhere((r) => r['question_text'] == copy['question_text']);
    if (existingIdx >= 0 && conflictAlgorithm == ConflictAlgorithm.replace) {
      bank[existingIdx] = copy;
      return copy['id'] as int;
    }
    bank.add(copy);
    return copy['id'] as int;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    int updatedCount = 0;
    for (int i = 0; i < bank.length; i++) {
      bool matches = true;
      if (where != null && whereArgs != null) {
        if (where == 'id = ?') {
          matches = bank[i]['id'] == whereArgs[0];
        } else if (where == 'question_text = ?') {
          matches = bank[i]['question_text'] == whereArgs[0];
        }
      }
      if (matches) {
        bank[i].addAll(values);
        updatedCount++;
      }
    }
    return updatedCount;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (where == null) {
      final count = bank.length;
      bank.clear();
      return count;
    }
    int initialLength = bank.length;
    if (where == 'id = ?' && whereArgs != null) {
      bank.removeWhere((r) => r['id'] == whereArgs[0]);
    }
    return initialLength - bank.length;
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
    var results = List<Map<String, dynamic>>.from(bank);

    if (where != null && whereArgs != null) {
      if (where.contains('question_text = ?')) {
        results = results.where((r) => r['question_text'] == whereArgs[0]).toList();
      } else if (where.contains('due_counter <= ?')) {
        final counter = whereArgs[0] as int;
        results = results.where((r) => (r['due_counter'] as int) <= counter).toList();
        if (where.contains('topic IN')) {
          final topics = whereArgs.skip(1).cast<String>().toSet();
          results = results.where((r) => topics.contains(r['topic'])).toList();
        }
      } else if (where.contains('topic IN')) {
        final topics = whereArgs.cast<String>().toSet();
        results = results.where((r) => topics.contains(r['topic'])).toList();
      } else if (where == 'id = ?') {
        results = results.where((r) => r['id'] == whereArgs[0]).toList();
      }
    }

    if (orderBy != null) {
      if (orderBy.contains('stage ASC')) {
        results.sort((a, b) {
          final sA = a['stage'] as int;
          final sB = b['stage'] as int;
          if (sA != sB) return sA.compareTo(sB);
          final wA = a['wrong_count'] as int;
          final wB = b['wrong_count'] as int;
          return wB.compareTo(wA);
        });
      }
    }

    if (offset != null && offset > 0) {
      results = results.skip(offset).toList();
    }
    if (limit != null && results.length > limit) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    if (sql.contains('SELECT COUNT(*)')) {
      return [{'count': bank.length}];
    }
    return [];
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async {
    if (sql.contains('DELETE FROM mistake_bank')) {
      final excess = arguments?[0] as int? ?? 0;
      if (excess > 0 && bank.isNotEmpty) {
        // Sort: highest correct_streak first, then oldest added_at
        bank.sort((a, b) {
          final strA = a['correct_streak'] as int;
          final strB = b['correct_streak'] as int;
          if (strA != strB) return strB.compareTo(strA);
          final dtA = a['added_at'] is int ? a['added_at'] as int : 0;
          final dtB = b['added_at'] is int ? b['added_at'] as int : 0;
          return dtA.compareTo(dtB);
        });
        final removeCount = excess.clamp(0, bank.length);
        bank.removeRange(0, removeCount);
        return removeCount;
      }
    }
    return 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeMistakeDatabase fakeDb;
  late MistakeRepository repo;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeDb = _FakeMistakeDatabase();
    repo = MistakeRepository(
      dbHelper: DatabaseHelper.withDatabase(fakeDb),
      prefs: prefs,
    );
  });

  group('MistakeRepository', () {
    test('records wrong attempt and sets stage 0, streak 0, wrongCount 1', () async {
      const question = Question(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        displayText: '15 + 27',
        operands: [15, 27],
        correctAnswer: 42,
      );

      final added = await repo.recordAttempt(
        question: question,
        isCorrect: false,
        isSkipped: false,
        timeMs: 3000,
      );

      expect(added, isTrue);
      expect(fakeDb.bank.length, 1);
      final entry = fakeDb.bank.first;
      expect(entry['question_text'], '15 + 27');
      expect(entry['stage'], 0);
      expect(entry['correct_streak'], 0);
      expect(entry['wrong_count'], 1);
      expect(entry['source'], 'wrong');
      // Due counter should be current + stageGaps[0] (3)
      expect(entry['due_counter'], 3);
    });

    test('updating existing mistake increments wrong_count and resets stage & streak to 0', () async {
      const question = Question(
        topic: Topic.multiplication,
        difficulty: Difficulty.medium,
        displayText: '12 × 14',
        operands: [12, 14],
        correctAnswer: 168,
      );

      // First try wrong
      await repo.recordAttempt(
        question: question,
        isCorrect: false,
        isSkipped: false,
        timeMs: 4000,
      );

      // Replay was correct once (promoted to stage 1, streak 1)
      final mistakeId = fakeDb.bank.first['id'] as int;
      await repo.handleReplayResult(
        mistakeId: mistakeId,
        isCorrect: true,
        isSkipped: false,
        timeMs: 3000,
        targetTimeMs: 10000,
      );
      expect(fakeDb.bank.first['stage'], 1);
      expect(fakeDb.bank.first['correct_streak'], 1);

      // User gets it wrong again in another practice session
      await repo.recordAttempt(
        question: question,
        isCorrect: false,
        isSkipped: false,
        timeMs: 5000,
      );

      // Stage and streak reset to 0, wrong_count becomes 2
      final updated = fakeDb.bank.first;
      expect(updated['stage'], 0);
      expect(updated['correct_streak'], 0);
      expect(updated['wrong_count'], 2);
    });

    test('replays progress through stages 0 -> 1 -> 2 and removes on 3rd consecutive correct', () async {
      const question = Question(
        topic: Topic.squares,
        difficulty: Difficulty.medium,
        displayText: '24²',
        operands: [24],
        correctAnswer: 576,
      );

      await repo.recordAttempt(
        question: question,
        isCorrect: false,
        isSkipped: false,
        timeMs: 4000,
      );
      final id = fakeDb.bank.first['id'] as int;

      // 1st correct replay: stage 0 -> 1, streak 0 -> 1, gap = 10
      final cleared1 = await repo.handleReplayResult(
        mistakeId: id,
        isCorrect: true,
        isSkipped: false,
        timeMs: 2000,
        targetTimeMs: 8000,
      );
      expect(cleared1, isFalse);
      expect(fakeDb.bank.first['stage'], 1);
      expect(fakeDb.bank.first['correct_streak'], 1);
      expect(fakeDb.bank.first['due_counter'], 10);

      // 2nd correct replay: stage 1 -> 2, streak 1 -> 2, gap = 25
      final cleared2 = await repo.handleReplayResult(
        mistakeId: id,
        isCorrect: true,
        isSkipped: false,
        timeMs: 2000,
        targetTimeMs: 8000,
      );
      expect(cleared2, isFalse);
      expect(fakeDb.bank.first['stage'], 2);
      expect(fakeDb.bank.first['correct_streak'], 2);
      expect(fakeDb.bank.first['due_counter'], 25);

      // 3rd correct replay: streak reaches 3 -> cleared from bank!
      final cleared3 = await repo.handleReplayResult(
        mistakeId: id,
        isCorrect: true,
        isSkipped: false,
        timeMs: 2000,
        targetTimeMs: 8000,
      );
      expect(cleared3, isTrue);
      expect(fakeDb.bank.isEmpty, isTrue);
    });

    test('replayed mistake answered wrong resets stage and streak to 0', () async {
      const question = Question(
        topic: Topic.cubes,
        difficulty: Difficulty.easy,
        displayText: '4³',
        operands: [4],
        correctAnswer: 64,
      );

      await repo.recordAttempt(
        question: question,
        isCorrect: false,
        isSkipped: false,
        timeMs: 3000,
      );
      final id = fakeDb.bank.first['id'] as int;

      // Progress to stage 1
      await repo.handleReplayResult(
        mistakeId: id,
        isCorrect: true,
        isSkipped: false,
        timeMs: 2000,
        targetTimeMs: 5000,
      );
      expect(fakeDb.bank.first['stage'], 1);

      // Answer wrong on replay
      final cleared = await repo.handleReplayResult(
        mistakeId: id,
        isCorrect: false,
        isSkipped: false,
        timeMs: 2000,
        targetTimeMs: 5000,
      );
      expect(cleared, isFalse);
      expect(fakeDb.bank.first['stage'], 0);
      expect(fakeDb.bank.first['correct_streak'], 0);
      expect(fakeDb.bank.first['wrong_count'], 2);
    });

    test('capacity eviction: evicts highest streak mistakes when capacity exceeds 300', () async {
      // Fill bank with 300 items
      for (int i = 0; i < AdaptiveConstants.mistakeBankCapacity; i++) {
        fakeDb.bank.add({
          'id': i + 1,
          'topic': 'addition',
          'difficulty': 'easy',
          'question_text': 'Q#$i',
          'operands': '[1, 2]',
          'correct_answer': 3,
          'stage': i == 0 ? 2 : 0,
          'correct_streak': i == 0 ? 2 : 0, // Item 0 has highest streak
          'wrong_count': 1,
          'source': 'wrong',
          'added_at': 1000 + i,
          'due_counter': 0,
        });
      }
      fakeDb._nextId = 301;
      expect(fakeDb.bank.length, 300);

      // Record 301st mistake
      const question301 = Question(
        topic: Topic.cubes,
        difficulty: Difficulty.hard,
        displayText: '25³',
        operands: [25],
        correctAnswer: 15625,
      );
      await repo.recordAttempt(
        question: question301,
        isCorrect: false,
        isSkipped: false,
        timeMs: 5000,
      );

      // Bank size should stay at 300
      expect(fakeDb.bank.length, 300);
      // Item 0 (highest streak 2) was evicted
      expect(fakeDb.bank.any((r) => r['question_text'] == 'Q#0'), isFalse);
      // New item was added
      expect(fakeDb.bank.any((r) => r['question_text'] == '25³'), isTrue);
    });

    test('global smart question counter increments and retrieves due mistakes', () async {
      expect(repo.getSmartQuestionCounter(), 0);

      await repo.incrementSmartQuestionCounter(5);
      expect(repo.getSmartQuestionCounter(), 5);

      fakeDb.bank.add({
        'id': 10,
        'topic': 'addition',
        'difficulty': 'easy',
        'question_text': 'due question',
        'operands': '[1, 2]',
        'correct_answer': 3,
        'stage': 0,
        'correct_streak': 0,
        'wrong_count': 2,
        'source': 'wrong',
        'added_at': 1000,
        'due_counter': 4, // Due because 4 <= 5
      });

      fakeDb.bank.add({
        'id': 11,
        'topic': 'addition',
        'difficulty': 'easy',
        'question_text': 'not due question',
        'operands': '[3, 4]',
        'correct_answer': 7,
        'stage': 0,
        'correct_streak': 0,
        'wrong_count': 1,
        'source': 'wrong',
        'added_at': 1000,
        'due_counter': 10, // Not due because 10 > 5
      });

      final due = await repo.getDueMistakes(currentCounter: 5);
      expect(due.length, 1);
      expect(due.first.id, 10);
    });
  });
}
