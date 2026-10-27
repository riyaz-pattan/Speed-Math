// lib/features/home/widgets/upgrade_goal_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/constants/habit_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/settings_repository.dart';

/// One-time upgrade dialog shown to existing users to configure their daily practice goal.
class UpgradeGoalDialog extends ConsumerStatefulWidget {
  const UpgradeGoalDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UpgradeGoalDialog(),
    );
  }

  @override
  ConsumerState<UpgradeGoalDialog> createState() => _UpgradeGoalDialogState();
}

class _UpgradeGoalDialogState extends ConsumerState<UpgradeGoalDialog> {
  late int _selectedMinutes;
  bool _remindersEnabled = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsRepositoryProvider);
    _selectedMinutes = settings.dailyGoalMinutes;
    _remindersEnabled = settings.remindersEnabled;
  }

  Future<void> _handleSave() async {
    HapticFeedback.selectionClick();
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setDailyGoalMinutes(_selectedMinutes);
    await settings.setRemindersEnabled(_remindersEnabled);
    await settings.setOnboardingDone(true);

    if (_remindersEnabled) {
      final notifService = ref.read(notificationServiceProvider);
      await notifService.requestPermission();
      await notifService.syncReminders();
    }

    ref.read(dataRevisionProvider.notifier).state++;
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Set Your Daily Goal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Build consistent speed calculation habits. Choose how many minutes you want to practice each day:',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HabitConstants.dailyGoalPresets.map((preset) {
              final isSelected = preset == _selectedMinutes;
              final label = HabitConstants.goalLabel(preset);
              return ChoiceChip(
                label: Text(
                  '$preset min ($label)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.canvasBackground,
                onSelected: (selected) {
                  if (selected) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedMinutes = preset);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Reminder toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.canvasBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined,
                        size: 18, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text(
                      'Daily reminder',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _remindersEnabled,
                  activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  activeThumbColor: AppTheme.primaryColor,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _remindersEnabled = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: _handleSave,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: const Text(
            'Save Goal',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
