import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../domain/adaptive/adaptive_constants.dart';
import '../../domain/questions/pattern_constants.dart';
import '../repositories/skill_repository.dart';

/// Singleton helper class to manage SQLite database creation, migrations,
/// and connection lifecycle for Speed Math with AI.
class DatabaseHelper {
  static const String databaseName = 'speed_math.db';
  static const int databaseVersion = 7;

  static const String tableSessions = 'sessions';
  static const String tableAttempts = 'attempts';
  static const String tableMistakeBank = 'mistake_bank';
  static const String tableCoachMessages = 'coach_messages';
  static const String tableCoachReports = 'coach_reports';
  static const String tablePatternSkills = 'pattern_skills';

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();
  Database? _customDb;

  /// Constructor for testing with an injected database instance.
  DatabaseHelper.withDatabase(Database db) : _customDb = db;

  factory DatabaseHelper() => instance;

  /// Lazily opens and returns the SQLite database instance.
  Future<Database> get database async {
    if (_customDb != null) return _customDb!;
    if (_database != null) return _database!;
    _database = await _initDB(databaseName);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Enable SQLite foreign key constraints.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Creates sessions, attempts, and skill_ratings tables and indexes.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableSessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        mode TEXT NOT NULL,
        mode_value INTEGER NOT NULL,
        kind TEXT NOT NULL DEFAULT 'drill',
        started_at TEXT NOT NULL,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        total_questions INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        wrong_count INTEGER NOT NULL DEFAULT 0,
        skipped_count INTEGER NOT NULL DEFAULT 0,
        accuracy REAL NOT NULL DEFAULT 0.0,
        avg_time_ms REAL NOT NULL DEFAULT 0.0,
        score REAL NOT NULL DEFAULT 0.0,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAttempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        topic TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        question_text TEXT NOT NULL,
        operand_a TEXT NOT NULL,
        operand_b TEXT NOT NULL,
        correct_answer INTEGER NOT NULL,
        user_answer INTEGER,
        is_correct INTEGER NOT NULL DEFAULT 0,
        is_skipped INTEGER NOT NULL DEFAULT 0,
        time_ms INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        pattern TEXT,
        FOREIGN KEY (session_id) REFERENCES $tableSessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_attempts_topic_difficulty ON $tableAttempts(topic, difficulty);',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_topic_difficulty_mode ON $tableSessions(topic, difficulty, mode);',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_topic_diff_mode_val ON $tableSessions(topic, difficulty, mode, mode_value);',
    );

    // Create skill_ratings table
    await _createSkillRatingsTable(db);

    // Create mistake_bank table
    await _createMistakeBankTable(db);

    // Create coach tables
    await _createCoachTables(db);

