import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_engine.dart';
import 'package:speed_math_with_ai/domain/report/report_data.dart';
import 'package:speed_math_with_ai/domain/report/report_writer.dart';
import 'package:speed_math_with_ai/domain/report/todays_plan.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';

void main() {
  group('ReportWriter JSON Phrase Bank Integrity', () {
    test('assets/coach/phrases.json exists and has >= 4 variants for every situation', () {
      final file = File('assets/coach/phrases.json');
      expect(file.existsSync(), isTrue, reason: 'assets/coach/phrases.json must exist');

      final content = file.readAsStringSync();
      final Map<String, dynamic> decoded = jsonDecode(content);

      expect(decoded.length, greaterThanOrEqualTo(20),
          reason: 'Must have at least 20 situations in phrase bank');

      for (final entry in decoded.entries) {
        expect(entry.value, isA<List>(), reason: '${entry.key} must be a list');
        final list = entry.value as List;
        expect(list.length, greaterThanOrEqualTo(4),
            reason: '${entry.key} must have at least 4 phrasing variants, had ${list.length}');
        for (final phrase in list) {
          expect(phrase, isA<String>());
          expect((phrase as String).trim(), isNotEmpty);
        }
      }
    });
  });

  group('ReportWriter Text Generation', () {
    late ReportWriter writer;

    setUp(() {
      final file = File('assets/coach/phrases.json');
      final Map<String, dynamic> decoded = jsonDecode(file.readAsStringSync());
      final phrases = <String, List<String>>{};
      for (final e in decoded.entries) {
        phrases[e.key] = (e.value as List).map((s) => s.toString()).toList();
      }
      writer = ReportWriter(phrases: phrases);
    });

    ReportData createSampleReportData({
      int totalQuestions = 150,
      double? overallSpeedScore = 74.0,
      SpeedScoreLabel? speedScoreLabel = SpeedScoreLabel.strong,
      int totalMistakes = 4,
    }) {
      return ReportData(
        generatedAt: DateTime(2026, 10, 16),
        totalQuestionsAllTime: totalQuestions,
        overallSpeedScore: overallSpeedScore,
        speedScoreLabel: speedScoreLabel,
        weeklyComparison: const WeeklyComparison(
          currentWindow: WeeklyWindowStats(
            sessionsCount: 8,
            questionsAnswered: 80,
            correctCount: 72,
            wrongCount: 6,
            skippedCount: 2,
            practiceMinutes: 24.5,
            accuracy: 0.90,
            avgTimeMsPerCorrect: 2400,
          ),
          previousWindow: WeeklyWindowStats(
            sessionsCount: 5,
            questionsAnswered: 50,
            correctCount: 41,
            wrongCount: 7,
            skippedCount: 2,
            practiceMinutes: 18.0,
            accuracy: 0.82,
            avgTimeMsPerCorrect: 2800,
          ),
        ),
        topicPerformances: [
          TopicPerformance(
            topic: Topic.addition,
            level: SkillBucketLevel.strong,
            bestDifficulty: Difficulty.medium,
            perDifficulty: {
              Difficulty.easy: const SkillBucketSummary(
                topic: Topic.addition,
                difficulty: Difficulty.easy,
                mastery: 0.92,
                attempts: 30,
                level: SkillBucketLevel.strong,
              ),
            },
            accuracy: 0.95,
            avgTimeMs: 1800,
            totalAttempts: 50,
            daysSinceLastPracticed: 1,
            trend: TopicTrend.improving,
            currentWindowQuestions: 25,
            previousWindowQuestions: 20,
            currentWindowAccuracy: 0.96,
            previousWindowAccuracy: 0.85,
            currentWindowAvgTimeMs: 1700,
            previousWindowAvgTimeMs: 2100,
          ),
          TopicPerformance(
            topic: Topic.division,
            level: SkillBucketLevel.needsWork,
            bestDifficulty: Difficulty.hard,
            perDifficulty: {
              Difficulty.hard: const SkillBucketSummary(
                topic: Topic.division,
                difficulty: Difficulty.hard,
                mastery: 0.45,
                attempts: 12,
                level: SkillBucketLevel.needsWork,
              ),
            },
            accuracy: 0.60,
            avgTimeMs: 7200,
            totalAttempts: 20,
            daysSinceLastPracticed: 2,
            trend: TopicTrend.slipping,
            currentWindowQuestions: 15,
            previousWindowQuestions: 15,
            currentWindowAccuracy: 0.53,
            previousWindowAccuracy: 0.67,
            currentWindowAvgTimeMs: 8000,
            previousWindowAvgTimeMs: 6500,
          ),
        ],
        strongAreas: [
          const SkillBucketSummary(
            topic: Topic.addition,
            difficulty: Difficulty.easy,
            mastery: 0.92,
            attempts: 30,
            level: SkillBucketLevel.strong,
          ),
        ],
        weakAreas: [
          const SkillBucketSummary(
            topic: Topic.division,
            difficulty: Difficulty.hard,
            mastery: 0.45,
            attempts: 12,
            level: SkillBucketLevel.needsWork,
          ),
        ],
        neglectedTopics: [Topic.squares],
        neverPracticedTopics: [Topic.cubes],
        mistakeSummary: MistakeReportSummary(
          totalMistakes: totalMistakes,
          topMistakeTopics: [
            (topic: Topic.division, count: totalMistakes),
          ],
        ),
      );
    }

    test('no unreplaced placeholders in generated text', () {
      final data = createSampleReportData();
      final reportText = writer.writeReport(data, date: DateTime(2026, 10, 16));

      final allSections = [
        reportText.headline,
        reportText.weeklyActivity,
        reportText.weeklyAccuracy ?? '',
        reportText.weeklySpeed ?? '',
        reportText.strengths,
        reportText.weakAreas,
        reportText.improving ?? '',
        reportText.slipping ?? '',
        reportText.neglected ?? '',
        reportText.neverPracticed ?? '',
        reportText.mistakes,
        reportText.closingPush,
      ];

      final placeholderRegex = RegExp(r'\{[a-zA-Z0-9_]+\}');
      for (final text in allSections) {
        expect(placeholderRegex.hasMatch(text), isFalse,
            reason: 'Found unreplaced placeholder in: "$text"');
      }
    });

    test('numbers in generated text match ReportData exactly', () {
      final data = createSampleReportData(overallSpeedScore: 74.0);
      final reportText = writer.writeReport(data, date: DateTime(2026, 10, 16));

      // Speed score 74 must appear in headline
      expect(reportText.headline, contains('74'));
      expect(reportText.headline, contains('Strong'));

      // Weekly activity has 8 sessions, 80 questions, 25 or 24 minutes
      expect(reportText.weeklyActivity, contains('8'));
      expect(reportText.weeklyActivity, contains('80'));

      // Mistakes count 4 must appear in mistakes section
      expect(reportText.mistakes, contains('4'));
      expect(reportText.mistakes, contains('Division'));

      // Strengths must mention Addition
      expect(reportText.strengths, contains('Addition'));

      // Weakness must mention Division
      expect(reportText.weakAreas, contains('Division'));
    });

    test('same date gives identical text (stability)', () {
      final data = createSampleReportData();
      final date = DateTime(2026, 10, 16);

      final t1 = writer.writeReport(data, date: date);
      final t2 = writer.writeReport(data, date: date);

      expect(t1.headline, equals(t2.headline));
      expect(t1.weeklyActivity, equals(t2.weeklyActivity));
      expect(t1.strengths, equals(t2.strengths));
      expect(t1.weakAreas, equals(t2.weakAreas));
      expect(t1.mistakes, equals(t2.mistakes));
      expect(t1.closingPush, equals(t2.closingPush));
    });

    test('different dates can vary phrasing across situations', () {
      final data = createSampleReportData();
      final d1 = DateTime(2026, 10, 16);
      final d2 = DateTime(2026, 10, 25);

      final t1 = writer.writeReport(data, date: d1);
      final t2 = writer.writeReport(data, date: d2);

      // Across the whole report, at least one section should pick a different variant
      final differs = t1.headline != t2.headline ||
          t1.weeklyActivity != t2.weeklyActivity ||
          t1.strengths != t2.strengths ||
          t1.closingPush != t2.closingPush;

      expect(differs, isTrue, reason: 'Different dates should produce phrasing variations');
    });

    test('empty-data case (< 20 total questions) produces encouraging unlock text', () {
      final data = createSampleReportData(totalQuestions: 12);
      final reportText = writer.writeReport(data, date: DateTime(2026, 10, 16));

      expect(reportText.headline, contains('20'));
      expect(reportText.headline.toLowerCase(), contains('practice'));
    });

    test('closing push reflects completed vs pending plan', () {
      final data = createSampleReportData();
      final planNotDone = TodayPlan(
        date: DateTime(2026, 10, 16),
        blocks: [
          const PlanBlock(
            id: 1,
            type: PlanBlockType.weakness,
            title: 'Addition',
            reason: 'Weak area',
            config: PracticeConfig(
              topic: Topic.addition,
              difficulty: Difficulty.easy,
              mode: PracticeMode.timer,
              modeValue: 300,
              sessionSeed: 0,
            ),
            isCompleted: false,
          ),
        ],
      );

      final textNotDone = writer.writeReport(data, plan: planNotDone, date: DateTime(2026, 10, 16));
      expect(textNotDone.closingPush, isNotEmpty);

      final planAllDone = TodayPlan(
        date: DateTime(2026, 10, 16),
        blocks: [
          const PlanBlock(
            id: 1,
            type: PlanBlockType.weakness,
            title: 'Addition',
            reason: 'Weak area',
            config: PracticeConfig(
              topic: Topic.addition,
              difficulty: Difficulty.easy,
              mode: PracticeMode.timer,
              modeValue: 300,
              sessionSeed: 0,
            ),
            isCompleted: true,
          ),
        ],
      );

      final textAllDone = writer.writeReport(data, plan: planAllDone, date: DateTime(2026, 10, 16));
      expect(textAllDone.closingPush.toLowerCase(), contains('complete'));
    });

    test('accuracy comparison uses percentage points (points, not %)', () {
      final data = createSampleReportData(); // accuracy 0.82 -> 0.90 (+8 points)
      for (int day = 1; day <= 10; day++) {
        final text = writer.writeReport(data, date: DateTime(2026, 10, day));
        expect(text.weeklyAccuracy, isNotNull);
        expect(text.weeklyAccuracy, contains('8 points'));
        expect(text.weeklyAccuracy, isNot(contains('up by 8%')));
        expect(text.weeklyAccuracy, isNot(contains('gaining 8%')));
      }
    });

    test('speed improvement says fell/faster/dropped, never up or rose', () {
      final data = createSampleReportData(); // time 2800 -> 2400 (14% faster)
      for (int day = 1; day <= 20; day++) {
        final text = writer.writeReport(data, date: DateTime(2026, 10, day));
        expect(text.weeklySpeed, isNotNull);
        expect(text.weeklySpeed!.toLowerCase(), isNot(contains('up 14%')));
        expect(text.weeklySpeed!.toLowerCase(), isNot(contains('rose by')));
        final isImprovingWording = text.weeklySpeed!.contains('fell by 14%') ||
            text.weeklySpeed!.contains('14% faster') ||
            text.weeklySpeed!.contains('dropped by 14%');
        expect(isImprovingWording, isTrue,
            reason: 'Speed improvement must state time fell/dropped or faster: "${text.weeklySpeed}"');
      }
    });

    test('speed worsening says rose/slower/slowing, never faster', () {
      final data = ReportData(
        generatedAt: DateTime(2026, 10, 16),
        totalQuestionsAllTime: 100,
        overallSpeedScore: 70.0,
        speedScoreLabel: SpeedScoreLabel.strong,
        weeklyComparison: const WeeklyComparison(
          currentWindow: WeeklyWindowStats(
            sessionsCount: 5,
            questionsAnswered: 50,
            correctCount: 45,
            wrongCount: 5,
            skippedCount: 0,
            practiceMinutes: 15.0,
            accuracy: 0.90,
            avgTimeMsPerCorrect: 3200,
          ),
          previousWindow: WeeklyWindowStats(
            sessionsCount: 5,
            questionsAnswered: 50,
            correctCount: 45,
            wrongCount: 5,
            skippedCount: 0,
            practiceMinutes: 15.0,
            accuracy: 0.90,
            avgTimeMsPerCorrect: 2400,
          ),
        ),
        topicPerformances: const [],
        strongAreas: const [],
        weakAreas: const [],
        neglectedTopics: const [],
        neverPracticedTopics: const [],
        mistakeSummary: const MistakeReportSummary(totalMistakes: 0, topMistakeTopics: []),
      );

      for (int day = 1; day <= 20; day++) {
        final text = writer.writeReport(data, date: DateTime(2026, 10, day));
        expect(text.weeklySpeed, isNotNull);
        expect(text.weeklySpeed!.toLowerCase(), isNot(contains('faster')));
        final isSlowerWording = text.weeklySpeed!.contains('rose by 33%') ||
            text.weeklySpeed!.contains('33% slower') ||
            text.weeklySpeed!.contains('slowing by 33%');
        expect(isSlowerWording, isTrue,
            reason: 'Speed slowing must state time rose or slower: "${text.weeklySpeed}"');
      }
    });
  });
}
