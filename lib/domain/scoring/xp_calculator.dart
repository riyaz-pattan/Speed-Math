import 'dart:math';

/// Pure Dart utility for level and XP calculations, tier naming, and star thresholds.
abstract final class XpCalculator {
  XpCalculator._();

  static const double star2MinAccuracy = 0.70;
  static const double star3MinAccuracy = 0.90;

  static const List<String> levelTitles = [
    'Beginner',
    'Quick Thinker',
    'Rapid Solver',
    'Number Ninja',
    'Speedster',
    'Calculator Pro',
    'Mind Racer',
    'Math Wizard',
    'Lightning Mind',
    'Grandmaster',
  ];

  /// Returns the starting XP threshold for a given [level] (level >= 1).
  /// Formula: 50 * (level - 1)^2
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    final n = level - 1;
    return 50 * n * n;
  }

  /// Calculates the player's level from their [totalXp].
  /// Formula: 1 + floor(sqrt(totalXp / 50))
  static int levelFromXp(int totalXp) {
    if (totalXp <= 0) return 1;
    return 1 + sqrt(totalXp / 50.0).floor();
  }

  /// Returns the title name for a given [level].
  static String titleForLevel(int level) {
    if (level <= 0) return levelTitles.first;
    if (level > levelTitles.length) return levelTitles.last;
    return levelTitles[level - 1];
  }

  /// Progress fraction (0.0 to 1.0) towards the next level.
  static double progressToNextLevel(int totalXp) {
    final level = levelFromXp(totalXp);
    final currentLevelXp = xpForLevel(level);
    final nextLevelXp = xpForLevel(level + 1);
    final span = nextLevelXp - currentLevelXp;
    if (span <= 0) return 1.0;
    return ((totalXp - currentLevelXp) / span).clamp(0.0, 1.0);
  }

  /// Number of XP earned within the current level.
  static int currentLevelEarnedXp(int totalXp) {
    final level = levelFromXp(totalXp);
    return max(0, totalXp - xpForLevel(level));
  }

  /// Total XP required to advance from the current level to the next.
  static int currentLevelRequiredXp(int totalXp) {
    final level = levelFromXp(totalXp);
    return xpForLevel(level + 1) - xpForLevel(level);
  }

  /// Evaluates 1 to 3 stars earned for a session based on completion, accuracy,
  /// average response time, and the topic/difficulty target time.
  static int calculateStars({
    required double accuracy,
    required double avgTimeMs,
    required double targetTimeMs,
  }) {
    if (accuracy >= star3MinAccuracy && avgTimeMs <= targetTimeMs) {
      return 3;
    }
    if (accuracy >= star2MinAccuracy) {
      return 2;
    }
    return 1;
  }
}
