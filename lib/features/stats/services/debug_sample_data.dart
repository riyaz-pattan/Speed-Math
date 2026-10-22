import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/enums.dart';
import '../../../data/db/database_helper.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/session.dart';
import '../../../data/repositories/attempt_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../data/repositories/skill_repository.dart';
import '../../../domain/adaptive/mistake_entry.dart';
import '../../../domain/adaptive/skill_engine.dart';
import '../../../domain/adaptive/skill_rating.dart';

/// Debug-only utility to seed realistic practice history for testing charts and stats.
///
/// Guaranteed to be a no-op in release builds (guarded by [kDebugMode]).
class DebugSampleDataService {
  const DebugSampleDataService();

  /// Generates ~60 days of realistic sessions showing steady performance improvement,
  /// and updates skill_ratings accordingly.
  static Future<int> generateSampleHistory({
    required SessionRepository sessionRepo,
    required AttemptRepository attemptRepo,
    SkillRepository? skillRepo,
    required Topic topic,
    required Difficulty difficulty,
    required PracticeMode mode,
    required int modeValue,
  }) async {
    if (!kDebugMode) return 0;

    final repoSkill = skillRepo ?? SkillRepository();
    final skillEngine = const SkillEngine();
    final targetTimeMs = AppConstants.getTargetTimeMs(topic, difficulty);

    // Load or initialize current skill rating
    SkillRating runningRating = await repoSkill.getOrCreateRating(topic, difficulty);

    final now = DateTime.now();
    final random = Random(42);
    int count = 0;

    for (var day = 60; day >= 0; day--) {
      // 1 to 2 sessions per day
      final sessionsThisDay = 1 + (day % 3 == 0 ? 1 : 0);

      for (var s = 0; s < sessionsThisDay; s++) {
        final progressFactor = (60 - day) / 60.0; // 0.0 (day 60 ago) -> 1.0 (today)

        // Accuracy improves from ~65-75% up to ~90-98%
        final baseAcc = 0.68 + (0.26 * progressFactor);
        final accuracy = (baseAcc + (random.nextDouble() * 0.06 - 0.03)).clamp(0.5, 1.0);

        // Avg time improves (decreases) from ~4200ms down to ~1800ms
        final baseTime = 4200.0 - (2400.0 * progressFactor);
        final avgTimeMs = baseTime + (random.nextDouble() * 400.0 - 200.0);

        // Score improves from ~120 up to ~320
        final baseScore = 120.0 + (200.0 * progressFactor);
        final score = baseScore + (random.nextDouble() * 30.0 - 15.0);

        final totalQ = mode == PracticeMode.questions ? modeValue : (modeValue * 1000 / avgTimeMs).round();
        final correctCount = (totalQ * accuracy).round();
        final wrongCount = totalQ - correctCount;

        final sessionDate = now.subtract(Duration(days: day, hours: 2 + s * 4));

        final session = Session(
          topic: topic,
          difficulty: difficulty,
          mode: mode,
          modeValue: modeValue,
          startedAt: sessionDate,
          durationMs: (totalQ * avgTimeMs).round(),
          totalQuestions: totalQ,
          correctCount: correctCount,
          wrongCount: wrongCount,
          skippedCount: 0,
          accuracy: accuracy,
          avgTimeMs: avgTimeMs,
          score: score,
          completed: true,
        );

        final sessionId = await sessionRepo.insertSession(session);
        count++;

        // Add dummy attempts for session detail view and feed skill engine
        final attempts = <Attempt>[];
        for (var i = 0; i < totalQ; i++) {
          final isCorrect = i < correctCount;
          final timeMs = (avgTimeMs + (random.nextDouble() * 1000 - 500)).round().clamp(500, 10000);
          final attemptCreatedAt = sessionDate.add(Duration(seconds: i * 3));

          attempts.add(Attempt(
            sessionId: sessionId,
            topic: topic,
            difficulty: difficulty,
            questionText: 'Question #${i + 1}',
            operandA: '${i + 10}',
            operandB: '${i + 2}',
            correctAnswer: (i + 10) + (i + 2),
            userAnswer: isCorrect ? (i + 10) + (i + 2) : 999,
            isCorrect: isCorrect,
            isSkipped: false,
            timeMs: timeMs,
            createdAt: attemptCreatedAt,
          ));

          // Update skill rating with the exact same engine logic
          final outcome = skillEngine.calculateOutcomeScore(
            isCorrect: isCorrect,
            isSkipped: false,
            timeMs: timeMs,
            targetTimeMs: targetTimeMs,
          );
          runningRating = skillEngine.updateRating(
            runningRating,
            outcome,
            timeMsIfCorrect: isCorrect ? timeMs : null,
            now: attemptCreatedAt,
          );
        }
        await attemptRepo.insertAttempts(attempts);
      }
    }

    // Save final updated rating
    await repoSkill.saveRating(runningRating);

    // Seed varied report sections (strong, weak, improving, slipping, neglected)
    await _seedVariedReportData(sessionRepo, attemptRepo, repoSkill);

    // Seed ~15 sample mistakes across stages 0, 1, 2
    await seedSampleMistakes();

    return count;
  }

