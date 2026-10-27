// lib/features/learn/quadratic_hub_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/enums/enums.dart';
import '../../domain/questions/session_random.dart';
import '../practice_session/models/practice_models.dart';

/// The Quadratic & Linear Equations Mastery Hub.
/// Contains:
/// 1. Comprehensive Golden Rules Handbook (2-Second CND rule, Sign Table, Cross-Multiplying, Radical traps)
/// 2. Interactive Live Quadratic Equation Solver & Sign Tester
class QuadraticHubScreen extends ConsumerStatefulWidget {
  const QuadraticHubScreen({super.key});

  static const Color themeColor = Color(0xFF6366F1); // Indigo

  @override
  ConsumerState<QuadraticHubScreen> createState() => _QuadraticHubScreenState();
}

class _QuadraticHubScreenState extends ConsumerState<QuadraticHubScreen> {
  int _selectedTab = 0; // 0 = Golden Rules Handbook, 1 = Live Solver

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
                    _buildHandbookTab(),
                    const _LiveQuadraticSolverView(),
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
          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
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
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quadratic & Equations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Competitive Shortcuts, Sign Table & CND Golden Rules',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _tabButton('Golden Rules', 0, Icons.menu_book_rounded),
            _tabButton('Equation Solver', 1, Icons.calculate_rounded),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? QuadraticHubScreen.themeColor
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? QuadraticHubScreen.themeColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandbookTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Exam Secret Highlight Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4338CA).withValues(alpha: 0.08),
                const Color(0xFF6366F1).withValues(alpha: 0.14),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFF6366F1), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Competitive Exam Secret',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF312E81),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Over 40% of quadratic comparison questions in Bank PO & SSC can be solved in under 5 seconds using sign rules alone without finding roots!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4338CA),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rule 1: The 2-Second CND Rule
        _buildHandbookCard(
          badgeText: 'GOLDEN RULE #1',
          badgeColor: const Color(0xFFEF4444),
          title: 'The 2-Second CND Golden Rule',
          subtitle: 'Both constant terms negative → Instant CND',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If both quadratic equations have a negative constant term (c₁ < 0 and c₂ < 0), the answer is ALWAYS "Relationship cannot be determined (CND)"!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam Example:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'I:  x² + 5x − 24 = 0   (c = −24)\nII: y² − 3y − 40 = 0   (c = −40)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '→ Both c are negative. Answer: CND (0 seconds calculation!)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Why it works:\nWhen constant c < 0, the product of roots c/a is negative. Therefore, both equations have one positive (+) root and one negative (−) root. Since positive x > negative y, but negative x < positive y, the roots overlap and no single relationship holds!',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rule 2: The Universal Sign Table
        _buildHandbookCard(
          badgeText: 'GOLDEN RULE #2',
          badgeColor: const Color(0xFF10B981),
          title: 'The Universal Sign Table',
          subtitle: 'Predict root signs before computing numbers',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Memorize this conversion table to determine root signs immediately:',
                style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 10),
              _buildSignTable(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instant Winner Shortcut:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'If Equation I has signs (−, +) → roots are (+, +)\nIf Equation II has signs (+, +) → roots are (−, −)\n→ Every positive is greater than every negative! Result: x > y immediately!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rule 3: Fast Mental Factorization (a × c Split)
        _buildHandbookCard(
          badgeText: 'GOLDEN RULE #3',
          badgeColor: const Color(0xFF3B82F6),
          title: 'Mental Root Finding (a × c Split)',
          subtitle: '4 steps to solve without quadratic formula',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepRow(1, 'Multiply a × c', 'Find product P = a × c.'),
              _buildStepRow(2, 'Find Split Pair', 'Find two numbers (m, n) such that m × n = P and m + n = b.'),
              _buildStepRow(3, 'Flip the Signs', 'Change signs: m → −m, n → −n.'),
              _buildStepRow(4, 'Divide by a', 'Divide by leading coefficient: r₁ = −m/a, r₂ = −n/a.'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  'Example: 2x² − 11x + 14 = 0\n1. Product = 2 × 14 = 28\n2. Factors of 28 adding to −11: −7 and −4\n3. Flip signs: +7 and +4\n4. Divide by 2: Roots are 7/2 = 3.5 and 4/2 = 2!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: Color(0xFF1E40AF),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rule 4: Cross-Multiplication Trick for Unequal 'a'
        _buildHandbookCard(
          badgeText: 'GOLDEN RULE #4',
          badgeColor: const Color(0xFFF59E0B),
          title: 'Cross-Multiplication for Unequal Coefficients',
          subtitle: 'Avoid dividing by fractions during comparison',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When comparing roots of two equations with unequal "a" (e.g. a₁ = 2, a₂ = 3), do NOT divide by 2 and 3! That creates messy fractions.\nInstead, multiply x\'s roots by a₂ (3) and y\'s roots by a₁ (2)!',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'Eq I (a = 2): x candidates = 5, 3\nEq II (a = 3): y candidates = 4, 2\nMultiply x\'s by 3 → 15, 9\nMultiply y\'s by 2 → 8, 4\nCompare 15, 9 vs 8, 4 → All x > y! Done in integers!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: Color(0xFF92400E),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rule 5: Radical vs Even Power Trap
        _buildHandbookCard(
          badgeText: 'GOLDEN RULE #5',
          badgeColor: const Color(0xFF8B5CF6),
          title: 'The Radical vs Even-Power Trap',
          subtitle: 'x² = 16 vs y = √16',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Common competitive exam trap that costs negative marks:',
                style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• x² = 16  →  x = +4 AND −4 (two roots)\n• y = √16  →  y = +4 ONLY (principal root is always non-negative!)\n\nComparison:\nWhen x = +4: x = y\nWhen x = −4: x < y\nResult: x ≤ y  (NOT x = y or CND!)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B21A8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Rule 6: Symmetric Linear Systems
        _buildHandbookCard(
          badgeText: 'LINEAR SHORTCUT',
          badgeColor: const Color(0xFF0D9488),
          title: 'Symmetric Linear Systems (ax + by = c, bx + ay = d)',
          subtitle: '5-second solve without substitution',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When coefficients are swapped diagonally, simply ADD or SUBTRACT the two equations:',
                style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: const Text(
                  'Eq 1: 17x + 13y = 73\nEq 2: 13x + 17y = 47\n\nAdd both: 30x + 30y = 120 → x + y = 4!\nSubtract both: 4x − 4y = 26 → x − y = 6.5\nDirectly solve x and y in 10 seconds without huge multiplications!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: Color(0xFF115E59),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Quick Practice Launch Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Ready to Test Your Skills?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Practice root finding, CND shortcuts, and equation comparisons.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        final config = PracticeConfig(
                          topic: Topic.quadraticEquations,
                          difficulty: Difficulty.easy,
                          mode: PracticeMode.questions,
                          modeValue: 10,
                          sessionSeed: SessionRandom.newSessionSeed(),
                        );
                        context.push('/practice/session', extra: config);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.flash_on_rounded, size: 18),
                      label: const Text(
                        'Quadratic Drills',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        final config = PracticeConfig(
                          topic: Topic.linearEquations,
                          difficulty: Difficulty.easy,
                          mode: PracticeMode.questions,
                          modeValue: 10,
                          sessionSeed: SessionRandom.newSessionSeed(),
                        );
                        context.push('/practice/session', extra: config);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.timeline_rounded, size: 18),
                      label: const Text(
                        'Linear Drills',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHandbookCard({
    required String badgeText,
    required Color badgeColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSignTable() {
    const tableData = [
      ('+', '+', '−', '−', 'Both roots negative'),
      ('−', '+', '+', '+', 'Both roots positive'),
      ('+', '−', '−', '+', 'Bigger root is −'),
      ('−', '−', '+', '−', 'Bigger root is +'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(2.0),
        },
        border: TableBorder.symmetric(
          inside: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        children: [
          const TableRow(
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Text(
                  'Eq (b, c)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Text(
                  'Root (r₁, r₂)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: Text(
                  'Memory Tip',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          ...tableData.map((row) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Text(
                    '${row.$1} , ${row.$2}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Text(
                    '${row.$3} , ${row.$4}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: row.$3 == '+' && row.$4 == '+'
                          ? const Color(0xFF10B981)
                          : row.$3 == '−' && row.$4 == '−'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF6366F1),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Text(
                    row.$5,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepRow(int number, String stepTitle, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFF3B82F6),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                children: [
                  TextSpan(
                    text: '$stepTitle: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Live Quadratic Equation Solver & Sign Tester
class _LiveQuadraticSolverView extends StatefulWidget {
  const _LiveQuadraticSolverView();

  @override
  State<_LiveQuadraticSolverView> createState() => _LiveQuadraticSolverViewState();
}

class _LiveQuadraticSolverViewState extends State<_LiveQuadraticSolverView> {
  int _a = 1;
  int _b = -5;
  int _c = 6;

  static const List<(int, int, int, String)> _presets = [
    (1, -5, 6, 'x² − 5x + 6 = 0'),
    (1, -7, 12, 'x² − 7x + 12 = 0'),
    (1, 5, 6, 'x² + 5x + 6 = 0'),
    (2, 5, -12, '2x² + 5x − 12 = 0'),
    (1, -6, 9, 'x² − 6x + 9 = 0'),
    (2, -11, 14, '2x² − 11x + 14 = 0'),
    (1, 0, -25, 'x² − 25 = 0'),
  ];

  @override
  Widget build(BuildContext context) {
    final discriminant = (_b * _b) - (4 * _a * _c);
    final hasRealRoots = discriminant >= 0;
    final sqrtDisc = hasRealRoots ? sqrt(discriminant.toDouble()) : 0.0;
    final isSquare = hasRealRoots && (sqrtDisc - sqrtDisc.round()).abs() < 1e-9;

    double? r1;
    double? r2;
    if (hasRealRoots && _a != 0) {
      r1 = (-_b + sqrtDisc) / (2 * _a);
      r2 = (-_b - sqrtDisc) / (2 * _a);
    }

    final signDesc = _getSignPrediction(_b, _c);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Preset Chips
        const Text(
          'Select Preset Equation:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _presets.map((preset) {
              final isSelected = _a == preset.$1 && _b == preset.$2 && _c == preset.$3;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    preset.$4,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF6366F1),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _a = preset.$1;
                        _b = preset.$2;
                        _c = preset.$3;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Coefficients Control Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust Coefficients (ax² + bx + c = 0)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              _buildCoefficientRow('a', _a, (newVal) {
                if (newVal != 0) setState(() => _a = newVal);
              }, minVal: -10, maxVal: 10),
              const SizedBox(height: 10),
              _buildCoefficientRow('b', _b, (newVal) {
                setState(() => _b = newVal);
              }, minVal: -30, maxVal: 30),
              const SizedBox(height: 10),
              _buildCoefficientRow('c', _c, (newVal) {
                setState(() => _c = newVal);
              }, minVal: -50, maxVal: 50),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Equation Display Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF4338CA)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Active Equation',
                style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _formatEquation(_a, _b, _c),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sign Prediction Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rule_rounded, color: Color(0xFF6366F1), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign Table Prediction',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      signDesc,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Discriminant & Factors Breakdown
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Discriminant & Factor Analysis',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                '• Δ = b² − 4ac = ($_b)² − 4($_a)($_c) = $discriminant',
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF334155)),
              ),
              const SizedBox(height: 4),
              Text(
                '• Nature of roots: ${discriminant > 0 ? (isSquare ? "Real, Rational & Distinct" : "Real, Irrational & Distinct") : discriminant == 0 ? "Real & Equal (Repeated root)" : "No Real Roots (Imaginary)"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasRealRoots ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Product a × c = ${_a * _c}, Sum b = $_b',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Roots Output Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasRealRoots ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasRealRoots ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
            ),
          ),
          child: Column(
            children: [
              Text(
                hasRealRoots ? 'Calculated Real Roots' : 'Root Result',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasRealRoots ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                ),
              ),
              const SizedBox(height: 8),
              if (hasRealRoots && r1 != null && r2 != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRootBadge('x₁', r1),
                    const SizedBox(width: 24),
                    _buildRootBadge('x₂', r2),
                  ],
                )
              else
                const Text(
                  'No real roots (Imaginary roots are excluded from competitive exams).',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB91C1C),
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRootBadge(String label, double value) {
    final formatted = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
          ),
          const SizedBox(height: 2),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoefficientRow(
    String name,
    int value,
    ValueChanged<int> onChanged, {
    required int minVal,
    required int maxVal,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          alignment: Alignment.center,
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: Color(0xFF4338CA),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: value > minVal
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(value - 1);
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: const Color(0xFF6366F1),
          iconSize: 22,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          onPressed: value < maxVal
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(value + 1);
                }
              : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
          color: const Color(0xFF6366F1),
          iconSize: 22,
        ),
      ],
    );
  }

  String _formatEquation(int a, int b, int c) {
    final StringBuffer sb = StringBuffer();
    if (a == 1) {
      sb.write('x²');
    } else if (a == -1) {
      sb.write('−x²');
    } else {
      sb.write('${a}x²');
    }

    if (b > 0) {
      sb.write(' + ${b == 1 ? "" : b}x');
    } else if (b < 0) {
      sb.write(' − ${b == -1 ? "" : b.abs()}x');
    }

    if (c > 0) {
      sb.write(' + $c');
    } else if (c < 0) {
      sb.write(' − ${c.abs()}');
    }

    sb.write(' = 0');
    return sb.toString();
  }

  String _getSignPrediction(int b, int c) {
    if (c < 0) {
      return 'c is negative → Roots have OPPOSITE signs (+ and −). (Golden Rule #1 candidate!)';
    } else if (b > 0) {
      return 'Signs (+, +) → BOTH roots are NEGATIVE (−, −).';
    } else if (b < 0) {
      return 'Signs (−, +) → BOTH roots are POSITIVE (+, +).';
    } else {
      return 'b = 0 → Roots are equal and opposite (±√c).';
    }
  }
}
