// lib/features/learn/widgets/applied_math_custom_number_sheet.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// Modal bottom sheet allowing users to enter custom operands for Applied Maths lessons:
/// - Split Percentages (P% of N)
/// - Fraction to Percentage (n / d)
/// - Percentage to Fraction (P% applied to base N)
class AppliedMathCustomNumberSheet extends StatefulWidget {
  const AppliedMathCustomNumberSheet({
    super.key,
    required this.lessonId,
    required this.currentOperands,
    required this.onApply,
  });

  final String lessonId;
  final List<int> currentOperands;
  final void Function(List<int> newOperands) onApply;

  static void show({
    required BuildContext context,
    required String lessonId,
    required List<int> currentOperands,
    required void Function(List<int> newOperands) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppliedMathCustomNumberSheet(
        lessonId: lessonId,
        currentOperands: currentOperands,
        onApply: onApply,
      ),
    );
  }

  @override
  State<AppliedMathCustomNumberSheet> createState() =>
      _AppliedMathCustomNumberSheetState();
}

class _AppliedMathCustomNumberSheetState
    extends State<AppliedMathCustomNumberSheet> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _secondCtrl;
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    final ops = widget.currentOperands;
    if (widget.lessonId == 'split_percentages') {
      final pct = ops.isNotEmpty ? ops[0] : 15;
      final n = ops.length > 1 ? ops[1] : 240;
      _firstCtrl = TextEditingController(text: '$pct');
      _secondCtrl = TextEditingController(text: '$n');
    } else if (widget.lessonId == 'percentage_to_fraction') {
      final rawPct = ops.isNotEmpty ? ops[0] : 3750;
      final pctVal = rawPct > 500 ? (rawPct / 100.0) : rawPct.toDouble();
      final pctStr = (pctVal == pctVal.truncate())
          ? '${pctVal.truncate()}'
          : pctVal.toStringAsFixed(2);
      final examN = ops.length > 1 ? ops[1] : 640;
      _firstCtrl = TextEditingController(text: pctStr);
      _secondCtrl = TextEditingController(text: '$examN');
    } else {
      // fraction_pct_friends
      final num = ops.isNotEmpty ? ops[0] : 3;
      final den = ops.length > 1 ? ops[1] : 8;
      _firstCtrl = TextEditingController(text: '$num');
      _secondCtrl = TextEditingController(text: '$den');
    }
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  void _validateAndApply() {
    final t1 = _firstCtrl.text.trim();
    final t2 = _secondCtrl.text.trim();

    if (t1.isEmpty || t2.isEmpty) {
      setState(() => _warningMessage = 'Please fill in both fields.');
      return;
    }

    if (widget.lessonId == 'split_percentages') {
      final pct = double.tryParse(t1);
      final n = int.tryParse(t2);

      if (pct == null || pct <= 0 || pct > 9999) {
        setState(() => _warningMessage = 'Percentage must be a positive number (e.g. 35, 135, 250).');
        return;
      }
      if (n == null || n <= 0) {
        setState(() => _warningMessage = 'Number must be a positive integer.');
        return;
      }

      Navigator.pop(context);
      // If pct has decimals (e.g. 17.5), we encode as scaled by 100 or truncate if int
      final encodedPct = (pct == pct.truncate()) ? pct.truncate() : (pct * 100).round();
      widget.onApply([encodedPct, n]);
    } else if (widget.lessonId == 'percentage_to_fraction') {
      final pct = double.tryParse(t1);
      final base = int.tryParse(t2);

      if (pct == null || pct <= 0 || pct > 200) {
        setState(() => _warningMessage = 'Percentage must be between 0.5% and 200%.');
        return;
      }
      if (base == null || base <= 0) {
        setState(() => _warningMessage = 'Base number must be a positive integer.');
        return;
      }

      Navigator.pop(context);
      final encodedPct = (pct == pct.truncate()) ? pct.truncate() : (pct * 100).round();
      widget.onApply([encodedPct, base]);
    } else {
      // fraction_pct_friends
      final num = int.tryParse(t1);
      final den = int.tryParse(t2);

      if (num == null || num <= 0) {
        setState(() => _warningMessage = 'Numerator must be at least 1.');
        return;
      }
      if (den == null || den <= 1) {
        setState(() => _warningMessage = 'Denominator must be greater than 1.');
        return;
      }
      if (den > 50) {
        setState(() => _warningMessage = 'Denominator should be 50 or below for mental math.');
        return;
      }

      Navigator.pop(context);
      widget.onApply([num, den]);
    }
  }

  void _applyPreset(String val1, String val2) {
    HapticFeedback.selectionClick();
    setState(() {
      _firstCtrl.text = val1;
      _secondCtrl.text = val2;
      _warningMessage = null;
    });
  }

  void _applyRandom() {
    HapticFeedback.selectionClick();
    final rng = Random();
    if (widget.lessonId == 'split_percentages') {
      final presets = [
        ['15', '240'],
        ['35', '420'],
        ['45', '360'],
        ['48', '250'],
        ['65', '800'],
        ['95', '640'],
        ['17.5', '400'],
        ['99', '750'],
        ['75', '480'],
        ['12', '350'],
        ['55', '620'],
        ['22.5', '800'],
        ['135', '240'],
        ['250', '360'],
        ['175', '800'],
      ];
      final pick = presets[rng.nextInt(presets.length)];
      _applyPreset(pick[0], pick[1]);
    } else if (widget.lessonId == 'percentage_to_fraction') {
      final presets = [
        ['37.5', '640'],
        ['62.5', '480'],
        ['83.33', '360'],
        ['16.67', '726'],
        ['14.28', '490'],
        ['44.44', '270'],
        ['9.09', '330'],
        ['8.33', '288'],
        ['6.25', '640'],
        ['87.5', '560'],
        ['66.67', '450'],
        ['28.57', '350'],
      ];
      final pick = presets[rng.nextInt(presets.length)];
      _applyPreset(pick[0], pick[1]);
    } else {
      // fraction_pct_friends
      final presets = [
        ['1', '3'],
        ['2', '3'],
        ['1', '4'],
        ['3', '4'],
        ['1', '6'],
        ['5', '6'],
        ['1', '7'],
        ['2', '7'],
        ['4', '7'],
        ['1', '8'],
        ['3', '8'],
        ['5', '8'],
        ['7', '8'],
        ['1', '9'],
        ['4', '9'],
        ['5', '9'],
        ['1', '11'],
        ['3', '11'],
        ['1', '12'],
        ['5', '12'],
        ['7', '12'],
        ['1', '16'],
        ['3', '16'],
        ['5', '16'],
        ['7', '16'],
      ];
      final pick = presets[rng.nextInt(presets.length)];
      _applyPreset(pick[0], pick[1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, firstLabel, secondLabel, firstHint, secondHint, desc) =
        switch (widget.lessonId) {
      'split_percentages' => (
          'Custom Split Percentage',
          'Percentage (P%)',
          'Number (N)',
          'e.g. 35, 135, 250',
          'e.g. 240',
          'Break any percentage into 50%, 25%, 10%, 5%, and 1% mental chunks.',
        ),
      'percentage_to_fraction' => (
          'Custom Percentage to Fraction',
          'Percentage (P%)',
          'Exam Base Number',
          'e.g. 37.5, 62.5, 83.33',
          'e.g. 640',
          'Transform recurring and benchmark percentages into irreducible fractions for 2-second division.',
        ),
      _ => (
          'Custom Fraction to Percentage',
          'Numerator (n)',
          'Denominator (d)',
          'e.g. 3',
          'e.g. 8',
          'Enter any fraction to see its exact benchmark percentage and fast scaling strategy.',
        ),
    };

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Input Fields Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _firstCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: firstHint,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.borderLight),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        secondLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _secondCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: secondHint,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.borderLight),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_warningMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.amber.shade900, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _warningMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Presets Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Shortcut Examples',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _applyRandom,
                  child: Row(
                    children: const [
                      Icon(Icons.shuffle_rounded,
                          size: 14, color: AppTheme.primaryColor),
                      SizedBox(width: 4),
                      Text(
                        'Random',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Presets Chips Wrap
            _buildPresetChips(),

            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppTheme.borderLight),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _validateAndApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply & Draw',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChips() {
    if (widget.lessonId == 'split_percentages') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PresetChip(
            label: '15% of 240',
            onTap: () => _applyPreset('15', '240'),
          ),
          _PresetChip(
            label: '35% of 420',
            onTap: () => _applyPreset('35', '420'),
          ),
          _PresetChip(
            label: '45% of 360',
            onTap: () => _applyPreset('45', '360'),
          ),
          _PresetChip(
            label: '48% of 250',
            onTap: () => _applyPreset('48', '250'),
          ),
          _PresetChip(
            label: '65% of 800',
            onTap: () => _applyPreset('65', '800'),
          ),
          _PresetChip(
            label: '95% of 640',
            onTap: () => _applyPreset('95', '640'),
          ),
          _PresetChip(
            label: '17.5% of 400',
            onTap: () => _applyPreset('17.5', '400'),
          ),
          _PresetChip(
            label: '99% of 750',
            onTap: () => _applyPreset('99', '750'),
          ),
        ],
      );
    } else if (widget.lessonId == 'percentage_to_fraction') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PresetChip(
            label: '37.5% of 640 (3/8)',
            onTap: () => _applyPreset('37.5', '640'),
          ),
          _PresetChip(
            label: '62.5% of 480 (5/8)',
            onTap: () => _applyPreset('62.5', '480'),
          ),
          _PresetChip(
            label: '83.33% of 360 (5/6)',
            onTap: () => _applyPreset('83.33', '360'),
          ),
          _PresetChip(
            label: '16.67% of 726 (1/6)',
            onTap: () => _applyPreset('16.67', '726'),
          ),
          _PresetChip(
            label: '14.28% of 490 (1/7)',
            onTap: () => _applyPreset('14.28', '490'),
          ),
          _PresetChip(
            label: '44.44% of 270 (4/9)',
            onTap: () => _applyPreset('44.44', '270'),
          ),
          _PresetChip(
            label: '9.09% of 330 (1/11)',
            onTap: () => _applyPreset('9.09', '330'),
          ),
          _PresetChip(
            label: '8.33% of 288 (1/12)',
            onTap: () => _applyPreset('8.33', '288'),
          ),
          _PresetChip(
            label: '6.25% of 640 (1/16)',
            onTap: () => _applyPreset('6.25', '640'),
          ),
        ],
      );
    } else {
      // fraction_pct_friends
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PresetChip(
            label: '1/3  (33.33%)',
            onTap: () => _applyPreset('1', '3'),
          ),
          _PresetChip(
            label: '3/8  (37.5%)',
            onTap: () => _applyPreset('3', '8'),
          ),
          _PresetChip(
            label: '5/6  (83.33%)',
            onTap: () => _applyPreset('5', '6'),
          ),
          _PresetChip(
            label: '4/7  (57.14%)',
            onTap: () => _applyPreset('4', '7'),
          ),
          _PresetChip(
            label: '5/9  (55.56%)',
            onTap: () => _applyPreset('5', '9'),
          ),
          _PresetChip(
            label: '5/12  (41.67%)',
            onTap: () => _applyPreset('5', '12'),
          ),
          _PresetChip(
            label: '7/16  (43.75%)',
            onTap: () => _applyPreset('7', '16'),
          ),
          _PresetChip(
            label: '7/8  (87.5%)',
            onTap: () => _applyPreset('7', '8'),
          ),
        ],
      );
    }
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
