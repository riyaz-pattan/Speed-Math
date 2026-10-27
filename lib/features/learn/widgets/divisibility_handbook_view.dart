// lib/features/learn/widgets/divisibility_handbook_view.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';
import '../engine/divisibility_helper.dart';

/// Structured cheat-sheet reference definition for each divisibility rule.
class _DivisibilityCheatSheet {
  const _DivisibilityCheatSheet({
    required this.divisor,
    required this.ruleName,
    required this.goldenRule,
    required this.category,
    required this.roadmap,
    required this.passNumber,
    required this.passWorking,
    required this.failNumber,
    required this.failWorking,
    required this.memoryTip,
    required this.whyItWorks,
  });

  final int divisor;
  final String ruleName;
  final String goldenRule;
  final DivisibilityCategory category;
  final List<String> roadmap; // 3-step bullet roadmap
  final int passNumber;
  final String passWorking;
  final int failNumber;
  final String failWorking;
  final String memoryTip;
  final String whyItWorks;
}

/// The complete interactive Divisibility Handbook & Live Tester.
///
/// Features:
/// 1. Live Interactive Divisibility Tester (enter ANY number -> instant pass/fail breakdown)
/// 2. Category Filter Chips (All, Basics, Sums, Endings, Primes, Composites)
/// 3. Deep Cheat-Sheet Reference Cards with 3-step roadmaps, Pass/Fail examples, and speed tips.
class DivisibilityHandbookView extends StatefulWidget {
  const DivisibilityHandbookView({super.key});

  @override
  State<DivisibilityHandbookView> createState() =>
      _DivisibilityHandbookViewState();
}

class _DivisibilityHandbookViewState extends State<DivisibilityHandbookView> {
  final TextEditingController _numberCtrl =
      TextEditingController(text: '8415');
  int _currentNumber = 8415;
  DivisibilityCategory _selectedCat = DivisibilityCategory.all;
  int? _expandedDivisor;

  static const List<int> _presetNumbers = [
    342,
    1364,
    2520,
    5136,
    8415,
    19404,
    27830,
  ];

