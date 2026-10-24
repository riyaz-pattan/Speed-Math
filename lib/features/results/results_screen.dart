import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/enums.dart';
import '../../core/services/haptic_service.dart';
import '../../core/strings/app_strings.dart';
import '../../core/widgets/question_text_widget.dart';
import 'package:speed_math_with_ai/core/widgets/screen_header.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../data/models/attempt.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/questions/session_random.dart';
import '../../domain/scoring/session_summary.dart';
import '../../domain/scoring/xp_calculator.dart';
import '../learn/engine/lesson_registry.dart';
import '../practice_session/models/practice_models.dart';
import 'widgets/confetti_burst.dart';

/// Redesigned results screen featuring score hero card with soft gradient,
/// accuracy circular ring, highlighted badges, tidy stats grid, mistake reviews,
/// and primary "Play Again" with side-by-side secondary actions.
class ResultsScreen extends ConsumerStatefulWidget {
  final PracticeResultData resultData;

  const ResultsScreen({
    super.key,
    required this.resultData,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  PracticeResultData get resultData => widget.resultData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(settingsRepositoryProvider);
      if (settings.hapticsEnabled) {
        ref.read(hapticServiceProvider).resultsCelebration(
          strength: settings.vibrationStrength,
        );
      }
    });
  }

  String _formatDuration(int ms) {
    final totalSeconds = (ms / 1000).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String _formatAvgTime(double ms) {
    if (ms <= 0) return '0.0s';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsRepositoryProvider);
    final summary = resultData.summary;
    final isCompleted = resultData.savedSession?.completed ?? false;
    final isNotDrill = resultData.config.kind != SessionKind.drill ||
        resultData.config.mode == PracticeMode.smart ||
        resultData.config.mode == PracticeMode.mistakes;
    final topicColor = isNotDrill
        ? AppTheme.mixedColor
        : AppTheme.getTopicColor(resultData.config.topic);

    final isPerfectRound = summary.totalQuestions > 0 &&
        summary.correctCount == summary.totalQuestions &&
        summary.wrongCount == 0 &&
        summary.skippedCount == 0;
    final showConfetti = (resultData.isNewBestScore || (isCompleted && isPerfectRound)) &&
        settings.gameEffectsEnabled;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        backgroundColor: AppTheme.canvasBackground,
        body: Column(
          children: [
            ScreenHeader(
              title: isCompleted ? AppStrings.sessionComplete : 'Session Ended',
              leading: HeaderIconButton(
                icon: Icons.close_rounded,
                onPressed: () => context.go('/home'),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          children: [
                            // Subtle banner when session ended early
                            if (!isCompleted)
                              _buildEndedEarlyBanner(context, colorScheme),

                        // Highlighted Badges (New Best Score, New Top-3 Time) — only for drill, only completed
                        if (!isNotDrill &&
                            isCompleted &&
                            (resultData.isNewBestScore || resultData.isNewTop3Time))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                if (resultData.isNewBestScore)
                                  _buildBadge(
                                    icon: Icons.emoji_events_rounded,
                                    label: AppStrings.newBestScore,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                if (resultData.isNewTop3Time)
                                  _buildBadge(
                                    icon: Icons.bolt_rounded,
                                    label: AppStrings.newTop3Time,
                                    color: const Color(0xFF06B6D4),
                                  ),
                              ],
                            ),
                          ),

                        // Large Score Hero Card with soft gradient, Stars & Accuracy Ring
                        _buildScoreHeroCard(
                          context,
                          colorScheme,
                          topicColor,
                          settings.gameEffectsEnabled,
                        ),
                        const SizedBox(height: 16),

                        // XP and Level Progress Card
                        _buildXpLevelCard(
                          context,
                          colorScheme,
                          settings.gameEffectsEnabled,
                        ),
                        const SizedBox(height: 20),

                        // Tidy Stats Grid
                        _buildStatsGrid(context, colorScheme),
                        const SizedBox(height: 20),

                        // Dynamic Coach Insight Card
                        if (resultData.coachInsight != null) ...[
                          _buildCoachInsightCard(context, colorScheme),
                          const SizedBox(height: 24),
                        ],

                        // Per-Topic Breakdown for Mixed or Mistake Practice
                        if (isNotDrill) ...[
                          _buildTopicBreakdownSection(context, colorScheme),
                          const SizedBox(height: 24),
                        ],

                        // Review Mistakes Section
                        _buildMistakesSection(context, colorScheme),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Bottom Action Buttons: ONE big "Play Again" + two secondary buttons side-by-side
                  _buildBottomActions(context, colorScheme),
                ],
              ),

              // Lightweight Confetti burst on new best score or perfect round
              if (showConfetti) const ConfettiBurst(),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildEndedEarlyBanner(BuildContext context, ColorScheme colorScheme) {
    final String detailText;
    if (resultData.config.mode == PracticeMode.timer) {
      detailText = '${_formatDuration(resultData.summary.totalTimeMs)} practiced';
    } else {
      detailText =
          '${resultData.summary.totalQuestions} of ${resultData.config.modeValue} questions answered';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ended early - $detailText',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHeroCard(
    BuildContext context,
    ColorScheme colorScheme,
    Color topicColor,
    bool gameEffectsEnabled,
  ) {
    final summary = resultData.summary;
    final targetTimeMs = AppConstants.getTargetTimeMs(
      resultData.config.topic,
      resultData.config.difficulty,
    ).toDouble();
    final stars = XpCalculator.calculateStars(
      accuracy: summary.accuracy,
      avgTimeMs: summary.avgTimeMsPerCorrect,
      targetTimeMs: targetTimeMs,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Topic and difficulty pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              resultData.config.kind == SessionKind.mixed || resultData.config.mode == PracticeMode.smart
                  ? 'Mixed practice • ${resultData.config.mode == PracticeMode.timer ? "${resultData.config.modeValue ~/ 60}m" : "${resultData.config.modeValue}Q"}'
                  : (resultData.config.kind == SessionKind.mistakes || resultData.config.mode == PracticeMode.mistakes
                      ? 'Mistakes practice • ${resultData.config.modeValue}Q'
                      : '${resultData.config.topic.displayName} - ${resultData.config.difficulty.displayName} • ${resultData.config.mode.displayName}'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 1 to 3 Stars
          _buildStarsRow(stars, gameEffectsEnabled),
          const SizedBox(height: 14),

          // Score and Accuracy Ring row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Final Score Block with smooth count-up
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.finalScore.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  gameEffectsEnabled
                      ? TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: summary.totalScore),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) => Text(
                            val.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -1.0,
                            ),
                          ),
                        )
                      : Text(
                          summary.totalScore.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1.0,
                          ),
                        ),
                ],
              ),

              // Accuracy Ring
              _AccuracyRing(accuracy: summary.accuracy),
            ],
          ),
          const SizedBox(height: 16),

          // Contextual session headline
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _getSessionHeadline(summary),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarsRow(int stars, bool gameEffectsEnabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isFilled = index < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: gameEffectsEnabled
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 280 + index * 120),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, _) => Transform.scale(
                    scale: scale,
                    child: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFilled
                          ? const Color(0xFFFFD700)
                          : Colors.white.withValues(alpha: 0.35),
                      size: 32,
                    ),
                  ),
                )
              : Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled
                      ? const Color(0xFFFFD700)
                      : Colors.white.withValues(alpha: 0.35),
                  size: 32,
                ),
        );
      }),
    );
  }

  Widget _buildXpLevelCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool gameEffectsEnabled,
  ) {
    final totalXpAsync = ref.watch(totalXpProvider);
    final totalXp = totalXpAsync.valueOrNull ?? 0;
    final earnedXp = resultData.summary.totalScore.round();
    final prevXp = max(0, totalXp - earnedXp);
    final prevLevel = XpCalculator.levelFromXp(prevXp);
    final curLevel = XpCalculator.levelFromXp(totalXp);
    final curTitle = XpCalculator.titleForLevel(curLevel);
    final progress = XpCalculator.progressToNextLevel(totalXp);
    final didLevelUp = curLevel > prevLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.additionColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$earnedXp XP',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.additionColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Level $curLevel • $curTitle',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${XpCalculator.currentLevelEarnedXp(totalXp)} / ${XpCalculator.currentLevelRequiredXp(totalXp)} XP',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: gameEffectsEnabled
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) => LinearProgressIndicator(
                      value: val,
                      minHeight: 7,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  )
                : LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
          ),
          if (didLevelUp) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Level Up! You reached Level $curLevel: $curTitle',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSessionHeadline(SessionSummary summary) {
    if (summary.totalQuestions == 0) {
      return 'Session ended with 0 questions attempted.';
    }
    if (summary.skippedCount == summary.totalQuestions) {
      return 'You skipped every question. Try answering, even slowly — speed comes later.';
    }
    if (summary.correctCount == summary.totalQuestions &&
        summary.wrongCount == 0 &&
        summary.skippedCount == 0) {
      return 'Outstanding! Perfect score with zero errors.';
    }
    if (summary.skippedCount > summary.correctCount + summary.wrongCount) {
      return 'You skipped several questions. Give them a shot next time!';
    }
    if (summary.accuracy >= 0.8) {
      return 'Great accuracy! Keep pushing your speed.';
    }
    if (summary.accuracy >= 0.5) {
      return 'Good effort! Practice turns effort into instinct.';
    }
    return 'Keep practicing! Every attempt sharpens your skills.';
  }

  Widget _buildStatsGrid(BuildContext context, ColorScheme colorScheme) {
    final summary = resultData.summary;
    final avgTimePerCorrectMs = summary.avgTimeMsPerCorrect;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.check_circle_rounded,
                  label: AppStrings.correct,
                  value: '${summary.correctCount}',
                  color: AppTheme.additionColor,
                ),
              ),
              Container(width: 1, height: 44, color: colorScheme.outline.withValues(alpha: 0.15)),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.cancel_rounded,
                  label: AppStrings.wrong,
                  value: '${summary.wrongCount}',
                  color: Colors.redAccent,
                ),
              ),
              Container(width: 1, height: 44, color: colorScheme.outline.withValues(alpha: 0.15)),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.skip_next_rounded,
                  label: AppStrings.skipped,
                  value: '${summary.skippedCount}',
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.speed_rounded,
                  label: 'Avg. / Correct',
                  value: _formatAvgTime(avgTimePerCorrectMs),
                  color: colorScheme.primary,
                ),
              ),
              Container(width: 1, height: 44, color: colorScheme.outline.withValues(alpha: 0.15)),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.timer_outlined,
                  label: 'Total Time',
                  value: _formatDuration(summary.totalTimeMs),
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMistakesSection(BuildContext context, ColorScheme colorScheme) {
    final mistakes = resultData.wrongAttempts;
    final summary = resultData.summary;

    final isPerfect = summary.totalQuestions > 0 &&
        summary.correctCount == summary.totalQuestions &&
        summary.wrongCount == 0 &&
        summary.skippedCount == 0;

    if (isPerfect) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.additionColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.additionColor.withValues(alpha: 0.25),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_rounded, color: AppTheme.additionColor, size: 28),
            SizedBox(width: 12),
            Text(
              'Perfect score! Zero mistakes.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.additionColor,
              ),
            ),
          ],
        ),
      );
    }

    if (mistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    final allSkipped = summary.skippedCount == summary.totalQuestions;
    final headerTitle = allSkipped
        ? 'Skipped Questions'
        : (summary.skippedCount > 0 ? 'Review Mistakes & Skips' : 'Review Mistakes');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              headerTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (allSkipped ? Colors.grey : Colors.red).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${mistakes.length} to review',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: allSkipped ? Colors.grey.shade700 : Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...mistakes.map((attempt) {
          final isSkipped = attempt.isSkipped;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSkipped
                    ? Colors.grey.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      QuestionTextWidget(
                        text: attempt.question.displayText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isSkipped
                                ? 'Skipped'
                                : (attempt.question.isFractionAnswer
                                    ? (attempt.isCorrect
                                        ? 'You: ${attempt.question.targetAnswer}'
                                        : 'You: Incorrect')
                                    : 'You: ${attempt.userAnswer ?? "—"}'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSkipped ? Colors.grey : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Answer: ${attempt.question.targetAnswer}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.additionColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatAvgTime(attempt.timeMs.toDouble()),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    // Learn this trick button
                    Builder(builder: (ctx) {
                      final lessons = LessonRegistry.forTopic(attempt.question.topic);
                      if (lessons.isEmpty) return const SizedBox.shrink();
                      final lesson = lessons.first;
                      return GestureDetector(
                        onTap: () => ctx.push('/learn/${lesson.id}'),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Learn trick →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopicBreakdownSection(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    // Group attempts by topic
    final Map<Topic, List<Attempt>> topicGroups = {};
    for (final a in resultData.savedAttempts) {
      topicGroups.putIfAbsent(a.topic, () => []).add(a);
    }

    if (topicGroups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance by Topic',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...topicGroups.entries.map((entry) {
          final topic = entry.key;
          final attempts = entry.value;
          final total = attempts.length;
          final correct = attempts.where((a) => a.isCorrect).length;
          final totalTime = attempts.fold<int>(0, (sum, a) => sum + a.timeMs);
          final avgTimeMs = total > 0 ? (totalTime / total.toDouble()) : 0.0;
          final topicColor = AppTheme.getTopicColor(topic);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TactileCard(
              borderRadius: AppTheme.radiusMd,
              borderColor: topicColor.withValues(alpha: 0.25),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: topicColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      topic.symbol,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: topicColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '$correct / $total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: topicColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _formatAvgTime(avgTimeMs),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCoachInsightCard(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final insight = resultData.coachInsight;
    if (insight == null || insight.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.psychology_rounded,
                size: 22,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coach insight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ONE big primary button "Play Again"
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () {
                final freshConfig = resultData.config.copyWith(
                  sessionSeed: SessionRandom.newSessionSeed(),
                );
                context.pushReplacement('/practice/session', extra: freshConfig);
              },
              icon: const Icon(Icons.replay_rounded, size: 22),
              label: const Text(
                AppStrings.playAgain,
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
          const SizedBox(height: 10),

          // Two smaller secondary buttons side-by-side: "Change Setup" and "Home"
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/practice'),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.changeSetup,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      AppStrings.home,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular progress ring displaying accuracy percentage in center.
class _AccuracyRing extends StatelessWidget {
  final double accuracy;

  const _AccuracyRing({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final percent = (accuracy * 100).round();
    final ringColor = accuracy >= 0.8
        ? AppTheme.additionColor
        : accuracy >= 0.5
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: accuracy.clamp(0.0, 1.0),
            strokeWidth: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'ACC',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.82),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
