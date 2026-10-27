// lib/features/learn/multiplication_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/models/lesson_progress.dart';
import '../../data/repositories/lesson_repository.dart';
import 'widgets/lesson_stars.dart';

/// Hub screen for Multiplication techniques.
/// Grouped into:
/// 1. Universal Single-Line Criss-Cross (2×2, 3×2, 3×3)
/// 2. Mental Speed Multiplication Shortcuts (×5/25/75/125, ×11, ×9/99/999, Near-100)
class MultiplicationHubScreen extends ConsumerWidget {
  const MultiplicationHubScreen({super.key});

  static const Color _themeColor = Color(0xFF7C3AED); // Royal Purple

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
          colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.pop();
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
                  'Multiplication',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Criss-Cross Shortcut & Mental Calculation Tricks',
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
    const crissCrossSections = [
      _MultSectionItem(
        lessonId: 'multiply_2x2',
        title: '2-Digit Multiplication',
        badge: 'Criss-Cross Shortcut (3 Stages)',
        icon: Icons.grid_view_rounded,
      ),
      _MultSectionItem(
        lessonId: 'multiply_3x2',
        title: '3×2-Digit Multiplication',
        badge: 'Crosswise Expansion (4 Stages)',
        icon: Icons.view_column_rounded,
      ),
      _MultSectionItem(
        lessonId: 'multiply_3x3',
        title: '3-Digit Multiplication',
        badge: 'Star Cross Method (5 Stages)',
        icon: Icons.star_half_rounded,
      ),
    ];

    const mentalShortcuts = [
      _MultSectionItem(
        lessonId: 'multiply_by_5_25',
        title: 'Multiply by 5, 25, 75 & 125',
        badge: 'Multiplicative Inversion (÷2, ÷4, ÷8)',
        icon: Icons.flash_on_rounded,
      ),
      _MultSectionItem(
        lessonId: 'multiply_by_11',
        title: 'Multiply by 11',
        badge: 'Adjacent Digit Sum & Insertion',
        icon: Icons.add_link_rounded,
      ),
      _MultSectionItem(
        lessonId: 'multiply_by_99',
        title: 'Multiply by 9, 99 & 999',
        badge: 'Power-of-10 Identity & Vedic Complements',
        icon: Icons.filter_9_plus_rounded,
      ),
      _MultSectionItem(
        lessonId: 'near_100_mult',
        title: 'Near-100 Multiplication',
        badge: 'Base-100 Deviations & Cross Operation',
        icon: Icons.radar_rounded,
      ),
    ];

    final widgets = <Widget>[
      // Section 1 Header
      _buildSectionHeader('UNIVERSAL CRISS-CROSS (3 TECHNIQUES)'),
      const SizedBox(height: 10),
      ...crissCrossSections.map((s) => _buildCard(context, s, map[s.lessonId])),
      const SizedBox(height: 18),

      // Section 2 Header
      _buildSectionHeader('SPEED MULTIPLICATION SHORTCUTS (4 SHORTCUTS)'),
      const SizedBox(height: 10),
      ...mentalShortcuts.map((s) => _buildCard(context, s, map[s.lessonId])),
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
      BuildContext context, _MultSectionItem s, LessonProgress? progress) {
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
                      color: const Color(0xFFF3E8FF), // purple-100
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

class _MultSectionItem {
  const _MultSectionItem({
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
