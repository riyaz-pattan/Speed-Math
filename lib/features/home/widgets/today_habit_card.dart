// lib/features/home/widgets/today_habit_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/constants/habit_constants.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../data/models/habit_data.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import 'habits_bottom_sheet.dart';

/// Compact "Today" habit card shown on the Home screen below the level chip.
class TodayHabitCard extends ConsumerStatefulWidget {
  const TodayHabitCard({super.key});

  @override
  ConsumerState<TodayHabitCard> createState() => _TodayHabitCardState();
}

class _TodayHabitCardState extends ConsumerState<TodayHabitCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _flameController;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flameController?.dispose();
    super.dispose();
  }

  void _checkMilestones(HabitData habitData) {
    if (habitData.streakDays <= 0) return;
    final settings = ref.read(settingsRepositoryProvider);
    final lastCelebrated = settings.lastCelebratedStreak;

    for (final milestone in HabitConstants.streakMilestones) {
      if (habitData.streakDays >= milestone && lastCelebrated < milestone) {
        settings.setLastCelebratedStreak(milestone);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppToast.show(
              context,
              message: '$milestone-day streak milestone reached! Outstanding consistency!',
              type: AppToastType.success,
            );
          }
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitDataAsync = ref.watch(habitDataProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final gameEffectsOn = settings.gameEffectsEnabled;

    return habitDataAsync.when(
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (habitData) {
        _checkMilestones(habitData);

        final mins = habitData.practiceMinutesToday;
        final goal = habitData.dailyGoalMinutes;
        final progress = habitData.goalProgressToday;
        final streak = habitData.streakDays;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            HabitsBottomSheet.show(context, habitData);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: habitData.isGoalMetToday
                    ? const Color(0xFF10B981).withValues(alpha: 0.35)
                    : AppTheme.borderLight,
              ),
            ),
            child: Column(
              children: [
                // Top row: Goal Ring + Text (left) and Streak Chip (right)
                Row(
                  children: [
                    // Goal progress ring
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 4.5,
                            backgroundColor: AppTheme.borderLight,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              habitData.isGoalMetToday
                                  ? const Color(0xFF10B981)
                                  : AppTheme.primaryColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                          Icon(
                            habitData.isGoalMetToday
                                ? Icons.check_rounded
                                : Icons.timer_outlined,
                            size: 18,
                            color: habitData.isGoalMetToday
                                ? const Color(0xFF10B981)
                                : AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Goal text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$mins of $goal min today',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            habitData.isGoalMetToday
                                ? 'Daily goal reached! 🎉'
                                : '${goal - mins > 0 ? goal - mins : 0} min to reach target',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: habitData.isGoalMetToday
                                  ? const Color(0xFF10B981)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Streak chip
                    _buildStreakChip(streak, gameEffectsOn),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 10),

                // 7-day strip (Mon to Sun)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: habitData.weekDays.map((day) {
                    return _buildDayPill(day);
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStreakChip(int streak, bool gameEffectsOn) {
    final hasStreak = streak > 0;

    Widget flameIcon = Icon(
      hasStreak
          ? Icons.local_fire_department_rounded
          : Icons.local_fire_department_outlined,
      size: 16,
      color: hasStreak ? const Color(0xFFF97316) : AppTheme.textTertiary,
    );

    if (hasStreak && gameEffectsOn && _flameController != null) {
      flameIcon = AnimatedBuilder(
        animation: _flameController!,
        builder: (_, child) {
          final scale = 1.0 + (_flameController!.value * 0.12);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: flameIcon,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasStreak
            ? const Color(0xFFFFF7ED) // Orange tint
            : AppTheme.canvasBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasStreak
              ? const Color(0xFFFDBA74)
              : AppTheme.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          flameIcon,
          const SizedBox(width: 4),
          Text(
            hasStreak ? '$streak ${streak == 1 ? "day" : "days"}' : 'Start streak',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: hasStreak
                  ? const Color(0xFFEA580C)
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPill(HabitWeekDay day) {
    final isToday = day.isToday;
    final isGoalMet = day.isGoalMet;
    final isActive = day.isActive;
    final isFuture = day.isFuture;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day Label (M, T, W, ...)
        Text(
          day.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? AppTheme.primaryColor : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),

        // Indicator dot / check / ring
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday
                ? (isGoalMet
                    ? const Color(0xFF10B981)
                    : isActive
                        ? AppTheme.primaryColor
                        : AppTheme.primaryTint)
                : (isGoalMet
                    ? const Color(0xFF10B981)
                    : isActive
                        ? AppTheme.primaryColor
                        : Colors.transparent),
            border: Border.all(
              color: isToday
                  ? AppTheme.primaryColor
                  : (isActive || isGoalMet
                      ? Colors.transparent
                      : (isFuture ? AppTheme.borderLight : const Color(0xFFCBD5E1))),
              width: isToday ? 2.0 : 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: isGoalMet
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : isActive
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : (isToday
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null),
        ),
      ],
    );
  }
}
