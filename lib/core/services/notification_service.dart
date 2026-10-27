// lib/core/services/notification_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/settings_repository.dart';

/// Riverpod provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final habitRepo = ref.watch(habitRepositoryProvider);
  return NotificationService(settings, habitRepo);
});

/// A pure plan descriptor for a scheduled reminder notification.
class ScheduledReminderPlan {
  final int id;
  final tz.TZDateTime scheduledDateTime;
  final String situation;
  final String title;
  final String body;

  const ScheduledReminderPlan({
    required this.id,
    required this.scheduledDateTime,
    required this.situation,
    required this.title,
    required this.body,
  });

  @override
  String toString() =>
      'ScheduledReminderPlan(id: $id, date: $scheduledDateTime, situation: $situation, title: "$title")';
}

/// Service managing offline local notification reminders for habits.
class NotificationService {
  final SettingsRepository _settings;
  final HabitRepository _habitRepo;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  NotificationService(this._settings, this._habitRepo);

  /// Initializes the notification plugin, local timezone data, and Android channel.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (locErr) {
        // Fallback: match by local UTC offset in milliseconds
        final deviceOffsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
        final match = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == deviceOffsetMs,
          orElse: () => tz.getLocation('UTC'),
        );
        tz.setLocalLocation(match);
      }
    } catch (_) {
      try {
        final deviceOffsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
        final match = tz.timeZoneDatabase.locations.values.firstWhere(
          (loc) => loc.currentTimeZone.offset == deviceOffsetMs,
          orElse: () => tz.getLocation('UTC'),
        );
        tz.setLocalLocation(match);
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // App will open to Home screen automatically by default
        },
      );

      // Create Android Notification Channel explicitly
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'speed_math_reminders_v3',
          'Daily Practice Reminders',
          description: 'Gentle daily reminders to practice speed math',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('NotificationService: plugin initialization error: $e');
    }

    _isInitialized = true;
  }

  /// Pure function to build the 7-day reminder scheduling plan with rotating motivational content.
  static List<ScheduledReminderPlan> buildReminderPlan({
    required DateTime now,
    required String reminderTime, // "HH:mm"
    required bool isTodayActiveOrGoalMet,
    required int currentStreak,
    required int daysSinceLastActive,
    required Map<String, dynamic> phrases,
  }) {
    final List<ScheduledReminderPlan> plan = [];

    // Parse reminder hour and minute
    final parts = reminderTime.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 19) : 19;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    // Use exact local timezone location with robust uninitialized guard
    tz.Location tzLocation;
    if (now is tz.TZDateTime) {
      tzLocation = now.location;
    } else {
      try {
        tzLocation = tz.local;
      } catch (_) {
        try {
          tzLocation = tz.getLocation('UTC');
        } catch (_) {
          tz_data.initializeTimeZones();
          tzLocation = tz.getLocation('UTC');
        }
      }
    }
    final tzNow = (now is tz.TZDateTime)
        ? now
        : tz.TZDateTime(tzLocation, now.year, now.month, now.day, now.hour, now.minute, now.second);

    // Up to 7 days ahead (day 0 through day 6)
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = tzNow.add(Duration(days: dayOffset));
      // Strict 0th second for precision, directly constructed in tzLocation
      final scheduledTime = tz.TZDateTime(
        tzLocation,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
        0,
      );

      // Day 0 (today)
      if (dayOffset == 0) {
        if (scheduledTime.isBefore(tzNow)) {
          // Reminder time has already passed today
          continue;
        }
      }

      // Select phrasing category:
      // If user has an active streak, use streak_motivation
      // If returning after inactive days, use comeback_motivation for day 0
      // Otherwise use daily_motivation
      String category;
      if (currentStreak > 0 && dayOffset <= 2) {
        category = 'streak_motivation';
      } else if (daysSinceLastActive >= 2 && dayOffset == 0) {
        category = 'comeback_motivation';
      } else {
        category = 'daily_motivation';
      }

      var variantList = (phrases[category] as List<dynamic>?) ?? [];
      if (variantList.isEmpty) {
        // Fallback to normal/daily
        variantList = (phrases['daily_motivation'] as List<dynamic>?) ??
            (phrases['normal'] as List<dynamic>?) ??
            [];
      }
      if (variantList.isEmpty) continue;

      // Rotate deterministically using targetDate so every day has a different inspiring phrase
      final phraseIndex = (targetDate.day + dayOffset * 3) % variantList.length;
      final variantMap = variantList[phraseIndex] as Map<String, dynamic>;
      var title = (variantMap['title'] as String?) ?? 'Daily Mental Math ⚡';
      var body = (variantMap['body'] as String?) ??
          'Time for a quick mental calculation workout.';

      title = title
          .replaceAll('{streak}', '$currentStreak')
          .replaceAll('{streak_plus_one}', '${currentStreak + 1}');
      body = body
          .replaceAll('{streak}', '$currentStreak')
          .replaceAll('{streak_plus_one}', '${currentStreak + 1}');

      plan.add(ScheduledReminderPlan(
        id: 100 + dayOffset,
        scheduledDateTime: scheduledTime,
        situation: category,
        title: title,
        body: body,
      ));
    }

    return plan;
  }

  /// Cancels all previously scheduled reminders and schedules up to 7 days ahead
  /// based on the current habit stats and reminder settings.
  Future<void> syncReminders() async {
    try {
      if (!_settings.remindersEnabled) {
        await cancelAllReminders();
        return;
      }

      await cancelAllReminders();

      final habitData = await _habitRepo.getHabitData();
      final phrases = await _loadReminderPhrases();

      // Determine days since last active
      final now = tz.TZDateTime.now(tz.local);
      final today = DateTime(now.year, now.month, now.day);
      int daysSinceLastActive = 0;
      if (!habitData.isTodayActive) {
        // Find the most recent active day
        DateTime check = today.subtract(const Duration(days: 1));
        daysSinceLastActive = 1;
        while (daysSinceLastActive < 10) {
          final dStr = HabitRepository.formatDate(check);
          final isActive = habitData.weekDays.any((w) =>
              HabitRepository.formatDate(w.date) == dStr && w.isActive);
          if (isActive) break;
          check = check.subtract(const Duration(days: 1));
          daysSinceLastActive++;
        }
      }

      final plan = buildReminderPlan(
        now: now,
        reminderTime: _settings.reminderTime,
        isTodayActiveOrGoalMet:
            habitData.isTodayActive || habitData.isGoalMetToday,
        currentStreak: habitData.streakDays,
        daysSinceLastActive: daysSinceLastActive,
        phrases: phrases,
      );

      const androidDetails = AndroidNotificationDetails(
        'speed_math_reminders_v3',
        'Daily Practice Reminders',
        channelDescription: 'Gentle daily reminders to practice speed math',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        enableVibration: true,
      );
      const details = NotificationDetails(android: androidDetails);

      // Use alarmClock schedule mode — this uses AlarmManager.setAlarmClock()
      // which bypasses Samsung battery optimization, Doze, and all OEM restrictions.
      // It is the only mode that CANNOT be suppressed on Samsung/OEM devices.
      const AndroidScheduleMode scheduleMode = AndroidScheduleMode.alarmClock;

      // Also request exact alarm permission if not already granted
      try {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final canExact =
              await androidPlugin.canScheduleExactNotifications() ?? false;
          if (!canExact) {
            await androidPlugin.requestExactAlarmsPermission();
          }
        }
      } catch (_) {}

      for (final item in plan) {
        try {
          await _plugin.zonedSchedule(
            item.id,
            item.title,
            item.body,
            item.scheduledDateTime,
            details,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } catch (e) {
          debugPrint(
              'NotificationService: error scheduling item ${item.id}: $e');
        }
      }

      // Debug: confirm how many notifications are pending
      try {
        final pending = await _plugin.pendingNotificationRequests();
        debugPrint(
            'NotificationService: ${pending.length} notification(s) scheduled: '
            '${pending.map((n) => '${n.id}: ${n.title}').join(', ')}');
      } catch (_) {}
    } catch (e, stack) {
      debugPrint('NotificationService: syncReminders failed safely: $e\n$stack');
    }
  }

  /// Cancels a specific notification by id.
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('NotificationService: cancel error: $e');
    }
  }

  /// Cancels all notifications scheduled by this app.
  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: cancelAll error: $e');
    }
  }

  /// Sends an immediate test notification to verify setup.
  Future<void> sendTestReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'speed_math_reminders_v3',
      'Daily Practice Reminders',
      channelDescription: 'Gentle daily reminders to practice speed math',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        999,
        'Practice check-in ⚡',
        'Your daily speed math reminders are active and ready!',
        details,
      );
    } catch (e) {
      debugPrint('NotificationService: sendTestReminder error: $e');
    }
  }

  /// Checks notification permission status on Android 13+.
  Future<bool> hasPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;
    final granted = await androidImpl.areNotificationsEnabled();
    return granted ?? true;
  }

  /// Requests notification permission on Android 13+.
  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;
    final granted = await androidImpl.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<Map<String, dynamic>> _loadReminderPhrases() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/coach/reminder_phrases.json');
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
