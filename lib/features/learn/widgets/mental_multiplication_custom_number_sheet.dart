// lib/features/learn/widgets/mental_multiplication_custom_number_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// Modal bottom sheet allowing users to input custom numbers for Mental Multiplication shortcuts,
/// with instant validation and shortcut applicability advice.
class MentalMultiplicationCustomNumberSheet extends StatefulWidget {
  const MentalMultiplicationCustomNumberSheet({
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
      builder: (_) => MentalMultiplicationCustomNumberSheet(
        lessonId: lessonId,
        currentOperands: currentOperands,
        onApply: onApply,
      ),
    );
  }

  @override
  State<MentalMultiplicationCustomNumberSheet> createState() =>
      _MentalMultiplicationCustomNumberSheetState();
}

class _MentalMultiplicationCustomNumberSheetState
    extends State<MentalMultiplicationCustomNumberSheet> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _secondCtrl;
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    final first = widget.currentOperands.isNotEmpty
        ? widget.currentOperands[0]
        : 48;
    final second = widget.currentOperands.length > 1
        ? widget.currentOperands[1]
        : 5;

    _firstCtrl = TextEditingController(text: '$first');
    _secondCtrl = TextEditingController(text: '$second');
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  void _validateAndApply() {
    final first = int.tryParse(_firstCtrl.text.trim());
    if (first == null || first <= 0) {
      setState(() => _warningMessage = 'Please enter a valid positive number.');
      return;
    }

    final metaId = widget.lessonId;

    if (metaId == 'multiply_by_11') {
      Navigator.pop(context);
      widget.onApply([first, 11]);
      return;
    }

    final second = int.tryParse(_secondCtrl.text.trim());
    if (second == null || second <= 0) {
      setState(() => _warningMessage = 'Please enter a valid positive second number.');
      return;
    }

    if (metaId == 'multiply_by_5_25') {
      if (second != 5 && second != 25 && second != 75 && second != 125) {
        setState(() {
          _warningMessage =
              'This shortcut applies specifically to multiplying by 5, 25, 75, or 125. For other numbers, use Criss-Cross.';
        });
        return;
      }
    }

    if (metaId == 'multiply_by_99') {
      if (second != 9 && second != 99 && second != 999) {
        setState(() {
          _warningMessage =
              'This shortcut applies specifically to multiplying by 9, 99, or 999 (powers of 10 minus 1).';
        });
        return;
      }
    }

    if (metaId == 'near_100_mult') {
      if ((first - 100).abs() > 30 || (second - 100).abs() > 30) {
        setState(() {
          _warningMessage =
              'For Near-100 multiplication, both numbers should ideally be between 70 and 130 so deviations remain small and easy.';
        });
        return;
      }
    }

    Navigator.pop(context);
    widget.onApply([first, second]);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final metaId = widget.lessonId;
    final isTimes11 = metaId == 'multiply_by_11';

    final title = switch (metaId) {
      'multiply_by_5_25' => 'Custom Numbers: × 5, 25, 75 & 125',
      'multiply_by_11' => 'Custom Number: Multiply by 11',
      'multiply_by_99' => 'Custom Numbers: × 9, 99 & 999',
      'near_100_mult' => 'Custom Numbers: Near-100 Multiplication',
      _ => 'Custom Numbers',
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF), // purple-100
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calculate_rounded,
                      color: Color(0xFF7C3AED), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Test the mental shortcut with any custom values',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // First number input
            TextField(
              controller: _firstCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                labelText: isTimes11
                    ? 'Enter any number to multiply by 11'
                    : 'First Number (N)',
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
                prefixIcon: const Icon(Icons.numbers_rounded,
                    color: Color(0xFF7C3AED), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF7C3AED), width: 1.8),
                ),
              ),
            ),

            if (!isTimes11) ...[
              const SizedBox(height: 14),

              // Second number input
              TextField(
                controller: _secondCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  labelText: metaId == 'near_100_mult'
                      ? 'Second Number (near 100)'
                      : 'Multiplier',
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                  prefixIcon: const Icon(Icons.close_rounded,
                      color: Color(0xFF7C3AED), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF7C3AED), width: 1.8),
                  ),
                ),
              ),

              // Quick multiplier selector buttons
              if (metaId == 'multiply_by_5_25') ...[
                const SizedBox(height: 10),
                Row(
                  children: [5, 25, 75, 125].map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text('× $m'),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _secondCtrl.text = '$m';
                        },
                        backgroundColor: const Color(0xFFF3E8FF),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED),
                        ),
                        side: const BorderSide(color: Color(0xFFD8B4FE)),
                      ),
                    );
                  }).toList(),
                ),
              ],

              if (metaId == 'multiply_by_99') ...[
                const SizedBox(height: 10),
                Row(
                  children: [9, 99, 999].map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text('× $m'),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _secondCtrl.text = '$m';
                        },
                        backgroundColor: const Color(0xFFF3E8FF),
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED),
                        ),
                        side: const BorderSide(color: Color(0xFFD8B4FE)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],

            // Warning Banner
            if (_warningMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), // red-50
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _warningMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _validateAndApply,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Apply Numbers'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
}