  static const List<_DivisibilityCheatSheet> _cheatSheets = [
    _DivisibilityCheatSheet(
      divisor: 2,
      ruleName: 'Even Units Digit',
      goldenRule: 'The last digit must be an even number (0, 2, 4, 6, or 8).',
      category: DivisibilityCategory.basics,
      roadmap: [
        'Isolate the last (units) digit of the number.',
        'Check whether the digit is 0, 2, 4, 6, or 8.',
        'If yes, the entire number is divisible by 2!',
      ],
      passNumber: 748,
      passWorking: 'Ends in 8 (even) → Divisible by 2',
      failNumber: 749,
      failWorking: 'Ends in 9 (odd) → Leaves remainder 1',
      memoryTip: 'Ignore all leading digits completely — only the final unit matters.',
      whyItWorks: 'Every multiple of 10 is divisible by 2 (10 = 2 × 5). Only the units digit can leave a remainder.',
    ),
    _DivisibilityCheatSheet(
      divisor: 3,
      ruleName: 'Sum of Digits',
      goldenRule: 'The sum of all individual digits must be divisible by 3.',
      category: DivisibilityCategory.sums,
      roadmap: [
        'Sum all digits together (e.g. 4 + 7 + 1 = 12).',
        'Repeat or cast out 3s, 6s, 9s to keep total small.',
        'If the final sum is a multiple of 3, the number divides by 3!',
      ],
      passNumber: 4716,
      passWorking: '4 + 7 + 1 + 6 = 18 (18 ÷ 3 = 6) → Divisible',
      failNumber: 5234,
      failWorking: '5 + 2 + 3 + 4 = 14 (14 ÷ 3 = 4 R 2) → Not divisible',
      memoryTip: 'Cast out 3s: eliminate 3, 6, 9 or pairs adding to 3/9 as you scan left-to-right.',
      whyItWorks: 'Powers of 10 leave remainder 1 mod 3 (10 = 9+1, 100 = 99+1), so each digit acts as its face value.',
    ),
    _DivisibilityCheatSheet(
      divisor: 4,
      ruleName: 'Last 2 Digits',
      goldenRule: 'The last two digits must form a number divisible by 4 (or 2×tens + units is divisible by 4).',
      category: DivisibilityCategory.basics,
      roadmap: [
        'Look only at the last two digits of the number.',
        'Halve twice, or compute: 2 × (tens digit) + (units digit).',
        'If that result divides by 4, the entire number divides by 4!',
      ],
      passNumber: 3836,
      passWorking: '36 ÷ 4 = 9 (or 2×3 + 6 = 12) → Divisible',
      failNumber: 4938,
      failWorking: '38 ÷ 4 = 9 R 2 (or 2×3 + 8 = 14) → Remainder 2',
      memoryTip: 'Tens even → units must be 0, 4, 8. Tens odd → units must be 2, 6.',
      whyItWorks: '100 = 4 × 25. All hundreds, thousands, and higher places leave zero remainder.',
    ),
    _DivisibilityCheatSheet(
      divisor: 5,
      ruleName: 'Ends in 0 or 5',
      goldenRule: 'The units digit must be either 0 or 5.',
      category: DivisibilityCategory.endings,
      roadmap: [
        'Inspect the final (units) digit of the number.',
        'Check whether it ends in exactly 0 or 5.',
        'Ignore all other digits; it divides by 5!',
      ],
      passNumber: 9285,
      passWorking: 'Ends in 5 → Divisible by 5',
      failNumber: 9284,
      failWorking: 'Ends in 4 (not 0 or 5) → Remainder 4',
      memoryTip: 'If it ends in 0, it also divides by both 10 and 2.',
      whyItWorks: '10 = 5 × 2. Only the units digit can leave a remainder mod 5.',
    ),
    _DivisibilityCheatSheet(
      divisor: 6,
      ruleName: 'Composite (2 and 3)',
      goldenRule: 'The number must be EVEN and the sum of its digits must be divisible by 3.',
      category: DivisibilityCategory.composites,
      roadmap: [
        'Check Rule 2: Must be even (ends in 0, 2, 4, 6, 8).',
        'Check Rule 3: Sum of all digits must divide by 3.',
        'If both checks pass, the number divides by 6!',
      ],
      passNumber: 7524,
      passWorking: 'Even (4) AND digit sum 18 ÷ 3 = 6 → Divisible',
      failNumber: 7521,
      failWorking: 'Digit sum 15 divides by 3, but ends in odd 1 → Fails Rule 2',
      memoryTip: 'Check if even first! If odd, reject immediately without summing digits.',
      whyItWorks: '6 = 2 × 3. Because 2 and 3 are co-prime, any multiple of 6 must satisfy both rules simultaneously.',
    ),
    _DivisibilityCheatSheet(
      divisor: 7,
      ruleName: 'Truncate & Double',
      goldenRule: 'Double the last digit and subtract from remaining number; result must be 0 or divisible by 7.',
      category: DivisibilityCategory.primes,
      roadmap: [
        'Drop the last digit and double it.',
        'Subtract that doubled value from the remaining number.',
        'If the result is 0 or a multiple of 7, it divides by 7!',
      ],
      passNumber: 868,
      passWorking: '86 − 2(8) = 86 − 16 = 70 (70 ÷ 7 = 10) → Divisible',
      failNumber: 653,
      failWorking: '65 − 2(3) = 65 − 6 = 59 (59 ÷ 7 = 8 R 3) → Not divisible',
      memoryTip: 'Think "chop the tail, double it, subtract from the head".',
      whyItWorks: '(10a + b) − 21b = 10(a − 2b). Since 21 is a multiple of 7, 10a+b divides by 7 if and only if a−2b divides by 7.',
    ),
    _DivisibilityCheatSheet(
      divisor: 8,
      ruleName: 'Last 3 Digits',
      goldenRule: 'The last three digits form a multiple of 8 (or use the Odd/Even Hundreds shortcut).',
      category: DivisibilityCategory.basics,
      roadmap: [
        'Inspect hundreds digit H and last two digits.',
        'If H is even, test last 2 digits. If H is odd, test (last 2 digits + 4).',
        'If that value divides by 8, the entire number divides by 8!',
      ],
      passNumber: 5328,
      passWorking: 'Hundreds 3 is odd → 28 + 4 = 32 (32 ÷ 8 = 4) → Divisible',
      failNumber: 7422,
      failWorking: 'Hundreds 4 is even → 22 ÷ 8 = 2 R 6 → Not divisible',
      memoryTip: 'The Odd/Even Hundreds shortcut reduces an 8-check to a simple 2-digit table check.',
      whyItWorks: '1,000 = 8 × 125. All thousands and higher places leave zero remainder.',
    ),
    _DivisibilityCheatSheet(
      divisor: 9,
      ruleName: 'Sum of Digits = 9',
      goldenRule: 'The sum of all individual digits must be a multiple of 9.',
      category: DivisibilityCategory.sums,
      roadmap: [
        'Sum all digits together (cast out 9s or pairs adding to 9).',
        'Calculate the digital root.',
        'If the final digital root equals 9, the number divides by 9!',
      ],
      passNumber: 8415,
      passWorking: '8 + 4 + 1 + 5 = 18 (1 + 8 = 9) → Divisible',
      failNumber: 8416,
      failWorking: '8 + 4 + 1 + 6 = 19 (1 + 9 = 10 → 1) → Remainder 1',
      memoryTip: 'Cast out 9s: 8+1 = 9, 4+5 = 9 → mental sum cancels to zero!',
      whyItWorks: '10 ≡ 1 mod 9, 100 ≡ 1 mod 9. Every digit contributes its exact face value mod 9.',
    ),
    _DivisibilityCheatSheet(
      divisor: 10,
      ruleName: 'Ends in 0',
      goldenRule: 'The units digit must be 0.',
      category: DivisibilityCategory.endings,
      roadmap: [
        'Look at the final (units) digit of the number.',
        'Verify that the units digit is 0.',
        'If 0, it divides by 10 instantly!',
      ],
      passNumber: 14350,
      passWorking: 'Ends in 0 → Divisible by 10',
      failNumber: 14355,
      failWorking: 'Ends in 5 (not 0) → Remainder 5',
      memoryTip: 'Dividing by 10 is simply dropping the last zero or shifting the decimal left.',
      whyItWorks: 'Positional base-10 number system.',
    ),
    _DivisibilityCheatSheet(
      divisor: 11,
      ruleName: 'Alternating Digit Sum',
      goldenRule: 'The alternating sum of digits (odd positions minus even positions from right) is 0 or a multiple of 11.',
      category: DivisibilityCategory.primes,
      roadmap: [
        'Sum digits in odd positions (1st, 3rd, 5th from right).',
        'Sum digits in even positions (2nd, 4th, 6th from right).',
        'Subtract: Odd Sum − Even Sum. If difference is 0 or multiple of 11, it divides by 11!',
      ],
      passNumber: 91839,
      passWorking: '(9+8+9) − (3+1) = 26 − 4 = 22 (22 ÷ 11 = 2) → Divisible',
      failNumber: 91838,
      failWorking: '(8+8+9) − (3+1) = 25 − 4 = 21 (21 ÷ 11 = 1 R 10) → Not divisible',
      memoryTip: 'Think of a balance scale: alternate + and − on each digit from right to left.',
      whyItWorks: '10 ≡ −1 mod 11, 100 ≡ +1 mod 11, 1000 ≡ −1 mod 11.',
    ),
    _DivisibilityCheatSheet(
      divisor: 12,
      ruleName: 'Composite (3 and 4)',
      goldenRule: 'Must be divisible by BOTH 3 (digit sum) AND 4 (last 2 digits).',
      category: DivisibilityCategory.composites,
      roadmap: [
        'Check Rule 4: Do the last 2 digits divide by 4?',
        'Check Rule 3: Does the sum of all digits divide by 3?',
        'If both conditions pass, the number divides by 12!',
      ],
      passNumber: 5316,
      passWorking: '16 ÷ 4 = 4 AND 5+3+1+6 = 15 ÷ 3 = 5 → Divisible',
      failNumber: 5318,
      failWorking: 'Last 2 digits 18 not div by 4 → Fails Rule 4',
      memoryTip: '12 = 3 × 4. Never use 2 × 6 because 2 and 6 share common factor 2!',
      whyItWorks: '3 and 4 are co-prime: gcd(3, 4) = 1.',
    ),
    _DivisibilityCheatSheet(
      divisor: 13,
      ruleName: 'Osculator (+4 × last digit)',
      goldenRule: 'Multiply the last digit by 4 and ADD to the remaining number; result must be a multiple of 13.',
      category: DivisibilityCategory.primes,
      roadmap: [
        'Truncate the last digit and multiply it by 4.',
        'ADD that product to the remaining number.',
        'If the sum is a multiple of 13, it divides by 13!',
      ],
      passNumber: 845,
      passWorking: '84 + 4(5) = 104 → 10 + 4(4) = 26 (26 ÷ 13 = 2) → Divisible',
      failNumber: 846,
      failWorking: '84 + 4(6) = 108 → 10 + 4(8) = 42 (not div by 13) → Not divisible',
      memoryTip: 'Compare with 7: for 7 you SUBTRACT 2×; for 13 you ADD 4×!',
      whyItWorks: '(10a + b) + 39b = 10(a + 4b). Since 39 is 3×13, 10a+b divides by 13 if and only if a+4b divides by 13.',
    ),
    _DivisibilityCheatSheet(
      divisor: 14,
      ruleName: 'Composite (2 and 7)',
      goldenRule: 'The number must be EVEN and divisible by 7.',
      category: DivisibilityCategory.composites,
      roadmap: [
        'Check Rule 2: Must be even (units digit 0, 2, 4, 6, 8).',
        'Check Rule 7: Truncate and subtract double the last digit.',
        'If both pass, it divides by 14!',
      ],
      passNumber: 1288,
      passWorking: 'Even (8) AND 128 − 2(8) = 112 → 11 − 2(2) = 7 → Divisible',
      failNumber: 1281,
      failWorking: 'Divisible by 7, but ends in odd 1 → Fails Rule 2',
      memoryTip: 'Always verify the number is even first before testing Rule 7.',
      whyItWorks: '14 = 2 × 7 (co-prime factors).',
    ),
    _DivisibilityCheatSheet(
      divisor: 15,
      ruleName: 'Composite (3 and 5)',
      goldenRule: 'Must end in 0 or 5 AND the sum of digits must be divisible by 3.',
      category: DivisibilityCategory.composites,
      roadmap: [
        'Check Rule 5: Units digit must be 0 or 5.',
        'Check Rule 3: Sum of all digits must divide by 3.',
        'If both pass, the number divides by 15!',
      ],
      passNumber: 2745,
      passWorking: 'Ends in 5 AND 2+7+4+5 = 18 (18 ÷ 3 = 6) → Divisible',
      failNumber: 2740,
      failWorking: 'Ends in 0, but 2+7+4+0 = 13 (not div by 3) → Fails Rule 3',
      memoryTip: 'Ends in 0 or 5 is instant. Then just check digit sum for 3.',
      whyItWorks: '15 = 3 × 5 (co-prime factors).',
    ),
    _DivisibilityCheatSheet(
      divisor: 18,
      ruleName: 'Composite (2 and 9)',
      goldenRule: 'The number must be EVEN and the sum of digits must be a multiple of 9.',
      category: DivisibilityCategory.composites,
      roadmap: [
        'Check Rule 2: Units digit must be even (0, 2, 4, 6, 8).',
        'Check Rule 9: Sum of all digits must equal a multiple of 9.',
        'If both pass, the number divides by 18!',
      ],
      passNumber: 3492,
      passWorking: 'Even (2) AND 3+4+9+2 = 18 (multiple of 9) → Divisible',
      failNumber: 3495,
      failWorking: 'Digit sum 21 is multiple of 3, but number is odd → Fails Rule 2',
      memoryTip: 'An odd number can NEVER divide by 18, no matter what its digit sum is.',
      whyItWorks: '18 = 2 × 9 (co-prime factors).',
    ),
    _DivisibilityCheatSheet(
      divisor: 25,
      ruleName: 'Ends in 00, 25, 50, 75',
      goldenRule: 'The last two digits must end in 00, 25, 50, or 75.',
      category: DivisibilityCategory.endings,
      roadmap: [
        'Look at only the last two digits of the number.',
        'Check if they match 00, 25, 50, or 75.',
        'If matched, the number divides by 25!',
      ],
      passNumber: 18475,
      passWorking: 'Ends in 75 → Divisible by 25',
      failNumber: 18485,
      failWorking: 'Ends in 85 (not 00, 25, 50, 75) → Remainder 10',
      memoryTip: 'Think of 25-cent coins: 25, 50, 75, 100.',
      whyItWorks: '100 = 25 × 4. All hundreds and higher places leave zero remainder.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _numberCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _numberCtrl.text.trim().replaceAll(',', '');
    final val = int.tryParse(text);
    if (val != null && val > 0 && val != _currentNumber) {
      setState(() => _currentNumber = val);
    }
  }

  void _setPreset(int n) {
    HapticFeedback.selectionClick();
    _numberCtrl.text = '$n';
    setState(() {
      _currentNumber = n;
      _expandedDivisor = null;
    });
  }

  void _randomize() {
    HapticFeedback.selectionClick();
    final rng = Random();
    final randN = 100 + rng.nextInt(99900);
    _setPreset(randN);
  }

  @override
  void dispose() {
    _numberCtrl.removeListener(_onTextChanged);
    _numberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = DivisibilityHelper.checkAll(_currentNumber);
    final filteredSheets = _selectedCat == DivisibilityCategory.all
        ? _cheatSheets
        : _cheatSheets.where((s) => s.category == _selectedCat).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Interactive Live Divisibility Tester ──────────────────────
          _buildLiveTesterCard(results),

          const SizedBox(height: 20),

          // ── 2. Category Filter Tabs ────────────────────────────────────
          _buildCategoryFilters(),

          const SizedBox(height: 16),

          // ── 3. Rule Handbook Revision Cheat-Sheets ─────────────────────
          _buildRevisionCheatSheets(filteredSheets, results),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Live Tester Card ──────────────────────────────────────────────────────

  Widget _buildLiveTesterCard(List<DivisibilityResult> results) {
    final passCount = results.where((r) => r.isDivisible).length;

    return Container(
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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // amber-100
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Text(
                      'LIVE DIVISIBILITY CHECKER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD97706),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$passCount of ${results.length} divide $_currentNumber',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Number Input Field + Random Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numberCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Test any number',
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.numbers_rounded,
                        color: AppTheme.primaryColor, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.primaryColor, width: 1.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: _randomize,
                icon: const Icon(Icons.shuffle_rounded),
                tooltip: 'Random test number',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryTint,
                  foregroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Presets: ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                ..._presetNumbers.map((p) {
                  final active = _currentNumber == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _setPreset(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primaryColor
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active
                                ? AppTheme.primaryColor
                                : AppTheme.borderLight,
                          ),
                        ),
                        child: Text(
                          '$p',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            color: active
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Instant Status Chips Grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: results.map((r) {
              final isExpanded = _expandedDivisor == r.divisor;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _expandedDivisor =
                        _expandedDivisor == r.divisor ? null : r.divisor;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: r.isDivisible
                        ? const Color(0xFFDCFCE7) // green-100
                        : const Color(0xFFFEE2E2), // red-100
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isExpanded
                          ? (r.isDivisible
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626))
                          : (r.isDivisible
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5)),
                      width: isExpanded ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '÷${r.divisor}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: r.isDivisible
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        r.isDivisible
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 15,
                        color: r.isDivisible
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // If a chip is tapped, display its live working callout
          if (_expandedDivisor != null) ...[
            const SizedBox(height: 14),
            _buildExpandedChipDetails(
                results.firstWhere((r) => r.divisor == _expandedDivisor)),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedChipDetails(DivisibilityResult r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: r.isDivisible
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: r.isDivisible
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFCA5A5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                r.isDivisible
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: r.isDivisible
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rule for ${r.divisor}: ${r.ruleTitle}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: r.isDivisible
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _expandedDivisor = null),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.detailedWorking,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          if (r.whyItWorks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Why it works: ${r.whyItWorks}',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Category Filters ──────────────────────────────────────────────────────

  Widget _buildCategoryFilters() {
    final categories = [
      (DivisibilityCategory.all, 'All Rules (16)'),
      (DivisibilityCategory.basics, 'Basics (2, 4, 8)'),
      (DivisibilityCategory.sums, 'Sums (3, 9)'),
      (DivisibilityCategory.endings, 'Endings (5, 10, 25)'),
      (DivisibilityCategory.primes, 'Primes (7, 11, 13)'),
      (DivisibilityCategory.composites, 'Composites (6, 12, 14, 15, 18)'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((entry) {
          final isSelected = _selectedCat == entry.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.$2),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _selectedCat = entry.$1);
              },
              selectedColor: const Color(0xFFFEF3C7), // amber-100
              backgroundColor: AppTheme.surfaceCard,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFFB45309) // amber-700
                    : AppTheme.textSecondary,
              ),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFF59E0B)
                    : AppTheme.borderLight,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Revision Cheat-Sheets ─────────────────────────────────────────────────

  Widget _buildRevisionCheatSheets(
    List<_DivisibilityCheatSheet> sheets,
    List<DivisibilityResult> liveResults,
  ) {
    final liveMap = {for (final r in liveResults) r.divisor: r};

    return Column(
      children: sheets.map((sheet) {
        final live = liveMap[sheet.divisor];
        return _buildSingleCheatSheetCard(sheet, live);
      }).toList(),
    );
  }

  Widget _buildSingleCheatSheetCard(
    _DivisibilityCheatSheet sheet,
    DivisibilityResult? live,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // ── Header: Large Rule Badge + Title + Live Status Badge ──────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '÷${sheet.divisor}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sheet.ruleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _categoryLabel(sheet.category),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              if (live != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: live.isDivisible
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: live.isDivisible
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        live.isDivisible
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 13,
                        color: live.isDivisible
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        live.isDivisible ? 'DIVIDES' : 'FAILS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: live.isDivisible
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB91C1C),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // ── 1. Golden Rule Banner ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // amber-50
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.star_rounded,
                    size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GOLDEN RULE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sheet.goldenRule,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF78350F),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 2. Three-Step Numbered Bullet Roadmap ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded,
                        size: 15, color: AppTheme.primaryColor),
                    SizedBox(width: 6),
                    Text(
                      '3-Step Mental Roadmap:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(sheet.roadmap.length, (idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTint,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sheet.roadmap[idx],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── 3. Side-by-Side Color-Coded Pass ✅ / Fail ❌ Example Cards ────
          Row(
            children: [
              // Pass Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4), // green-50
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'PASS EXAMPLE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF15803D),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sheet.passNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF166534),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sheet.passWorking,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Fail Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2), // red-50
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cancel_rounded,
                              size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 4),
                          Text(
                            'FAIL EXAMPLE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB91C1C),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sheet.failNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF991B1B),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sheet.failWorking,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── 4. Live Calculation on Current Number ─────────────────────────
          if (live != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: live.isDivisible
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: live.isDivisible
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFFFECDD3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    live.isDivisible
                        ? Icons.check_circle_outline_rounded
                        : Icons.highlight_off_rounded,
                    size: 15,
                    color: live.isDivisible
                        ? const Color(0xFF059669)
                        : const Color(0xFFE11D48),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Live Check for $_currentNumber: ${live.detailedWorking}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: live.isDivisible
                            ? const Color(0xFF065F46)
                            : const Color(0xFF9F1239),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // ── 5. Memory Tip Banner ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 15, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Memory Tip: ${sheet.memoryTip}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB45309),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryLabel(DivisibilityCategory c) {
    switch (c) {
      case DivisibilityCategory.basics:
        return 'Basics Rule';
      case DivisibilityCategory.sums:
        return 'Digit Sum Rule';
      case DivisibilityCategory.endings:
        return 'Endings Rule';
      case DivisibilityCategory.primes:
        return 'Prime Shortcut Rule';
      case DivisibilityCategory.composites:
        return 'Co-Prime Composite Rule';
      case DivisibilityCategory.all:
        return 'Standard Rule';
    }
  }
}
