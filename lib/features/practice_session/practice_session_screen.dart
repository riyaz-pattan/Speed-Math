import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/wakelock_service.dart';
import '../../core/strings/app_strings.dart';
import '../../core/widgets/question_text_widget.dart';
import '../../data/repositories/settings_repository.dart';
import 'controllers/practice_session_controller.dart';
import 'models/practice_models.dart';
import 'widgets/keypad.dart';

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
    WakelockService.disable();
    WidgetsBinding.instance.removeObserver(this);
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

    // Progress calculation for top progress bar
    final double progress;
    if (state.config.mode == PracticeMode.timer) {
      final totalMs = state.config.modeValue * 1000;
      progress = totalMs > 0
          ? (state.timeRemainingMs / totalMs).clamp(0.0, 1.0)
          : 0.0;
    } else {
      final totalQ = state.config.modeValue;
      progress = totalQ > 0
          ? (state.attempts.length / totalQ).clamp(0.0, 1.0)
          : 0.0;
    }

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
                  // Thin smooth progress bar at the top
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(topicColor),
                  ),

                  // Session topic & difficulty chip so user always sees what they selected
                  _buildSessionChip(widget.config, topicColor),

                  // Header with close, progress/timer, live correct counter, and pause
                  _buildHeader(state, controller, colorScheme, topicColor),

                  // Center question card and answer input area
                  Expanded(
                    child: _buildQuestionArea(state, controller, colorScheme, topicColor),
                  ),

                  // Thumb-friendly keypad at bottom
                  MathKeypad(
                    onDigitPressed: controller.inputDigit,
                    onBackspacePressed: controller.deleteDigit,
                    onSubmitPressed: controller.submit,
                    onMinusPressed: controller.inputMinus,
                    style: settings.keypadStyle,
                    showSubmit: !settings.autoSubmit,
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

  Widget _buildSessionChip(PracticeConfig config, Color topicColor) {
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
      child: Center(
        child: Container(
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
      ),
    );
  }

  Widget _buildHeader(
    PracticeSessionState state,
    PracticeSessionController controller,
    ColorScheme colorScheme,
    Color topicColor,
  ) {
    final isTimerMode = state.config.mode == PracticeMode.timer;
    final correctCount = state.attempts.where((a) => a.isCorrect).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: AppStrings.quit,
            onPressed: _handleQuit,
          ),

          // Central badge: countdown or 7 / 20
          if (isTimerMode)
            _buildTimerBadge(state.timeRemainingMs, colorScheme)
          else
            _buildProgressBadge(
              current: state.attempts.length + 1,
              total: state.config.modeValue,
              colorScheme: colorScheme,
            ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live correct answers counter badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      size: 15,
                      color: AppTheme.additionColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$correctCount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.additionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
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
    final activeColor = state.config.mode == PracticeMode.smart ||
            state.config.mode == PracticeMode.mistakes
        ? AppTheme.getTopicColor(currentTopic)
        : topicColor;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large rounded question card with subtle topic accent
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          currentTopic.symbol,
                          style: TextStyle(
                            fontSize: 13,
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
                  const SizedBox(height: 18),

                  // Clear question text (responsive for single and multi-line expressions)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isLong = state.currentQuestion.displayText.length > 25;
                      final baseFontSize = isLong ? 26.0 : 52.0;
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                          minHeight: 64,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: QuestionTextWidget(
                              text: state.currentQuestion.displayText,
                              style: TextStyle(
                                fontSize: baseFontSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: isLong ? 0.0 : -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Answer display box
                  Container(
                    width: 180,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: state.currentInput.isNotEmpty
                            ? topicColor
                            : colorScheme.outline.withValues(alpha: 0.25),
                        width: state.currentInput.isNotEmpty ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        state.currentInput.isEmpty ? '—' : state.currentInput,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: state.currentInput.isEmpty
                              ? colorScheme.outline.withValues(alpha: 0.35)
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
