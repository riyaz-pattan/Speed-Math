import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/core/constants/app_constants.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';
import 'package:sqflite/sqflite.dart';

class _FakeResetDatabase implements Database {
  final List<Map<String, dynamic>> sessions = [
    {'id': 1, 'topic': 'addition', 'score': 100},
  ];
  final List<Map<String, dynamic>> attempts = [
    {'id': 1, 'session_id': 1, 'is_correct': 1},
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    if (table == DatabaseHelper.tableSessions) {
      final count = sessions.length;
      sessions.clear();
      return count;
    }
    if (table == DatabaseHelper.tableAttempts) {
      final count = attempts.length;
      attempts.clear();
      return count;
    }
    return 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepository', () {
    late SharedPreferences prefs;
    late SettingsRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = SettingsRepository(prefs);
    });

    test('default settings have correct initial values', () {
      expect(repository.themeMode, ThemeMode.light);
      expect(repository.keypadStyle, KeypadStyle.phone);
      expect(repository.autoSubmit, true);
      expect(repository.autoAdvance, true);
      expect(repository.hapticsEnabled, true);
      expect(repository.soundEnabled, false);
      expect(repository.lastTopic, Topic.addition);
      expect(repository.lastDifficulty, Difficulty.easy);
      expect(repository.lastMode, PracticeMode.questions);
      expect(repository.lastTimerDuration, AppConstants.defaultTimerDuration);
      expect(repository.lastQuestionCount, AppConstants.defaultQuestionCount);
    });

    test('keypadStyle persists and reads back correctly', () async {
      expect(repository.keypadStyle, KeypadStyle.phone);
      await repository.setKeypadStyle(KeypadStyle.calculator);
      expect(repository.keypadStyle, KeypadStyle.calculator);
      expect(SettingsRepository(prefs).keypadStyle, KeypadStyle.calculator);

      await repository.setKeypadStyle(KeypadStyle.phone);
      expect(repository.keypadStyle, KeypadStyle.phone);
    });

    test('toggling auto-submit persists correctly', () async {
      await repository.setAutoSubmit(false);
      expect(repository.autoSubmit, false);
      expect(repository.autoAdvance, false);
      expect(SettingsRepository(prefs).autoSubmit, false);

      await repository.setAutoSubmit(true);
      expect(repository.autoSubmit, true);
      expect(repository.autoAdvance, true);
    });

    test('themeMode is always ThemeMode.light (light mode only)', () async {
      await repository.setThemeMode(ThemeMode.light);
      expect(repository.themeMode, ThemeMode.light);

      final freshRepo = SettingsRepository(prefs);
      expect(freshRepo.themeMode, ThemeMode.light);
    });

    test('ThemeModeNotifier is always ThemeMode.light', () async {
      final notifier = ThemeModeNotifier(repository);
      expect(notifier.state, ThemeMode.light);

      await notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      expect(repository.themeMode, ThemeMode.light);
    });

    test('toggling auto-advance persists correctly', () async {
      await repository.setAutoAdvance(false);
      expect(repository.autoAdvance, false);
      expect(SettingsRepository(prefs).autoAdvance, false);

      await repository.setAutoAdvance(true);
      expect(repository.autoAdvance, true);
    });

    test('toggling haptics persists correctly', () async {
      await repository.setHapticsEnabled(false);
      expect(repository.hapticsEnabled, false);
      expect(SettingsRepository(prefs).hapticsEnabled, false);

      await repository.setHapticsEnabled(true);
      expect(repository.hapticsEnabled, true);
    });

    test('toggling correct and wrong sounds persists correctly', () async {
      expect(repository.correctSoundEnabled, false);
      expect(repository.wrongSoundEnabled, false);

      await repository.setCorrectSoundEnabled(true);
      expect(repository.correctSoundEnabled, true);
      expect(repository.wrongSoundEnabled, false);
      expect(repository.soundEnabled, true);

      await repository.setWrongSoundEnabled(true);
      expect(repository.correctSoundEnabled, true);
      expect(repository.wrongSoundEnabled, true);

      await repository.setCorrectSoundEnabled(false);
      expect(repository.correctSoundEnabled, false);
      expect(repository.wrongSoundEnabled, true);
      expect(repository.soundEnabled, true);

      await repository.setWrongSoundEnabled(false);
      expect(repository.soundEnabled, false);
    });

    test('sound volume defaults to 1.0 and clamps properly', () async {
      expect(repository.soundVolume, 1.0);

      await repository.setSoundVolume(0.5);
      expect(repository.soundVolume, 0.5);
      expect(SettingsRepository(prefs).soundVolume, 0.5);

      await repository.setSoundVolume(1.5);
      expect(repository.soundVolume, 1.0);

      await repository.setSoundVolume(-0.2);
      expect(repository.soundVolume, 0.0);
    });

    test('migrates legacy settings_sound ON to both correct and wrong ON', () async {
      SharedPreferences.setMockInitialValues({
        'settings_sound': true,
      });
      final mockPrefs = await SharedPreferences.getInstance();
      final migratedRepo = SettingsRepository(mockPrefs);

      expect(migratedRepo.correctSoundEnabled, true);
      expect(migratedRepo.wrongSoundEnabled, true);
      expect(mockPrefs.containsKey('settings_sound'), false);
    });

    test('migrates legacy settings_sound OFF to both correct and wrong OFF', () async {
      SharedPreferences.setMockInitialValues({
        'settings_sound': false,
      });
      final mockPrefs = await SharedPreferences.getInstance();
      final migratedRepo = SettingsRepository(mockPrefs);

      expect(migratedRepo.correctSoundEnabled, false);
      expect(migratedRepo.wrongSoundEnabled, false);
      expect(mockPrefs.containsKey('settings_sound'), false);
    });

    test('savePracticeSetup persists all setup attributes', () async {
      await repository.savePracticeSetup(
        topic: Topic.multiplication,
        difficulty: Difficulty.hard,
        mode: PracticeMode.questions,
        timerDuration: 180,
        questionCount: 30,
      );

      final freshRepo = SettingsRepository(prefs);
      expect(freshRepo.lastTopic, Topic.multiplication);
      expect(freshRepo.lastDifficulty, Difficulty.hard);
      expect(freshRepo.lastMode, PracticeMode.questions);
      expect(freshRepo.lastTimerDuration, 180);
      expect(freshRepo.lastQuestionCount, 30);
    });

    test('resetAllData clears database tables and preserves user settings', () async {
      // Configure customized user settings
      await repository.setThemeMode(ThemeMode.dark);
      await repository.setSoundEnabled(true);
      await repository.setHapticsEnabled(false);
      await repository.setAutoAdvance(false);

      final fakeDb = _FakeResetDatabase();
      final dbHelper = DatabaseHelper.withDatabase(fakeDb);

      expect(fakeDb.sessions, isNotEmpty);
      expect(fakeDb.attempts, isNotEmpty);

      // Perform reset
      await repository.resetAllData(dbHelper: dbHelper);

      // Database tables must be emptied
      expect(fakeDb.sessions, isEmpty);
      expect(fakeDb.attempts, isEmpty);

      // Settings must remain intact
      expect(repository.themeMode, ThemeMode.light);
      expect(repository.soundEnabled, true);
      expect(repository.hapticsEnabled, false);
      expect(repository.autoAdvance, false);
    });
  });
}
