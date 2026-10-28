// lib/features/learn/widgets/variant_chooser.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../../../data/models/lesson_progress.dart';
import '../engine/lesson_block.dart';
import 'lesson_stars.dart';

/// Screen / view to choose a specific variant of a lesson (e.g. ×5, ×25, ×125).
class VariantChooser extends StatelessWidget {
  const VariantChooser({
    super.key,
    required this.meta,
    required this.progressMap,
    required this.onSelect,
    required this.onBack,
  });

  final LessonMeta meta;
  final Map<String, LessonProgress?> progressMap;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.canvasBackground,
        appBar: AppBar(
          title: Text(meta.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Choose a trick variant:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Master each shortcut one by one with animated steps and practice.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: meta.variants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final v = meta.variants[index];
                    final progId = meta.progressId(v.variantId);
                    final prog = progressMap[progId];
                    final stars = prog?.stars ?? 0;
                    final isMastered = prog?.status == LessonStatus.mastered;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelect(v.variantId);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: isMastered
                                ? AppTheme.primaryColor
                                : AppTheme.borderLight,
                            width: isMastered ? 1.5 : 1.0,
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                v.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Shortcut for ${v.displayName}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      LessonStars(stars: stars, size: 15),
                                      const SizedBox(width: 8),
                                      Text(
                                        isMastered
                                            ? 'Mastered'
                                            : stars > 0
                                                ? 'Learned'
                                                : 'Not started',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isMastered
                                              ? AppTheme.primaryColor
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
