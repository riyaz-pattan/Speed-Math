import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/wakelock_service.dart';
import '../../core/strings/app_strings.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/question_text_widget.dart';
import '../../data/repositories/settings_repository.dart';
import 'controllers/practice_session_controller.dart';
import 'models/practice_models.dart';
import 'widgets/keypad.dart';

class _SpeedTagInfo {
  final String label;
  final IconData icon;
  final Color color;

  const _SpeedTagInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Fullscreen practice session screen featuring question display,
/// custom keypad, auto-submit, progress tracking, and pause/quit controls.
class PracticeSessionScreen extends ConsumerStatefulWidget {
  final PracticeConfig config;

  const PracticeSessionScreen({
    super.key,
    required this.config,
  });

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen>
    with WidgetsBindingObserver {
  int _lastFeedbackTick = 0;
  bool _hasNavigated = false;
  int _lastAttemptCount = 0;
  _SpeedTagInfo? _speedTag;
  Timer? _speedTagTimer;
  bool _fractionHintDismissed = false;

  int _computeStreak(List<SessionAttempt> attempts, bool currentHasWrongTry) {
    if (currentHasWrongTry) return 0;
    int streak = 0;
    for (int i = attempts.length - 1; i >= 0; i--) {
      if (attempts[i].isCorrect) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockService.enable();
    // Start session once widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(practiceSessionControllerProvider(widget.config).notifier)
          .start();
    });
  }

  @override
  void dispose() {
    _speedTagTimer?.cancel();
    WakelockService.disable();
    WidgetsBinding.instance.removeObserver(this);
    ref.invalidate(practiceSessionControllerProvider(widget.config));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Auto-pause if app goes to background
      ref.read(practiceSessionControllerProvider(widget.config).notifier).pause();
    }
  }

  void _triggerFeedback(
    AnswerFeedback feedback, {
    required bool hapticsEnabled,
    required VibrationStrength vibrationStrength,
  }) {
    if (feedback == AnswerFeedback.none) return;

    if (hapticsEnabled) {
      final haptic = ref.read(hapticServiceProvider);
      if (feedback == AnswerFeedback.correct) {
        haptic.correctAnswer(strength: vibrationStrength);
      } else if (feedback == AnswerFeedback.wrong) {
        haptic.wrongAnswer(strength: vibrationStrength);
      }
    }
  }

