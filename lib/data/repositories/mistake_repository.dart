import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/enums/enums.dart';
import '../../domain/adaptive/adaptive_constants.dart';
import '../../domain/adaptive/mistake_entry.dart';
import '../../domain/questions/question.dart';
import '../db/database_helper.dart';
import 'settings_repository.dart';

/// Riverpod provider for MistakeRepository.
final mistakeRepositoryProvider = Provider<MistakeRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MistakeRepository(
    dbHelper: DatabaseHelper.instance,
    prefs: prefs,
    ref: ref,
  );
});

/// Repository managing the spaced repetition mistake bank and global smart counter.
class MistakeRepository {
  final DatabaseHelper _dbHelper;
  final SharedPreferences? _prefs;
  final Ref? _ref;

  static const String keySmartQuestionCounter = 'smart_question_counter';

  MistakeRepository({
    DatabaseHelper? dbHelper,
    SharedPreferences? prefs,
    Ref? ref,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _prefs = prefs,
        _ref = ref;

  // --- Global Smart Question Counter ---

  int getSmartQuestionCounter() {
    return _prefs?.getInt(keySmartQuestionCounter) ?? 0;
  }

  Future<int> incrementSmartQuestionCounter([int delta = 1]) async {
    final current = getSmartQuestionCounter();
    final next = current + delta;
    await _prefs?.setInt(keySmartQuestionCounter, next);
    return next;
  }

  Future<void> resetSmartQuestionCounter() async {
    await _prefs?.setInt(keySmartQuestionCounter, 0);
  }

  // --- Bank Operations ---

  /// Total count of questions currently in the mistake bank.
  Future<int> getMistakeCount() async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableMistakeBank}',
    );
    if (res.isNotEmpty) {
      return (res.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  /// Retrieves all banked mistakes, sorted by topic then added_at DESC.
  Future<List<MistakeEntry>> getAllMistakes() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableMistakeBank,
      orderBy: 'topic ASC, added_at DESC',
    );
    return rows.map((r) => MistakeEntry.fromMap(r)).toList();
  }

  /// Retrieves due mistakes ready for resurfacing in Smart Practice.
  /// Ordered by lowest stage first, then highest wrong_count.
  Future<List<MistakeEntry>> getDueMistakes({
    required int currentCounter,
    List<Topic>? topics,
    int? limit,
  }) async {
    final db = await _dbHelper.database;
    String whereClause = 'due_counter <= ?';
    final List<dynamic> whereArgs = [currentCounter];

    if (topics != null && topics.isNotEmpty) {
      final topicPlaceholders = List.filled(topics.length, '?').join(', ');
      whereClause += ' AND topic IN ($topicPlaceholders)';
      whereArgs.addAll(topics.map((t) => t.name));
    }

    final rows = await db.query(
      DatabaseHelper.tableMistakeBank,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'stage ASC, wrong_count DESC, added_at ASC',
      limit: limit,
    );

    return rows.map((r) => MistakeEntry.fromMap(r)).toList();
  }

  /// Retrieves up to [limit] banked mistakes for Mistake Practice.
  /// Prioritizes lowest stage and highest wrong_count.
  Future<List<MistakeEntry>> getMistakesForPractice({
    List<Topic>? topics,
    int limit = AdaptiveConstants.mistakePracticeLimit,
  }) async {
    final db = await _dbHelper.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (topics != null && topics.isNotEmpty) {
      final topicPlaceholders = List.filled(topics.length, '?').join(', ');
      whereClause = 'topic IN ($topicPlaceholders)';
      whereArgs = topics.map((t) => t.name).toList();
    }

    final rows = await db.query(
      DatabaseHelper.tableMistakeBank,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'stage ASC, wrong_count DESC, added_at ASC',
      limit: limit,
    );

    return rows.map((r) => MistakeEntry.fromMap(r)).toList();
  }

