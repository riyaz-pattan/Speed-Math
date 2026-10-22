import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/app/theme.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/repositories/report_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_engine.dart';
import 'package:speed_math_with_ai/domain/report/report_data.dart';
import 'package:speed_math_with_ai/domain/report/report_writer.dart';
import 'package:speed_math_with_ai/domain/report/todays_plan.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';
import 'package:speed_math_with_ai/features/report/report_screen.dart';

void main() {
  ReportData createSampleReportData({
    int totalQuestions = 120,
    double? speedScore = 72.0,
    SpeedScoreLabel? speedLabel = SpeedScoreLabel.strong,
    int mistakeCount = 4,
  }) {
    return ReportData(
      generatedAt: DateTime(2026, 10, 16),
      totalQuestionsAllTime: totalQuestions,
      overallSpeedScore: speedScore,
      speedScoreLabel: speedLabel,
      weeklyComparison: const WeeklyComparison(
        currentWindow: WeeklyWindowStats(
          sessionsCount: 7,
          questionsAnswered: 70,
          correctCount: 63,
          wrongCount: 5,
          skippedCount: 2,
          practiceMinutes: 21.0,
          accuracy: 0.90,
          avgTimeMsPerCorrect: 2200,
        ),
        previousWindow: WeeklyWindowStats(
          sessionsCount: 4,
          questionsAnswered: 40,
          correctCount: 32,
          wrongCount: 6,
          skippedCount: 2,
          practiceMinutes: 14.0,
          accuracy: 0.80,
          avgTimeMsPerCorrect: 2600,
        ),
      ),
      topicPerformances: Topic.standardTopics.map((topic) {
        return TopicPerformance(
          topic: topic,
          level: topic == Topic.addition ? SkillBucketLevel.strong : SkillBucketLevel.gettingThere,
          bestDifficulty: Difficulty.easy,
          perDifficulty: {
            Difficulty.easy: SkillBucketSummary(
              topic: topic,
              difficulty: Difficulty.easy,
              mastery: topic == Topic.addition ? 0.92 : 0.65,
              attempts: 20,
              level: topic == Topic.addition ? SkillBucketLevel.strong : SkillBucketLevel.gettingThere,
            ),
          },
          accuracy: 0.88,
          avgTimeMs: 2200,
          totalAttempts: 30,
          daysSinceLastPracticed: 1,
          trend: topic == Topic.addition ? TopicTrend.improving : TopicTrend.steady,
          currentWindowQuestions: 20,
          previousWindowQuestions: 20,
          currentWindowAccuracy: 0.90,
          previousWindowAccuracy: 0.80,
          currentWindowAvgTimeMs: 2200,
          previousWindowAvgTimeMs: 2600,
        );
      }).toList(),
      strongAreas: [
        const SkillBucketSummary(
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          mastery: 0.92,
          attempts: 25,
          level: SkillBucketLevel.strong,
        ),
      ],
      weakAreas: [
        const SkillBucketSummary(
          topic: Topic.division,
          difficulty: Difficulty.hard,
          mastery: 0.42,
          attempts: 10,
          level: SkillBucketLevel.needsWork,
        ),
      ],
      neglectedTopics: [],
      neverPracticedTopics: [],
      mistakeSummary: MistakeReportSummary(
        totalMistakes: mistakeCount,
        topMistakeTopics: [
          (topic: Topic.division, count: mistakeCount),
        ],
      ),
    );
  }

  TodayPlan createSamplePlan() {
    return TodayPlan(
      date: DateTime(2026, 10, 16),
      blocks: [
        const PlanBlock(
          id: 1,
          type: PlanBlockType.weakness,
          title: 'Division • Hard',
          reason: 'Your lowest mastery topic (42% mastery)',
          config: PracticeConfig(
            topic: Topic.division,
            difficulty: Difficulty.hard,
            mode: PracticeMode.timer,
            modeValue: 300,
            sessionSeed: 0,
          ),
          isCompleted: false,
        ),
        const PlanBlock(
          id: 2,
          type: PlanBlockType.weakness,
          title: 'Squares • Medium',
          reason: 'Second weakest area (55% mastery)',
          config: PracticeConfig(
            topic: Topic.squares,
            difficulty: Difficulty.medium,
            mode: PracticeMode.timer,
            modeValue: 300,
            sessionSeed: 0,
          ),
          isCompleted: true,
        ),
        const PlanBlock(
          id: 3,
          type: PlanBlockType.mistakes,
          title: 'Clear your mistakes',
          reason: '4 mistakes waiting in your mistake bank',
          config: PracticeConfig(
            topic: Topic.mixed,
            difficulty: Difficulty.mixed,
            mode: PracticeMode.mistakes,
            modeValue: 20,
            sessionSeed: 0,
          ),
          isCompleted: false,
        ),
      ],
    );
  }

  Widget buildTestWidget({
    required ReportData data,
    required TodayPlan plan,
    ThemeData? theme,
  }) {
    final writer = ReportWriter();
    final text = writer.writeReport(data, plan: plan);

    return ProviderScope(
      overrides: [
        reportViewModelProvider.overrideWith(
          (ref) => Future.value((data: data, plan: plan, text: text)),
        ),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: const ReportScreen(),
      ),
    );
  }

  testWidgets('renders empty state when total questions < 20', (tester) async {
    final data = createSampleReportData(totalQuestions: 14);
    final plan = createSamplePlan();

    await tester.pumpWidget(buildTestWidget(data: data, plan: plan));
    await tester.pumpAndSettle();

    expect(find.text('Unlock Your Report'), findsOneWidget);
    expect(find.textContaining('14 / 20 questions answered'), findsOneWidget);
    expect(find.text('Start practice (20 Q)'), findsOneWidget);
  });

  testWidgets('renders all populated report sections when data has >= 20 questions', (tester) async {
    final data = createSampleReportData(totalQuestions: 120, speedScore: 72.0);
    final plan = createSamplePlan();

    await tester.pumpWidget(buildTestWidget(data: data, plan: plan));
    await tester.pumpAndSettle();

    // 1. Title
    expect(find.text('Performance Report'), findsOneWidget);

    // 2. Speed Score hero
    expect(find.text('Overall Speed Score'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('Strong Speed'), findsOneWidget);

    // 3. Today's Plan
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.text('1 of 3 Done'), findsOneWidget);
    expect(find.text('Division • Hard'), findsOneWidget);
    expect(find.text('Squares • Medium'), findsOneWidget);
    expect(find.text('Clear your mistakes'), findsOneWidget);
    expect(find.text('Start'), findsNWidgets(2)); // Block 1 and 3 are not done
    expect(find.text('Done'), findsOneWidget); // Block 2 is completed

    // 4. This week vs last week
    await tester.scrollUntilVisible(find.text('This Week vs Last Week'), 300);
    expect(find.text('This Week vs Last Week'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);

    // 5. Strong areas
    await tester.scrollUntilVisible(find.text('Strong Areas'), 300);
    expect(find.text('Strong Areas'), findsOneWidget);
    expect(find.text('Addition (Easy)'), findsOneWidget);

    // 6. Needs work
    await tester.scrollUntilVisible(find.text('Needs Work'), 300);
    expect(find.text('Needs Work'), findsOneWidget);
    expect(find.text('Division (Hard)'), findsOneWidget);

    // 7. Topic table
    await tester.scrollUntilVisible(find.text('Topic Breakdown'), 300);
    expect(find.text('Topic Breakdown'), findsOneWidget);
    expect(find.text('Addition'), findsWidgets);
    expect(find.text('Multiplication'), findsWidgets);
    expect(find.text('Division'), findsWidgets);

    // 8. Mistakes summary
    await tester.scrollUntilVisible(find.text('4 mistakes to revise'), 300);
    expect(find.text('4 mistakes to revise'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
  });

  testWidgets('renders cleanly without overflow at 360px width and text scale 1.3x', (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 800 * 2);
    tester.view.devicePixelRatio = 2.0;

    final data = createSampleReportData(totalQuestions: 120, speedScore: 72.0);
    final plan = createSamplePlan();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(1.3),
          size: Size(360, 800),
        ),
        child: buildTestWidget(data: data, plan: plan),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'Must not overflow at 360px and 1.3x scale');

    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('renders properly with dark theme', (tester) async {
    final data = createSampleReportData(totalQuestions: 120);
    final plan = createSamplePlan();

    await tester.pumpWidget(buildTestWidget(data: data, plan: plan, theme: AppTheme.darkTheme));
    await tester.pumpAndSettle();

    expect(find.text('Performance Report'), findsOneWidget);
    expect(find.text('Overall Speed Score'), findsOneWidget);
  });
}
