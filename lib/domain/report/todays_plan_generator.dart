import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/enums/enums.dart';
import '../../data/db/database_helper.dart';
import '../../data/models/session.dart';
import '../../features/practice_session/models/practice_models.dart';
import 'report_constants.dart';
import 'report_data.dart';
import 'todays_plan.dart';

/// Pure Dart generator and manager for Today's Plan.
///
/// Builds 3 focused daily blocks (~15 min total), caches the plan per day in
/// SharedPreferences, and evaluates real-time completion based on sessions completed today.
class TodaysPlanGenerator {
  final DatabaseHelper _dbHelper;
  final SharedPreferences? _prefs;

  static const String keyPlanDate = 'speed_math_todays_plan_date';
  static const String keyPlanBlocks = 'speed_math_todays_plan_blocks';

  TodaysPlanGenerator({
    DatabaseHelper? dbHelper,
    SharedPreferences? prefs,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _prefs = prefs;

  /// Retrieves or generates Today's Plan for the specified [today] date.
  ///
  /// If a plan was already generated today, loads cached block configurations
  /// and updates each block's completion state against today's completed sessions.
  Future<TodayPlan> getTodayPlan(ReportData reportData, {DateTime? today}) async {
    final now = today ?? DateTime.now();
    final dateKey = _formatDateKey(now);

    List<PlanBlock> blocks;

    // 1. Check cache
    final cachedDate = _prefs?.getString(keyPlanDate);
    final cachedJson = _prefs?.getString(keyPlanBlocks);

    if (cachedDate == dateKey && cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedJson) as List<dynamic>;
        blocks = decoded
            .map((item) => PlanBlock.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        blocks = _generateNewPlanBlocks(reportData);
        await _cachePlanBlocks(dateKey, blocks);
      }
    } else {
      blocks = _generateNewPlanBlocks(reportData);
      await _cachePlanBlocks(dateKey, blocks);
    }

    // 2. Evaluate completion against today's completed sessions
    final completedBlocks = await _evaluateCompletion(blocks, today: now);

    return TodayPlan(
      date: now,
      blocks: completedBlocks,
    );
  }

  /// Clears the cached plan (called during Reset All Data).
  Future<void> clearCachedPlan() async {
    await _prefs?.remove(keyPlanDate);
    await _prefs?.remove(keyPlanBlocks);
  }

  /// Caches the static plan configuration for today.
  Future<void> _cachePlanBlocks(String dateKey, List<PlanBlock> blocks) async {
    final jsonList = blocks.map((b) => b.toMap()).toList();
    await _prefs?.setString(keyPlanDate, dateKey);
    await _prefs?.setString(keyPlanBlocks, jsonEncode(jsonList));
  }

  /// Generates 3 practice blocks following the master rules.
  List<PlanBlock> _generateNewPlanBlocks(ReportData reportData) {
    // Collect all standard topic+difficulty candidates
    final candidates = <({Topic topic, Difficulty difficulty, double mastery, int attempts})>[];

    for (final tp in reportData.topicPerformances) {
      for (final diff in [Difficulty.easy, Difficulty.medium, Difficulty.hard]) {
        final bucket = tp.perDifficulty[diff];
        if (bucket != null) {
          candidates.add((
            topic: bucket.topic,
            difficulty: bucket.difficulty,
            mastery: bucket.mastery,
            attempts: bucket.attempts,
          ));
        } else {
          candidates.add((
            topic: tp.topic,
            difficulty: diff,
            mastery: 0.50,
            attempts: 0,
          ));
        }
      }
    }

    // Sort: lowest mastery first; if tie, higher attempts first
    candidates.sort((a, b) {
      final cmp = a.mastery.compareTo(b.mastery);
      if (cmp != 0) return cmp;
      return b.attempts.compareTo(a.attempts);
    });

    // Block 1: Weakest bucket
    final b1 = candidates.isNotEmpty
        ? candidates.first
        : (topic: Topic.addition, difficulty: Difficulty.easy, mastery: 0.5, attempts: 0);

    final b1Reason = b1.attempts >= 5 && b1.mastery < ReportConstants.weakAreaMasteryMax
        ? 'Your lowest mastery topic (${(b1.mastery * 100).round()}% mastery)'
        : 'Target your fastest area to build calculation speed';

    final block1 = PlanBlock(
      id: 1,
      type: PlanBlockType.weakness,
      title: '${b1.topic.displayName} • ${b1.difficulty.displayName}',
      reason: b1Reason,
      config: PracticeConfig(
        topic: b1.topic,
        difficulty: b1.difficulty,
        mode: PracticeMode.timer,
        modeValue: ReportConstants.planTimerDurationSeconds,
        sessionSeed: 0,
      ),
    );

    // Block 2: Second weakest bucket, with a different topic if possible
    final differentTopicCandidates =
        candidates.where((c) => c.topic != b1.topic).toList();
    final b2 = differentTopicCandidates.isNotEmpty
        ? differentTopicCandidates.first
        : (candidates.length > 1
            ? candidates[1]
            : (topic: Topic.multiplication, difficulty: Difficulty.easy, mastery: 0.5, attempts: 0));

    final b2Reason = b2.attempts >= 5 && b2.mastery < ReportConstants.weakAreaMasteryMax
        ? 'Second weakest area (${(b2.mastery * 100).round()}% mastery)'
        : 'Build breadth across key topics';

    final block2 = PlanBlock(
      id: 2,
      type: PlanBlockType.weakness,
      title: '${b2.topic.displayName} • ${b2.difficulty.displayName}',
      reason: b2Reason,
      config: PracticeConfig(
        topic: b2.topic,
        difficulty: b2.difficulty,
        mode: PracticeMode.timer,
        modeValue: ReportConstants.planTimerDurationSeconds,
        sessionSeed: 0,
      ),
    );

    // Block 3:
    // a) Mistake Practice if bank has any mistakes
    // b) Else if user has weak areas, third weakest bucket
    // c) Else "Keep it sharp" Smart Practice (20 questions)
    final PlanBlock block3;
    final totalMistakes = reportData.mistakeSummary.totalMistakes;

    if (totalMistakes > 0) {
      block3 = PlanBlock(
        id: 3,
        type: PlanBlockType.mistakes,
        title: 'Clear your mistakes',
        reason: totalMistakes == 1
            ? '1 mistake waiting to be revised'
            : '$totalMistakes mistakes waiting to be revised',
        config: const PracticeConfig(
          topic: Topic.mixed,
          difficulty: Difficulty.mixed,
          mode: PracticeMode.mistakes,
          kind: SessionKind.mistakes,
          modeValue: ReportConstants.planMistakePracticeQuestionCount,
          sessionSeed: 0,
        ),
      );
    } else {
      // Check for third weakest bucket (preferring different topic from block 1 & 2)
      final remainingCandidates = candidates.where((c) =>
          c.topic != b1.topic &&
          c.topic != b2.topic &&
          c.mastery < ReportConstants.weakAreaMasteryMax &&
          c.attempts >= 5).toList();

      final hasThirdWeakBucket = remainingCandidates.isNotEmpty ||
          (reportData.weakAreas.length >= 3);

      if (hasThirdWeakBucket) {
        final b3 = remainingCandidates.isNotEmpty
            ? remainingCandidates.first
            : (candidates.firstWhere(
                (c) =>
                    (c.topic != b1.topic || c.difficulty != b1.difficulty) &&
                    (c.topic != b2.topic || c.difficulty != b2.difficulty),
                orElse: () => candidates.last,
              ));

        block3 = PlanBlock(
          id: 3,
          type: PlanBlockType.weakness,
          title: '${b3.topic.displayName} • ${b3.difficulty.displayName}',
          reason: 'Strengthen your third weakest area',
          config: PracticeConfig(
            topic: b3.topic,
            difficulty: b3.difficulty,
            mode: PracticeMode.timer,
            kind: SessionKind.drill,
            modeValue: ReportConstants.planTimerDurationSeconds,
            sessionSeed: 0,
          ),
        );
      } else {
        block3 = const PlanBlock(
          id: 3,
          type: PlanBlockType.keepSharp,
          title: 'Keep it sharp',
          reason: 'Adaptive mixed drills to maintain speed and precision',
          config: PracticeConfig(
            topic: Topic.mixed,
            difficulty: Difficulty.mixed,
            mode: PracticeMode.questions,
            kind: SessionKind.mixed,
            modeValue: ReportConstants.planSmartPracticeQuestionCount,
            sessionSeed: 0,
          ),
        );
      }
    }

    return [block1, block2, block3];
  }

  /// Evaluates whether each block has been completed today.
  ///
  /// A block is marked Done when a COMPLETED session matching its topic and difficulty
  /// (or a Mistake Practice session for the mistakes block, or Smart Practice for keep-it-sharp)
  /// is saved today.
  Future<List<PlanBlock>> _evaluateCompletion(
    List<PlanBlock> blocks, {
    required DateTime today,
  }) async {
    final todayStart = DateTime(today.year, today.month, today.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableSessions,
      where: 'completed = 1 AND started_at >= ? AND started_at < ?',
      whereArgs: [
        todayStart.toIso8601String(),
        tomorrowStart.toIso8601String(),
      ],
    );

    final sessionsToday = rows.map((r) => Session.fromMap(r)).toList();

    return blocks.map((block) {
      bool isCompleted = false;

      for (final s in sessionsToday) {
        if (block.type == PlanBlockType.mistakes) {
          if (s.kind == SessionKind.mistakes || s.mode == PracticeMode.mistakes) {
            isCompleted = true;
            break;
          }
        } else if (block.type == PlanBlockType.keepSharp) {
          if (s.kind == SessionKind.mixed || s.mode == PracticeMode.smart) {
            isCompleted = true;
            break;
          }
        } else {
          // Weakness block: matches topic and difficulty
          if (s.topic == block.config.topic &&
              s.difficulty == block.config.difficulty) {
            isCompleted = true;
            break;
          }
        }
      }

      return block.copyWith(isCompleted: isCompleted);
    }).toList();
  }

  String _formatDateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
