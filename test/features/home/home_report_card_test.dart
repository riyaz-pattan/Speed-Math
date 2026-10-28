import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/repositories/report_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_engine.dart';
import 'package:speed_math_with_ai/domain/report/report_data.dart';
import 'package:speed_math_with_ai/domain/report/report_writer.dart';
import 'package:speed_math_with_ai/domain/report/todays_plan.dart';
import 'package:speed_math_with_ai/features/home/widgets/home_report_card.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';

void main() {
  testWidgets('HomeReportCard shows unlock message when < 10 questions', (tester) async {
    final data = ReportData(
      generatedAt: DateTime(2026, 10, 16),
      totalQuestionsAllTime: 5,
      overallSpeedScore: null,
      speedScoreLabel: null,
      weeklyComparison: WeeklyComparison(
        currentWindow: WeeklyWindowStats(),
        previousWindow: WeeklyWindowStats(),
      ),
      topicPerformances: [],
      strongAreas: [],
      weakAreas: [],
      neglectedTopics: [],
      neverPracticedTopics: [],
      mistakeSummary: MistakeReportSummary(),
    );

    final plan = TodayPlan(date: DateTime(2026, 10, 16), blocks: []);
    final writer = ReportWriter();
    final text = writer.writeReport(data, plan: plan);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportViewModelProvider.overrideWith(
            (ref) => Future.value((data: data, plan: plan, text: text)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HomeReportCard(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Performance Report'), findsOneWidget);
    expect(find.text('Practice to unlock (5/10 Q)'), findsOneWidget);
    expect(find.text('Ask Coach'), findsOneWidget);
  });

  testWidgets('HomeReportCard shows Speed Score and plan progress when >= 20 questions', (tester) async {
    final data = ReportData(
      generatedAt: DateTime(2026, 10, 16),
      totalQuestionsAllTime: 100,
      overallSpeedScore: 74.0,
      speedScoreLabel: SpeedScoreLabel.strong,
      weeklyComparison: const WeeklyComparison(
        currentWindow: WeeklyWindowStats(sessionsCount: 5, questionsAnswered: 50),
        previousWindow: WeeklyWindowStats(sessionsCount: 3, questionsAnswered: 30),
      ),
      topicPerformances: [
        TopicPerformance(
          topic: Topic.addition,
          level: SkillBucketLevel.strong,
          bestDifficulty: Difficulty.easy,
          perDifficulty: const {},
          accuracy: 0.90,
          avgTimeMs: 2000,
          totalAttempts: 30,
          daysSinceLastPracticed: 1,
          trend: TopicTrend.improving,
          currentWindowQuestions: 20,
          previousWindowQuestions: 20,
          currentWindowAccuracy: 0.90,
          previousWindowAccuracy: 0.80,
          currentWindowAvgTimeMs: 2000,
          previousWindowAvgTimeMs: 2400,
        ),
      ],
      strongAreas: [],
      weakAreas: [],
      neglectedTopics: [],
      neverPracticedTopics: [],
      mistakeSummary: const MistakeReportSummary(),
    );

    final plan = TodayPlan(
      date: DateTime(2026, 10, 16),
      blocks: [
        const PlanBlock(
          id: 1,
          type: PlanBlockType.weakness,
          title: 'Addition',
          reason: 'Reason 1',
          config: PracticeConfig(
            topic: Topic.addition,
            difficulty: Difficulty.easy,
            mode: PracticeMode.timer,
            modeValue: 300,
            sessionSeed: 0,
          ),
          isCompleted: true,
        ),
        const PlanBlock(
          id: 2,
          type: PlanBlockType.weakness,
          title: 'Multiplication',
          reason: 'Reason 2',
          config: PracticeConfig(
            topic: Topic.multiplication,
            difficulty: Difficulty.easy,
            mode: PracticeMode.timer,
            modeValue: 300,
            sessionSeed: 0,
          ),
          isCompleted: false,
        ),
        const PlanBlock(
          id: 3,
          type: PlanBlockType.keepSharp,
          title: 'Smart Practice',
          reason: 'Reason 3',
          config: PracticeConfig(
            topic: Topic.mixed,
            difficulty: Difficulty.mixed,
            mode: PracticeMode.smart,
            modeValue: 20,
            sessionSeed: 0,
          ),
          isCompleted: false,
        ),
      ],
    );

    final writer = ReportWriter();
    final text = writer.writeReport(data, plan: plan);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportViewModelProvider.overrideWith(
            (ref) => Future.value((data: data, plan: plan, text: text)),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: HomeReportCard(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Speed Score: 74 • Strong'), findsOneWidget);
    expect(find.text("Today's plan: 1 of 3 done"), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
  });
}
