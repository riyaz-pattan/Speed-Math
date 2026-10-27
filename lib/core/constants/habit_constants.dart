// lib/core/constants/habit_constants.dart

/// Constants for habit tracking, daily goals, streaks, and reminders.
class HabitConstants {
  HabitConstants._();

  /// Minimum questions answered in a single day to count as an active day.
  static const int activeDayQuestionThreshold = 10;

  /// Presets available for the user's daily practice goal in minutes.
  static const List<int> dailyGoalPresets = [5, 10, 15, 20, 30];

  /// Default daily goal in minutes.
  static const int defaultDailyGoalMinutes = 10;

  /// Default reminder time formatted as HH:mm (24-hour).
  static const String defaultReminderTime = '19:00';

  /// Key streak milestones that trigger celebration toasts once per reach.
  static const List<int> streakMilestones = [3, 7, 14, 30, 60, 100];

  /// Friendly labels for each daily goal preset.
  static String goalLabel(int minutes) {
    switch (minutes) {
      case 5:
        return 'Light';
      case 10:
        return 'Steady';
      case 15:
        return 'Serious';
      case 20:
        return 'Intense';
      case 30:
        return 'Genius';
      default:
        return '$minutes min';
    }
  }
}
