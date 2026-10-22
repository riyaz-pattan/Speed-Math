import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_engine.dart';
import 'package:speed_math_with_ai/domain/report/report_constants.dart';
import 'package:speed_math_with_ai/domain/report/report_data.dart';
import 'package:speed_math_with_ai/domain/report/todays_plan.dart';
import 'package:speed_math_with_ai/domain/report/todays_plan_generator.dart';
import 'package:sqflite/sqflite.dart';

class _FakePlanDb implements Database {
  final List<Map<String, dynamic>> sessions = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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
    if (table == DatabaseHelper.tableSessions) {
      if (where != null && where.contains('started_at >=')) {
        final startIso = whereArgs![0] as String;
        final endIso = whereArgs[1] as String;
        return sessions.where((s) {
          final st = s['started_at'] as String;
          final completed = (s['completed'] as num?)?.toInt() ?? 0;
          return completed == 1 && st.compareTo(startIso) >= 0 && st.compareTo(endIso) < 0;
        }).toList();
      }
      return sessions;
    }
    return [];
  }
}

void main() {
  late _FakePlanDb fakeDb;
  late SharedPreferences prefs;
  late TodaysPlanGenerator generator;
  final testToday = DateTime(2026, 10, 16);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fakeDb = _FakePlanDb();
    generator = TodaysPlanGenerator(
      dbHelper: DatabaseHelper.withDatabase(fakeDb),
      prefs: prefs,
    );
  });

  ReportData createMockReportData({
    required List<SkillBucketSummary> weakAreas,
    int mistakeCount = 0,
  }) {
    // Populate perDifficulty maps for topic performances
    final topicPerformances = Topic.standardTopics.map((topic) {
      final perDiff = <Difficulty, SkillBucketSummary>{};
      for (final diff in [Difficulty.easy, Difficulty.medium, Difficulty.hard]) {
        // Find if this bucket is in weakAreas
        final matchingWeak = weakAreas.where((w) => w.topic == topic && w.difficulty == diff);
        if (matchingWeak.isNotEmpty) {
          perDiff[diff] = matchingWeak.first;
        } else {
          perDiff[diff] = SkillBucketSummary(
            topic: topic,
            difficulty: diff,
            mastery: 0.75, // Default solid mastery
            attempts: 10,
            level: SkillBucketLevel.gettingThere,
          );
        }
      }
      return TopicPerformance(
        topic: topic,
        level: SkillBucketLevel.gettingThere,
        bestDifficulty: Difficulty.easy,
        perDifficulty: perDiff,
        accuracy: 0.85,
        avgTimeMs: 2500,
        totalAttempts: 30,
        daysSinceLastPracticed: 1,
        trend: TopicTrend.steady,
        currentWindowQuestions: 20,
        previousWindowQuestions: 20,
        currentWindowAccuracy: 0.85,
        previousWindowAccuracy: 0.85,
        currentWindowAvgTimeMs: 2500,
        previousWindowAvgTimeMs: 2500,
      );
    }).toList();

    return ReportData(
      generatedAt: testToday,
      totalQuestionsAllTime: 100,
      overallSpeedScore: 65,
      speedScoreLabel: SpeedScoreLabel.strong,
      weeklyComparison: const WeeklyComparison(
        currentWindow: WeeklyWindowStats(),
        previousWindow: WeeklyWindowStats(),
      ),
      topicPerformances: topicPerformances,
      strongAreas: [],
      weakAreas: weakAreas,
      neglectedTopics: [],
      neverPracticedTopics: [],
      mistakeSummary: MistakeReportSummary(
        totalMistakes: mistakeCount,
      ),
    );
  }

  group('Block Selection Rules', () {
    test('Block 1 and 2 target the two weakest buckets with different topics', () async {
      final report = createMockReportData(
        weakAreas: [
          const SkillBucketSummary(
            topic: Topic.addition,
            difficulty: Difficulty.hard,
            mastery: 0.35,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
          const SkillBucketSummary(
            topic: Topic.addition,
            difficulty: Difficulty.medium,
            mastery: 0.40,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
          const SkillBucketSummary(
            topic: Topic.multiplication,
            difficulty: Difficulty.hard,
            mastery: 0.45,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
        ],
      );

      final plan = await generator.getTodayPlan(report, today: testToday);
      expect(plan.blocks.length, equals(3));

      // Block 1: Addition Hard (lowest mastery 0.35)
      expect(plan.blocks[0].config.topic, equals(Topic.addition));
      expect(plan.blocks[0].config.difficulty, equals(Difficulty.hard));
      expect(plan.blocks[0].config.mode, equals(PracticeMode.timer));
      expect(plan.blocks[0].config.modeValue, equals(ReportConstants.planTimerDurationSeconds));

      // Block 2: Multiplication Hard (different topic from Addition, mastery 0.45)
      expect(plan.blocks[1].config.topic, equals(Topic.multiplication));
      expect(plan.blocks[1].config.difficulty, equals(Difficulty.hard));
      expect(plan.blocks[1].config.mode, equals(PracticeMode.timer));
    });

    test('Block 3 targets Mistake Practice if mistake bank has any mistakes', () async {
      final report = createMockReportData(
        weakAreas: [],
        mistakeCount: 5,
      );

      final plan = await generator.getTodayPlan(report, today: testToday);
      expect(plan.blocks[2].type, equals(PlanBlockType.mistakes));
      expect(plan.blocks[2].title, equals('Clear your mistakes'));
      expect(plan.blocks[2].config.mode, equals(PracticeMode.mistakes));
      expect(plan.blocks[2].config.modeValue, equals(20));
      expect(plan.blocks[2].reason, contains('5 mistakes'));
    });

    test('Block 3 targets third weak bucket when no mistakes but weak areas exist', () async {
      final report = createMockReportData(
        weakAreas: [
          const SkillBucketSummary(
            topic: Topic.addition,
            difficulty: Difficulty.hard,
            mastery: 0.30,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
          const SkillBucketSummary(
            topic: Topic.multiplication,
            difficulty: Difficulty.hard,
            mastery: 0.40,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
          const SkillBucketSummary(
            topic: Topic.division,
            difficulty: Difficulty.medium,
            mastery: 0.50,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
        ],
        mistakeCount: 0,
      );

      final plan = await generator.getTodayPlan(report, today: testToday);
      expect(plan.blocks[2].type, equals(PlanBlockType.weakness));
      expect(plan.blocks[2].config.topic, equals(Topic.division));
      expect(plan.blocks[2].config.difficulty, equals(Difficulty.medium));
      expect(plan.blocks[2].config.mode, equals(PracticeMode.timer));
    });

    test('Block 3 targets Keep It Sharp Smart Practice when no mistakes and no weak areas', () async {
      final report = createMockReportData(
        weakAreas: [],
        mistakeCount: 0,
      );

      final plan = await generator.getTodayPlan(report, today: testToday);
      expect(plan.blocks[2].type, equals(PlanBlockType.keepSharp));
      expect(plan.blocks[2].config.mode, equals(PracticeMode.questions));
      expect(plan.blocks[2].config.kind, equals(SessionKind.mixed));
      expect(plan.blocks[2].config.modeValue, equals(20));
    });
  });

  group('Daily Caching and Done Detection', () {
    test('caches plan for the day and does not change when report data updates', () async {
      final report1 = createMockReportData(
        weakAreas: [
          const SkillBucketSummary(
            topic: Topic.addition,
            difficulty: Difficulty.easy,
            mastery: 0.30,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
        ],
      );

      final plan1 = await generator.getTodayPlan(report1, today: testToday);
      final initialTitle1 = plan1.blocks[0].title;

      // New report with different weaknesses on the SAME day
      final report2 = createMockReportData(
        weakAreas: [
          const SkillBucketSummary(
            topic: Topic.cubes,
            difficulty: Difficulty.hard,
            mastery: 0.10,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
        ],
      );

      final plan2 = await generator.getTodayPlan(report2, today: testToday);
      expect(plan2.blocks[0].title, equals(initialTitle1),
          reason: 'Plan must be cached and not change on the same day');
    });

    test('creates a new plan on a new day', () async {
      final report1 = createMockReportData(
        weakAreas: [
          const SkillBucketSummary(
            topic: Topic.addition,
            difficulty: Difficulty.easy,
            mastery: 0.30,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
        ],
      );

      final plan1 = await generator.getTodayPlan(report1, today: testToday);
      expect(plan1.blocks[0].config.topic, equals(Topic.addition));

      // Tomorrow
      final tomorrow = testToday.add(const Duration(days: 1));
      final report2 = createMockReportData(
        weakAreas: [
          const SkillBucketSummary(
            topic: Topic.cubes,
            difficulty: Difficulty.hard,
            mastery: 0.10,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
        ],
      );

      final planTomorrow = await generator.getTodayPlan(report2, today: tomorrow);
      expect(planTomorrow.blocks[0].config.topic, equals(Topic.cubes),
          reason: 'A new day must generate a fresh plan based on current report data');
    });

    test('detects completed sessions saved today and marks blocks as Done', () async {
      final report = createMockReportData(
        weakAreas: [
          const SkillBucketSummary(
            topic: Topic.addition,
            difficulty: Difficulty.easy,
            mastery: 0.30,
            attempts: 10,
            level: SkillBucketLevel.needsWork,
          ),
        ],
        mistakeCount: 3,
      );

      // Initially no completed sessions
      var plan = await generator.getTodayPlan(report, today: testToday);
      expect(plan.blocks[0].isCompleted, isFalse);
      expect(plan.blocks[2].isCompleted, isFalse);
      expect(plan.completedCount, equals(0));

      // User completes Block 1 (Addition Easy) today
      fakeDb.sessions.add(
        Session(
          id: 1,
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          mode: PracticeMode.timer,
          modeValue: 300,
          startedAt: testToday.add(const Duration(hours: 2)),
          completed: true,
          durationMs: 300000,
          totalQuestions: 25,
          correctCount: 22,
          wrongCount: 3,
          skippedCount: 0,
          accuracy: 0.88,
          avgTimeMs: 2500,
          score: 250,
        ).toMap(),
      );

      plan = await generator.getTodayPlan(report, today: testToday);
      expect(plan.blocks[0].isCompleted, isTrue);
      expect(plan.blocks[1].isCompleted, isFalse);
      expect(plan.blocks[2].isCompleted, isFalse);
      expect(plan.completedCount, equals(1));

      // User completes Block 3 (Mistakes) today
      fakeDb.sessions.add(
        Session(
          id: 2,
          topic: Topic.mixed,
          difficulty: Difficulty.mixed,
          mode: PracticeMode.mistakes,
          modeValue: 20,
          startedAt: testToday.add(const Duration(hours: 3)),
          completed: true,
          durationMs: 60000,
          totalQuestions: 20,
          correctCount: 18,
          wrongCount: 2,
          skippedCount: 0,
          accuracy: 0.90,
          avgTimeMs: 2000,
          score: 180,
        ).toMap(),
      );

      plan = await generator.getTodayPlan(report, today: testToday);
      expect(plan.blocks[0].isCompleted, isTrue);
      expect(plan.blocks[2].isCompleted, isTrue);
      expect(plan.completedCount, equals(2));
    });
  });
}
