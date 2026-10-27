// lib/features/learn/widgets/squares_custom_number_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// Modal bottom sheet allowing users to input custom numbers for Squaring shortcuts,
/// with instant validation and shortcut applicability advice.
class SquaresCustomNumberSheet extends StatefulWidget {
  const SquaresCustomNumberSheet({
    super.key,
    required this.lessonId,
    required this.currentNumber,
    required this.onApply,
  });

  final String lessonId;
  final int currentNumber;
  final void Function(int newNumber) onApply;

  static void show({
    required BuildContext context,
    required String lessonId,
    required int currentNumber,
    required void Function(int newNumber) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SquaresCustomNumberSheet(
        lessonId: lessonId,
        currentNumber: currentNumber,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SquaresCustomNumberSheet> createState() =>
      _SquaresCustomNumberSheetState();
}

class _SquaresCustomNumberSheetState extends State<SquaresCustomNumberSheet> {
  late final TextEditingController _numCtrl;
  String? _warningMessage;

  @override
  void initState() {
    super.initState();
    _numCtrl = TextEditingController(text: '${widget.currentNumber}');
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    super.dispose();
  }

  void _validateAndApply() {
    final val = int.tryParse(_numCtrl.text.trim());
    if (val == null || val <= 0) {
      setState(() => _warningMessage = 'Please enter a valid positive number.');
      return;
    }

    final metaId = widget.lessonId;

    if (metaId == 'squares_ending_5') {
      if (val % 10 != 5) {
        setState(() {
          _warningMessage =
              'This shortcut cannot be applied here. The number must end with the digit 5.';
        });
        return;
      }
      if (val < 10 || val > 99) {
        setState(() {
          _warningMessage =
              'This shortcut cannot be applied here. Please enter a 2-digit number ending with 5 (15 to 95).';
        });
        return;
      }
    }

    if (metaId == 'squares_base_25') {
      if (val < 15 || val > 35) {
        setState(() {
          _warningMessage =
              'For Base 25 squaring, the number should ideally be between 18 and 32 so deviations remain small and easy to compute mentally.';
        });
        return;
      }
    }

    if (metaId == 'squares_base_50') {
      if (val < 30 || val > 70) {
        setState(() {
          _warningMessage =
              'For Base 50 squaring, the number should ideally be between 35 and 65 so deviations remain small and easy to compute mentally.';
        });
        return;
      }
    }

    if (metaId == 'squares_base_100') {
      if (val < 70 || val > 130) {
        setState(() {
          _warningMessage =
              'For Base 100 squaring, the number should ideally be between 75 and 125 so deviations remain small.';
        });
        return;
      }
    }

    if (metaId == 'squares_base_150') {
      if (val < 125 || val > 175) {
        setState(() {
          _warningMessage =
              'For Base 150 squaring, the number should ideally be between 130 and 170.';
        });
        return;
      }
    }

    if (metaId == 'squares_base_200') {
      if (val < 170 || val > 230) {
        setState(() {
          _warningMessage =
              'For Base 200 squaring, the number should ideally be between 175 and 225.';
        });
        return;
      }
    }

    Navigator.pop(context);
    widget.onApply(val);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final metaId = widget.lessonId;

    final title = switch (metaId) {
      'squares_ending_5' => 'Custom Number: Ending in 5',
      'squares_base_25' => 'Custom Number: Base 25',
      'squares_base_50' => 'Custom Number: Base 50',
      'squares_base_100' => 'Custom Number: Base 100',
      'squares_base_150' => 'Custom Number: Base 150',
      'squares_base_200' => 'Custom Number: Base 200',
      _ => 'Custom Number: Squaring',
    };

    final hintText = switch (metaId) {
      'squares_ending_5' => 'Enter a 2-digit number ending with 5 (e.g. 35, 65)',
      'squares_base_25' => 'Enter a number near 25 (e.g. 21 to 29)',
      'squares_base_50' => 'Enter a number near 50 (e.g. 35 to 65)',
      'squares_base_100' => 'Enter a number near 100 (e.g. 75 to 125)',
      'squares_base_150' => 'Enter a number near 150 (e.g. 130 to 170)',
      'squares_base_200' => 'Enter a number near 200 (e.g. 175 to 225)',
      _ => 'Enter a number to square',
    };

    final List<int> quickPresets = switch (metaId) {
      'squares_ending_5' => [15, 25, 35, 45, 55, 65, 75, 85, 95],
      'squares_base_25' => [21, 22, 23, 24, 26, 27, 28, 29],
      'squares_base_50' => [41, 46, 48, 52, 54, 58],
      'squares_base_100' => [88, 92, 96, 97, 104, 108],
      'squares_base_150' => [142, 146, 148, 152, 154, 158],
      'squares_base_200' => [192, 196, 198, 202, 204, 208],
      _ => [25, 35, 45],
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
                    color: const Color(0xFFFFEDD5), // orange-100
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.superscript_rounded,
                      color: Color(0xFFEA580C), size: 22),
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
                      Text(
                        hintText,
                        style: const TextStyle(
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

            // Number Input
            TextField(
              controller: _numCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                labelText: 'Number to Square (N)',
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
                prefixIcon: const Icon(Icons.numbers_rounded,
                    color: Color(0xFFEA580C), size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFEA580C), width: 1.8),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Quick preset chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickPresets.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text('$p²'),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _numCtrl.text = '$p';
                        setState(() => _warningMessage = null);
                      },
                      backgroundColor: const Color(0xFFFFEDD5),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEA580C),
                      ),
                      side: const BorderSide(color: Color(0xFFFDBA74)),
                    ),
                  );
                }).toList(),
              ),
            ),

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
                    label: const Text('Apply Number'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
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
