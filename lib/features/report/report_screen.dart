import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import 'package:speed_math_with_ai/core/widgets/screen_header.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/report/report_constants.dart';
import '../../domain/report/report_data.dart';
import '../../domain/report/todays_plan.dart';
import '../practice_session/models/practice_models.dart';

/// Screen displaying the Performance Report, Speed Score hero, Today's Plan,
/// weekly comparative analytics, and topic mastery breakdowns.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reportAsync = ref.watch(reportViewModelProvider);

    // Auto-refresh when practice data mutations occur
    ref.listen(dataRevisionProvider, (_, __) {
      ref.invalidate(reportDataProvider);
      ref.invalidate(reportViewModelProvider);
    });

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Performance Report',
            subtitle: 'Speed score and mastery insights',
            actions: [
              HeaderIconButton(
                icon: Icons.psychology_rounded,
                tooltip: 'Ask Coach',
                onPressed: () => context.push('/coach'),
              ),
            ],
          ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to generate report',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(reportViewModelProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (vm) {
                final data = vm.data;
                final plan = vm.plan;
                final text = vm.text;

                if (!data.hasEnoughData) {
                  return _buildEmptyState(context, ref, data.totalQuestionsAllTime);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(reportDataProvider);
                    await ref.read(reportViewModelProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // Early Report banner (10-40 questions)
                      if (data.isEarlyReport) ...[
                        _buildEarlyReportBanner(context, data),
                        const SizedBox(height: 14),
                      ],

                      // 1. Speed Score hero card
                      _buildSpeedScoreHero(context, data, text),
                      const SizedBox(height: 18),

                      // 2. Today's Plan (~15 min)
                      _buildTodaysPlanSection(context, ref, plan, text),
                      const SizedBox(height: 18),

                      // 3. This week vs last week (hidden if 0 questions in both windows)
                      if (data.weeklyComparison.currentWindow.questionsAnswered > 0 ||
                          data.weeklyComparison.previousWindow.questionsAnswered > 0) ...[
                        _buildWeeklyComparison(context, data, text),
                        const SizedBox(height: 18),
                      ],

                      // 4. Strong areas (hidden if empty)
                      if (data.strongAreas.isNotEmpty) ...[
                        _buildStrongAreas(context, data),
                        const SizedBox(height: 18),
                      ],

                      // 5. Needs work (hidden if empty)
                      if (data.weakAreas.isNotEmpty) ...[
                        _buildWeakAreas(context, data),
                        const SizedBox(height: 18),
                      ],

                      // 6. Improving and Slipping (hidden if both empty)
                      if (text.improving != null || text.slipping != null) ...[
                        _buildTrendsSection(context, data, text),
                        const SizedBox(height: 18),
                      ],

                      // 7. Topic table in topic colors
                      _buildTopicTable(context, data),
                      const SizedBox(height: 18),

                      // 8. Mistakes summary (hidden if 0 mistakes)
                      if (data.mistakeSummary.totalMistakes > 0) ...[
                        _buildMistakesSummary(context, ref, data),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Early Report Banner (10-40 questions) ---
  Widget _buildEarlyReportBanner(BuildContext context, ReportData data) {
    return TactileCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: AppTheme.radiusMd,
      backgroundColor: AppTheme.primaryTint.withValues(alpha: 0.5),
      borderColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Early report • Gets sharper with more practice (${data.totalQuestionsAllTime}/40 questions answered).',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 1: Speed Score Hero Card ---
  Widget _buildSpeedScoreHero(BuildContext context, ReportData data, dynamic text) {
    final score = data.overallSpeedScore;
    final label = data.speedScoreLabel;
    final scoreInt = score?.round() ?? 0;
    final scoreRatio = (scoreInt / 100.0).clamp(0.0, 1.0);

    final Color ringColor = switch (label) {
      SpeedScoreLabel.elite => AppTheme.successColor,
      SpeedScoreLabel.strong => AppTheme.primaryColor,
      SpeedScoreLabel.building => AppTheme.warningColor,
      _ => AppTheme.textSecondary,
    };

    return TactileCard(
      padding: const EdgeInsets.all(20),
      borderColor: ringColor.withValues(alpha: 0.35),
      child: Column(
        children: [
          Row(
            children: [
              // Score Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: scoreRatio,
                      strokeWidth: 8,
                      backgroundColor: ringColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score != null ? '$scoreInt' : '--',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: ringColor,
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 18),
              // Label & Summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ringColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        score != null
                            ? '${label?.displayName ?? 'No Score'} Speed'
                            : 'Building Data',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ringColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Overall Speed Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          Text(
            score != null
                ? text.headline
                : 'Your Speed Score appears after 5 answers in the same topic and level (${data.answersNeededForSpeedScore} answers still needed).',
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 2: Today's Plan ---
  Widget _buildTodaysPlanSection(
    BuildContext context,
    WidgetRef ref,
    TodayPlan plan,
    dynamic text,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Text(
              "Today's Plan",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: plan.isAllCompleted
                    ? AppTheme.successColor.withValues(alpha: 0.15)
                    : AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${plan.completedCount} of ${plan.totalCount} Done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: plan.isAllCompleted ? AppTheme.successColor : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '3 blocks • ~15 minutes total',
          style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
        ),
        const SizedBox(height: 12),
        ...plan.blocks.map((block) => _buildPlanBlockCard(context, ref, block)),
        const SizedBox(height: 6),
        Text(
          text.closingPush,
          style: const TextStyle(
            fontSize: 12.5,
            fontStyle: FontStyle.italic,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanBlockCard(BuildContext context, WidgetRef ref, PlanBlock block) {
    final topicColor = block.type == PlanBlockType.mistakes || block.type == PlanBlockType.keepSharp
        ? AppTheme.mixedColor
        : AppTheme.getTopicColor(block.config.topic);

    final modeSubtitle = block.config.mode == PracticeMode.timer
        ? 'Timer • ${(block.config.modeValue / 60).round()} min'
        : 'Questions • ${block.config.modeValue} Q';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TactileCard(
        padding: const EdgeInsets.all(14),
        borderRadius: AppTheme.radiusMd,
        borderColor: block.isCompleted
            ? AppTheme.successColor.withValues(alpha: 0.4)
            : AppTheme.borderLight,
        child: Row(
          children: [
            // Done checkbox or number badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: block.isCompleted
                    ? AppTheme.successColor
                    : topicColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: block.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        '#${block.id}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: topicColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      decoration: block.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modeSubtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    block.reason,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Start or Done button
            if (block.isCompleted)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.successColor,
                  ),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: () {
                  final configToLaunch = block.config.copyWith(
                    sessionSeed: DateTime.now().millisecondsSinceEpoch,
                  );
                  context.push('/practice/session', extra: configToLaunch);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(60, 34),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  // --- Section 3: This Week vs Last Week ---
  Widget _buildWeeklyComparison(BuildContext context, ReportData data, dynamic text) {
    final comp = data.weeklyComparison;
    final curr = comp.currentWindow;
    final prev = comp.previousWindow;

    final hasPriorData = prev.questionsAnswered > 0;

    return TactileCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppTheme.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                hasPriorData ? 'This Week vs Last Week' : 'This Week',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Text(
                'Last 7 days',
                style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text.weeklyActivity,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Sessions',
                  value: '${curr.sessionsCount}',
                  delta: hasPriorData ? comp.sessionsDelta : null,
                  isPositiveGood: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Questions',
                  value: '${curr.questionsAnswered}',
                  delta: hasPriorData ? comp.questionsDelta : null,
                  isPositiveGood: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Minutes',
                  value: '${curr.practiceMinutes.round()}m',
                  delta: hasPriorData ? comp.minutesDelta.round() : null,
                  isPositiveGood: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: 'Accuracy',
                  value: '${(curr.accuracy * 100).round()}%',
                  deltaPoints: hasPriorData ? (comp.accuracyDelta * 100).round() : null,
                  isPositiveGood: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMetricTile(
            context,
            label: 'Avg Time / Q',
            value: curr.avgTimeMsPerCorrect > 0
                ? '${(curr.avgTimeMsPerCorrect / 1000).toStringAsFixed(1)}s'
                : '--',
            deltaPoints: hasPriorData && curr.avgTimeMsPerCorrect > 0 && prev.avgTimeMsPerCorrect > 0
                ? -((curr.avgTimeMsPerCorrect - prev.avgTimeMsPerCorrect) / 1000).round()
                : null,
            isPositiveGood: true,
            customNote: hasPriorData && comp.speedImprovementPercent != null
                ? '${comp.speedImprovementPercent! >= 0 ? '+' : ''}${comp.speedImprovementPercent!.round()}% speed'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    num? delta,
    num? deltaPoints,
    required bool isPositiveGood,
    String? customNote,
  }) {
    Widget? deltaBadge;
    if (deltaPoints != null && deltaPoints != 0) {
      final isPositive = deltaPoints > 0;
      final isGood = isPositiveGood ? isPositive : !isPositive;
      final color = isGood ? AppTheme.successColor : AppTheme.errorColor;
      deltaBadge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          Text(
            '${deltaPoints.abs()} pts',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      );
    } else if (delta != null && delta != 0) {
      final isPositive = delta > 0;
      final isGood = isPositiveGood ? isPositive : !isPositive;
      final color = isGood ? AppTheme.successColor : AppTheme.errorColor;
      deltaBadge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          Text(
            '${delta.abs()}',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (deltaBadge != null) deltaBadge,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (customNote != null)
            Text(
              customNote,
              style: const TextStyle(fontSize: 9.5, color: AppTheme.textTertiary),
            ),
        ],
      ),
    );
  }

  // --- Section 4: Strong Areas ---
  Widget _buildStrongAreas(BuildContext context, ReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: AppTheme.successColor, size: 20),
                SizedBox(width: 6),
                Text(
                  'Strong Areas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              'Mastery ≥ 80%',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.strongAreas.map((area) {
            final topicColor = AppTheme.getTopicColor(area.topic);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: topicColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: topicColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    area.topic.symbol,
                    style: TextStyle(fontWeight: FontWeight.bold, color: topicColor),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${area.topic.displayName} (${area.difficulty.displayName})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(area.mastery * 100).round()}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Section 5: Needs Work ---
  Widget _buildWeakAreas(BuildContext context, ReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 20),
                SizedBox(width: 6),
                Text(
                  'Needs Work',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              'Mastery < 65%',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: data.weakAreas.map((area) {
            final topicColor = AppTheme.getTopicColor(area.topic);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        area.topic.symbol,
                        style: TextStyle(fontWeight: FontWeight.bold, color: topicColor),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${area.topic.displayName} (${area.difficulty.displayName})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(area.mastery * 100).round()}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (area.weakestPatternExplanation != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      area.weakestPatternExplanation!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Section 6: Trends (Improving and Slipping) ---
  Widget _buildTrendsSection(BuildContext context, ReportData data, dynamic text) {
    return TactileCard(
      padding: const EdgeInsets.all(16),
      borderRadius: AppTheme.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trends & Shifts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (text.improving != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_up_rounded, color: AppTheme.successColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text.improving!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (text.slipping != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_down_rounded, color: AppTheme.errorColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text.slipping!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (text.neglected != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, color: AppTheme.textTertiary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text.neglected!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Section 7: Topic Table ---
  Widget _buildTopicTable(BuildContext context, ReportData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            const Text(
              'Topic Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'All ${data.topicPerformances.length} Topics',
              style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TactileCard(
          padding: EdgeInsets.zero,
          borderRadius: AppTheme.radiusLg,
          child: Column(
            children: data.topicPerformances.asMap().entries.map((entry) {
              final index = entry.key;
              final tp = entry.value;
              final isLast = index == data.topicPerformances.length - 1;
              final topicColor = AppTheme.getTopicColor(tp.topic);

              final trendIcon = switch (tp.trend) {
                TopicTrend.improving => const Icon(Icons.arrow_upward_rounded, size: 16, color: AppTheme.successColor),
                TopicTrend.slipping => const Icon(Icons.arrow_downward_rounded, size: 16, color: AppTheme.errorColor),
                TopicTrend.steady => const Icon(Icons.drag_handle_rounded, size: 16, color: AppTheme.textTertiary),
                TopicTrend.notEnoughData => const SizedBox.shrink(),
              };

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Topic icon / symbol
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: topicColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              tp.topic.symbol,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: topicColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and Level
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tp.topic.displayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                tp.level.displayName,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Accuracy & Avg Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              tp.totalAttempts > 0 ? '${(tp.accuracy * 100).round()}% acc' : '--',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              tp.avgTimeMs > 0 ? '${(tp.avgTimeMs / 1000).toStringAsFixed(1)}s' : '--',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Trend arrow
                        SizedBox(
                          width: 20,
                          child: trendIcon,
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 60,
                      color: AppTheme.borderLight,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- Section 8: Mistakes Summary ---
  Widget _buildMistakesSummary(BuildContext context, WidgetRef ref, ReportData data) {
    final count = data.mistakeSummary.totalMistakes;

    return TactileCard(
      padding: const EdgeInsets.all(18),
      borderRadius: AppTheme.radiusLg,
      borderColor: AppTheme.mixedColor.withValues(alpha: 0.3),
      backgroundColor: AppTheme.mixedColor.withValues(alpha: 0.05),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mixedColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_edu_rounded, color: AppTheme.mixedColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count mistakes to revise',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Spaced repetition drills ready',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              const config = PracticeConfig(
                topic: Topic.mixed,
                difficulty: Difficulty.mixed,
                mode: PracticeMode.mistakes,
                modeValue: 20,
                sessionSeed: 0,
              );
              context.push('/practice/session', extra: config.copyWith(
                sessionSeed: DateTime.now().millisecondsSinceEpoch,
              ));
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.mixedColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Practice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Empty State (< 20 questions) ---
  Widget _buildEmptyState(BuildContext context, WidgetRef ref, int totalQuestions) {
    final progress = totalQuestions.clamp(0, ReportConstants.minTotalQuestionsForReport);
    final needed = ReportConstants.minTotalQuestionsForReport - progress;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(reportDataProvider);
        await ref.read(reportViewModelProvider.future);
      },
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.lock_clock_rounded, size: 48, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 20),
              const Text(
                'Unlock Your Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Answer 10 questions to unlock your Speed Score, strengths, and personalized daily plan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 220,
                  height: 10,
                  child: LinearProgressIndicator(
                    value: (progress / ReportConstants.minTotalQuestionsForReport).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.surfaceSecondary,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$progress / ${ReportConstants.minTotalQuestionsForReport} questions answered ($needed more to go)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: () {
                  final config = PracticeConfig(
                    topic: Topic.mixed,
                    difficulty: Difficulty.mixed,
                    mode: PracticeMode.questions,
                    modeValue: 10,
                    kind: SessionKind.mixed,
                    selectedTopics: Topic.standardTopics,
                    sessionSeed: DateTime.now().millisecondsSinceEpoch,
                  );
                  context.push('/practice/session', extra: config);
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Start practice'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
