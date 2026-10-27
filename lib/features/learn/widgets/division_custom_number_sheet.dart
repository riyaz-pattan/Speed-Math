// lib/features/learn/widgets/division_custom_number_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// Modal bottom sheet allowing users to input custom numbers for Division shortcuts,
/// with validation explaining when a number does not fit a specific shortcut.
class DivisionCustomNumberSheet extends StatefulWidget {
  const DivisionCustomNumberSheet({
    super.key,
    required this.lessonId,
    required this.currentDividend,
    required this.currentDivisor,
    required this.onApply,
  });

  final String lessonId;
  final int currentDividend;
  final num currentDivisor; // int or double (for reciprocal 2.5)
  final void Function(int newDividend, num newDivisor) onApply;

  static void show({
    required BuildContext context,
    required String lessonId,
    required int currentDividend,
    required num currentDivisor,
    required void Function(int newDividend, num newDivisor) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DivisionCustomNumberSheet(
        lessonId: lessonId,
        currentDividend: currentDividend,
        currentDivisor: currentDivisor,
        onApply: onApply,
      ),
    );
  }

  @override
  State<DivisionCustomNumberSheet> createState() =>
      _DivisionCustomNumberSheetState();
}

class _DivisionCustomNumberSheetState extends State<DivisionCustomNumberSheet> {
  late final TextEditingController _dividendCtrl;
  late final TextEditingController _divisorCtrl;
  String? _validationWarning;

  @override
  void initState() {
    super.initState();
    _dividendCtrl = TextEditingController(text: '${widget.currentDividend}');
    _divisorCtrl = TextEditingController(
      text: widget.currentDivisor == widget.currentDivisor.truncate()
          ? '${widget.currentDivisor.truncate()}'
          : '${widget.currentDivisor}',
    );
  }

  @override
  void dispose() {
    _dividendCtrl.dispose();
    _divisorCtrl.dispose();
    super.dispose();
  }

  void _validateAndApply() {
    final dividend = int.tryParse(_dividendCtrl.text.trim());
    if (dividend == null || dividend <= 0) {
      setState(() => _validationWarning = 'Please enter a valid positive dividend.');
      return;
    }

    final divisorStr = _divisorCtrl.text.trim();
    final divisor = num.tryParse(divisorStr);
    if (divisor == null || divisor <= 0) {
      setState(() => _validationWarning = 'Please enter a valid positive divisor.');
      return;
    }

    // Specific shortcut validation
    switch (widget.lessonId) {
      case 'divide_by_5_25':
        if (divisor != 5 && divisor != 25 && divisor != 125) {
          setState(() {
            _validationWarning =
                'This shortcut applies to division by 5, 25, or 125 (powers of 5). For other divisors, use factor division or general division.';
          });
          return;
        }
      case 'divide_by_9_99':
        if (divisor != 9 && divisor != 99) {
          setState(() {
            _validationWarning =
                'The Vedic running sum shortcut applies specifically to division by 9 and 99.';
          });
          return;
        }
      case 'factor_division':
        final intDiv = divisor.toInt();
        const validComposites = [14, 15, 18, 21, 24, 27, 28, 32, 35, 36, 42, 45, 48, 54, 56, 63, 64, 72, 81];
        if (!validComposites.contains(intDiv)) {
          setState(() {
            _validationWarning =
                '$intDiv cannot be decomposed into clean single-digit factors. Factor division applies to composite divisors like 14, 15, 18, 24, 36, 45, 72.';
          });
          return;
        }
      case 'reciprocal_division':
        const validDecimals = [0.5, 0.25, 0.2, 0.125, 2.5, 7.5];
        final match = validDecimals.any((v) => (v - divisor).abs() < 0.001);
        if (!match) {
          setState(() {
            _validationWarning =
                '$divisorStr does not have a simple whole-number reciprocal. This shortcut applies to decimal fractions like 0.5, 0.25, 0.2, 0.125, 2.5, 7.5.';
          });
          return;
        }
      case 'flag_division':
        if (divisor < 10 || divisor > 99) {
          setState(() {
            _validationWarning =
                'Straight division (Flag method) is designed for 2-digit divisors (10 to 99).';
          });
          return;
        }
    }

    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    widget.onApply(dividend, divisor);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text(
              'Enter Custom Numbers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'The shortcut board will instantly adapt to demonstrate the mental steps on your numbers.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Warning Banner if applicable
            if (_validationWarning != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationWarning!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Input Fields
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _dividendCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Dividend (N)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '÷',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _divisorCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Divisor',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _validateAndApply,
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Apply & Show Shortcut',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
