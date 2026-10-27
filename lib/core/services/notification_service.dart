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
import '../../data/repositories/settings_repository.dart';

/// Riverpod provider for NotificationService.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return NotificationService(settings);
});

/// Service managing offline local notification reminders for daily practice.
///
/// Architecture for 100% offline, reliable delivery on real Android devices:
///   • Fully local: Does NOT require Firebase Cloud Messaging (FCM) or any internet connection.
///   • Uses Android native [AlarmManager] via [FlutterLocalNotificationsPlugin].
///   • Uses [AndroidScheduleMode.exactAllowWhileIdle] when exact alarms are permitted
///     (wakes the device through Doze mode at the exact minute).
///   • Falls back to [AndroidScheduleMode.inexactAllowWhileIdle] if exact alarms are not granted.
///   • Uses [DateTimeComponents.dayOfWeekAndTime] so alarms repeat weekly on each enabled day
///     automatically at the OS level without needing the app to be open.
///   • Notification IDs 200–206 correspond to Monday (200) through Sunday (206).
///   • Fallback small-icon handling ensures notifications never crash if resources are shrunk.
class NotificationService {
  final SettingsRepository _settings;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  NotificationService(this._settings);

  static const String channelId = 'speed_math_reminders_v4';
  static const String channelName = 'Daily Practice Reminders';
  static const String channelDescription =
      'Gentle daily reminders to practice mental math';

  // Notification IDs: one per weekday (Monday=200 … Sunday=206)
  static const int _baseId = 200;
  static const int testNotificationId = 999;
  static const int testScheduledNotificationId = 998;

  /// Maps 0-based weekday index (0=Mon … 6=Sun) to notification ID.
  static int _idForDay(int dayIndex) => _baseId + dayIndex;

  // ─────────────────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────────────────

