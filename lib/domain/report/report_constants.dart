/// Constants and thresholds for the Performance Report and AI Coach analysis.
///
/// Pure Dart — all tunable parameters are placed here for maintainability.
abstract final class ReportConstants {
  ReportConstants._();

  /// Number of days in the comparison window (last 7 days vs previous 7 days).
  static const int windowDays = 7;

  /// Minimum total questions answered across all sessions to unlock the report.
  static const int minTotalQuestionsForReport = 10;

  /// Maximum questions answered threshold for the "Early report" indicator.
  static const int earlyReportMaxQuestions = 40;

  // --- Speed Score Thresholds ---
  /// Minimum attempts required in a (topic, difficulty) bucket to count toward the Speed Score.
  static const int speedScoreMinAttemptsPerBucket = 5;

  /// Maximum weight cap per bucket for Speed Score calculation: weight = min(attempts, 50).
  static const int speedScoreMaxWeightPerBucket = 50;

  /// Score under 40 is classified as Beginner.
  static const double scoreBeginnerMax = 40.0;

  /// Score from 40 up to 60 is classified as Building.
  static const double scoreBuildingMax = 60.0;

  /// Score from 60 up to 80 is classified as Strong.
  static const double scoreStrongMax = 80.0;

  /// Score 80 and above is classified as Elite.

  // --- Trend Evaluation Rules ---
  /// Minimum answered questions in EACH 7-day window required to compute a topic trend.
  static const int trendMinQuestionsPerWindow = 15;

  /// Fractional change in average time per correct answer to qualify as Improving/Slipping (8%).
  static const double trendTimeChangeRatio = 0.08;

  /// Absolute accuracy point difference to qualify as Improving/Slipping (5 points = 0.05).
  static const double trendAccuracyPointChange = 0.05;

  // --- Strengths & Weaknesses ---
  /// Minimum mastery to qualify as a Strong area.
  static const double strongAreaMasteryThreshold = 0.80;

  /// Maximum number of strong areas highlighted in the report.
  static const int maxStrongAreas = 3;

  /// Minimum attempts to be evaluated as a Weak area.
  static const int weakAreaMinAttempts = 5;

  /// Maximum mastery to qualify as a Weak area (must be strictly under 0.65).
  static const double weakAreaMasteryMax = 0.65;

  /// Maximum number of weak areas highlighted in the report.
  static const int maxWeakAreas = 3;

  /// Days without practice before a previously practiced topic is classified as "Not practiced".
  static const int neglectedDaysThreshold = 7;

  // --- Today's Plan Defaults ---
  /// Duration in seconds for Timer practice blocks in Today's Plan (5 minutes).
  static const int planTimerDurationSeconds = 300;

  /// Question count for Smart Practice "Keep it sharp" block in Today's Plan.
  static const int planSmartPracticeQuestionCount = 20;

  /// Maximum questions drilled in a Mistake Practice block in Today's Plan.
  static const int planMistakePracticeQuestionCount = 20;

  /// Number of daily blocks in Today's Plan.
  static const int planTotalBlocks = 3;
}
