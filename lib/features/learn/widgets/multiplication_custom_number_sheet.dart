// lib/features/learn/widgets/multiplication_custom_number_sheet.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Modal bottom sheet allowing users to select preset numbers or enter ANY
/// custom numbers for Speed Multiplication (up to 3 digits).
class MultiplicationCustomNumberSheet extends StatefulWidget {
  const MultiplicationCustomNumberSheet({
    super.key,
    required this.currentA,
    required this.currentB,
    required this.onApply,
  });

  final int currentA;
  final int currentB;
  final void Function(int a, int b) onApply;

  static Future<void> show({
    required BuildContext context,
    required int currentA,
    required int currentB,
    required void Function(int a, int b) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => MultiplicationCustomNumberSheet(
        currentA: currentA,
        currentB: currentB,
        onApply: onApply,
      ),
    );
  }

  @override
  State<MultiplicationCustomNumberSheet> createState() =>
      _MultiplicationCustomNumberSheetState();
}

class _MultiplicationCustomNumberSheetState
    extends State<MultiplicationCustomNumberSheet> {
  late final TextEditingController _ctrlA;
  late final TextEditingController _ctrlB;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrlA = TextEditingController(text: '${widget.currentA}');
    _ctrlB = TextEditingController(text: '${widget.currentB}');
  }

  @override
  void dispose() {
    _ctrlA.dispose();
    _ctrlB.dispose();
    super.dispose();
  }

  void _apply() {
    final a = int.tryParse(_ctrlA.text.trim());
    final b = int.tryParse(_ctrlB.text.trim());

    if (a == null || a <= 0 || a > 999) {
      setState(() => _error =
          'Please enter a positive number up to 3 digits (1 to 999) for the first number.');
      return;
    }
    if (b == null || b <= 0 || b > 999) {
      setState(() => _error =
          'Please enter a positive number up to 3 digits (1 to 999) for the second number.');
      return;
    }

    widget.onApply(a, b);
    Navigator.of(context).pop();
  }

  void _setPreset(int a, int b) {
    setState(() {
      _ctrlA.text = '$a';
      _ctrlB.text = '$b';
      _error = null;
    });
  }

  void _randomize(int digitsA, int digitsB) {
    final rng = Random();
    int gen(int d) {
      if (d == 1) return 2 + rng.nextInt(8);
      if (d == 2) return 11 + rng.nextInt(88);
      return 101 + rng.nextInt(898);
    }

    _setPreset(gen(digitsA), gen(digitsB));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Multiplication Numbers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Up to 3-digit multiplication combinations',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Number Inputs
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First Number (A)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _ctrlA,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'e.g. 23',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 24, 10, 0),
                  child: Text(
                    '×',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Second Number (B)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _ctrlB,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'e.g. 42',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryColor, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Quick Presets: 2x2
            const Text(
              '2-Digit × 2-Digit Presets:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _PresetBtn(label: '23 × 42', onTap: () => _setPreset(23, 42)),
                _PresetBtn(label: '31 × 24', onTap: () => _setPreset(31, 24)),
                _PresetBtn(label: '47 × 36', onTap: () => _setPreset(47, 36)),
                _PresetBtn(label: '84 × 23', onTap: () => _setPreset(84, 23)),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Presets: 3x2
            const Text(
              '3-Digit × 2-Digit Presets:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _PresetBtn(label: '312 × 42', onTap: () => _setPreset(312, 42)),
                _PresetBtn(label: '214 × 32', onTap: () => _setPreset(214, 32)),
                _PresetBtn(label: '425 × 38', onTap: () => _setPreset(425, 38)),
                _PresetBtn(label: '624 × 57', onTap: () => _setPreset(624, 57)),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Presets: 3x3
            const Text(
              '3-Digit × 3-Digit Presets:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _PresetBtn(
                    label: '123 × 321', onTap: () => _setPreset(123, 321)),
                _PresetBtn(
                    label: '231 × 214', onTap: () => _setPreset(231, 214)),
                _PresetBtn(
                    label: '342 × 256', onTap: () => _setPreset(342, 256)),
                _PresetBtn(
                    label: '512 × 438', onTap: () => _setPreset(512, 438)),
              ],
            ),
            const SizedBox(height: 14),

            // Random Generator Chips
            Row(
              children: [
                _RandomChip(
                  label: 'Random 2×2',
                  onTap: () => _randomize(2, 2),
                ),
                const SizedBox(width: 8),
                _RandomChip(
                  label: 'Random 3×2',
                  onTap: () => _randomize(3, 2),
                ),
                const SizedBox(width: 8),
                _RandomChip(
                  label: 'Random 3×3',
                  onTap: () => _randomize(3, 3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                onPressed: _apply,
                child: const Text(
                  'Apply Numbers to Diagram',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

class _PresetBtn extends StatelessWidget {
  const _PresetBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryColor,
      ),
      backgroundColor: AppTheme.primaryTint,
      side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      onPressed: onTap,
    );
  }
}

class _RandomChip extends StatelessWidget {
  const _RandomChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.casino_outlined, size: 14),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: const BorderSide(color: AppTheme.borderLight),
          padding: const EdgeInsets.symmetric(vertical: 8),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