  /// Initializes plugin, timezones, and the Android notification channel.
  /// Safe to call multiple times (idempotent).
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize timezone database
    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    // 2. Initialize FlutterLocalNotificationsPlugin with safe launcher icon fallback
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (_) {
          // Android launchMode=singleTop brings MainActivity to foreground automatically
        },
      );
    } catch (e) {
      debugPrint('NotificationService: plugin initialization error: $e');
    }

    // 3. Create high-importance Android Notification Channel
    await _createNotificationChannel();

    _isInitialized = true;
  }

  static Future<void> _configureLocalTimezone() async {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        return;
      } catch (_) {
        _matchTimezoneByUtcOffset();
      }
    } catch (_) {
      _matchTimezoneByUtcOffset();
    }
  }

  static void _matchTimezoneByUtcOffset() {
    try {
      final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
      final match = tz.timeZoneDatabase.locations.values.firstWhere(
        (loc) => loc.currentTimeZone.offset == offsetMs,
        orElse: () => tz.getLocation('UTC'),
      );
      tz.setLocalLocation(match);
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }

  static Future<void> _createNotificationChannel() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('NotificationService: create channel error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // Permission helpers
  // ─────────────────────────────────────────────────────────

  /// Checks if POST_NOTIFICATIONS is granted (Android 13+).
  Future<bool> hasPermission() async {
    if (!_isInitialized) await initialize();
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (impl == null) return true;
      return (await impl.areNotificationsEnabled()) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Requests POST_NOTIFICATIONS permission on Android 13+.
  Future<bool> requestPermission() async {
    if (!_isInitialized) await initialize();
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (impl == null) return true;
      final granted = await impl.requestNotificationsPermission();
      if (granted != null) return granted;
      return (await impl.areNotificationsEnabled()) ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Checks if SCHEDULE_EXACT_ALARM permission is granted by the system (Android 12+).
  Future<bool> canScheduleExactAlarms() async {
    if (!_isInitialized) await initialize();
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (impl == null) return true;
      return (await impl.canScheduleExactNotifications()) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system "Alarms & Reminders" settings screen so the user can allow exact alarms.
  Future<void> openExactAlarmSettings() async {
    if (!_isInitialized) await initialize();
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await impl?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────
  // Core reminder scheduling
  // ─────────────────────────────────────────────────────────

  /// Cancels all existing reminders, then schedules weekly recurring reminders
  /// for each enabled day in [_settings.reminderDays] at [_settings.reminderTime].
  ///
  /// Each notification uses [DateTimeComponents.dayOfWeekAndTime], which tells
  /// Android's native AlarmManager to re-fire every week on that day/time,
  /// entirely independently of whether the app is open or closed.
  Future<void> syncReminders() async {
    if (!_isInitialized) await initialize();

    try {
      // 1. Cancel previous alarms to prevent stale/duplicate entries
      await cancelAllReminders();

      if (!_settings.remindersEnabled) return;

      final enabledDays = _settings.reminderDays; // 0=Mon … 6=Sun
      if (enabledDays.isEmpty) return;

      final phrases = await _loadReminderPhrases();
      final timeStr = _settings.reminderTime; // "HH:mm"
      final parts = timeStr.split(':');
      final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 19) : 19;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      // 2. Select exactAllowWhileIdle if exact alarms are allowed, else inexactAllowWhileIdle
      final canExact = await canScheduleExactAlarms();
      final scheduleMode = canExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        onlyAlertOnce: false,
      );
      const details = NotificationDetails(android: androidDetails);

      final now = tz.TZDateTime.now(tz.local);

      // Build a comprehensive, deduplicated pool of unique reminder phrases
      final pool = <Map<String, String>>[];
      final seenTitles = <String>{};

      void addCategory(String categoryName) {
        final list = (phrases[categoryName] as List<dynamic>?) ?? [];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final t = (item['title'] as String?)?.trim() ?? '';
            final b = (item['body'] as String?)?.trim() ?? '';
            if (t.isNotEmpty && b.isNotEmpty && !seenTitles.contains(t)) {
              seenTitles.add(t);
              pool.add({'title': t, 'body': b});
            }
          }
        }
      }

      addCategory('daily_motivation');
      addCategory('comeback_motivation');
      addCategory('normal');

      // Include active streak phrases with accurate numbers if streak > 0
      final streak = _settings.lastCelebratedStreak;
      if (streak > 0) {
        final streakList = (phrases['streak_motivation'] as List<dynamic>?) ?? [];
        for (final item in streakList) {
          if (item is Map<String, dynamic>) {
            var t = (item['title'] as String?)?.trim() ?? '';
            var b = (item['body'] as String?)?.trim() ?? '';
            t = t.replaceAll('{streak}', '$streak').replaceAll('{streak_plus_one}', '${streak + 1}');
            b = b.replaceAll('{streak}', '$streak').replaceAll('{streak_plus_one}', '${streak + 1}');
            if (t.isNotEmpty && b.isNotEmpty && !seenTitles.contains(t)) {
              seenTitles.add(t);
              pool.add({'title': t, 'body': b});
            }
          }
        }
      }

      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final weekOfYear = (dayOfYear ~/ 7);

      for (final dayIndex in enabledDays) {
        // dayIndex: 0=Mon ... 6=Sun
        // Dart DateTime weekday: 1=Mon ... 7=Sun
        final dartWeekday = dayIndex + 1;

        final scheduledTime = _nextWeekdayTime(now, dartWeekday, hour, minute);

        // Rotating phrase: guaranteed unique across days in the same week,
        // and rotates continuously week-to-week through the entire phrase library.
        String title = 'Daily Mental Math ⚡';
        String body = 'Time for a quick mental calculation workout.';
        if (pool.isNotEmpty) {
          final phraseIndex = (dayIndex * 3 + weekOfYear * 7 + dayOfYear) % pool.length;
          title = pool[phraseIndex]['title'] ?? title;
          body = pool[phraseIndex]['body'] ?? body;
        }

        try {
          await _plugin.zonedSchedule(
            _idForDay(dayIndex),
            title,
            body,
            scheduledTime,
            details,
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          debugPrint(
            'NotificationService: scheduled day=$dayIndex (weekday=$dartWeekday) at $scheduledTime with phrase: "$title"',
          );
        } catch (e) {
          debugPrint('NotificationService: error scheduling day $dayIndex: $e');
        }
      }

      final pending = await _plugin.pendingNotificationRequests();
      debugPrint(
        'NotificationService: ${pending.length} reminder notification(s) actively scheduled.',
      );
    } catch (e, stack) {
      debugPrint('NotificationService: syncReminders failed: $e\n$stack');
    }
  }

  /// Calculates the next future occurrence of [dartWeekday] (1=Mon … 7=Sun)
  /// at [hour]:[minute].
  static tz.TZDateTime _nextWeekdayTime(
    tz.TZDateTime now,
    int dartWeekday,
    int hour,
    int minute,
  ) {
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    int iterations = 0;
    while (candidate.weekday != dartWeekday || !candidate.isAfter(now)) {
      candidate = tz.TZDateTime(
        tz.local,
        candidate.year,
        candidate.month,
        candidate.day + 1,
        hour,
        minute,
        0,
      );
      iterations++;
      if (iterations > 14) break;
    }
    return candidate;
  }

  // ─────────────────────────────────────────────────────────
  // Cancellation
  // ─────────────────────────────────────────────────────────

  /// Cancels the reminder for a specific day index (0=Mon … 6=Sun).
  Future<void> cancelDayReminder(int dayIndex) async {
    if (!_isInitialized) await initialize();
    try {
      await _plugin.cancel(_idForDay(dayIndex));
    } catch (e) {
      debugPrint('NotificationService: cancel day=$dayIndex error: $e');
    }
  }

  /// Cancels all reminder notifications.
  Future<void> cancelAllReminders() async {
    if (!_isInitialized) await initialize();
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: cancelAll error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // Diagnostics & Testing
  // ─────────────────────────────────────────────────────────

  /// Fires an immediate test notification right away.
  Future<void> sendTestReminder() async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        testNotificationId,
        'Speed Math Test ⚡',
        'Notification system is active and working on this device!',
        details,
      );
    } catch (e) {
      debugPrint('NotificationService: sendTestReminder error: $e');
      rethrow;
    }
  }

  /// Schedules a test reminder [seconds] in the future (default 10s).
  /// Perfect for testing that notifications fire when the app is minimized or closed!
  Future<void> sendScheduledTestReminder({int seconds = 10}) async {
    if (!_isInitialized) await initialize();

    final canExact = await canScheduleExactAlarms();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );
    const details = NotificationDetails(android: androidDetails);

    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    try {
      await _plugin.zonedSchedule(
        testScheduledNotificationId,
        'Speed Math Test (Background) ⚡',
        'Background alarms are working! Time for a quick mental calculation.',
        scheduledTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
        'NotificationService: scheduled test reminder in $seconds seconds at $scheduledTime',
      );
    } catch (e) {
      debugPrint('NotificationService: sendScheduledTestReminder error: $e');
      rethrow;
    }
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
