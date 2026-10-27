// lib/data/repositories/habit_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/habit_constants.dart';
import '../db/database_helper.dart';
import '../models/habit_data.dart';
import 'settings_repository.dart';

/// Riverpod provider for HabitRepository.
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return HabitRepository(DatabaseHelper.instance, settings);
});

/// Riverpod provider for live derived HabitData.
/// Updates reactively whenever sessions/lessons change (via dataRevisionProvider).
final habitDataProvider = FutureProvider<HabitData>((ref) async {
  ref.watch(dataRevisionProvider);
  final repo = ref.watch(habitRepositoryProvider);
  return repo.getHabitData();
});

/// Repository that computes derived habit, streak, and daily goal statistics
/// directly from SQLite sessions and lesson_progress.
class HabitRepository {
  final DatabaseHelper _dbHelper;
  final SettingsRepository _settings;

  const HabitRepository(this._dbHelper, this._settings);

  /// Formats [DateTime] into local 'yyyy-MM-dd' string.
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Pure function to calculate current streak from a set of active day strings.
  static int calculateStreak(Set<String> activeDays, DateTime today) {
    final todayStr = formatDate(today);
    final yesterdayStr = formatDate(today.subtract(const Duration(days: 1)));

    DateTime current;
    if (activeDays.contains(todayStr)) {
      current = today;
    } else if (activeDays.contains(yesterdayStr)) {
      current = today.subtract(const Duration(days: 1));
    } else {
      return 0;
    }

    int count = 0;
    while (activeDays.contains(formatDate(current))) {
      count++;
      current = current.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// Pure function to calculate the all-time longest streak in days.
  static int calculateLongestStreak(Set<String> activeDays) {
    if (activeDays.isEmpty) return 0;
    final sorted = activeDays.map((s) => DateTime.parse(s)).toList()..sort();
    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? previous;

    for (final date in sorted) {
      if (previous == null) {
        currentStreak = 1;
      } else {
        // Difference in calendar days
        final prevNorm = DateTime(previous.year, previous.month, previous.day);
        final currNorm = DateTime(date.year, date.month, date.day);
        final diff = currNorm.difference(prevNorm).inDays;
        if (diff == 1) {
          currentStreak++;
        } else if (diff > 1) {
          currentStreak = 1;
        }
      }
      previous = date;
      if (currentStreak > maxStreak) {
        maxStreak = currentStreak;
      }
    }
    return maxStreak;
  }

  /// Fetches and derives all habit statistics.
  Future<HabitData> getHabitData({DateTime? nowOverride}) async {
    final now = nowOverride ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = formatDate(today);
    final maxAllowedFuture = now.add(const Duration(days: 1)).toIso8601String();

    final db = await _dbHelper.database;
    final goalMinutes = _settings.dailyGoalMinutes;

    // 1. Query sessions grouped by local calendar day
    final sessionRows = await db.rawQuery('''
      SELECT
        (CASE WHEN started_at LIKE '%Z' THEN date(started_at, 'localtime') ELSE date(started_at) END) AS day,
        SUM(duration_ms) AS total_duration_ms,
        SUM(correct_count + wrong_count) AS answered_count
      FROM ${DatabaseHelper.tableSessions}
      WHERE started_at <= ?
      GROUP BY day
    ''', [maxAllowedFuture]);

    // 2. Query completed lessons grouped by local calendar day
    final lessonRows = await db.rawQuery('''
      SELECT
        (CASE WHEN last_completed_at LIKE '%Z' THEN date(last_completed_at, 'localtime') ELSE date(last_completed_at) END) AS day,
        COUNT(*) AS completed_count
      FROM ${DatabaseHelper.tableLessonProgress}
      WHERE last_completed_at IS NOT NULL AND last_completed_at <= ?
      GROUP BY day
    ''', [maxAllowedFuture]);

    // Aggregations by day string
    final Map<String, int> durationMsByDay = {};
    final Map<String, int> answeredByDay = {};
    for (final row in sessionRows) {
      final day = row['day'] as String?;
      if (day == null) continue;
      durationMsByDay[day] = ((row['total_duration_ms'] as num?)?.toInt() ?? 0);
      answeredByDay[day] = ((row['answered_count'] as num?)?.toInt() ?? 0);
    }

    final Map<String, int> lessonsByDay = {};
    for (final row in lessonRows) {
      final day = row['day'] as String?;
      if (day == null) continue;
      lessonsByDay[day] = ((row['completed_count'] as num?)?.toInt() ?? 0);
    }

    // Determine all active days
    final Set<String> allDays = {
      ...durationMsByDay.keys,
      ...lessonsByDay.keys,
    };

    final Set<String> activeDays = {};
    final Map<String, int> minutesByDay = {};

    for (final day in allDays) {
      final ms = durationMsByDay[day] ?? 0;
      final mins = ms ~/ 60000;
      minutesByDay[day] = mins;

      final answered = answeredByDay[day] ?? 0;
      final lessons = lessonsByDay[day] ?? 0;

      if (answered >= HabitConstants.activeDayQuestionThreshold || lessons > 0) {
        activeDays.add(day);
      }
    }

    // Today's metrics
    final practiceMinutesToday = minutesByDay[todayStr] ?? 0;
    final isTodayActive = activeDays.contains(todayStr);
    final isGoalMetToday = practiceMinutesToday >= goalMinutes;
    final goalProgressToday = goalMinutes > 0
        ? (practiceMinutesToday / goalMinutes).clamp(0.0, 1.0)
        : 0.0;

    // Streaks
    final streakDays = calculateStreak(activeDays, today);
    final longestStreak = calculateLongestStreak(activeDays);
    final totalActiveDays = activeDays.length;

    // Weekday strip (Mon to Sun of current week)
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    int weekPracticeMinutes = 0;

    final weekDays = List.generate(7, (i) {
      final d = DateTime(monday.year, monday.month, monday.day).add(Duration(days: i));
      final dStr = formatDate(d);
      final isT = dStr == todayStr;
      final isFut = d.isAfter(today);
      final isAct = activeDays.contains(dStr);
      final mins = minutesByDay[dStr] ?? 0;
      weekPracticeMinutes += mins;
      final isMet = mins >= goalMinutes;

      return HabitWeekDay(
        date: d,
        label: labels[i],
        isActive: isAct,
        isGoalMet: isMet,
        isToday: isT,
        isFuture: isFut,
      );
    });

    // Active days in past 30 days
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    int activeDaysPast30 = 0;
    int totalMinutesOnActiveDays = 0;

    for (final day in activeDays) {
      final dt = DateTime.tryParse(day);
      if (dt != null) {
        if (!dt.isBefore(thirtyDaysAgo) && !dt.isAfter(today)) {
          activeDaysPast30++;
        }
      }
      totalMinutesOnActiveDays += (minutesByDay[day] ?? 0);
    }

    final avgMinutes = totalActiveDays > 0
        ? (totalMinutesOnActiveDays / totalActiveDays)
        : 0.0;

    return HabitData(
      practiceMinutesToday: practiceMinutesToday,
      dailyGoalMinutes: goalMinutes,
      streakDays: streakDays,
      longestStreak: longestStreak,
      totalActiveDays: totalActiveDays,
      isTodayActive: isTodayActive,
      isGoalMetToday: isGoalMetToday,
      goalProgressToday: goalProgressToday,
      weekDays: weekDays,
      weekPracticeMinutes: weekPracticeMinutes,
      activeDaysPast30: activeDaysPast30,
      averageMinutesPerActiveDay: avgMinutes,
    );
  }
}