  /// Evaluates an attempt after a session and adds or updates it in the bank
  /// if it was wrong, skipped, or answered slowly (> 2x target time).
  ///
  /// Returns `true` if a new mistake was added or an existing one updated.
  Future<bool> recordAttempt({
    required Question question,
    required bool isCorrect,
    required bool isSkipped,
    required int timeMs,
    int? targetTimeMs,
  }) async {
    // If answer was correct, clear it from mistake bank if present and do not record
    if (isCorrect) {
      await clearMistakeByQuestionText(question.displayText);
      return false;
    }

    final MistakeSource source;
    if (isSkipped) {
      source = MistakeSource.skipped;
    } else {
      source = MistakeSource.wrong;
    }

    final db = await _dbHelper.database;
    final currentCounter = getSmartQuestionCounter();
    final dueCounter = currentCounter + AdaptiveConstants.stageGaps[0];

    // Check if question already exists in bank
    final existing = await db.query(
      DatabaseHelper.tableMistakeBank,
      where: 'question_text = ?',
      whereArgs: [question.displayText],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final currentEntry = MistakeEntry.fromMap(existing.first);
      await db.update(
        DatabaseHelper.tableMistakeBank,
        {
          'wrong_count': currentEntry.wrongCount + 1,
          'stage': 0,
          'correct_streak': 0,
          'due_counter': dueCounter,
          'source': source.name,
        },
        where: 'id = ?',
        whereArgs: [currentEntry.id],
      );
    } else {
      final newEntry = MistakeEntry(
        topic: question.topic,
        difficulty: question.difficulty,
        questionText: question.displayText,
        operands: question.operands,
        correctAnswer: question.correctAnswer,
        stage: 0,
        correctStreak: 0,
        wrongCount: 1,
        source: source,
        addedAt: DateTime.now(),
        dueCounter: dueCounter,
      );
      await db.insert(
        DatabaseHelper.tableMistakeBank,
        newEntry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Enforce 300 capacity limit
    await _enforceCapacity(db);
    _ref?.read(dataRevisionProvider.notifier).state++;
    return true;
  }

  /// Processes a replayed mistake result in Smart or Mistake Practice.
  ///
  /// Returns `true` if the mistake was cleared (removed after 3 consecutive fast corrects).
  Future<bool> handleReplayResult({
    required int mistakeId,
    required bool isCorrect,
    required bool isSkipped,
    required int timeMs,
    required int targetTimeMs,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableMistakeBank,
      where: 'id = ?',
      whereArgs: [mistakeId],
      limit: 1,
    );

    if (rows.isEmpty) return false;
    final entry = MistakeEntry.fromMap(rows.first);
    final currentCounter = getSmartQuestionCounter();

    bool cleared = false;
    if (isCorrect) {
      // Correct answer immediately clears the mistake from the mistake revision list!
      await db.delete(
        DatabaseHelper.tableMistakeBank,
        where: 'id = ?',
        whereArgs: [mistakeId],
      );
      cleared = true;
    } else {
      // Wrong or skipped: reset stage and streak, increment wrong_count
      final nextDue = currentCounter + AdaptiveConstants.stageGaps[0];
      await db.update(
        DatabaseHelper.tableMistakeBank,
        {
          'stage': 0,
          'correct_streak': 0,
          'wrong_count': entry.wrongCount + 1,
          'due_counter': nextDue,
        },
        where: 'id = ?',
        whereArgs: [mistakeId],
      );
      cleared = false;
    }

    _ref?.read(dataRevisionProvider.notifier).state++;
    return cleared;
  }

  /// Clears any mistake matching [questionText] when answered correctly.
  Future<bool> clearMistakeByQuestionText(String questionText) async {
    final db = await _dbHelper.database;
    final deleted = await db.delete(
      DatabaseHelper.tableMistakeBank,
      where: 'question_text = ?',
      whereArgs: [questionText],
    );
    if (deleted > 0) {
      _ref?.read(dataRevisionProvider.notifier).state++;
      return true;
    }
    return false;
  }

  /// Enforces maximum capacity of [AdaptiveConstants.mistakeBankCapacity].
  /// Drops highest streak first, then oldest added_at.
  Future<void> _enforceCapacity(Database db) async {
    final countRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableMistakeBank}',
    );
    final count = (countRes.first['count'] as num?)?.toInt() ?? 0;
    final excess = count - AdaptiveConstants.mistakeBankCapacity;

    if (excess > 0) {
      await db.rawDelete(
        '''
        DELETE FROM ${DatabaseHelper.tableMistakeBank}
        WHERE id IN (
          SELECT id FROM ${DatabaseHelper.tableMistakeBank}
          ORDER BY correct_streak DESC, added_at ASC
          LIMIT ?
        )
        ''',
        [excess],
      );
    }
  }

  /// Removes a single mistake by ID (e.g. on swipe dismiss).
  Future<int> removeMistake(int id) async {
    final db = await _dbHelper.database;
    final res = await db.delete(
      DatabaseHelper.tableMistakeBank,
      where: 'id = ?',
      whereArgs: [id],
    );
    _ref?.read(dataRevisionProvider.notifier).state++;
    return res;
  }

  /// Re-inserts a previously removed mistake (e.g. for undoing swipe dismiss).
  Future<int> reinsertMistake(MistakeEntry entry) async {
    final db = await _dbHelper.database;
    final res = await db.insert(
      DatabaseHelper.tableMistakeBank,
      entry.toMap(),
    );
    _ref?.read(dataRevisionProvider.notifier).state++;
    return res;
  }

  /// Clears all mistakes and resets the global counter.
  Future<void> clearAllMistakes() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableMistakeBank);
    await resetSmartQuestionCounter();
    _ref?.read(dataRevisionProvider.notifier).state++;
  }
}
