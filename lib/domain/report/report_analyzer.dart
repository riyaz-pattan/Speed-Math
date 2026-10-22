import 'package:sqflite/sqflite.dart';
import '../../core/enums/enums.dart';
import '../../data/db/database_helper.dart';
import '../../data/repositories/skill_repository.dart';
import '../adaptive/skill_engine.dart';
import '../adaptive/skill_rating.dart';
import 'report_constants.dart';
import 'report_data.dart';

/// Pure Dart analyzer for generating comprehensive performance reports.
///
/// Uses efficient SQL aggregates without loading all raw attempt rows into memory.
/// Completely decoupled from UI with injectable date for deterministic testing.
class ReportAnalyzer {
  final DatabaseHelper _dbHelper;
  final SkillEngine _skillEngine;

  ReportAnalyzer({
    DatabaseHelper? dbHelper,
    SkillEngine? skillEngine,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _skillEngine = skillEngine ?? const SkillEngine();

  /// Analyzes the SQLite database and produces a structured [ReportData] object.
  ///
  /// [today] can be injected in tests to analyze relative to any arbitrary date.
  Future<ReportData> generateReport({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final db = await _dbHelper.database;

    // Define 7-day comparison window boundaries
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final currentWindowStart =
        todayStart.subtract(const Duration(days: ReportConstants.windowDays));
    final previousWindowStart =
        currentWindowStart.subtract(const Duration(days: ReportConstants.windowDays));

    final currentStartIso = currentWindowStart.toIso8601String();
    final currentEndIso = tomorrowStart.toIso8601String();
    final previousStartIso = previousWindowStart.toIso8601String();
    final previousEndIso = currentStartIso;

    // 1. Total questions answered all time
    final totalQuestionsAllTime = await _getTotalQuestionsAllTime(db);

    // 2. Fetch all skill ratings for standard topics
    final allRatings = await _getAllStandardSkillRatings(db);

    // 3. Compute Overall Speed Score
    final (speedScore, speedScoreLabel, answersNeeded) = _computeSpeedScore(allRatings);

    // 4. Compute Weekly Summaries (current window vs previous window)
    final weeklyComparison = await _computeWeeklyComparison(
      db,
      currentStartIso: currentStartIso,
      currentEndIso: currentEndIso,
      previousStartIso: previousStartIso,
      previousEndIso: previousEndIso,
    );

    // 5. Per-topic Performance and Trend Analysis
    final topicPerformances = await _analyzeTopicPerformances(
      db,
      allRatings: allRatings,
      today: todayStart,
      currentStartIso: currentStartIso,
      currentEndIso: currentEndIso,
      previousStartIso: previousStartIso,
      previousEndIso: previousEndIso,
    );

    // 6. Strong and Weak Areas
    final strongAreas = _extractStrongAreas(allRatings);
    final weakAreas = _extractWeakAreas(allRatings);

    // 7. Neglected and Never Practiced Topics
    final neglectedTopics = <Topic>[];
    final neverPracticedTopics = <Topic>[];
    for (final tp in topicPerformances) {
      if (tp.isNeverPracticed) {
        neverPracticedTopics.add(tp.topic);
      } else if (tp.isNeglected) {
        neglectedTopics.add(tp.topic);
      }
    }

    // 8. Mistake Bank Summary
    final mistakeSummary = await _getMistakeSummary(db);

    return ReportData(
      generatedAt: now,
      totalQuestionsAllTime: totalQuestionsAllTime,
      overallSpeedScore: speedScore,
      speedScoreLabel: speedScoreLabel,
      answersNeededForSpeedScore: answersNeeded,
      weeklyComparison: weeklyComparison,
      topicPerformances: topicPerformances,
      strongAreas: strongAreas,
      weakAreas: weakAreas,
      neglectedTopics: neglectedTopics,
      neverPracticedTopics: neverPracticedTopics,
      mistakeSummary: mistakeSummary,
    );
  }

  /// Total questions answered all time (correct or wrong, NOT skipped) across all modes.
  Future<int> _getTotalQuestionsAllTime(Database db) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableAttempts} WHERE COALESCE(is_skipped, 0) = 0',
    );
    if (result.isNotEmpty) {
      return (result.first['count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  /// Retrieves all skill ratings for the 9 standard topics.
  Future<List<SkillRating>> _getAllStandardSkillRatings(Database db) async {
    final rows = await db.query(SkillRepository.tableSkillRatings);
    final list = <SkillRating>[];
    for (final r in rows) {
      try {
        final rating = SkillRating.fromMap(r);
        if (rating.topic != Topic.mixed &&
            rating.difficulty != Difficulty.mixed) {
          list.add(rating);
        }
      } catch (_) {}
    }
    return list;
  }

  /// Computes the Overall Speed Score (0-100) and its label.
  ///
  /// Weighted average of mastery over all topic+difficulty buckets with at least 5 attempts:
  /// weight = min(attempts, 50).
  /// If no buckets have >= 5 attempts, returns (null, null, answersNeeded).
  (double?, SpeedScoreLabel?, int) _computeSpeedScore(List<SkillRating> ratings) {
    double weightedMasterySum = 0.0;
    int totalWeight = 0;
    int maxAttempts = 0;

    for (final r in ratings) {
      if (r.attemptsCount > maxAttempts) {
        maxAttempts = r.attemptsCount;
      }
      if (r.attemptsCount >= ReportConstants.speedScoreMinAttemptsPerBucket) {
        final weight = r.attemptsCount < ReportConstants.speedScoreMaxWeightPerBucket
            ? r.attemptsCount
            : ReportConstants.speedScoreMaxWeightPerBucket;
        weightedMasterySum += r.mastery * weight;
        totalWeight += weight;
      }
    }

    final answersNeeded = (ReportConstants.speedScoreMinAttemptsPerBucket - maxAttempts)
        .clamp(0, ReportConstants.speedScoreMinAttemptsPerBucket);

    if (totalWeight == 0) {
      return (null, null, answersNeeded);
    }

    final score = (weightedMasterySum / totalWeight) * 100.0;
    final clampedScore = score.clamp(0.0, 100.0);
    final label = SpeedScoreLabel.fromScore(clampedScore);
    return (clampedScore, label, 0);
  }

  /// Extracts up to 3 Strong areas (mastery >= 0.80), ordered by mastery DESC.
  List<SkillBucketSummary> _extractStrongAreas(List<SkillRating> ratings) {
    final candidates = ratings
        .where((r) => r.mastery >= ReportConstants.strongAreaMasteryThreshold)
        .toList()
      ..sort((a, b) {
        final cmp = b.mastery.compareTo(a.mastery);
        if (cmp != 0) return cmp;
        return b.attemptsCount.compareTo(a.attemptsCount);
      });

    return candidates.take(ReportConstants.maxStrongAreas).map((r) {
      return SkillBucketSummary(
        topic: r.topic,
        difficulty: r.difficulty,
        mastery: r.mastery,
        attempts: r.attemptsCount,
        level: _skillEngine.classifyBucket(r),
      );
    }).toList();
  }

  /// Extracts up to 3 Weak areas (attempts >= 5, mastery < 0.65), ordered by mastery ASC.
  List<SkillBucketSummary> _extractWeakAreas(List<SkillRating> ratings) {
    final candidates = ratings
        .where((r) =>
            r.attemptsCount >= ReportConstants.weakAreaMinAttempts &&
            r.mastery < ReportConstants.weakAreaMasteryMax)
        .toList()
      ..sort((a, b) {
        final cmp = a.mastery.compareTo(b.mastery);
        if (cmp != 0) return cmp;
        return b.attemptsCount.compareTo(a.attemptsCount);
      });

    return candidates.take(ReportConstants.maxWeakAreas).map((r) {
      return SkillBucketSummary(
        topic: r.topic,
        difficulty: r.difficulty,
        mastery: r.mastery,
        attempts: r.attemptsCount,
        level: _skillEngine.classifyBucket(r),
      );
    }).toList();
  }

  /// Aggregates sessions and attempts for the two 7-day windows using SQL.
  Future<WeeklyComparison> _computeWeeklyComparison(
    Database db, {
    required String currentStartIso,
    required String currentEndIso,
    required String previousStartIso,
    required String previousEndIso,
  }) async {
    final currentStats = await _aggregateWindowStats(
      db,
      startIso: currentStartIso,
      endIso: currentEndIso,
    );

    final previousStats = await _aggregateWindowStats(
      db,
      startIso: previousStartIso,
      endIso: previousEndIso,
    );

    return WeeklyComparison(
      currentWindow: currentStats,
      previousWindow: previousStats,
    );
  }

  /// Computes aggregate statistics for sessions and attempts within [startIso, endIso).
  Future<WeeklyWindowStats> _aggregateWindowStats(
    Database db, {
    required String startIso,
    required String endIso,
  }) async {
    // Session-level aggregates
    final sessionRows = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as session_count,
        COALESCE(SUM(total_questions), 0) as total_q,
        COALESCE(SUM(correct_count), 0) as total_c,
        COALESCE(SUM(wrong_count), 0) as total_w,
        COALESCE(SUM(skipped_count), 0) as total_s,
        COALESCE(SUM(duration_ms), 0) as total_duration
      FROM ${DatabaseHelper.tableSessions}
      WHERE completed = 1
        AND started_at >= ?
        AND started_at < ?
      ''',
      [startIso, endIso],
    );

    int sessionCount = 0;
    int totalQ = 0;
    int totalC = 0;
    int totalW = 0;
    int totalS = 0;
    int totalDurationMs = 0;

    if (sessionRows.isNotEmpty) {
      final row = sessionRows.first;
      sessionCount = (row['session_count'] as num?)?.toInt() ?? 0;
      totalQ = (row['total_q'] as num?)?.toInt() ?? 0;
      totalC = (row['total_c'] as num?)?.toInt() ?? 0;
      totalW = (row['total_w'] as num?)?.toInt() ?? 0;
      totalS = (row['total_s'] as num?)?.toInt() ?? 0;
      totalDurationMs = (row['total_duration'] as num?)?.toInt() ?? 0;
    }

    // Average time per correct answer across attempts in this window
    final attemptRows = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as correct_count,
        COALESCE(SUM(time_ms), 0) as total_time
      FROM ${DatabaseHelper.tableAttempts}
      WHERE is_correct = 1
        AND is_skipped = 0
        AND created_at >= ?
        AND created_at < ?
      ''',
      [startIso, endIso],
    );

    double avgTimeMs = 0.0;
    if (attemptRows.isNotEmpty) {
      final cCount = (attemptRows.first['correct_count'] as num?)?.toInt() ?? 0;
      final tTime = (attemptRows.first['total_time'] as num?)?.toDouble() ?? 0.0;
      if (cCount > 0) {
        avgTimeMs = tTime / cCount;
      }
    }

    final totalAnswered = totalC + totalW + totalS;
    final accuracy = totalAnswered > 0 ? (totalC / totalAnswered) : 0.0;
    final practiceMinutes = totalDurationMs / 60000.0;

    return WeeklyWindowStats(
      sessionsCount: sessionCount,
      questionsAnswered: totalQ,
      correctCount: totalC,
      wrongCount: totalW,
      skippedCount: totalS,
      practiceMinutes: practiceMinutes,
      accuracy: accuracy.clamp(0.0, 1.0),
      avgTimeMsPerCorrect: avgTimeMs,
    );
  }

  /// Analyzes all 9 standard math topics for level, accuracy, time, and trend.
  Future<List<TopicPerformance>> _analyzeTopicPerformances(
    Database db, {
    required List<SkillRating> allRatings,
    required DateTime today,
    required String currentStartIso,
    required String currentEndIso,
    required String previousStartIso,
    required String previousEndIso,
  }) async {
    final list = <TopicPerformance>[];

    // Map ratings by topic and difficulty
    final Map<Topic, Map<Difficulty, SkillRating>> ratingsByTopic = {};
    for (final r in allRatings) {
      ratingsByTopic.putIfAbsent(r.topic, () => {})[r.difficulty] = r;
    }

    for (final topic in Topic.standardTopics) {
      final topicRatings = ratingsByTopic[topic] ?? {};

      // Find the best-attempted difficulty (highest attempts count)
      Difficulty bestDifficulty = Difficulty.easy;
      int maxAttempts = -1;
      SkillRating? bestRating;

      for (final diff in [Difficulty.easy, Difficulty.medium, Difficulty.hard]) {
        final r = topicRatings[diff];
        final attempts = r?.attemptsCount ?? 0;
        if (attempts > maxAttempts) {
          maxAttempts = attempts;
          bestDifficulty = diff;
          bestRating = r;
        }
      }

      final level = bestRating != null
          ? _skillEngine.classifyBucket(bestRating)
          : SkillBucketLevel.notEnoughData;

      // Build per-difficulty summary map
      final perDiffMap = <Difficulty, SkillBucketSummary>{};
      DateTime? latestPracticedAt;

      for (final diff in [Difficulty.easy, Difficulty.medium, Difficulty.hard]) {
        final r = topicRatings[diff] ?? SkillRating(topic: topic, difficulty: diff);
        perDiffMap[diff] = SkillBucketSummary(
          topic: topic,
          difficulty: diff,
          mastery: r.mastery,
          attempts: r.attemptsCount,
          level: _skillEngine.classifyBucket(r),
        );
        if (r.lastPracticedAt != null) {
          if (latestPracticedAt == null ||
              r.lastPracticedAt!.isAfter(latestPracticedAt)) {
            latestPracticedAt = r.lastPracticedAt;
          }
        }
      }

      // Overall attempts, accuracy, avg time, and latest attempt from attempts table
      final overallRows = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_attempts,
          SUM(CASE WHEN is_correct = 1 AND is_skipped = 0 THEN 1 ELSE 0 END) as correct_c,
          SUM(CASE WHEN is_correct = 1 AND is_skipped = 0 THEN time_ms ELSE 0 END) as correct_time,
          MAX(created_at) as last_attempt_at
        FROM ${DatabaseHelper.tableAttempts}
        WHERE topic = ?
        ''',
        [topic.name],
      );

      int totalAttempts = 0;
      double overallAccuracy = 0.0;
      double overallAvgTimeMs = 0.0;

      if (overallRows.isNotEmpty) {
        final row = overallRows.first;
        totalAttempts = (row['total_attempts'] as num?)?.toInt() ?? 0;
        final correctC = (row['correct_c'] as num?)?.toInt() ?? 0;
        final correctTime = (row['correct_time'] as num?)?.toDouble() ?? 0.0;

        if (totalAttempts > 0) {
          overallAccuracy = (correctC / totalAttempts).clamp(0.0, 1.0);
        }
        if (correctC > 0) {
          overallAvgTimeMs = correctTime / correctC;
        }

        final lastAttemptIso = row['last_attempt_at'] as String?;
        if (lastAttemptIso != null) {
          final dt = DateTime.tryParse(lastAttemptIso);
          if (dt != null &&
              (latestPracticedAt == null || dt.isAfter(latestPracticedAt))) {
            latestPracticedAt = dt;
          }
        }
      }

      // Compute days since last practiced
      int? daysSinceLastPracticed;
      if (latestPracticedAt != null) {
        final lastDay = DateTime(
          latestPracticedAt.year,
          latestPracticedAt.month,
          latestPracticedAt.day,
        );
        daysSinceLastPracticed = today.difference(lastDay).inDays;
        if (daysSinceLastPracticed < 0) daysSinceLastPracticed = 0;
      }

      // Query window stats for this topic
      final currWindowData = await _queryTopicWindowData(
        db,
        topic: topic,
        startIso: currentStartIso,
        endIso: currentEndIso,
      );

      final prevWindowData = await _queryTopicWindowData(
        db,
        topic: topic,
        startIso: previousStartIso,
        endIso: previousEndIso,
      );

      // Evaluate trend based on rules
      final trend = _evaluateTopicTrend(
        currQuestions: currWindowData.questions,
        prevQuestions: prevWindowData.questions,
        currAccuracy: currWindowData.accuracy,
        prevAccuracy: prevWindowData.accuracy,
        currAvgTimeMs: currWindowData.avgTimeMs,
        prevAvgTimeMs: prevWindowData.avgTimeMs,
      );

      list.add(TopicPerformance(
        topic: topic,
        level: level,
        bestDifficulty: bestDifficulty,
        perDifficulty: perDiffMap,
        accuracy: overallAccuracy,
        avgTimeMs: overallAvgTimeMs,
        totalAttempts: totalAttempts,
        daysSinceLastPracticed: daysSinceLastPracticed,
        trend: trend,
        currentWindowQuestions: currWindowData.questions,
        previousWindowQuestions: prevWindowData.questions,
        currentWindowAccuracy: currWindowData.accuracy,
        previousWindowAccuracy: prevWindowData.accuracy,
        currentWindowAvgTimeMs: currWindowData.avgTimeMs,
        previousWindowAvgTimeMs: prevWindowData.avgTimeMs,
      ));
    }

    return list;
  }

  /// Queries answered questions, accuracy, and avg time for a topic in a specific time window.
  Future<({int questions, double accuracy, double avgTimeMs})>
      _queryTopicWindowData(
    Database db, {
    required Topic topic,
    required String startIso,
    required String endIso,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_q,
        SUM(CASE WHEN is_correct = 1 AND is_skipped = 0 THEN 1 ELSE 0 END) as correct_c,
        SUM(CASE WHEN is_correct = 1 AND is_skipped = 0 THEN time_ms ELSE 0 END) as correct_time
      FROM ${DatabaseHelper.tableAttempts}
      WHERE topic = ?
        AND created_at >= ?
        AND created_at < ?
      ''',
      [topic.name, startIso, endIso],
    );

    if (rows.isEmpty) {
      return (questions: 0, accuracy: 0.0, avgTimeMs: 0.0);
    }

    final row = rows.first;
    final totalQ = (row['total_q'] as num?)?.toInt() ?? 0;
    final correctC = (row['correct_c'] as num?)?.toInt() ?? 0;
    final correctTime = (row['correct_time'] as num?)?.toDouble() ?? 0.0;

    final acc = totalQ > 0 ? (correctC / totalQ).clamp(0.0, 1.0) : 0.0;
    final timeMs = correctC > 0 ? (correctTime / correctC) : 0.0;

    return (questions: totalQ, accuracy: acc, avgTimeMs: timeMs);
  }

  /// Evaluates trend according to master rules:
  ///
  /// Requires at least 15 answered questions in EACH of the two windows:
  /// - "Improving" if avg time fell by 8%+ OR accuracy rose by 5 points+ (0.05).
  /// - "Slipping" if time rose by 8%+ OR accuracy fell by 5 points+ (0.05).
  /// - Otherwise "Steady".
  /// - Otherwise "Not enough data".
  TopicTrend _evaluateTopicTrend({
    required int currQuestions,
    required int prevQuestions,
    required double currAccuracy,
    required double prevAccuracy,
    required double currAvgTimeMs,
    required double prevAvgTimeMs,
  }) {
    if (currQuestions < ReportConstants.trendMinQuestionsPerWindow ||
        prevQuestions < ReportConstants.trendMinQuestionsPerWindow) {
      return TopicTrend.notEnoughData;
    }

    final accuracyDiff = currAccuracy - prevAccuracy;
    final hasPrevTime = prevAvgTimeMs > 0 && currAvgTimeMs > 0;

    // Time improvements (time fell by >= 8%)
    final isTimeImproving = hasPrevTime &&
        ((prevAvgTimeMs - currAvgTimeMs) / prevAvgTimeMs) >=
            ReportConstants.trendTimeChangeRatio;

    // Accuracy improvement (rose by >= 5 percentage points)
    final isAccImproving =
        accuracyDiff >= ReportConstants.trendAccuracyPointChange;

    // Time slipping (time rose by >= 8%)
    final isTimeSlipping = hasPrevTime &&
        ((currAvgTimeMs - prevAvgTimeMs) / prevAvgTimeMs) >=
            ReportConstants.trendTimeChangeRatio;

    // Accuracy slipping (fell by >= 5 percentage points)
    final isAccSlipping =
        accuracyDiff <= -ReportConstants.trendAccuracyPointChange;

    final isImproving = isTimeImproving || isAccImproving;
    final isSlipping = isTimeSlipping || isAccSlipping;

    if (isImproving && !isSlipping) {
      return TopicTrend.improving;
    }
    if (isSlipping && !isImproving) {
      return TopicTrend.slipping;
    }
    if (isImproving && isSlipping) {
      // Prioritize accuracy stability if conflicting
      return isAccImproving ? TopicTrend.improving : TopicTrend.slipping;
    }
    return TopicTrend.steady;
  }

  /// Retrieves mistake count and top 3 mistake topics.
  Future<MistakeReportSummary> _getMistakeSummary(Database db) async {
    final countRows = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableMistakeBank}',
    );
    final totalMistakes = countRows.isNotEmpty
        ? ((countRows.first['count'] as num?)?.toInt() ?? 0)
        : 0;

    final topRows = await db.rawQuery(
      '''
      SELECT topic, COUNT(*) as count
      FROM ${DatabaseHelper.tableMistakeBank}
      GROUP BY topic
      ORDER BY count DESC
      LIMIT 3
      ''',
    );

    final topTopics = <({Topic topic, int count})>[];
    for (final row in topRows) {
      final topicStr = row['topic'] as String?;
      final count = (row['count'] as num?)?.toInt() ?? 0;
      if (topicStr != null) {
        final topic = Topic.values.firstWhere(
          (t) => t.name.toLowerCase() == topicStr.toLowerCase(),
          orElse: () => Topic.addition,
        );
        topTopics.add((topic: topic, count: count));
      }
    }

    return MistakeReportSummary(
      totalMistakes: totalMistakes,
      topMistakeTopics: topTopics,
    );
  }
}