    // Create pattern_skills table
    await _createPatternSkillsTable(db);
  }

  /// Creates coach_messages and coach_reports tables.
  static Future<void> _createCoachTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCoachMessages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        text TEXT NOT NULL,
        actions TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_coach_messages_created ON $tableCoachMessages(created_at);',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableCoachReports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at INTEGER NOT NULL,
        user_message TEXT NOT NULL,
        coach_reply TEXT NOT NULL,
        reason TEXT NOT NULL
      )
    ''');
  }

  /// Creates the mistake_bank table.
  static Future<void> _createMistakeBankTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableMistakeBank (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        question_text TEXT NOT NULL UNIQUE,
        operands TEXT NOT NULL,
        correct_answer INTEGER NOT NULL,
        stage INTEGER NOT NULL DEFAULT 0,
        correct_streak INTEGER NOT NULL DEFAULT 0,
        wrong_count INTEGER NOT NULL DEFAULT 1,
        source TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        due_counter INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mistake_bank_due ON $tableMistakeBank(due_counter);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_mistake_bank_topic ON $tableMistakeBank(topic);',
    );
  }

  /// Creates the skill_ratings table.
  static Future<void> _createSkillRatingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${SkillRepository.tableSkillRatings} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        mastery REAL NOT NULL DEFAULT 0.5,
        attempts_count INTEGER NOT NULL DEFAULT 0,
        accuracy_ema REAL NOT NULL DEFAULT 0.0,
        avg_time_ms_ema REAL NOT NULL DEFAULT 0.0,
        last_practiced_at TEXT,
        UNIQUE(topic, difficulty)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_skill_ratings_topic ON ${SkillRepository.tableSkillRatings}(topic);',
    );
  }

  /// Creates the pattern_skills table.
  static Future<void> _createPatternSkillsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tablePatternSkills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        pattern TEXT NOT NULL,
        mastery REAL NOT NULL DEFAULT 0.5,
        attempts_count INTEGER NOT NULL DEFAULT 0,
        accuracy_ema REAL NOT NULL DEFAULT 0.0,
        avg_time_ms_ema REAL NOT NULL DEFAULT 0.0,
        last_practiced_at TEXT,
        UNIQUE(topic, difficulty, pattern)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pattern_skills_lookup ON $tablePatternSkills(topic, difficulty, pattern);',
    );
  }

  /// Handles schema migrations across versions.
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_topic_diff_mode_val ON $tableSessions(topic, difficulty, mode, mode_value);',
      );
    }
    if (oldVersion < 3 && newVersion >= 3) {
      await _createSkillRatingsTable(db);
      await _backfillSkillRatings(db);
    }
    if (oldVersion < 4 && newVersion >= 4) {
      await _createMistakeBankTable(db);
    }
    if (oldVersion < 5 && newVersion >= 5) {
      await db.execute(
        "ALTER TABLE $tableSessions ADD COLUMN kind TEXT NOT NULL DEFAULT 'drill';",
      );
      await db.execute(
        "UPDATE $tableSessions SET mode = 'questions', kind = 'mixed' WHERE mode = 'smart';",
      );
      await db.execute(
        "UPDATE $tableSessions SET mode = 'questions', kind = 'mistakes' WHERE mode = 'mistakes';",
      );
    }
    if (oldVersion < 6 && newVersion >= 6) {
      await _createCoachTables(db);
    }
    if (oldVersion < 7 && newVersion >= 7) {
      await db.execute('ALTER TABLE $tableAttempts ADD COLUMN pattern TEXT;');
      await _createPatternSkillsTable(db);
      await _backfillPatternsAndSkills(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await onUpgrade(db, oldVersion, newVersion);
  }

  /// Backfills skill_ratings from all existing attempts, replaying them
  /// in time order using the same update rules as SkillEngine.
  /// Processes in batches of 500 to avoid loading too many rows at once.
  static Future<void> _backfillSkillRatings(Database db) async {
    // In-memory map of (topic, difficulty) -> running skill state
    final Map<String, _BackfillState> states = {};

    const batchSize = 500;
    int offset = 0;
    bool hasMore = true;

    while (hasMore) {
      final rows = await db.rawQuery(
        '''
        SELECT topic, difficulty, is_correct, is_skipped, time_ms, created_at
        FROM $tableAttempts
        ORDER BY created_at ASC
        LIMIT ? OFFSET ?
        ''',
        [batchSize, offset],
      );

      if (rows.isEmpty) {
        hasMore = false;
        break;
      }

      for (final row in rows) {
        final topicStr = row['topic'] as String;
        final diffStr = row['difficulty'] as String;
        final key = '$topicStr:$diffStr';

        final state = states.putIfAbsent(key, () => _BackfillState(topicStr, diffStr));

        final isCorrect = ((row['is_correct'] as num?)?.toInt() ?? 0) == 1;
        final isSkipped = ((row['is_skipped'] as num?)?.toInt() ?? 0) == 1;
        final timeMs = (row['time_ms'] as num?)?.toInt() ?? 0;
        final createdAt = row['created_at'] as String?;

        // Calculate outcome score
        final topic = Topic.values.firstWhere(
          (e) => e.name.toLowerCase() == topicStr.toLowerCase(),
          orElse: () => Topic.addition,
        );
        final difficulty = Difficulty.values.firstWhere(
          (e) => e.name.toLowerCase() == diffStr.toLowerCase(),
          orElse: () => Difficulty.easy,
        );
        final targetTimeMs = AppConstants.getTargetTimeMs(topic, difficulty);

        double outcomeScore = 0.0;
        if (isCorrect && !isSkipped && targetTimeMs > 0) {
          final t = timeMs / targetTimeMs;
          if (t <= AdaptiveConstants.fastThreshold) {
            outcomeScore = AdaptiveConstants.maxOutcomeScore;
          } else if (t >= AdaptiveConstants.slowThreshold) {
            outcomeScore = AdaptiveConstants.minOutcomeScore;
          } else {
            final range = AdaptiveConstants.slowThreshold - AdaptiveConstants.fastThreshold;
            final ratio = (t - AdaptiveConstants.fastThreshold) / range;
            outcomeScore = AdaptiveConstants.maxOutcomeScore -
                ratio * (AdaptiveConstants.maxOutcomeScore - AdaptiveConstants.minOutcomeScore);
          }
        }

        // Update running state
        final alpha = state.attemptsCount < AdaptiveConstants.earlyAttemptThreshold
            ? AdaptiveConstants.alphaEarly
            : AdaptiveConstants.alphaLate;

        state.mastery = state.mastery + alpha * (outcomeScore - state.mastery);
        state.mastery = state.mastery.clamp(0.0, 1.0);

        final accuracyInput = outcomeScore > 0 ? 1.0 : 0.0;
        state.accuracyEma = state.accuracyEma + alpha * (accuracyInput - state.accuracyEma);
        state.accuracyEma = state.accuracyEma.clamp(0.0, 1.0);

        if (isCorrect && !isSkipped) {
          if (state.avgTimeMsEma == 0.0) {
            state.avgTimeMsEma = timeMs.toDouble();
          } else {
            state.avgTimeMsEma = state.avgTimeMsEma +
                alpha * (timeMs.toDouble() - state.avgTimeMsEma);
          }
        }

        state.attemptsCount++;
        if (createdAt != null) state.lastPracticedAt = createdAt;
      }

      offset += batchSize;
      if (rows.length < batchSize) hasMore = false;
    }

    // Write all accumulated states to the database
    if (states.isNotEmpty) {
      await db.transaction((txn) async {
        for (final state in states.values) {
          await txn.insert(
            SkillRepository.tableSkillRatings,
            {
              'topic': state.topic,
              'difficulty': state.difficulty,
              'mastery': state.mastery,
              'attempts_count': state.attemptsCount,
              'accuracy_ema': state.accuracyEma,
              'avg_time_ms_ema': state.avgTimeMsEma,
              'last_practiced_at': state.lastPracticedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
  }

  /// Backfills attempts.pattern for existing attempts and rebuilds pattern_skills.
  static Future<void> _backfillPatternsAndSkills(Database db) async {
    final Map<String, _BackfillState> patternStates = {};
    const batchSize = 500;
    int offset = 0;
    bool hasMore = true;

    while (hasMore) {
      final rows = await db.rawQuery(
        '''
        SELECT id, topic, difficulty, question_text, operand_a, operand_b, is_correct, is_skipped, time_ms, created_at
        FROM $tableAttempts
        ORDER BY created_at ASC
        LIMIT ? OFFSET ?
        ''',
        [batchSize, offset],
      );

      if (rows.isEmpty) {
        hasMore = false;
        break;
      }

      await db.transaction((txn) async {
        for (final row in rows) {
          final id = (row['id'] as num).toInt();
          final topicStr = row['topic'] as String;
          final diffStr = row['difficulty'] as String;
          final questionText = row['question_text'] as String;
          final opA = (row['operand_a'] ?? '').toString();
          final opB = (row['operand_b'] ?? '').toString();

          final topic = Topic.values.firstWhere(
            (e) => e.name.toLowerCase() == topicStr.toLowerCase(),
            orElse: () => Topic.addition,
          );
          final difficulty = Difficulty.values.firstWhere(
            (e) => e.name.toLowerCase() == diffStr.toLowerCase(),
            orElse: () => Difficulty.easy,
          );

          final operands = _parseOperands(topic, questionText, opA, opB);
          final pattern =
              PatternConstants.patternOf(topic, difficulty, operands);

          // Update attempt with pattern
          await txn.rawUpdate(
            'UPDATE $tableAttempts SET pattern = ? WHERE id = ?',
            [pattern, id],
          );

          // Update running pattern skill state
          final key = '${topic.name}:${difficulty.name}:$pattern';
          final state = patternStates.putIfAbsent(
            key,
            () => _BackfillState(topicStr, diffStr, pattern: pattern),
          );

          final isCorrect = ((row['is_correct'] as num?)?.toInt() ?? 0) == 1;
          final isSkipped = ((row['is_skipped'] as num?)?.toInt() ?? 0) == 1;
          final timeMs = (row['time_ms'] as num?)?.toInt() ?? 0;
          final createdAt = row['created_at'] as String?;

          final targetTimeMs = AppConstants.getTargetTimeMs(topic, difficulty);
          double outcomeScore = 0.0;
          if (isCorrect && !isSkipped && targetTimeMs > 0) {
            final t = timeMs / targetTimeMs;
            if (t <= AdaptiveConstants.fastThreshold) {
              outcomeScore = AdaptiveConstants.maxOutcomeScore;
            } else if (t >= AdaptiveConstants.slowThreshold) {
              outcomeScore = AdaptiveConstants.minOutcomeScore;
            } else {
              final range =
                  AdaptiveConstants.slowThreshold - AdaptiveConstants.fastThreshold;
              final ratio = (t - AdaptiveConstants.fastThreshold) / range;
              outcomeScore = AdaptiveConstants.maxOutcomeScore -
                  ratio *
                      (AdaptiveConstants.maxOutcomeScore -
                          AdaptiveConstants.minOutcomeScore);
            }
          }

          final alpha = state.attemptsCount <
                  AdaptiveConstants.earlyAttemptThreshold
              ? AdaptiveConstants.alphaEarly
              : AdaptiveConstants.alphaLate;

          state.mastery =
              (state.mastery + alpha * (outcomeScore - state.mastery))
                  .clamp(0.0, 1.0);
          final accuracyInput = outcomeScore > 0 ? 1.0 : 0.0;
          state.accuracyEma =
              (state.accuracyEma + alpha * (accuracyInput - state.accuracyEma))
                  .clamp(0.0, 1.0);

          if (isCorrect && !isSkipped) {
            if (state.avgTimeMsEma == 0.0) {
              state.avgTimeMsEma = timeMs.toDouble();
            } else {
              state.avgTimeMsEma = state.avgTimeMsEma +
                  alpha * (timeMs.toDouble() - state.avgTimeMsEma);
            }
          }

          state.attemptsCount++;
          if (createdAt != null) state.lastPracticedAt = createdAt;
        }
      });

      offset += batchSize;
      if (rows.length < batchSize) hasMore = false;
    }

    if (patternStates.isNotEmpty) {
      await db.transaction((txn) async {
        for (final state in patternStates.values) {
          await txn.insert(
            tablePatternSkills,
            {
              'topic': state.topic,
              'difficulty': state.difficulty,
              'pattern': state.pattern,
              'mastery': state.mastery,
              'attempts_count': state.attemptsCount,
              'accuracy_ema': state.accuracyEma,
              'avg_time_ms_ema': state.avgTimeMsEma,
              'last_practiced_at': state.lastPracticedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
  }

  static List<int> _parseOperands(
    Topic topic,
    String questionText,
    String opA,
    String opB,
  ) {
    if (topic == Topic.addition && questionText.contains('+')) {
      final parts = questionText
          .split('+')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
      if (parts.length >= 2) return parts;
    }
    final a = int.tryParse(opA);
    final b = int.tryParse(opB);
    if (a != null && b != null) return [a, b];
    if (a != null) return [a];
    final nums = RegExp(r'\d+')
        .allMatches(questionText)
        .map((m) => int.tryParse(m.group(0)!))
        .whereType<int>()
        .toList();
    return nums.isNotEmpty ? nums : [1];
  }

  /// Closes database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

/// Helper class for in-memory state during backfill.
class _BackfillState {
  final String topic;
  final String difficulty;
  final String pattern;
  double mastery = AdaptiveConstants.initialMastery;
  int attemptsCount = 0;
  double accuracyEma = 0.0;
  double avgTimeMsEma = 0.0;
  String? lastPracticedAt;

  _BackfillState(this.topic, this.difficulty, {this.pattern = ''});
}
