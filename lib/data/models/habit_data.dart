// lib/data/models/habit_data.dart

/// Represents a single day in the weekly 7-day strip (Monday to Sunday).
class HabitWeekDay {
  final DateTime date;
  final String label; // "M", "T", "W", "T", "F", "S", "S"
  final bool isActive;
  final bool isGoalMet;
  final bool isToday;
  final bool isFuture;

  const HabitWeekDay({
    required this.date,
    required this.label,
    required this.isActive,
    required this.isGoalMet,
    required this.isToday,
    required this.isFuture,
  });
}

/// Comprehensive habit metrics derived from sessions and lesson progress.
class HabitData {
  final int practiceMinutesToday;
  final int dailyGoalMinutes;
  final int streakDays;
  final int longestStreak;
  final int totalActiveDays;
  final bool isTodayActive;
  final bool isGoalMetToday;
  final double goalProgressToday;
  final List<HabitWeekDay> weekDays; // Mon-Sun of current week
  final int weekPracticeMinutes;
  final int activeDaysPast30;
  final double averageMinutesPerActiveDay;

  const HabitData({
    required this.practiceMinutesToday,
    required this.dailyGoalMinutes,
    required this.streakDays,
    required this.longestStreak,
    required this.totalActiveDays,
    required this.isTodayActive,
    required this.isGoalMetToday,
    required this.goalProgressToday,
    required this.weekDays,
    required this.weekPracticeMinutes,
    required this.activeDaysPast30,
    required this.averageMinutesPerActiveDay,
  });

  static HabitData empty({int dailyGoalMinutes = 10}) {
    final now = DateTime.now();
    // Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final week = List.generate(7, (i) {
      final d = DateTime(monday.year, monday.month, monday.day).add(Duration(days: i));
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      final isFuture = d.isAfter(DateTime(now.year, now.month, now.day));
      return HabitWeekDay(
        date: d,
        label: labels[i],
        isActive: false,
        isGoalMet: false,
        isToday: isToday,
        isFuture: isFuture,
      );
    });

    return HabitData(
      practiceMinutesToday: 0,
      dailyGoalMinutes: dailyGoalMinutes,
      streakDays: 0,
      longestStreak: 0,
      totalActiveDays: 0,
      isTodayActive: false,
      isGoalMetToday: false,
      goalProgressToday: 0.0,
      weekDays: week,
      weekPracticeMinutes: 0,
      activeDaysPast30: 0,
      averageMinutesPerActiveDay: 0.0,
    );
  }
}
