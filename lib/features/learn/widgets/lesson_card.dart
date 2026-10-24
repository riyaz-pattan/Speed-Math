// lib/features/learn/widgets/lesson_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../data/models/lesson_progress.dart';
import '../engine/lesson_data.dart';
import 'lesson_stars.dart';

/// Card widget for one lesson on the Learn screen.
class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.meta,
    required this.progress,
    required this.onTap,
  });

  final LessonMeta meta;
  final LessonProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stars = progress?.stars ?? 0;
    final status = progress?.status ?? LessonStatus.none;
    final catColor = _categoryColor(meta.category);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(meta.icon, color: catColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      LessonStars(stars: stars, size: 13),
                      const SizedBox(width: 8),
                      Text(
                        meta.durationLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (status != LessonStatus.none) ...[
              const SizedBox(width: 8),
              _StatusBadge(status: status),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) => switch (category) {
        'Arithmetic' => const Color(0xFF10B981),
        'Mental Shortcuts' => AppTheme.primaryColor,
        'Powers & Roots' => const Color(0xFFF97316),
        'Applied Maths' => const Color(0xFF8B5CF6),
        _ => AppTheme.primaryColor,
      };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final LessonStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      LessonStatus.started => ('Started', Colors.orange.shade100, Colors.orange.shade800),
      LessonStatus.learned => ('Learned', Colors.green.shade100, Colors.green.shade800),
      LessonStatus.mastered => ('Mastered', AppTheme.primaryTint, AppTheme.primaryColor),
      LessonStatus.none => ('', Colors.transparent, Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
