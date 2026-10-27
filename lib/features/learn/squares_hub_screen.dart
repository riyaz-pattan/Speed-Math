// lib/features/learn/squares_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/models/lesson_progress.dart';
import '../../data/repositories/lesson_repository.dart';
import 'widgets/lesson_stars.dart';

/// Hub screen for all Squaring techniques.
/// Grouped into:
/// 1. Digit Ending in 5 (Ekadhikena Shortcut)
/// 2. Base Method Squares (Base 25, 50, 100, 150, 200)
class SquaresHubScreen extends ConsumerWidget {
  const SquaresHubScreen({super.key});

  static const Color _themeColor = Color(0xFFEA580C); // Warm Orange

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProgressAsync = ref.watch(allLessonProgressProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/learn');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.canvasBackground,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: allProgressAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SliverFillRemaining(
                    child: Center(child: Text('Could not load progress.')),
                  ),
                  data: (progressList) {
                    final map = {for (final p in progressList) p.lessonId: p};
                    return _buildSections(context, map);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC2410C), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/learn');
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Squares',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ending in 5 & Base Method Shortcuts (up to 200)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildSections(
      BuildContext context, Map<String, LessonProgress?> map) {
    const endingInFive = [
      _SquareSectionItem(
        lessonId: 'squares_ending_5',
        title: 'Squares Ending in 5',
        badge: 'Ekadhikena Shortcut (N × (N+1) | 25)',
        icon: Icons.star_outline_rounded,
      ),
    ];

    const baseShortcuts = [
      _SquareSectionItem(
        lessonId: 'squares_base_25',
        title: 'Base 25 Squares (21–29)',
        badge: 'Identity: 625 ± 50d + d²',
        icon: Icons.filter_2_rounded,
      ),
      _SquareSectionItem(
        lessonId: 'squares_base_50',
        title: 'Base 50 Squares (35–65)',
        badge: 'Half-Base: (25 ± d) | d²',
        icon: Icons.filter_5_rounded,
      ),
      _SquareSectionItem(
        lessonId: 'squares_base_100',
        title: 'Base 100 Squares (75–125)',
        badge: 'Reference Base: (N ± d) | d²',
        icon: Icons.filter_9_plus_rounded,
      ),
      _SquareSectionItem(
        lessonId: 'squares_base_150',
        title: 'Base 150 Squares (130–170)',
        badge: 'Scaled 1.5×: (N ± d) × 1.5 | d²',
        icon: Icons.looks_one_rounded,
      ),
      _SquareSectionItem(
        lessonId: 'squares_base_200',
        title: 'Base 200 Squares (175–225)',
        badge: 'Double Base: (N ± d) × 2 | d²',
        icon: Icons.looks_two_rounded,
      ),
    ];

    final widgets = <Widget>[
      // Section 1 Header
      _buildSectionHeader('DIGIT ENDING IN 5 (1 SHORTCUT)'),
      const SizedBox(height: 10),
      ...endingInFive.map((s) => _buildCard(context, s, map[s.lessonId])),
      const SizedBox(height: 18),

      // Section 2 Header
      _buildSectionHeader('BASE METHOD SQUARES (5 SHORTCUTS)'),
      const SizedBox(height: 10),
      ...baseShortcuts.map((s) => _buildCard(context, s, map[s.lessonId])),
      const SizedBox(height: 24),
    ];

    return SliverList(delegate: SliverChildListDelegate(widgets));
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: _themeColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _themeColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
      BuildContext context, _SquareSectionItem s, LessonProgress? progress) {
    final stars = progress?.stars ?? 0;
    final status = progress?.status ?? LessonStatus.none;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/learn/${s.lessonId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(s.icon, color: _themeColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5), // orange-100
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _themeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      LessonStars(stars: stars, size: 14),
                      if (status != LessonStatus.none) ...[
                        const SizedBox(width: 8),
                        Text(
                          status.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _themeColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SquareSectionItem {
  const _SquareSectionItem({
    required this.lessonId,
    required this.title,
    required this.badge,
    required this.icon,
  });

  final String lessonId;
  final String title;
  final String badge;
  final IconData icon;
}
