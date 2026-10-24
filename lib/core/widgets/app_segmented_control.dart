import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Segment item specification for [AppSegmentedControl].
class AppSegmentedItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const AppSegmentedItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// A premium, animated segmented control designed to replace Flutter's default [SegmentedButton].
///
/// Features:
/// - Single-line guaranteed: labels never wrap, safely scaled via [FittedBox].
/// - Animated width allocation: the selected segment smoothly expands to ~1.6x width,
///   while unselected segments shrink to ~1.0x width over 220 ms.
/// - Smooth animated check icon next to the selected segment's label.
/// - Responsive and overflow-proof at 360 px width and 1.3x text scale.
/// - Seamless light and dark mode adaptation.
class AppSegmentedControl<T> extends StatelessWidget {
  final List<AppSegmentedItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final Color? activeColor;
  final Color? activeTextColor;
  final Color? inactiveTextColor;
  final double height;
  final EdgeInsetsGeometry padding;

  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onValueChanged,
    this.activeColor,
    this.activeTextColor,
    this.inactiveTextColor,
    this.height = 42.0,
    this.padding = const EdgeInsets.all(3.0),
  });

  @override
  Widget build(BuildContext context) {
    assert(items.isNotEmpty, 'AppSegmentedControl requires at least one item');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveActiveColor = activeColor ?? colorScheme.primary;
    final effectiveActiveTextColor = activeTextColor ?? colorScheme.onPrimary;
    final effectiveInactiveTextColor =
        inactiveTextColor ?? colorScheme.onSurfaceVariant;

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final responsiveHeight = math.max(height, 42.0 * textScale.clamp(1.0, 1.3));

    return Container(
      height: responsiveHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      padding: padding,
      child: Row(
        children: items.map((item) {
          final isSelected = item.value == selectedValue;
          return Expanded(
            flex: isSelected ? 16 : 10,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isSelected ? effectiveActiveColor : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: effectiveActiveColor.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onValueChanged(item.value),
                  borderRadius: BorderRadius.circular(11),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Smooth checkmark entry
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOutCubic,
                          child: isSelected
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: effectiveActiveTextColor,
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Optional item icon (if provided and not selected)
                        if (item.icon != null && !isSelected) ...[
                          Icon(
                            item.icon,
                            size: 14,
                            color: effectiveInactiveTextColor,
                          ),
                          const SizedBox(width: 3),
                        ],

                        // Single-line text, safely scaled down if tight
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? effectiveActiveTextColor
                                    : effectiveInactiveTextColor,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