  /// Seeds ~15 realistic sample mistakes (stages 0, 1, 2) across topics and sources.
  static Future<void> seedSampleMistakes() async {
    if (!kDebugMode) return;
    final db = await DatabaseHelper.instance.database;

    // Check if mistake bank is empty
    final existing = await db.rawQuery('SELECT COUNT(*) as count FROM ${DatabaseHelper.tableMistakeBank}');
    final count = (existing.first['count'] as num?)?.toInt() ?? 0;
    if (count > 0) return;

    final now = DateTime.now();
    final sampleMistakes = [
      // Stage 0 (5 mistakes, streak 0)
      MistakeEntry(
        topic: Topic.multiplication,
        difficulty: Difficulty.hard,
        questionText: '17 × 19',
        operands: const [17, 19],
        correctAnswer: 323,
        stage: 0,
        correctStreak: 0,
        wrongCount: 2,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 4)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.addition,
        difficulty: Difficulty.medium,
        questionText: '78 + 69',
        operands: const [78, 69],
        correctAnswer: 147,
        stage: 0,
        correctStreak: 0,
        wrongCount: 1,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 3)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.cubes,
        difficulty: Difficulty.medium,
        questionText: '14³',
        operands: const [14],
        correctAnswer: 2744,
        stage: 0,
        correctStreak: 0,
        wrongCount: 3,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 2)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.squareRoots,
        difficulty: Difficulty.hard,
        questionText: '√784',
        operands: const [784],
        correctAnswer: 28,
        stage: 0,
        correctStreak: 0,
        wrongCount: 1,
        source: MistakeSource.slow,
        addedAt: now.subtract(const Duration(days: 1)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.subtraction,
        difficulty: Difficulty.hard,
        questionText: '152 - 87',
        operands: const [152, 87],
        correctAnswer: 65,
        stage: 0,
        correctStreak: 0,
        wrongCount: 1,
        source: MistakeSource.skipped,
        addedAt: now.subtract(const Duration(hours: 12)),
        dueCounter: 0,
      ),

