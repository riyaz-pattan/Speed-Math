import 'package:flutter/foundation.dart';
import '../../core/enums/enums.dart';
import '../adaptive/skill_engine.dart';
import 'report_constants.dart';

/// Label categorizing the user's Overall Speed Score (0-100).
enum SpeedScoreLabel {
  beginner('Beginner'),
  building('Building'),
  strong('Strong'),
  elite('Elite');

  const SpeedScoreLabel(this.displayName);
  final String displayName;

  static SpeedScoreLabel fromScore(double score) {
    if (score < ReportConstants.scoreBeginnerMax) {
      return SpeedScoreLabel.beginner;
    }
    if (score < ReportConstants.scoreBuildingMax) {
      return SpeedScoreLabel.building;
    }
    if (score < ReportConstants.scoreStrongMax) {
      return SpeedScoreLabel.strong;
    }
    return SpeedScoreLabel.elite;
  }
}

/// Trend direction for a math topic over the two 7-day windows.
enum TopicTrend {
  improving('Improving'),
  slipping('Slipping'),
  steady('Steady'),
  notEnoughData('Not enough data');

  const TopicTrend(this.displayName);
  final String displayName;
}

/// Snapshot summary of a single (topic, difficulty) skill bucket.
@immutable
class SkillBucketSummary {
  final Topic topic;
  final Difficulty difficulty;
  final double mastery;
  final int attempts;
  final SkillBucketLevel level;

  const SkillBucketSummary({
    required this.topic,
    required this.difficulty,
    required this.mastery,
    required this.attempts,
    required this.level,
  });

  @override
  String toString() =>
      '${topic.displayName} ${difficulty.displayName} (${(mastery * 100).toStringAsFixed(0)}% mastery, $attempts attempts)';
}

/// Aggregated practice metrics for a single 7-day window.
@immutable
class WeeklyWindowStats {
  final int sessionsCount;
  final int questionsAnswered;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double practiceMinutes;
  final double accuracy; // 0.0 to 1.0
  final double avgTimeMsPerCorrect;

  const WeeklyWindowStats({
    this.sessionsCount = 0,
    this.questionsAnswered = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.skippedCount = 0,
    this.practiceMinutes = 0.0,
    this.accuracy = 0.0,
    this.avgTimeMsPerCorrect = 0.0,
  });
}

/// Comparison between the current 7 days and the previous 7 days.
@immutable
class WeeklyComparison {
  final WeeklyWindowStats currentWindow;
  final WeeklyWindowStats previousWindow;

  const WeeklyComparison({
    required this.currentWindow,
    required this.previousWindow,
  });

  int get sessionsDelta =>
      currentWindow.sessionsCount - previousWindow.sessionsCount;

  int get questionsDelta =>
      currentWindow.questionsAnswered - previousWindow.questionsAnswered;

  double get minutesDelta =>
      currentWindow.practiceMinutes - previousWindow.practiceMinutes;

  /// Absolute accuracy difference in points (e.g. +0.05 is +5%).
  double get accuracyDelta =>
      currentWindow.accuracy - previousWindow.accuracy;

  /// Delta in average time per correct answer in ms (negative means faster/improved).
  double get timeDeltaMs =>
      currentWindow.avgTimeMsPerCorrect - previousWindow.avgTimeMsPerCorrect;

  /// Percentage speed change relative to previous window (positive = faster).
  double? get speedImprovementPercent {
    if (previousWindow.avgTimeMsPerCorrect <= 0 ||
        currentWindow.avgTimeMsPerCorrect <= 0) {
      return null;
    }
    return ((previousWindow.avgTimeMsPerCorrect -
                currentWindow.avgTimeMsPerCorrect) /
            previousWindow.avgTimeMsPerCorrect) *
        100;
  }
}

/// Performance analysis for an individual topic across windows and difficulties.
@immutable
class TopicPerformance {
  final Topic topic;
  final SkillBucketLevel level;
  final Difficulty bestDifficulty;
  final Map<Difficulty, SkillBucketSummary> perDifficulty;
  final double accuracy; // Overall accuracy (0.0 to 1.0)
  final double avgTimeMs; // Overall avg time per correct answer
  final int totalAttempts;
  final int? daysSinceLastPracticed; // null if never practiced
  final TopicTrend trend;
  final int currentWindowQuestions;
  final int previousWindowQuestions;
  final double currentWindowAccuracy;
  final double previousWindowAccuracy;
  final double currentWindowAvgTimeMs;
  final double previousWindowAvgTimeMs;

  const TopicPerformance({
    required this.topic,
    required this.level,
    required this.bestDifficulty,
    required this.perDifficulty,
    required this.accuracy,
    required this.avgTimeMs,
    required this.totalAttempts,
    required this.daysSinceLastPracticed,
    required this.trend,
    required this.currentWindowQuestions,
    required this.previousWindowQuestions,
    required this.currentWindowAccuracy,
    required this.previousWindowAccuracy,
    required this.currentWindowAvgTimeMs,
    required this.previousWindowAvgTimeMs,
  });

  bool get isNeglected =>
      daysSinceLastPracticed != null &&
      daysSinceLastPracticed! >= ReportConstants.neglectedDaysThreshold;

  bool get isNeverPracticed =>
      totalAttempts == 0 || daysSinceLastPracticed == null;
}

/// Mistake bank metrics for the performance report.
@immutable
class MistakeReportSummary {
  final int totalMistakes;
  final List<({Topic topic, int count})> topMistakeTopics;

  const MistakeReportSummary({
    this.totalMistakes = 0,
    this.topMistakeTopics = const [],
  });
}

/// Complete performance report data model.
///
/// Pure Dart — completely decoupled from UI, directly consumable by UI and AI Coach.
@immutable
class ReportData {
  final DateTime generatedAt;
  final int totalQuestionsAllTime;
  final double? overallSpeedScore; // 0 to 100, null if no bucket >= 5 attempts
  final SpeedScoreLabel? speedScoreLabel;
  final int answersNeededForSpeedScore;
  final WeeklyComparison weeklyComparison;
  final List<TopicPerformance> topicPerformances;
  final List<SkillBucketSummary> strongAreas;
  final List<SkillBucketSummary> weakAreas;
  final List<Topic> neglectedTopics;
  final List<Topic> neverPracticedTopics;
  final MistakeReportSummary mistakeSummary;

  const ReportData({
    required this.generatedAt,
    required this.totalQuestionsAllTime,
    required this.overallSpeedScore,
    required this.speedScoreLabel,
    this.answersNeededForSpeedScore = 0,
    required this.weeklyComparison,
    required this.topicPerformances,
    required this.strongAreas,
    required this.weakAreas,
    required this.neglectedTopics,
    required this.neverPracticedTopics,
    required this.mistakeSummary,
  });

  /// Whether the user has answered enough total questions to unlock the full report (10+).
  bool get hasEnoughData =>
      totalQuestionsAllTime >= ReportConstants.minTotalQuestionsForReport;

  /// Whether the report is in its early stages (10 to 40 questions answered).
  bool get isEarlyReport =>
      totalQuestionsAllTime >= ReportConstants.minTotalQuestionsForReport &&
      totalQuestionsAllTime < ReportConstants.earlyReportMaxQuestions;
}
