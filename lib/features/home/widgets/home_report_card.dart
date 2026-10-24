import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import 'package:speed_math_with_ai/core/widgets/tactile_card.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../domain/report/report_constants.dart';
import '../../../domain/report/report_data.dart';

/// Compact card displayed on the Home screen above the practice topics grid.
///
/// Surfaces the user's Overall Speed Score, one key insight sentence,
/// Today's Plan progress ("X of Y done"), and a shortcut to the Report tab.
class HomeReportCard extends ConsumerWidget {
  const HomeReportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportViewModelProvider);

    return reportAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (vm) {
        final data = vm.data;
        final plan = vm.plan;
        final text = vm.text;

        if (!data.hasEnoughData) {
          final progress = data.totalQuestionsAllTime
              .clamp(0, ReportConstants.minTotalQuestionsForReport);
          return TactileCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Report',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Practice to unlock ($progress/${ReportConstants.minTotalQuestionsForReport} Q)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/coach'),
                  icon: const Icon(Icons.psychology_rounded, size: 16),
                  label: const Text(
                    'Ask Coach',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Populated card
        final score = data.overallSpeedScore;
        final scoreLabel = data.speedScoreLabel?.displayName ?? 'Building';
        final scoreText =
            score != null ? '${score.round()} • $scoreLabel' : scoreLabel;

        final Color scoreColor = switch (data.speedScoreLabel) {
          SpeedScoreLabel.elite => AppTheme.accentGreen,
          SpeedScoreLabel.strong => AppTheme.primaryLight,
          SpeedScoreLabel.building => AppTheme.warningAmber,
          _ => AppTheme.primaryColor,
        };

        return TactileCard(
          onTap: () => context.push('/report'),
          borderColor: scoreColor.withValues(alpha: 0.25),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Speed Score + shortcut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 16, color: scoreColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Speed Score: $scoreText',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Report',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Insight sentence
              Text(
                text.headline,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Plan status
              Row(
                children: [
                  Icon(
                    plan.isAllCompleted
                        ? Icons.check_circle_rounded
                        : Icons.calendar_today_rounded,
                    size: 15,
                    color: plan.isAllCompleted
                        ? AppTheme.accentGreen
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Today's plan: ${plan.completedCount} of ${plan.totalCount} done",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: plan.isAllCompleted
                            ? AppTheme.accentGreen
                            : AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 60,
                      height: 6,
                      child: LinearProgressIndicator(
                        value: plan.totalCount > 0
                            ? plan.completedCount / plan.totalCount
                            : 0.0,
                        backgroundColor: AppTheme.surfaceSecondary,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          plan.isAllCompleted
                              ? AppTheme.accentGreen
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Action buttons: Ask Coach & View Report
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.push('/coach'),
                      icon: const Icon(Icons.psychology_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Ask Coach',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryTint,
                        foregroundColor: AppTheme.primaryColor,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/report'),
                      icon: const Icon(Icons.insights_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'View Report',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
