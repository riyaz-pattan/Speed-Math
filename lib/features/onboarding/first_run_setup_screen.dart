// lib/features/onboarding/first_run_setup_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme.dart';
import '../../core/ads/ad_config.dart';
import '../../core/constants/habit_constants.dart';
import '../../core/enums/enums.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/repositories/settings_repository.dart';
import '../practice_session/models/practice_models.dart';

/// 4-step onboarding and setup wizard shown on fresh app installations.
class FirstRunSetupScreen extends ConsumerStatefulWidget {
  const FirstRunSetupScreen({super.key});

  @override
  ConsumerState<FirstRunSetupScreen> createState() => _FirstRunSetupScreenState();
}

class _FirstRunSetupScreenState extends ConsumerState<FirstRunSetupScreen> {
  int _currentStep = 0; // 0: Welcome, 1: Daily Goal, 2: Reminders, 3: Find Level
  int _selectedGoalMinutes = 10;
  bool _remindersEnabled = false;
  String _reminderTime = '19:00';

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider);
    _selectedGoalMinutes = settings.dailyGoalMinutes;
    _reminderTime = settings.reminderTime;
  }

  Future<void> _finishSetupAndGoHome() async {
    HapticFeedback.selectionClick();
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setDailyGoalMinutes(_selectedGoalMinutes);
    await settings.setRemindersEnabled(_remindersEnabled);
    await settings.setReminderTime(_reminderTime);
    await settings.setOnboardingDone(true);

    if (_remindersEnabled) {
      await ref.read(notificationServiceProvider).syncReminders();
    }
    ref.read(dataRevisionProvider.notifier).state++;

    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _startLevelAssessment() async {
    HapticFeedback.selectionClick();
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setDailyGoalMinutes(_selectedGoalMinutes);
    await settings.setRemindersEnabled(_remindersEnabled);
    await settings.setReminderTime(_reminderTime);
    await settings.setOnboardingDone(true);

    if (_remindersEnabled) {
      await ref.read(notificationServiceProvider).syncReminders();
    }
    ref.read(dataRevisionProvider.notifier).state++;

    // 12 mixed questions: 2 each of 6 core topics
    final config = PracticeConfig(
      topic: Topic.mixed,
      difficulty: Difficulty.mixed,
      mode: PracticeMode.questions,
      modeValue: 12,
      sessionSeed: Random().nextInt(1000000),
      kind: SessionKind.mixed,
      selectedTopics: const [
        Topic.addition,
        Topic.subtraction,
        Topic.multiplication,
        Topic.division,
        Topic.squares,
        Topic.percentages,
      ],
      autoSubmit: settings.autoSubmit,
      hapticsEnabled: settings.hapticsEnabled,
      vibrationStrength: settings.vibrationStrength,
      soundEnabled: settings.soundEnabled,
      correctSoundEnabled: settings.correctSoundEnabled,
      wrongSoundEnabled: settings.wrongSoundEnabled,
      soundVolume: settings.soundVolume,
      correctSoundVolume: settings.correctSoundVolume,
      wrongSoundVolume: settings.wrongSoundVolume,
      keypadStyle: settings.keypadStyle,
      focusOnWeakAreas: false,
    );

    if (mounted) {
      context.go('/practice/session', extra: config);
    }
  }

  void _nextStep() {
    HapticFeedback.selectionClick();
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _finishSetupAndGoHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _buildProgressIndicator(),
        actions: [
          TextButton(
            onPressed: _finishSetupAndGoHome,
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildCurrentStepContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index == _currentStep;
        final isPassed = index < _currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primaryColor
                : isPassed
                    ? AppTheme.primaryColor.withValues(alpha: 0.4)
                    : AppTheme.borderLight,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepWelcome();
      case 1:
        return _buildStepGoal();
      case 2:
        return _buildStepReminders();
      case 3:
      default:
        return _buildStepFindLevel();
    }
  }

  // --- Step 1: Welcome ---
  Widget _buildStepWelcome() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppTheme.primaryTint,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.bolt_rounded,
              size: 42,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Mental Calculation Tricks',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Master rapid mental calculations with clean visual shortcuts and adaptive daily drills.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        _buildFeatureItem(
          icon: Icons.flash_on_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Adaptive Practice',
          subtitle: 'Drills that adapt to your speed and targeting your weak areas.',
        ),
        const SizedBox(height: 14),
        _buildFeatureItem(
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Shortcut Notebooks',
          subtitle: 'Visual, step-by-step methods for multiplication, divisibility, and roots.',
        ),
        const SizedBox(height: 14),
        _buildFeatureItem(
          icon: Icons.insights_rounded,
          iconColor: AppTheme.primaryColor,
          title: 'Progress & Habits',
          subtitle: 'Personal performance analytics and daily streak tracking.',
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Practice works offline. Your practice data stays on your phone. Ads, when you are online, are provided by Google AdMob.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _nextStep,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              final uri = Uri.parse(AdConfig.privacyPolicyUrl);
              final ctx = context;
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (ctx.mounted) {
                  AppToast.show(ctx, message: 'Please turn on the internet to view our Privacy Policy.', type: AppToastType.warning);
                }
              } catch (_) {
                if (ctx.mounted) {
                  AppToast.show(ctx, message: 'Please turn on the internet to view our Privacy Policy.', type: AppToastType.warning);
                }
              }
            },
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Daily Goal ---
  Widget _buildStepGoal() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Choose Your Daily Goal',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Short, regular training sessions compound into effortless mental calculation speed.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            children: HabitConstants.dailyGoalPresets.map((preset) {
              final isSelected = preset == _selectedGoalMinutes;
              final label = HabitConstants.goalLabel(preset);
              final desc = switch (preset) {
                5 => 'A fast 5-minute warm-up for busy days',
                10 => 'Recommended for consistent, steady progress',
                15 => 'Accelerated training to build serious speed',
                20 => 'High-volume practice for rapid reflexes',
                30 => 'Comprehensive deep focus session',
                _ => '$preset minutes per day',
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedGoalMinutes = preset);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryTint : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.borderLight,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.canvasBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '$preset',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$preset min/day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primaryColor,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _nextStep,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Set Goal & Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // --- Step 3: Reminders ---
  Widget _buildStepReminders() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Daily Reminder',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Set a time for a daily check-in to practice mental math and build your speed.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          size: 20, color: AppTheme.primaryColor),
                      SizedBox(width: 10),
                      Text(
                        'Enable daily reminder',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _remindersEnabled,
                    activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) async {
                      HapticFeedback.selectionClick();
                      if (val) {
                        final notif = ref.read(notificationServiceProvider);
                        final granted = await notif.requestPermission();
                        setState(() => _remindersEnabled = granted);
                        if (granted) {
                          final canExact = await notif.canScheduleExactAlarms();
                          if (!canExact) {
                            await notif.openExactAlarmSettings();
                          }
                        }
                      } else {
                        setState(() => _remindersEnabled = false);
                      }
                    },
                  ),
                ],
              ),
              if (_remindersEnabled) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final parts = _reminderTime.split(':');
                    final curTod = TimeOfDay(
                      hour: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 19) : 19,
                      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
                    );
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: curTod,
                    );
                    if (picked != null) {
                      setState(() {
                        _reminderTime =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reminder time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatTime(_reminderTime),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined,
                              size: 16, color: AppTheme.primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _nextStep,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // --- Step 4: Find My Level ---
  Widget _buildStepFindLevel() {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), // Amber tint
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3), width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.speed_rounded,
              size: 40,
              color: Color(0xFFD97706),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Find My Starting Level',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'A quick 12-question check across Addition, Subtraction, Multiplication, Division, Squares, and Percentages to calibrate your skill ratings.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: const Column(
            children: [
              _CheckRow(text: '12 questions • ~2 minutes'),
              SizedBox(height: 8),
              _CheckRow(text: 'Calibrates starting difficulty'),
              SizedBox(height: 8),
              _CheckRow(text: 'Feeds your initial performance report'),
            ],
          ),
        ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _startLevelAssessment,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text(
              'Start 12-Question Check',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _finishSetupAndGoHome,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "I'll start on my own",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 19) : 19;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final tod = TimeOfDay(hour: hour, minute: minute);
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}

class _CheckRow extends StatelessWidget {
  final String text;

  const _CheckRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