  void _navigateToResults(PracticeResultData resultData) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.pushReplacement('/results', extra: resultData);
  }

  Future<void> _handleQuit() async {
    final controller =
        ref.read(practiceSessionControllerProvider(widget.config).notifier);
    final state =
        ref.read(practiceSessionControllerProvider(widget.config));

    controller.pause();

    // Check if at least one question has been answered
    final hasAnswered = state.attempts.isNotEmpty;

    if (!hasAnswered) {
      // NO question answered: simple confirmation; leaving saves nothing
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave practice?'),
          content: const Text('No questions answered yet. Nothing will be saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );

      if (shouldLeave == true) {
        controller.discard();
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.pop();
        }
      } else {
        controller.resume();
      }
      return;
    }

    // At least one question answered: 3 choices
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave practice?'),
        content: Text(
          'You have answered ${state.attempts.length} question${state.attempts.length == 1 ? '' : 's'}. What would you like to do?',
        ),
        actions: [
          // 1. Discard session (saves nothing)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(1),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Discard session'),
          ),
          // 2. Keep practicing (resume)
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(2),
            child: const Text('Keep practicing'),
          ),
          // 3. End and see results (save completed = 0, navigate to Results)
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(3),
            child: const Text('End and see results'),
          ),
        ],
      ),
    );

    if (choice == 3) {
      // End and see results
      final resultData = await controller.quit();
      if (!mounted || _hasNavigated) return;
      if (resultData != null) {
        _navigateToResults(resultData);
      } else {
        _hasNavigated = true;
        context.pop();
      }
    } else if (choice == 1) {
      // Discard session: save nothing at all
      controller.discard();
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.pop();
      }
    } else {
      // Dismissed or choice 2 (Keep practicing)
      controller.resume();
    }
  }

  String _formatTime(int ms) {
    final totalSeconds = (ms / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(practiceSessionControllerProvider(widget.config));
    final controller =
        ref.read(practiceSessionControllerProvider(widget.config).notifier);

    final settings = ref.watch(settingsRepositoryProvider);

    // Watch for state changes that conclude the session or trigger audio/haptics
    ref.listen<PracticeSessionState>(
      practiceSessionControllerProvider(widget.config),
      (prev, next) {
        if (next.feedbackTick != _lastFeedbackTick) {
          _lastFeedbackTick = next.feedbackTick;
          _triggerFeedback(
            next.feedback,
            hapticsEnabled: settings.hapticsEnabled,
            vibrationStrength: settings.vibrationStrength,
          );
        }

        if (next.attempts.length > _lastAttemptCount) {
          _lastAttemptCount = next.attempts.length;
          final lastAttempt = next.attempts.last;
          if (lastAttempt.isCorrect) {
            final streak = _computeStreak(next.attempts, false);
            // Milestone toast
            if (settings.gameEffectsEnabled &&
                (streak == 5 || streak == 10 || streak == 20 || streak == 30)) {
              AppToast.show(
                context,
                message: '$streak in a row! 🔥',
                type: AppToastType.info,
                duration: const Duration(milliseconds: 1500),
              );
              if (settings.hapticsEnabled) {
                ref.read(hapticServiceProvider).keyPress(strength: VibrationStrength.light);
              }
            }

            // Speed tag
            if (settings.gameEffectsEnabled) {
              final targetMs = AppConstants.getTargetTimeMs(
                lastAttempt.question.topic,
                lastAttempt.question.difficulty,
              );
              final _SpeedTagInfo tag;
              if (lastAttempt.timeMs <= targetMs * 0.5) {
                tag = const _SpeedTagInfo(
                  label: 'Lightning',
                  icon: Icons.bolt_rounded,
                  color: Colors.amber,
                );
              } else if (lastAttempt.timeMs <= targetMs) {
                tag = const _SpeedTagInfo(
                  label: 'On pace',
                  icon: Icons.speed_rounded,
                  color: Color(0xFF10B981),
                );
              } else {
                tag = const _SpeedTagInfo(
                  label: 'Steady',
                  icon: Icons.check_circle_outline_rounded,
                  color: Color(0xFF6B7280),
                );
              }

              _speedTagTimer?.cancel();
              setState(() => _speedTag = tag);
              _speedTagTimer = Timer(const Duration(milliseconds: 600), () {
                if (mounted) setState(() => _speedTag = null);
              });
            }
          }
        }

        if (prev?.status != PracticeSessionStatus.completed &&
            next.status == PracticeSessionStatus.completed) {
          controller.finishSession().then((resultData) {
            if (!mounted || _hasNavigated) return;
            _navigateToResults(resultData);
          });
        }
      },
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPaused = state.status == PracticeSessionStatus.paused;
    final topicColor = AppTheme.getTopicColor(state.config.topic);

    final streak = _computeStreak(state.attempts, state.currentQuestionHasWrongTry);
    final liveScore = state.attempts.fold<double>(0.0, (sum, a) => sum + a.points).round();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleQuit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // Main practice interface
              Column(
                children: [
                  // Progress bar at the top (with milestone dots in Question mode)
                  _buildTopProgressBar(
                    state: state,
                    colorScheme: colorScheme,
                    topicColor: topicColor,
                  ),

                  // Session topic & difficulty chip, and streak chip
                  _buildSessionChip(
                    widget.config,
                    topicColor,
                    streak: streak,
                    gameEffectsEnabled: settings.gameEffectsEnabled,
                  ),

                  // Header with close, progress/timer, live points & correct counter, and pause
                  _buildHeader(
                    state,
                    controller,
                    colorScheme,
                    topicColor,
                    liveScore: liveScore,
                  ),

                  // Center question card and answer input area
                  Expanded(
                    child: _buildQuestionArea(state, controller, colorScheme, topicColor),
                  ),

                  // Dedicated fraction '/' button above the keypad for easy right-thumb reach
                  if (state.currentQuestion.isFractionAnswer) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fraction: numerator / denominator',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                            ),
                          ),
                          Material(
                            color: state.currentInput.contains('/')
                                ? topicColor.withValues(alpha: 0.4)
                                : topicColor,
                            borderRadius: BorderRadius.circular(14),
                            elevation: state.currentInput.contains('/') ? 0 : 2,
                            shadowColor: topicColor.withValues(alpha: 0.35),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: state.currentInput.contains('/')
                                  ? null
                                  : () {
                                      controller.inputSlash();
                                      if (settings.hapticsEnabled) {
                                        ref.read(hapticServiceProvider).keyPress(
                                          strength: settings.vibrationStrength,
                                        );
                                      }
                                      if (!settings.hasSeenFractionInputHint) {
                                        settings.setFractionInputHintSeen();
                                        if (mounted) {
                                          setState(() => _fractionHintDismissed = true);
                                        }
                                      }
                                    },
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '/',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Slash ( / )',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white.withValues(
                                          alpha: state.currentInput.contains('/') ? 0.7 : 1.0,
                                        ),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Thumb-friendly keypad at bottom
                  MathKeypad(
                    onDigitPressed: controller.inputDigit,
                    onBackspacePressed: controller.deleteDigit,
                    onSubmitPressed: controller.submit,
                    onMinusPressed: controller.inputMinus,
                    style: settings.keypadStyle,
                    showSubmit: !settings.autoSubmit,
                    showSlash: false,
                    hapticsEnabled: settings.hapticsEnabled,
                    vibrationStrength: settings.vibrationStrength,
                    hapticService: ref.read(hapticServiceProvider),
                    soundEnabled: settings.soundEnabled,
                  ),
                  const SizedBox(height: 8),
                ],
              ),

              // Paused overlay to conceal question
              if (isPaused) _buildPausedOverlay(controller, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopProgressBar({
    required PracticeSessionState state,
    required ColorScheme colorScheme,
    required Color topicColor,
  }) {
    if (state.config.mode == PracticeMode.timer) {
      final totalMs = state.config.modeValue * 1000;
      final progress = totalMs > 0
          ? (state.timeRemainingMs / totalMs).clamp(0.0, 1.0)
          : 0.0;
      return LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        valueColor: AlwaysStoppedAnimation<Color>(topicColor),
      );
    }

    final totalQ = state.config.modeValue;
    final progress = totalQ > 0
        ? (state.attempts.length / totalQ).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return SizedBox(
          height: 6,
          width: w,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 4,
                width: w,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                width: w * progress,
                decoration: BoxDecoration(
                  color: topicColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Milestone dots at 25%, 50%, 75%
              for (final frac in const [0.25, 0.50, 0.75])
                Positioned(
                  left: (w * frac) - 3,
                  top: -1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: progress >= frac
                          ? (progress > frac ? topicColor : Colors.white)
                          : colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: progress >= frac
                            ? topicColor
                            : colorScheme.outline.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionChip(
    PracticeConfig config,
    Color topicColor, {
    required int streak,
    required bool gameEffectsEnabled,
  }) {
    final String label;
    if (config.mode == PracticeMode.mistakes) {
      label = 'Mistakes Practice';
    } else if (config.topic == Topic.mixed || config.difficulty == Difficulty.mixed) {
      label = 'Mixed • Auto';
    } else {
      label = '${config.topic.displayName} • ${config.difficulty.displayName}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: topicColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: topicColor.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: topicColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (gameEffectsEnabled && streak > 1) ...[
              const SizedBox(width: 8),
              AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepOrange.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: Colors.deepOrangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak in a row',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    PracticeSessionState state,
    PracticeSessionController controller,
    ColorScheme colorScheme,
    Color topicColor, {
    required int liveScore,
  }) {
    final isTimerMode = state.config.mode == PracticeMode.timer;
    final correctCount = state.attempts.where((a) => a.isCorrect).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded),
            tooltip: AppStrings.quit,
            onPressed: _handleQuit,
          ),

          // Central badge: countdown or 7 / 20
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: isTimerMode
                  ? _buildTimerBadge(state.timeRemainingMs, colorScheme)
                  : _buildProgressBadge(
                      current: state.attempts.length + 1,
                      total: state.config.modeValue,
                      colorScheme: colorScheme,
                    ),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live score points badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 3),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: liveScore.toDouble()),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, val, _) => Text(
                        '${val.round()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Live correct answers counter badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.additionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.additionColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppTheme.additionColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$correctCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.additionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  state.status == PracticeSessionStatus.paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                ),
                tooltip: AppStrings.pause,
                onPressed: () {
                  if (state.status == PracticeSessionStatus.paused) {
                    controller.resume();
                  } else {
                    controller.pause();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBadge(int timeRemainingMs, ColorScheme colorScheme) {
    final isUrgent = timeRemainingMs <= 10000;
    final formattedTime = _formatTime(timeRemainingMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? Colors.red : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 16,
            color: isUrgent ? Colors.red : colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge({
    required int current,
    required int total,
    required ColorScheme colorScheme,
  }) {
    final displayCurrent = current > total ? total : current;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '$displayCurrent / $total',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildQuestionArea(
    PracticeSessionState state,
    PracticeSessionController controller,
    ColorScheme colorScheme,
    Color topicColor,
  ) {
    final currentTopic = state.currentQuestion.topic;
    final settings = ref.watch(settingsRepositoryProvider);
    final activeColor = state.config.mode == PracticeMode.smart ||
            state.config.mode == PracticeMode.mistakes
        ? AppTheme.getTopicColor(currentTopic)
        : topicColor;

    final isApproximation = currentTopic == Topic.approximation;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large rounded question card with subtle topic accent (reduced margin & padding for maximum width)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.35),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Topic icon & title header inside card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentTopic.symbol,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentTopic.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (state.currentQuestionIsReplay) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'REVIEW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Measured, responsive question text
                  QuestionTextWidget(
                    text: state.currentQuestion.displayText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Answer display box
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 200,
                      maxWidth: 280,
                      minHeight: 58,
                      maxHeight: 58,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: state.currentInput.isNotEmpty
                            ? topicColor
                            : const Color(0xFFCBD5E1),
                        width: state.currentInput.isNotEmpty ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: state.currentInput.isEmpty
                          ? Text(
                              state.currentQuestion.isFractionAnswer
                                  ? '? / ?'
                                  : 'Type your answer',
                              style: TextStyle(
                                fontSize: state.currentQuestion.isFractionAnswer ? 22 : 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: state.currentQuestion.isFractionAnswer ? 2.0 : 0.2,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                state.currentInput,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Speed tag (Lightning / On pace / Steady) for 600ms
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 20,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _speedTag != null
                            ? Row(
                                key: ValueKey(_speedTag!.label),
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _speedTag!.icon,
                                    size: 15,
                                    color: _speedTag!.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _speedTag!.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _speedTag!.color,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // Special hint line for Approximation questions
                  if (isApproximation) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Round each number first, then calculate.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            if (state.currentQuestion.isFractionAnswer &&
                !settings.hasSeenFractionInputHint &&
                !_fractionHintDismissed) ...[
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: activeColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: activeColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Type numerator, tap the \'/\' button above keypad, then denominator (e.g. 1/8)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: activeColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        settings.setFractionInputHintSeen();
                        if (mounted) {
                          setState(() => _fractionHintDismissed = true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Clear, small Skip button near the question
            TextButton.icon(
              onPressed: controller.skip,
              icon: Icon(
                Icons.skip_next_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              label: Text(
                AppStrings.skip,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedOverlay(
    PracticeSessionController controller,
    ColorScheme colorScheme,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_filled_rounded,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              AppStrings.paused,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 180,
              height: 48,
              child: FilledButton.icon(
                onPressed: controller.resume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  AppStrings.resumeSession,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 180,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _handleQuit,
                icon: const Icon(Icons.close_rounded),
                label: const Text(
                  AppStrings.quit,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
