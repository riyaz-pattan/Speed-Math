import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/habit_constants.dart';
import '../../core/enums/enums.dart';
import '../db/database_helper.dart';
import 'skill_repository.dart';

/// Provider for SharedPreferences instance. Must be initialized in main or overridden.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Riverpod provider for SettingsRepository.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(prefs);
});

/// Revision counter to notify screens when database data changes (e.g. on Reset Data).
final dataRevisionProvider = StateProvider<int>((ref) => 0);

/// State notifier provider for active app theme mode.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(settings);
});

/// Notifier handling live theme updates and persistence (always light).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _settings;

  ThemeModeNotifier(this._settings) : super(ThemeMode.light);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = ThemeMode.light;
    await _settings.setThemeMode(mode);
  }
}

/// Repository for persistent app settings and user preferences.
class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs) {
    _migrateSoundSettings();
    _migrateThemeSettings();
  }

  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyAutoAdvance = 'settings_auto_advance';
  static const _keyGameEffects = 'settings_game_effects';
  static const _keyKeypadStyle = 'settings_keypad_style';
  static const _keyHaptics = 'settings_haptics';
  static const _keyVibrationStrength = 'settings_vibration_strength';
  static const _keySound = 'settings_sound';
  static const _keyCorrectSound = 'settings_correct_sound';
  static const _keyWrongSound = 'settings_wrong_sound';
  static const _keySoundVolume = 'settings_sound_volume';
  static const _keyCorrectSoundVolume = 'settings_correct_sound_volume';
  static const _keyWrongSoundVolume = 'settings_wrong_sound_volume';
  static const _keyLastTopic = 'practice_last_topic';
  static const _keyLastDifficulty = 'practice_last_difficulty';
  static const _keyLastMode = 'practice_last_mode';
  static const _keyLastTimerDuration = 'practice_last_timer_duration';
  static const _keyLastQuestionCount = 'practice_last_question_count';
  static const _keyFractionInputHintSeen = 'settings_fraction_input_hint_seen';
  static const _keyDailyGoalMinutes = 'daily_goal_minutes';
  static const _keyRemindersEnabled = 'reminders_enabled';
  static const _keyReminderTime = 'reminder_time';
  /// Stores enabled reminder weekdays as a comma-separated string of ints.
  /// 0=Monday, 1=Tuesday, 2=Wednesday, 3=Thursday, 4=Friday, 5=Saturday, 6=Sunday.
  static const _keyReminderDays = 'reminder_days_v2';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyLastCelebratedStreak = 'last_celebrated_streak';

  void _migrateSoundSettings() {
    if (_prefs.containsKey(_keySound)) {
      final oldVal = _prefs.getBool(_keySound) ?? false;
      if (!_prefs.containsKey(_keyCorrectSound)) {
        _prefs.setBool(_keyCorrectSound, oldVal);
      }
      if (!_prefs.containsKey(_keyWrongSound)) {
        _prefs.setBool(_keyWrongSound, oldVal);
      }
      _prefs.remove(_keySound);
    }
  }

  void _migrateThemeSettings() {
    // Dark mode has been completely removed. Clean up any stale persisted value.
    if (_prefs.containsKey(_keyThemeMode)) {
      _prefs.remove(_keyThemeMode);
    }
  }

  // --- Theme Mode ---

  /// Dark mode has been completely removed. Always returns [ThemeMode.light].
  ThemeMode get themeMode => ThemeMode.light;

  Future<bool> setThemeMode(ThemeMode mode) => _prefs.remove(_keyThemeMode);

  // --- Keypad Style ---

  KeypadStyle get keypadStyle {
    final name = _prefs.getString(_keyKeypadStyle);
    if (name == null) return KeypadStyle.phone;
    return KeypadStyle.values.firstWhere(
      (k) => k.name == name,
      orElse: () => KeypadStyle.phone,
    );
  }

  Future<bool> setKeypadStyle(KeypadStyle style) =>
      _prefs.setString(_keyKeypadStyle, style.name);

  // --- Core Settings ---

  bool get autoSubmit => _prefs.getBool(_keyAutoAdvance) ?? true;
  Future<bool> setAutoSubmit(bool value) =>
      _prefs.setBool(_keyAutoAdvance, value);

  bool get autoAdvance => autoSubmit;
  Future<bool> setAutoAdvance(bool value) => setAutoSubmit(value);

  bool get gameEffectsEnabled => _prefs.getBool(_keyGameEffects) ?? true;
  Future<bool> setGameEffectsEnabled(bool value) =>
      _prefs.setBool(_keyGameEffects, value);

  bool get hapticsEnabled => _prefs.getBool(_keyHaptics) ?? true;
  Future<bool> setHapticsEnabled(bool value) =>
      _prefs.setBool(_keyHaptics, value);

  VibrationStrength get vibrationStrength {
    final name = _prefs.getString(_keyVibrationStrength);
    if (name == null) return VibrationStrength.medium;
    return VibrationStrength.values.firstWhere(
      (s) => s.name == name,
      orElse: () => VibrationStrength.medium,
    );
  }

  Future<bool> setVibrationStrength(VibrationStrength strength) =>
      _prefs.setString(_keyVibrationStrength, strength.name);

  bool get correctSoundEnabled => _prefs.getBool(_keyCorrectSound) ?? false;
  Future<bool> setCorrectSoundEnabled(bool value) =>
      _prefs.setBool(_keyCorrectSound, value);

  bool get wrongSoundEnabled => _prefs.getBool(_keyWrongSound) ?? false;
  Future<bool> setWrongSoundEnabled(bool value) =>
      _prefs.setBool(_keyWrongSound, value);

  double get soundVolume => _prefs.getDouble(_keySoundVolume) ?? 1.0;
  Future<bool> setSoundVolume(double value) =>
      _prefs.setDouble(_keySoundVolume, value.clamp(0.0, 1.0));

  double get correctSoundVolume =>
      _prefs.getDouble(_keyCorrectSoundVolume) ?? soundVolume;
  Future<bool> setCorrectSoundVolume(double value) =>
      _prefs.setDouble(_keyCorrectSoundVolume, value.clamp(0.0, 1.0));

  double get wrongSoundVolume =>
      _prefs.getDouble(_keyWrongSoundVolume) ?? soundVolume;
  Future<bool> setWrongSoundVolume(double value) =>
      _prefs.setDouble(_keyWrongSoundVolume, value.clamp(0.0, 1.0));

  bool get soundEnabled => correctSoundEnabled || wrongSoundEnabled;
  Future<bool> setSoundEnabled(bool value) async {
    await setCorrectSoundEnabled(value);
    return setWrongSoundEnabled(value);
  }

  // --- Fraction Input One-Time Hint ---

  bool get hasSeenFractionInputHint =>
      _prefs.getBool(_keyFractionInputHintSeen) ?? false;

  Future<bool> setFractionInputHintSeen() =>
      _prefs.setBool(_keyFractionInputHintSeen, true);

  // --- Practice Setup History ---

  Topic get lastTopic {
    final name = _prefs.getString(_keyLastTopic);
    if (name == null) return Topic.addition;
    return Topic.values.firstWhere(
      (t) => t.name == name,
      orElse: () => Topic.addition,
    );
  }

  Future<bool> setLastTopic(Topic topic) =>
      _prefs.setString(_keyLastTopic, topic.name);

  Difficulty get lastDifficulty {
    final name = _prefs.getString(_keyLastDifficulty);
    if (name == null) return Difficulty.easy;
    return Difficulty.values.firstWhere(
      (d) => d.name == name,
      orElse: () => Difficulty.easy,
    );
  }

  Future<bool> setLastDifficulty(Difficulty difficulty) =>
      _prefs.setString(_keyLastDifficulty, difficulty.name);

  PracticeMode get lastMode {
    final name = _prefs.getString(_keyLastMode);
    if (name == null) return PracticeMode.questions;
    return PracticeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => PracticeMode.questions,
    );
  }

  Future<bool> setLastMode(PracticeMode mode) =>
      _prefs.setString(_keyLastMode, mode.name);

  int get lastTimerDuration =>
      _prefs.getInt(_keyLastTimerDuration) ?? AppConstants.defaultTimerDuration;

  Future<bool> setLastTimerDuration(int seconds) =>
      _prefs.setInt(_keyLastTimerDuration, seconds);

  int get lastQuestionCount =>
      _prefs.getInt(_keyLastQuestionCount) ?? AppConstants.defaultQuestionCount;

  Future<bool> setLastQuestionCount(int count) =>
      _prefs.setInt(_keyLastQuestionCount, count);

  // --- Unified Practice Setup Preferences ---
  static const _keyPracticeTopics = 'practice_selected_topics';
  static const _keyPracticeDifficulty = 'practice_selected_difficulty';
  static const _keyPracticeFocusWeakAreas = 'practice_focus_weak_areas';

  List<Topic> get practiceTopics {
    final list = _prefs.getStringList(_keyPracticeTopics);
    if (list == null || list.isEmpty) {
      return smartTopics;
    }
    final result = <Topic>[];
    for (final name in list) {
      final t = Topic.values.firstWhere(
        (e) => e.name == name,
        orElse: () => Topic.addition,
      );
      if (t != Topic.mixed && !result.contains(t)) {
        result.add(t);
      }
    }
    return result.isEmpty ? Topic.standardTopics : result;
  }

  Future<bool> setPracticeTopics(List<Topic> topics) {
    return _prefs.setStringList(
      _keyPracticeTopics,
      topics.map((t) => t.name).toList(),
    );
  }

  Difficulty? get practiceDifficulty {
    final val = _prefs.getString(_keyPracticeDifficulty);
    if (val == null) return Difficulty.easy;
    if (val == 'auto') return null;
    return Difficulty.values.firstWhere(
      (d) => d.name == val,
      orElse: () => Difficulty.easy,
    );
  }

  Future<bool> setPracticeDifficulty(Difficulty? difficulty) {
    if (difficulty == null) {
      return _prefs.setString(_keyPracticeDifficulty, 'auto');
    }
    return _prefs.setString(_keyPracticeDifficulty, difficulty.name);
  }

  bool get practiceFocusWeakAreas =>
      _prefs.getBool(_keyPracticeFocusWeakAreas) ?? true;

  Future<bool> setPracticeFocusWeakAreas(bool value) =>
      _prefs.setBool(_keyPracticeFocusWeakAreas, value);

  // --- Legacy Smart Practice Preferences (kept for compatibility) ---

  List<Topic> get smartTopics {
    final list = _prefs.getStringList('practice_smart_topics');
    if (list == null || list.isEmpty) {
      return Topic.standardTopics;
    }
    final result = <Topic>[];
    for (final name in list) {
      final t = Topic.values.firstWhere(
        (e) => e.name == name,
        orElse: () => Topic.addition,
      );
      if (t != Topic.mixed && !result.contains(t)) {
        result.add(t);
      }
    }
    return result.isEmpty ? Topic.standardTopics : result;
  }

  Future<bool> setSmartTopics(List<Topic> topics) {
    return _prefs.setStringList(
      'practice_smart_topics',
      topics.map((t) => t.name).toList(),
    );
  }

  int get smartQuestionCount => _prefs.getInt('practice_smart_question_count') ?? 20;

  Future<bool> setSmartQuestionCount(int count) =>
      _prefs.setInt('practice_smart_question_count', count);

  /// Saves the full practice setup state in one call.
  Future<void> savePracticeSetup({
    required Topic topic,
    required Difficulty difficulty,
    required PracticeMode mode,
    required int timerDuration,
    required int questionCount,
  }) async {
    await setLastTopic(topic);
    await setLastDifficulty(difficulty);
    await setLastMode(mode);
    await setLastTimerDuration(timerDuration);
    await setLastQuestionCount(questionCount);
  }

  /// Saves the unified practice setup state in one call.
  Future<void> saveUnifiedPracticeSetup({
    required List<Topic> topics,
    required Difficulty? difficulty,
    required bool focusWeakAreas,
    required PracticeMode mode,
    required int timerDuration,
    required int questionCount,
  }) async {
    await setPracticeTopics(topics);
    await setPracticeDifficulty(difficulty);
    await setPracticeFocusWeakAreas(focusWeakAreas);
    await setLastMode(mode);
    await setLastTimerDuration(timerDuration);
    await setLastQuestionCount(questionCount);
    if (topics.length == 1) {
      await setLastTopic(topics.first);
    }
    if (difficulty != null) {
      await setLastDifficulty(difficulty);
    }
  }

  // --- Habit & Daily Goal Preferences ---

  int get dailyGoalMinutes =>
      _prefs.getInt(_keyDailyGoalMinutes) ?? HabitConstants.defaultDailyGoalMinutes;

  Future<bool> setDailyGoalMinutes(int minutes) =>
      _prefs.setInt(_keyDailyGoalMinutes, minutes);

  bool get remindersEnabled =>
      _prefs.getBool(_keyRemindersEnabled) ?? false;

  Future<bool> setRemindersEnabled(bool enabled) =>
      _prefs.setBool(_keyRemindersEnabled, enabled);

  String get reminderTime =>
      _prefs.getString(_keyReminderTime) ?? HabitConstants.defaultReminderTime;

  Future<bool> setReminderTime(String time) =>
      _prefs.setString(_keyReminderTime, time);

  /// Returns the list of enabled weekday indices (0=Mon … 6=Sun).
  /// Defaults to all 7 days if not set.
  List<int> get reminderDays {
    final stored = _prefs.getString(_keyReminderDays);
    if (stored == null || stored.isEmpty) {
      // Default: all 7 days enabled
      return [0, 1, 2, 3, 4, 5, 6];
    }
    return stored
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((d) => d >= 0 && d <= 6)
        .toList();
  }

  Future<bool> setReminderDays(List<int> days) {
    final sorted = days.toSet().toList()..sort();
    return _prefs.setString(_keyReminderDays, sorted.join(','));
  }

  bool get isOnboardingDone =>
      _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<bool> setOnboardingDone(bool done) =>
      _prefs.setBool(_keyOnboardingDone, done);

  int get lastCelebratedStreak =>
      _prefs.getInt(_keyLastCelebratedStreak) ?? 0;

  Future<bool> setLastCelebratedStreak(int streak) =>
      _prefs.setInt(_keyLastCelebratedStreak, streak);

  /// Permanently deletes all sessions, attempts, skill ratings, mistake bank, and coach chat while preserving user preferences.
  Future<void> resetAllData({DatabaseHelper? dbHelper}) async {
    final helper = dbHelper ?? DatabaseHelper.instance;
    final db = await helper.database;
    await db.delete(DatabaseHelper.tableAttempts);
    await db.delete(DatabaseHelper.tableSessions);
    await db.delete(SkillRepository.tableSkillRatings);
    await db.delete(DatabaseHelper.tablePatternSkills);
    await db.delete(DatabaseHelper.tableMistakeBank);
    await db.delete(DatabaseHelper.tableCoachMessages);
    await db.delete(DatabaseHelper.tableCoachReports);
    await db.delete(DatabaseHelper.tableLessonProgress);
    await _prefs.remove('smart_question_counter');
    await _prefs.remove('speed_math_todays_plan_date');
    await _prefs.remove('speed_math_todays_plan_blocks');
  }
}
