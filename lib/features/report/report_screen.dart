import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
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
    final colorScheme = theme.colorScheme;
    final reportAsync = ref.watch(reportViewModelProvider);

    // Auto-refresh when practice data mutations occur
    ref.listen(dataRevisionProvider, (_, __) {
      ref.invalidate(reportDataProvider);
      ref.invalidate(reportViewModelProvider);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Performance Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/coach'),
            icon: const Icon(Icons.psychology_rounded),
            tooltip: 'Ask Coach',
          ),
        ],
      ),
      body: SafeArea(
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to generate report',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
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
                    const SizedBox(height: 16),
                  ],

                  // 1. Speed Score hero card
                  _buildSpeedScoreHero(context, data, text),
                  const SizedBox(height: 20),

                  // 2. Today's Plan (~15 min)
                  _buildTodaysPlanSection(context, ref, plan, text),
                  const SizedBox(height: 20),

                  // 3. This week vs last week (hidden if 0 questions in both windows)
                  if (data.weeklyComparison.currentWindow.questionsAnswered > 0 ||
                      data.weeklyComparison.previousWindow.questionsAnswered > 0) ...[
                    _buildWeeklyComparison(context, data, text),
                    const SizedBox(height: 20),
                  ],

                  // 4. Strong areas (hidden if empty)
                  if (data.strongAreas.isNotEmpty) ...[
                    _buildStrongAreas(context, data),
                    const SizedBox(height: 20),
                  ],

                  // 5. Needs work (hidden if empty)
                  if (data.weakAreas.isNotEmpty) ...[
                    _buildWeakAreas(context, data),
                    const SizedBox(height: 20),
                  ],

                  // 6. Improving and Slipping (hidden if both empty)
                  if (text.improving != null || text.slipping != null) ...[
                    _buildTrendsSection(context, data, text),
                    const SizedBox(height: 20),
                  ],

                  // 7. Topic table in topic colors
                  _buildTopicTable(context, data),
                  const SizedBox(height: 20),

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
    );
  }

  // --- Early Report Banner (10-40 questions) ---
  Widget _buildEarlyReportBanner(BuildContext context, ReportData data) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Early report • Gets sharper with more practice (${data.totalQuestionsAllTime}/40 questions answered).',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 1: Speed Score Hero Card ---
  Widget _buildSpeedScoreHero(BuildContext context, ReportData data, dynamic text) {
    final theme = Theme.of(context);
    final score = data.overallSpeedScore;
    final label = data.speedScoreLabel;
    final scoreInt = score?.round() ?? 0;
    final scoreRatio = (scoreInt / 100.0).clamp(0.0, 1.0);

    final Color ringColor = switch (label) {
      SpeedScoreLabel.elite => const Color(0xFF10B981), // Emerald
      SpeedScoreLabel.strong => AppTheme.primaryLight,
      SpeedScoreLabel.building => const Color(0xFFF59E0B), // Amber
      _ => const Color(0xFF64748B), // Slate
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ringColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ringColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
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
                        color: ringColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        score != null
                            ? '${label?.displayName ?? 'No Score'} Speed'
                            : 'Building Data',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: ringColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Overall Speed Score',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            score != null
                ? text.headline
                : 'Your Speed Score appears after 5 answers in the same topic and level (${data.answersNeededForSpeedScore} answers still needed).',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              "Today's Plan",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: plan.isAllCompleted
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${plan.completedCount} of ${plan.totalCount} Done',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: plan.isAllCompleted ? const Color(0xFF10B981) : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '3 blocks • ~15 minutes total',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ...plan.blocks.map((block) => _buildPlanBlockCard(context, ref, block)),
        const SizedBox(height: 6),
        Text(
          text.closingPush,
          style: TextStyle(
            fontSize: 12.5,
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanBlockCard(BuildContext context, WidgetRef ref, PlanBlock block) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topicColor = block.type == PlanBlockType.mistakes || block.type == PlanBlockType.keepSharp
        ? AppTheme.mixedColor
        : AppTheme.getTopicColor(block.config.topic);

    final modeSubtitle = block.config.mode == PracticeMode.timer
        ? 'Timer • ${(block.config.modeValue / 60).round()} min'
        : 'Questions • ${block.config.modeValue} Q';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: block.isCompleted
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.15),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Done checkbox or number badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: block.isCompleted
                    ? const Color(0xFF10B981)
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
                      fontWeight: FontWeight.bold,
                      decoration: block.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modeSubtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    block.reason,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final comp = data.weeklyComparison;
    final curr = comp.currentWindow;
    final prev = comp.previousWindow;

    final hasPriorData = prev.questionsAnswered > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
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
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Last 7 days',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text.weeklyActivity,
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget? deltaBadge;
    if (deltaPoints != null && deltaPoints != 0) {
      final isPositive = deltaPoints > 0;
      final isGood = isPositiveGood ? isPositive : !isPositive;
      final color = isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
      final color = isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
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
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (deltaBadge != null) deltaBadge,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (customNote != null)
            Text(
              customNote,
              style: TextStyle(fontSize: 9.5, color: colorScheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  // --- Section 4: Strong Areas ---
  Widget _buildStrongAreas(BuildContext context, ReportData data) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Strong Areas',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Text(
              'Mastery ≥ 80%',
              style: TextStyle(fontSize: 11.5, color: Colors.grey),
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
                color: topicColor.withValues(alpha: 0.12),
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
                  Text(
                    '${area.topic.displayName} (${area.difficulty.displayName})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 6),
                Text(
                  'Needs Work',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Text(
              'Mastery < 65%',
              style: TextStyle(fontSize: 11.5, color: Colors.grey),
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
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
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
                      Text(
                        '${area.topic.displayName} (${area.difficulty.displayName})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trends & Shifts',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (text.improving != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text.improving!,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
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
                const Icon(Icons.trending_down_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text.slipping!,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
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
                const Icon(Icons.schedule, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text.neglected!,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Topic Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'All ${data.topicPerformances.length} Topics',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: data.topicPerformances.asMap().entries.map((entry) {
              final index = entry.key;
              final tp = entry.value;
              final isLast = index == data.topicPerformances.length - 1;
              final topicColor = AppTheme.getTopicColor(tp.topic);

              final trendIcon = switch (tp.trend) {
                TopicTrend.improving => const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFF10B981)),
                TopicTrend.slipping => const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFFEF4444)),
                TopicTrend.steady => const Icon(Icons.drag_handle_rounded, size: 16, color: Colors.grey),
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
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: topicColor.withValues(alpha: 0.14),
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
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                tp.level.displayName,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colorScheme.onSurfaceVariant,
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
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              tp.avgTimeMs > 0 ? '${(tp.avgTimeMs / 1000).toStringAsFixed(1)}s' : '--',
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
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
                  if (!isLast) Divider(height: 1, indent: 60, color: colorScheme.outline.withValues(alpha: 0.1)),
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
    final theme = Theme.of(context);
    final count = data.mistakeSummary.totalMistakes;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.mixedColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.mixedColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mixedColor.withValues(alpha: 0.18),
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Spaced repetition drills ready',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              'Unlock Your Report',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Answer ${ReportConstants.minTotalQuestionsForReport} questions to unlock your Speed Score, strengths, and personalized daily plan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, height: 1.4),
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
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$progress / ${ReportConstants.minTotalQuestionsForReport} questions answered ($needed more to go)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
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
