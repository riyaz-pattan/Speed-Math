// lib/features/learn/division_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/models/lesson_progress.dart';
import '../../data/repositories/lesson_repository.dart';
import 'widgets/divisibility_handbook_view.dart';
import 'widgets/divisibility_speed_drill.dart';
import 'widgets/lesson_stars.dart';

/// The Division Topic Hub.
/// Contains:
/// 1. Divisibility Handbook & Interactive Live Tester
/// 2. Speed Division Shortcuts
/// 3. Divisibility Speed Drill
class DivisionHubScreen extends ConsumerStatefulWidget {
  const DivisionHubScreen({super.key});

  static const Color themeColor = Color(0xFFD97706); // Warm Amber

  @override
  ConsumerState<DivisionHubScreen> createState() => _DivisionHubScreenState();
}

class _DivisionHubScreenState extends ConsumerState<DivisionHubScreen> {
  int _selectedTab = 0; // 0 = Handbook, 1 = Speed Shortcuts, 2 = Speed Drill

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    const DivisibilityHandbookView(),
                    _buildShortcutsTab(),
                    const DivisibilitySpeedDrill(),
                  ],
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFD97706)],
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
                  'Division',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Divisibility Handbook & Speed Calculation Shortcuts',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          _TabItem(
            icon: Icons.menu_book_rounded,
            label: 'Handbook',
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          _TabItem(
            icon: Icons.bolt_rounded,
            label: 'Shortcuts',
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
          _TabItem(
            icon: Icons.flash_on_rounded,
            label: 'Speed Drill',
            isSelected: _selectedTab == 2,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsTab() {
    final allAsync = ref.watch(allLessonProgressProvider);

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) =>
          const Center(child: Text('Could not load division shortcuts.')),
      data: (progressList) {
        final map = {for (final p in progressList) p.lessonId: p};

        final shortcuts = [
          _DivisionShortcutItem(
            lessonId: 'divide_by_5_25',
            title: 'Divide by 5, 25 & 125',
            badge: 'Double-and-Shift Trick',
            description:
                'Convert division into instant mental multiplication: ÷ 5 = (× 2) ÷ 10, ÷ 25 = (× 4) ÷ 100, and ÷ 125 = (× 8) ÷ 1000.',
            formula: 'N ÷ 5 = (N × 2) ÷ 10',
            example: '342 ÷ 5 = 684 ÷ 10 = 68.4',
            icon: Icons.trending_up_rounded,
          ),
          _DivisionShortcutItem(
            lessonId: 'divide_by_9_99',
            title: 'Division by 9 & 99',
            badge: 'Vedic Running Sums',
            description:
                'Bypasses long division entirely! The quotient digits are simply the running sums of the dividend digits.',
            formula: 'Quotient = running sums of digits',
            example: '1,214 ÷ 9 = 134 R 8 (134.88...)',
            icon: Icons.alt_route_rounded,
          ),
          _DivisionShortcutItem(
            lessonId: 'factor_division',
            title: 'Factor Division',
            badge: 'Composite Divisors',
            description:
                'Break composite divisors (like 14, 15, 18, 24, 36, 45) into two 1-digit factors and divide sequentially.',
            formula: 'N ÷ (a × b) = (N ÷ a) ÷ b',
            example: '1,620 ÷ 45 = (1620 ÷ 9) ÷ 5 = 36',
            icon: Icons.call_split_rounded,
          ),
          _DivisionShortcutItem(
            lessonId: 'reciprocal_division',
            title: 'Reciprocal & Decimals',
            badge: 'Fraction Replacement',
            description:
                'Convert fractional and decimal divisors into whole multiplications: ÷ 0.5 = × 2, ÷ 0.25 = × 4, ÷ 2.5 = × 4 ÷ 10.',
            formula: '÷ 0.5 → × 2   •   ÷ 0.25 → × 4',
            example: '140 ÷ 2.5 = 140 × 4 ÷ 10 = 56',
            icon: Icons.swap_horiz_rounded,
          ),
          _DivisionShortcutItem(
            lessonId: 'flag_division',
            title: 'Straight Division',
            badge: 'Flag Method (Dhvajanka)',
            description:
                'The crown jewel of mental division: divides any 3-4 digit number by a 2-digit divisor directly on a single line.',
            formula: 'Base Divisor + Flag Adjustment',
            example: '4,536 ÷ 54 = 84 R 0',
            icon: Icons.flag_rounded,
          ),
        ];

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          itemCount: shortcuts.length,
          itemBuilder: (context, index) {
            final item = shortcuts[index];
            final p = map[item.lessonId];
            final stars = p?.stars ?? 0;
            final status = p?.status ?? LessonStatus.none;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.cardShadow,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Icon(item.icon,
                            color: DivisionHubScreen.themeColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.badge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: DivisionHubScreen.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status != LessonStatus.none) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: DivisionHubScreen.themeColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      LessonStars(stars: stars, size: 16),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.push('/learn/${item.lessonId}');
                        },
                        icon: const Icon(Icons.architecture_rounded, size: 16),
                        label: const Text('Open Lesson'),
                        style: FilledButton.styleFrom(
                          backgroundColor: DivisionHubScreen.themeColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
      },
    );
  }
}

class _DivisionShortcutItem {
  const _DivisionShortcutItem({
    required this.lessonId,
    required this.title,
    required this.badge,
    required this.description,
    required this.formula,
    required this.example,
    required this.icon,
  });

  final String lessonId;
  final String title;
  final String badge;
  final String description;
  final String formula;
  final String example;
  final IconData icon;
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFEF3C7) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? DivisionHubScreen.themeColor
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? DivisionHubScreen.themeColor
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
