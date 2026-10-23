import '../enums/enums.dart';

/// App-wide constants for scoring, timings, options, and defaults.
abstract final class AppConstants {
  AppConstants._();

  /// App name displayed across the system.
  static const String appName = 'Speed Math with AI';

  // --- Scoring Constants ---
  /// Base points awarded for each correct answer.
  static const int basePoints = 10;

  /// Multiplier applied to score for easy difficulty.
  static const double easyDifficultyMultiplier = 1.0;

  /// Multiplier applied to score for medium difficulty.
  static const double mediumDifficultyMultiplier = 1.5;

  /// Multiplier applied to score for hard difficulty.
  static const double hardDifficultyMultiplier = 2.0;

  /// Maximum speed bonus points awarded for fast correct answers.
  static const int maxSpeedBonus = 5;

  /// Map of difficulty level to score multipliers.
  static const Map<Difficulty, double> difficultyMultipliers = {
    Difficulty.easy: easyDifficultyMultiplier,
    Difficulty.medium: mediumDifficultyMultiplier,
    Difficulty.hard: hardDifficultyMultiplier,
  };

  // --- Target Times (in milliseconds) ---
  /// Target completion times per question based on topic and difficulty level.
  /// Used to calculate speed bonus and evaluate performance speed.
  static const Map<Topic, Map<Difficulty, int>> targetTimesMs = {
    Topic.addition: {
      Difficulty.easy: 4000,   // 2-digit + 2-digit
      Difficulty.medium: 7000, // 3-digit + 3-digit
      Difficulty.hard: 12000,  // three 3-4 digit numbers
    },
    Topic.subtraction: {
      Difficulty.easy: 5000,   // 2-digit − 2-digit
      Difficulty.medium: 8000, // 3-digit − 3-digit
      Difficulty.hard: 12000,  // 4-digit − 4-digit
    },
    Topic.multiplication: {
      Difficulty.easy: 5000,    // 2-digit × 1-digit
      Difficulty.medium: 10000, // 2-digit × 2-digit
      Difficulty.hard: 15000,   // 3-digit × 2-digit
    },
    Topic.division: {
      Difficulty.easy: 5000,    // 2-digit ÷ 1-digit
      Difficulty.medium: 10000, // 3-digit ÷ 1-digit or 2-digit ÷ 2-digit
      Difficulty.hard: 15000,   // 4-digit ÷ 2-digit
    },
    Topic.squares: {
      Difficulty.easy: 4000,    // 1–20 squared
      Difficulty.medium: 8000,  // 21–50 squared
      Difficulty.hard: 14000,   // 51–99 squared
    },
    Topic.cubes: {
      Difficulty.easy: 5000,    // 2–10 cubed
      Difficulty.medium: 10000, // 11–20 cubed
      Difficulty.hard: 18000,   // 21–35 cubed
    },
    Topic.squareRoots: {
      Difficulty.easy: 5000,    // √(1–20²)
      Difficulty.medium: 10000, // √(21–50²)
      Difficulty.hard: 16000,   // √(51–99²)
    },
    Topic.cubeRoots: {
      Difficulty.easy: 6000,    // ∛(2–10³)
      Difficulty.medium: 12000, // ∛(11–20³)
      Difficulty.hard: 20000,   // ∛(21–35³)
    },
    Topic.exponents: {
      Difficulty.easy: 5000,    // base 2–9, power 2–3
      Difficulty.medium: 10000, // base 2–9, power 2–5
      Difficulty.hard: 16000,   // base 2–15, power 3–6
    },
    Topic.percentages: {
      Difficulty.easy: 5000,    // friendly 10, 20, 25, 50%
      Difficulty.medium: 9000,  // multiples of 5% up to 1000
      Difficulty.hard: 15000,   // dual percentage combination
    },
    Topic.fractions: {
      Difficulty.easy: 5000,    // single fraction small denom
      Difficulty.medium: 9000,  // fraction up to 1000
      Difficulty.hard: 15000,   // dual fraction combination
    },
    Topic.simplification: {
      Difficulty.easy: 6000,    // a + b × c
      Difficulty.medium: 12000, // brackets and two operations
      Difficulty.hard: 18000,   // square + exact division + mul
    },
    Topic.averages: {
      Difficulty.easy: 7000,    // average of 3 numbers
      Difficulty.medium: 12000, // average of 5 numbers
      Difficulty.hard: 16000,   // find fifth missing number
    },
    Topic.missingNumber: {
      Difficulty.easy: 5000,    // ? + a = b, 6 × ? = 48
      Difficulty.medium: 9000,  // ? × 23 = 391, ? / 14 = 12
      Difficulty.hard: 14000,   // (? + 18) × 7 = 245
    },
  };

  /// Returns the target time in milliseconds for the given topic and difficulty.
  static int getTargetTimeMs(Topic topic, Difficulty difficulty) {
    return targetTimesMs[topic]?[difficulty] ?? 5000;
  }

  // --- Practice Mode Options ---
  /// Available duration options in seconds for Timer Mode.
  static const List<int> timerModeOptions = [60, 120, 180, 300, 600];

  /// Default duration in seconds for Timer Mode.
  static const int defaultTimerDuration = 120;

  /// Available question count options for Question Mode.
  static const List<int> questionModeOptions = [10, 20, 30, 50];

  /// Default question count for Question Mode.
  static const int defaultQuestionCount = 20;

  // --- Performance & Thresholds ---
  /// Minimum accuracy (0.0 to 1.0) required for a session to qualify for best times (80%).
  static const double minAccuracyForBestTimes = 0.8;

  /// Current app version matching pubspec.yaml.
  static const String appVersion = '1.7.0';
}
