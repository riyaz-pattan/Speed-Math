import '../enums/enums.dart';

/// App-wide constants for scoring, timings, options, and defaults.
abstract final class AppConstants {
  AppConstants._();

  /// App name displayed across the system.
  static const String appName = 'Mental Calculation Tricks';

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
    Topic.numberSeries: {
      Difficulty.easy: 6000,    // constant diff, ×2/×3, consecutive squares/cubes
      Difficulty.medium: 12000, // growing diff, Fibonacci, ×n ± k, primes
      Difficulty.hard: 25000,   // interleaved, growing multipliers, alternating ops
    },
    Topic.approximation: {
      Difficulty.easy: 6000,    // two operations with near numbers
      Difficulty.medium: 11000, // near %, square or sqrt of near-perfect
      Difficulty.hard: 18000,   // 4-5 mixed terms up to 100000
    },
    Topic.fractionReciprocals: {
      Difficulty.easy: 5000,    // simple unit fractions (1/2, 1/4, 1/5)
      Difficulty.medium: 8000,  // recurring decimals (1/3, 1/6, 1/8)
      Difficulty.hard: 12000,   // harder primes (1/7, 1/13, 1/16)
    },
    Topic.derivedFractions: {
      Difficulty.easy: 6000,    // simple multiples (3/4, 4/5, 7/10)
      Difficulty.medium: 10000, // eighths and sixths (3/8, 5/6)
      Difficulty.hard: 15000,   // sevenths and twelfths
    },
    Topic.fractionPercentages: {
      Difficulty.easy: 5000,    // 25%, 50%, 75% of clean numbers
      Difficulty.medium: 9000,  // 12.5%, 37.5%, 16.67%
      Difficulty.hard: 15000,   // 14.28%, 8.33%, 6.25%
    },
    Topic.basePercentages: {
      Difficulty.easy: 5000,    // 120%, 125%, 150% of round numbers
      Difficulty.medium: 9000,  // 112.5%, 137.5%, 133.33%
      Difficulty.hard: 15000,   // 114.28%, 141.67%, 187.5%
    },
    Topic.splitPercentages: {
      Difficulty.easy: 5000,    // 15%, 35%, 55% of multiples of 20
      Difficulty.medium: 9000,  // two-digit % of round hundreds
      Difficulty.hard: 14000,   // non-round % of larger bases
    },
    Topic.powerOfFive: {
      Difficulty.easy: 4000,    // × 5 or ÷ 5 of 2-digit
      Difficulty.medium: 6000,  // × 25 or ÷ 25
      Difficulty.hard: 10000,   // × 125 or ÷ 125
    },
    Topic.patternMultiplication: {
      Difficulty.easy: 4000,    // 2-digit × 11 no carry, single × 99
      Difficulty.medium: 7000,  // 2-digit × 11 with carry, × 99
      Difficulty.hard: 12000,   // 3-digit × 11, × 101, × 99
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
  static const int defaultQuestionCount = 10;

  // --- Performance & Thresholds ---
  /// Minimum accuracy (0.0 to 1.0) required for a session to qualify for best times (80%).
  static const double minAccuracyForBestTimes = 0.8;

  /// Current app version matching pubspec.yaml.
  static const String appVersion = '1.13.1';
}