      // Stage 1 (5 mistakes, streak 1)
      MistakeEntry(
        topic: Topic.squares,
        difficulty: Difficulty.medium,
        questionText: '23²',
        operands: const [23],
        correctAnswer: 529,
        stage: 1,
        correctStreak: 1,
        wrongCount: 1,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 6)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.cubeRoots,
        difficulty: Difficulty.medium,
        questionText: '∛3375',
        operands: const [3375],
        correctAnswer: 15,
        stage: 1,
        correctStreak: 1,
        wrongCount: 2,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 5)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.exponents,
        difficulty: Difficulty.medium,
        questionText: '7⁴',
        operands: const [7, 4],
        correctAnswer: 2401,
        stage: 1,
        correctStreak: 1,
        wrongCount: 1,
        source: MistakeSource.slow,
        addedAt: now.subtract(const Duration(days: 4)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.division,
        difficulty: Difficulty.medium,
        questionText: '198 ÷ 6',
        operands: const [198, 6],
        correctAnswer: 33,
        stage: 1,
        correctStreak: 1,
        wrongCount: 1,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 3)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.multiplication,
        difficulty: Difficulty.medium,
        questionText: '14 × 16',
        operands: const [14, 16],
        correctAnswer: 224,
        stage: 1,
        correctStreak: 1,
        wrongCount: 2,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 2)),
        dueCounter: 0,
      ),

      // Stage 2 (5 mistakes, streak 2)
      MistakeEntry(
        topic: Topic.cubes,
        difficulty: Difficulty.easy,
        questionText: '8³',
        operands: const [8],
        correctAnswer: 512,
        stage: 2,
        correctStreak: 2,
        wrongCount: 1,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 10)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.squares,
        difficulty: Difficulty.easy,
        questionText: '19²',
        operands: const [19],
        correctAnswer: 361,
        stage: 2,
        correctStreak: 2,
        wrongCount: 1,
        source: MistakeSource.slow,
        addedAt: now.subtract(const Duration(days: 8)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.addition,
        difficulty: Difficulty.hard,
        questionText: '347 + 588',
        operands: const [347, 588],
        correctAnswer: 935,
        stage: 2,
        correctStreak: 2,
        wrongCount: 2,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 7)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.squareRoots,
        difficulty: Difficulty.medium,
        questionText: '√1521',
        operands: const [1521],
        correctAnswer: 39,
        stage: 2,
        correctStreak: 2,
        wrongCount: 1,
        source: MistakeSource.wrong,
        addedAt: now.subtract(const Duration(days: 6)),
        dueCounter: 0,
      ),
      MistakeEntry(
        topic: Topic.exponents,
        difficulty: Difficulty.easy,
        questionText: '3⁵',
        operands: const [3, 5],
        correctAnswer: 243,
        stage: 2,
        correctStreak: 2,
        wrongCount: 1,
        source: MistakeSource.skipped,
        addedAt: now.subtract(const Duration(days: 5)),
        dueCounter: 0,
      ),
    ];

    final batch = db.batch();
    for (final m in sampleMistakes) {
      batch.insert(DatabaseHelper.tableMistakeBank, m.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Seeds varied data (strong, weak, improving, slipping, neglected) across standard topics
  /// to ensure every Performance Report section has data to display in debug mode.
  static Future<void> _seedVariedReportData(
    SessionRepository sessionRepo,
    AttemptRepository attemptRepo,
    SkillRepository repoSkill,
  ) async {
    final now = DateTime.now();

    // 1. Strong Area: Addition Easy (Mastery 0.92, 35 attempts)
    await repoSkill.saveRating(SkillRating(
      topic: Topic.addition,
      difficulty: Difficulty.easy,
      mastery: 0.92,
      attemptsCount: 35,
      accuracyEma: 0.94,
      avgTimeMsEma: 1800.0,
      lastPracticedAt: now.subtract(const Duration(hours: 4)),
    ));

    // 2. Weak Area: Division Hard (Mastery 0.42, 15 attempts)
    await repoSkill.saveRating(SkillRating(
      topic: Topic.division,
      difficulty: Difficulty.hard,
      mastery: 0.42,
      attemptsCount: 15,
      accuracyEma: 0.52,
      avgTimeMsEma: 6800.0,
      lastPracticedAt: now.subtract(const Duration(days: 1)),
    ));

    // 3. Neglected Topic: Subtraction Medium (last practiced 10 days ago)
    final subDate = now.subtract(const Duration(days: 10));
    await repoSkill.saveRating(SkillRating(
      topic: Topic.subtraction,
      difficulty: Difficulty.medium,
      mastery: 0.68,
      attemptsCount: 20,
      accuracyEma: 0.82,
      avgTimeMsEma: 2600.0,
      lastPracticedAt: subDate,
    ));

    final subSession = Session(
      topic: Topic.subtraction,
      difficulty: Difficulty.medium,
      mode: PracticeMode.timer,
      modeValue: 120,
      startedAt: subDate,
      durationMs: 120000,
      totalQuestions: 20,
      correctCount: 16,
      wrongCount: 4,
      skippedCount: 0,
      accuracy: 0.80,
      avgTimeMs: 2600.0,
      score: 180.0,
      completed: true,
    );
    final subSessionId = await sessionRepo.insertSession(subSession);
    final subAttempts = List.generate(20, (i) => Attempt(
      sessionId: subSessionId,
      topic: Topic.subtraction,
      difficulty: Difficulty.medium,
      questionText: '54 - 2${i + 1}',
      operandA: '54',
      operandB: '2${i + 1}',
      correctAnswer: 54 - (20 + i + 1),
      userAnswer: i < 16 ? 54 - (20 + i + 1) : 0,
      isCorrect: i < 16,
      isSkipped: false,
      timeMs: 2600,
      createdAt: subDate.add(Duration(seconds: i * 5)),
    ));
    await attemptRepo.insertAttempts(subAttempts);

    // 4. Improving Topic: Multiplication Easy
    // Previous window (10 days ago): 20 questions, 3800ms avg, 75% accuracy
    final prevMultDate = now.subtract(const Duration(days: 10));
    final prevMultSession = Session(
      topic: Topic.multiplication,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 20,
      startedAt: prevMultDate,
      durationMs: 76000,
      totalQuestions: 20,
      correctCount: 15,
      wrongCount: 5,
      skippedCount: 0,
      accuracy: 0.75,
      avgTimeMs: 3800.0,
      score: 160.0,
      completed: true,
    );
    final prevMultId = await sessionRepo.insertSession(prevMultSession);
    final prevMultAttempts = List.generate(20, (i) => Attempt(
      sessionId: prevMultId,
      topic: Topic.multiplication,
      difficulty: Difficulty.easy,
      questionText: '1${i + 2} * 6',
      operandA: '1${i + 2}',
      operandB: '6',
      correctAnswer: (12 + i) * 6,
      userAnswer: i < 15 ? (12 + i) * 6 : 0,
      isCorrect: i < 15,
      isSkipped: false,
      timeMs: 3800,
      createdAt: prevMultDate.add(Duration(seconds: i * 4)),
    ));
    await attemptRepo.insertAttempts(prevMultAttempts);

    // Current window (2 days ago): 20 questions, 2800ms avg (26% faster), 90% accuracy
    final currMultDate = now.subtract(const Duration(days: 2));
    final currMultSession = Session(
      topic: Topic.multiplication,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 20,
      startedAt: currMultDate,
      durationMs: 56000,
      totalQuestions: 20,
      correctCount: 18,
      wrongCount: 2,
      skippedCount: 0,
      accuracy: 0.90,
      avgTimeMs: 2800.0,
      score: 220.0,
      completed: true,
    );
    final currMultId = await sessionRepo.insertSession(currMultSession);
    final currMultAttempts = List.generate(20, (i) => Attempt(
      sessionId: currMultId,
      topic: Topic.multiplication,
      difficulty: Difficulty.easy,
      questionText: '1${i + 2} * 7',
      operandA: '1${i + 2}',
      operandB: '7',
      correctAnswer: (12 + i) * 7,
      userAnswer: i < 18 ? (12 + i) * 7 : 0,
      isCorrect: i < 18,
      isSkipped: false,
      timeMs: 2800,
      createdAt: currMultDate.add(Duration(seconds: i * 3)),
    ));
    await attemptRepo.insertAttempts(currMultAttempts);

    await repoSkill.saveRating(SkillRating(
      topic: Topic.multiplication,
      difficulty: Difficulty.easy,
      mastery: 0.78,
      attemptsCount: 40,
      accuracyEma: 0.88,
      avgTimeMsEma: 2800.0,
      lastPracticedAt: currMultDate,
    ));

    // 5. Slipping Topic: Squares Easy
    // Previous window (9 days ago): 20 questions, 2200ms avg, 95% accuracy
    final prevSqDate = now.subtract(const Duration(days: 9));
    final prevSqSession = Session(
      topic: Topic.squares,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 20,
      startedAt: prevSqDate,
      durationMs: 44000,
      totalQuestions: 20,
      correctCount: 19,
      wrongCount: 1,
      skippedCount: 0,
      accuracy: 0.95,
      avgTimeMs: 2200.0,
      score: 240.0,
      completed: true,
    );
    final prevSqId = await sessionRepo.insertSession(prevSqSession);
    final prevSqAttempts = List.generate(20, (i) => Attempt(
      sessionId: prevSqId,
      topic: Topic.squares,
      difficulty: Difficulty.easy,
      questionText: '${i + 1}²',
      operandA: '${i + 1}',
      operandB: '2',
      correctAnswer: (i + 1) * (i + 1),
      userAnswer: i < 19 ? (i + 1) * (i + 1) : 0,
      isCorrect: i < 19,
      isSkipped: false,
      timeMs: 2200,
      createdAt: prevSqDate.add(Duration(seconds: i * 3)),
    ));
    await attemptRepo.insertAttempts(prevSqAttempts);

    // Current window (1 day ago): 20 questions, 2900ms avg (31% slower), 75% accuracy
    final currSqDate = now.subtract(const Duration(days: 1));
    final currSqSession = Session(
      topic: Topic.squares,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 20,
      startedAt: currSqDate,
      durationMs: 58000,
      totalQuestions: 20,
      correctCount: 15,
      wrongCount: 5,
      skippedCount: 0,
      accuracy: 0.75,
      avgTimeMs: 2900.0,
      score: 160.0,
      completed: true,
    );
    final currSqId = await sessionRepo.insertSession(currSqSession);
    final currSqAttempts = List.generate(20, (i) => Attempt(
      sessionId: currSqId,
      topic: Topic.squares,
      difficulty: Difficulty.easy,
      questionText: '${i + 1}²',
      operandA: '${i + 1}',
      operandB: '2',
      correctAnswer: (i + 1) * (i + 1),
      userAnswer: i < 15 ? (i + 1) * (i + 1) : 0,
      isCorrect: i < 15,
      isSkipped: false,
      timeMs: 2900,
      createdAt: currSqDate.add(Duration(seconds: i * 3)),
    ));
    await attemptRepo.insertAttempts(currSqAttempts);

    await repoSkill.saveRating(SkillRating(
      topic: Topic.squares,
      difficulty: Difficulty.easy,
      mastery: 0.62,
      attemptsCount: 40,
      accuracyEma: 0.76,
      avgTimeMsEma: 2900.0,
      lastPracticedAt: currSqDate,
    ));
  }

  /// Clears all database records including skill ratings and mistake bank (debug only).
  static Future<void> clearAllSampleData() async {
    if (!kDebugMode) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete(DatabaseHelper.tableAttempts);
    await db.delete(DatabaseHelper.tableSessions);
    await db.delete(SkillRepository.tableSkillRatings);
    await db.delete(DatabaseHelper.tableMistakeBank);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('smart_question_counter');
    await prefs.remove('speed_math_todays_plan_date');
    await prefs.remove('speed_math_todays_plan_blocks');
  }
}
