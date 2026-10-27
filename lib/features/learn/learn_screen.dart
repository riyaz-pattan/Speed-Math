// lib/features/learn/learn_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/ads/widgets/banner_ad_container.dart';
import '../../data/models/lesson_progress.dart';
import '../../data/repositories/lesson_repository.dart';
import 'engine/lesson_registry.dart';
import 'widgets/lesson_card.dart';

/// The Learn screen — all 8 lessons grouped by category with progress.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allLessonProgressProvider);
    final showBanner =
        allAsync.hasValue && !allAsync.isLoading && !allAsync.hasError;

    return Scaffold(
      backgroundColor: AppTheme.canvasBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _Header(allAsync: allAsync)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    sliver: allAsync.when(
                      loading: () => const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SliverFillRemaining(
                        child: Center(child: Text('Could not load lessons.')),
                      ),
                      data: (list) {
                        final map = {for (final p in list) p.lessonId: p};
                        return _buildContent(context, map);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (showBanner) const BannerAdContainer(),
          ],
        ),
      ),
    );
  }

  SliverList _buildContent(
      BuildContext context, Map<String, LessonProgress?> map) {
    final widgets = <Widget>[];
    for (final category in LessonRegistry.categories) {
      final lessons = LessonRegistry.forCategory(category);
      if (lessons.isEmpty) continue;
      widgets.add(_CategoryHeader(category: category));
      widgets.add(const SizedBox(height: 10));
      for (final meta in lessons) {
        int? variantCount;
        int? totalVariants;

        if (meta.id == 'multiplication_hub') {
          const multIds = [
            'multiply_2x2',
            'multiply_3x2',
            'multiply_3x3',
            'multiply_by_5_25',
            'multiply_by_11',
            'multiply_by_99',
            'near_100_mult',
          ];
          totalVariants = multIds.length;
          variantCount = multIds.where((id) {
            final p = map[id];
            return p != null &&
                (p.status == LessonStatus.learned ||
                    p.status == LessonStatus.mastered);
          }).length;
        } else if (meta.id == 'division_hub') {
          const divIds = [
            'divide_by_5_25',
            'divide_by_9_99',
            'factor_division',
            'reciprocal_division',
            'flag_division'
          ];
          totalVariants = divIds.length;
          variantCount = divIds.where((id) {
            final p = map[id];
            return p != null &&
                (p.status == LessonStatus.learned ||
                    p.status == LessonStatus.mastered);
          }).length;
        } else if (meta.id == 'squares_hub') {
          const squareIds = [
            'squares_ending_5',
            'squares_base_25',
            'squares_base_50',
            'squares_base_100',
            'squares_base_150',
            'squares_base_200',
          ];
          totalVariants = squareIds.length;
          variantCount = squareIds.where((id) {
            final p = map[id];
            return p != null &&
                (p.status == LessonStatus.learned ||
                    p.status == LessonStatus.mastered);
          }).length;
        } else if (meta.hasVariants) {
          totalVariants = meta.variants.length;
          variantCount = meta.variants.where((v) {
            final p = map[meta.progressId(v.variantId)];
            return p != null &&
                (p.status == LessonStatus.learned ||
                    p.status == LessonStatus.mastered);
          }).length;
        }

        widgets.add(LessonCard(
          meta: meta,
          progress: map[meta.id],
          variantProgressCount: variantCount,
          totalVariantsCount: totalVariants,
          onTap: () {
            if (meta.id == 'multiplication_hub') {
              context.push('/learn/multiplication');
            } else if (meta.id == 'division_hub') {
              context.push('/learn/division');
            } else if (meta.id == 'squares_hub') {
              context.push('/learn/squares');
            } else {
              context.push('/learn/${meta.id}');
            }
          },
        ));
        widgets.add(const SizedBox(height: 10));
      }
      widgets.add(const SizedBox(height: 8));
    }
    return SliverList(delegate: SliverChildListDelegate(widgets));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.allAsync});
  final AsyncValue<List<LessonProgress>> allAsync;

  @override
  Widget build(BuildContext context) {
    final learnedCount = allAsync.whenOrNull(
          data: (list) {
            final map = {for (final p in list) p.lessonId: p};
            int count = 0;
            for (final meta in LessonRegistry.all) {
              if (meta.hasVariants) {
                final anyLearned = meta.variants.any((v) {
                  final p = map[meta.progressId(v.variantId)];
                  return p != null &&
                      (p.status == LessonStatus.learned ||
                          p.status == LessonStatus.mastered);
                });
                if (anyLearned) count++;
              } else {
                final p = map[meta.id];
                if (p != null &&
                    (p.status == LessonStatus.learned ||
                        p.status == LessonStatus.mastered)) {
                  count++;
                }
              }
            }
            return count;
          },
        ) ??
        0;
    final total = LessonRegistry.all.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learn Shortcuts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '$learnedCount of $total lessons learned',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$learnedCount/$total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    final color = switch (category) {
      'Arithmetic' => const Color(0xFF10B981),
      'Mental Shortcuts' => AppTheme.primaryColor,
      'Powers & Roots' => const Color(0xFFF97316),
      'Applied Maths' => const Color(0xFF8B5CF6),
      _ => AppTheme.primaryColor,
    };
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          category,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.1),
        ),
      ],
    );
  }
}
