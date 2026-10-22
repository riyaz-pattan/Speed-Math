import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/enums/enums.dart';
import '../../../core/services/haptic_service.dart';

/// Actions supported by individual keypad keys.
enum KeyAction {
  digit,
  backspace,
  submit,
  empty,
  minus, // Available for future topic extensions
}

/// Data definition for an individual keypad key.
class KeypadKeyData {
  final KeyAction action;
  final String? digit;

  const KeypadKeyData.digit(String d)
      : action = KeyAction.digit,
        digit = d;

  const KeypadKeyData.backspace()
      : action = KeyAction.backspace,
        digit = null;

  const KeypadKeyData.submit()
      : action = KeyAction.submit,
        digit = null;

  const KeypadKeyData.empty()
      : action = KeyAction.empty,
        digit = null;

  const KeypadKeyData.minus()
      : action = KeyAction.minus,
        digit = null;
}

/// Returns the 4x3 layout grid for the requested keypad style and submit mode.
List<List<KeypadKeyData>> getKeypadLayout({
  required KeypadStyle style,
  required bool showSubmit,
}) {
  final List<List<KeypadKeyData>> digitRows;
  switch (style) {
    case KeypadStyle.phone:
      digitRows = [
        [
          const KeypadKeyData.digit('1'),
          const KeypadKeyData.digit('2'),
          const KeypadKeyData.digit('3'),
        ],
        [
          const KeypadKeyData.digit('4'),
          const KeypadKeyData.digit('5'),
          const KeypadKeyData.digit('6'),
        ],
        [
          const KeypadKeyData.digit('7'),
          const KeypadKeyData.digit('8'),
          const KeypadKeyData.digit('9'),
        ],
      ];
      break;
    case KeypadStyle.calculator:
      digitRows = [
        [
          const KeypadKeyData.digit('7'),
          const KeypadKeyData.digit('8'),
          const KeypadKeyData.digit('9'),
        ],
        [
          const KeypadKeyData.digit('4'),
          const KeypadKeyData.digit('5'),
          const KeypadKeyData.digit('6'),
        ],
        [
          const KeypadKeyData.digit('1'),
          const KeypadKeyData.digit('2'),
          const KeypadKeyData.digit('3'),
        ],
      ];
      break;
  }

  final bottomRow = [
    const KeypadKeyData.backspace(),
    const KeypadKeyData.digit('0'),
    showSubmit ? const KeypadKeyData.submit() : const KeypadKeyData.empty(),
  ];

  return [...digitRows, bottomRow];
}

/// Custom in-app number keypad for fast mental math input.
///
/// Large, thumb-friendly keys that never trigger the device system keyboard.
class MathKeypad extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onSubmitPressed;
  final VoidCallback? onMinusPressed;
  final KeypadStyle style;
  final bool showSubmit;
  final bool hapticsEnabled;
  final VibrationStrength vibrationStrength;
  final HapticService? hapticService;
  final bool soundEnabled;

  const MathKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onSubmitPressed,
    this.onMinusPressed,
    this.style = KeypadStyle.phone,
    this.showSubmit = false,
    this.hapticsEnabled = true,
    this.vibrationStrength = VibrationStrength.medium,
    this.hapticService,
    this.soundEnabled = false,
  });

  void _tap(VoidCallback action) {
    if (hapticsEnabled) {
      if (hapticService != null) {
        hapticService!.keyPress(strength: vibrationStrength);
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    action();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final layout = getKeypadLayout(style: style, showSubmit: showSubmit);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: layout.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: _buildKeyWidget(key, colorScheme),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyWidget(KeypadKeyData key, ColorScheme colorScheme) {
    switch (key.action) {
      case KeyAction.digit:
        return _KeyButton(
          onTap: () => _tap(() => onDigitPressed(key.digit!)),
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          foregroundColor: colorScheme.onSurface,
          child: Text(
            key.digit!,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case KeyAction.backspace:
        return _KeyButton(
          onTap: () => _tap(onBackspacePressed),
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          foregroundColor: colorScheme.onSurfaceVariant,
          child: const Icon(Icons.backspace_outlined, size: 24),
        );

      case KeyAction.submit:
        return _KeyButton(
          onTap: () => _tap(onSubmitPressed),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, size: 20),
              SizedBox(width: 4),
              Text(
                'GO',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );

      case KeyAction.minus:
        return _KeyButton(
          onTap: () => _tap(() => onMinusPressed?.call()),
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          foregroundColor: colorScheme.onSurfaceVariant,
          child: const Text('−', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        );

      case KeyAction.empty:
        return const SizedBox(height: 56);
    }
  }
}

class _KeyButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;

  const _KeyButton({
    required this.onTap,
    required this.child,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: foregroundColor.withValues(alpha: 0.15),
          highlightColor: foregroundColor.withValues(alpha: 0.08),
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(color: foregroundColor),
              child: IconTheme(
                data: IconThemeData(color: foregroundColor),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact live preview widget for keypad style selection in Settings.
class KeypadPreviewWidget extends StatelessWidget {
  final KeypadStyle style;
  final bool isSelected;

  const KeypadPreviewWidget({
    super.key,
    required this.style,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final layout = getKeypadLayout(style: style, showSubmit: false);

    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            style.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...layout.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  return Container(
                    width: 28,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    decoration: BoxDecoration(
                      color: key.action == KeyAction.empty
                          ? Colors.transparent
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: key.action == KeyAction.digit
                          ? Text(
                              key.digit!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            )
                          : key.action == KeyAction.backspace
                              ? Icon(
                                  Icons.backspace_outlined,
                                  size: 10,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : null,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
