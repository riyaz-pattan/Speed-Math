// lib/features/learn/widgets/subtraction_custom_number_sheet.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Modal bottom sheet allowing users to select preset numbers or enter ANY
/// custom numbers for the Subtraction shortcut.
class SubtractionCustomNumberSheet extends StatefulWidget {
  const SubtractionCustomNumberSheet({
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
      builder: (ctx) => SubtractionCustomNumberSheet(
        currentA: currentA,
        currentB: currentB,
        onApply: onApply,
      ),
    );
  }

  @override
  State<SubtractionCustomNumberSheet> createState() =>
      _SubtractionCustomNumberSheetState();
}

class _SubtractionCustomNumberSheetState
    extends State<SubtractionCustomNumberSheet> {
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

    if (a == null || a <= 0 || a > 99999) {
      setState(() => _error = 'Please enter a positive number up to 5 digits for the first number.');
      return;
    }
    if (b == null || b <= 0 || b > 99999) {
      setState(() => _error = 'Please enter a positive number up to 5 digits for the second number.');
      return;
    }
    if (b > a) {
      setState(() => _error = 'For subtraction, the first number should be larger than or equal to the second number.');
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

  void _randomize(int digits) {
    final rng = Random();
    int a, b;
    if (digits == 2) {
      a = 40 + rng.nextInt(59);
      b = 11 + rng.nextInt(a - 15);
    } else if (digits == 3) {
      a = 250 + rng.nextInt(740);
      b = 100 + rng.nextInt(a - 110);
    } else {
      a = 1500 + rng.nextInt(8400);
      b = 300 + rng.nextInt(a - 350);
    }
    _setPreset(a, b);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Choose Numbers for Subtraction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter any 2-digit, 3-digit, 4-digit, or 5-digit numbers. The app shows how to subtract left-to-right without borrowing.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Presets row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('85 − 42 (2-digit easy)'),
                onPressed: () => _setPreset(85, 42),
                backgroundColor: AppTheme.primaryTint,
                labelStyle: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              ActionChip(
                label: const Text('83 − 47 (2-digit borrow)'),
                onPressed: () => _setPreset(83, 47),
                backgroundColor: AppTheme.primaryTint,
                labelStyle: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              ActionChip(
                label: const Text('342 − 156 (3-digit)'),
                onPressed: () => _setPreset(342, 156),
                backgroundColor: AppTheme.primaryTint,
                labelStyle: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              ActionChip(
                label: const Text('624 − 278 (3-digit heavy)'),
                onPressed: () => _setPreset(624, 278),
                backgroundColor: AppTheme.primaryTint,
                labelStyle: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              ActionChip(
                label: const Text('1250 − 480 (4-digit)'),
                onPressed: () => _setPreset(1250, 480),
                backgroundColor: AppTheme.primaryTint,
                labelStyle: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.shuffle_rounded, size: 14),
                label: const Text('Random'),
                onPressed: () => _randomize(2),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Inputs: A − B
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrlA,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'First Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '−',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _ctrlB,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Second Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              onPressed: _apply,
              icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Show Shortcut Diagram',
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
    );
  }
}
