import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('NotificationService.buildReminderPlan', () {
    final Map<String, dynamic> samplePhrases = {
      'daily_motivation': [
        {'title': 'Daily Brain Warmup ⚡', 'body': 'Quick 3-minute drill.'},
        {'title': 'Stay Sharp 🎯', 'body': 'Feel your calculation speed accelerate.'},
        {'title': 'Master Numbers 🧠', 'body': 'Compounds every day.'},
      ],
      'streak_motivation': [
        {'title': 'Keep {streak}-day streak alive! 🔥', 'body': 'Extend to {streak_plus_one} days!'},
      ],
      'comeback_motivation': [
        {'title': 'Ready to restart? ⚡', 'body': 'Reflexes bounce right back.'},
      ],
    };

    test('always schedules at zeroth second', () {
      final now = DateTime(2026, 10, 26, 14, 25, 30);
      final plan = NotificationService.buildReminderPlan(
        now: now,
        reminderTime: '14:27',
        isTodayActiveOrGoalMet: false,
        currentStreak: 0,
        daysSinceLastActive: 0,
        phrases: samplePhrases,
      );

      expect(plan, isNotEmpty);
      for (final p in plan) {
        expect(p.scheduledDateTime.second, 0);
        expect(p.scheduledDateTime.millisecond, 0);
      }
      expect(plan.first.scheduledDateTime.year, 2026);
      expect(plan.first.scheduledDateTime.month, 10);
      expect(plan.first.scheduledDateTime.day, 26);
      expect(plan.first.scheduledDateTime.hour, 14);
      expect(plan.first.scheduledDateTime.minute, 27);
      expect(plan.first.scheduledDateTime.second, 0);
    });

    test('replaces streak placeholders correctly', () {
      final now = DateTime(2026, 10, 26, 10, 0, 0);
      final plan = NotificationService.buildReminderPlan(
        now: now,
        reminderTime: '18:00',
        isTodayActiveOrGoalMet: false,
        currentStreak: 5,
        daysSinceLastActive: 0,
        phrases: samplePhrases,
      );

      expect(plan.first.title, contains('5-day streak'));
      expect(plan.first.body, contains('6 days'));
    });

    test('does not break early and never contains passive-aggressive text', () {
      final now = DateTime(2026, 10, 26, 10, 0, 0);
      final plan = NotificationService.buildReminderPlan(
        now: now,
        reminderTime: '18:00',
        isTodayActiveOrGoalMet: false,
        currentStreak: 0,
        daysSinceLastActive: 10, // Inactive for 10 days
        phrases: samplePhrases,
      );

      // Must schedule 7 items
      expect(plan.length, 7);
      for (final p in plan) {
        expect(p.body, isNot(contains("won't remind you again")));
        expect(p.body, isNot(contains("pausing")));
      }
    });

    test('offset fallback finds matching timezone', () {
      tz_data.initializeTimeZones();
      final deviceOffsetMs = const Duration(hours: 5, minutes: 30).inMilliseconds;
      final match = tz.timeZoneDatabase.locations.values.firstWhere(
        (loc) => loc.currentTimeZone.offset == deviceOffsetMs,
        orElse: () => tz.getLocation('UTC'),
      );
      expect(match.currentTimeZone.offset, deviceOffsetMs);
    });
  });
}
