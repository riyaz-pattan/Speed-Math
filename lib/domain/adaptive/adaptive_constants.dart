/// Constants for the adaptive/skill tracking engine.
///
/// All tunable numbers in one place so they can be adjusted without
/// modifying logic code.
abstract final class AdaptiveConstants {
  AdaptiveConstants._();

  // --- Mastery Update ---
  /// Learning rate (alpha) for the first [earlyAttemptThreshold] attempts.
  static const double alphaEarly = 0.20;

  /// Learning rate (alpha) after [earlyAttemptThreshold] attempts.
  static const double alphaLate = 0.08;

  /// Number of attempts below which [alphaEarly] is used.
  static const int earlyAttemptThreshold = 10;

  /// Starting mastery for a brand-new skill bucket.
  static const double initialMastery = 0.50;

  // --- Outcome Score (time-based) ---
  /// If time_taken / target_time <= this, score is 1.0 (perfect).
  static const double fastThreshold = 0.50;

  /// If time_taken / target_time >= this, score is 0.5 (minimum for correct).
  static const double slowThreshold = 2.00;

  /// Score at the fast threshold.
  static const double maxOutcomeScore = 1.0;

  /// Score at (and beyond) the slow threshold.
  static const double minOutcomeScore = 0.5;

  // --- Bucket Classification ---
  /// Minimum attempts before a bucket can be classified.
  static const int minAttemptsForClassification = 5;

  /// Mastery below this is "Needs work".
  static const double needsWorkThreshold = 0.50;

  /// Mastery at or above this is "Strong".
  static const double strongThreshold = 0.80;

  // Wrong / skipped outcome score.
  static const double wrongOutcomeScore = 0.0;
  static const double skippedOutcomeScore = 0.0;

  // --- Mistake Bank ---
  /// Maximum number of mistakes stored in the bank before eviction.
  static const int mistakeBankCapacity = 300;

  /// Resurfacing gaps in smart questions answered: [stage 0, stage 1, stage 2].
  static const List<int> stageGaps = [3, 10, 25];

  /// Consecutive correct answers needed to remove a mistake from the bank.
  static const int maxConsecutiveCorrect = 3;

  /// Maximum ratio of due mistakes allowed in a single session (at most 1/3).
  static const double maxDueMistakesRatio = 1.0 / 3.0;

  /// Maximum number of mistakes served in a Mistake Practice session.
  static const int mistakePracticeLimit = 20;

  // --- Smart Question Picker Mix ---
  /// Target mix proportion for Weak buckets.
  static const double weakBucketWeight = 0.60;

  /// Target mix proportion for Medium buckets (includes Not enough data).
  static const double mediumBucketWeight = 0.30;

  /// Target mix proportion for Strong buckets.
  static const double strongBucketWeight = 0.10;

  // --- Cold Start ---
  /// Minimum attempts on an easier difficulty before unlocking the next difficulty.
  static const int coldStartMinAttempts = 5;

  /// Minimum mastery on an easier difficulty before unlocking the next difficulty.
  static const double coldStartMinMastery = 0.50;

  // --- Difficulty Nudge ---
  /// Minimum recent questions evaluated for difficulty nudge.
  static const int nudgeWindowSize = 10;

  /// If recent accuracy is >= this, nudge difficulty up.
  static const double nudgeAccuracyHigh = 0.85;

  /// If recent accuracy is <= this, nudge difficulty down.
  static const double nudgeAccuracyLow = 0.60;
}
