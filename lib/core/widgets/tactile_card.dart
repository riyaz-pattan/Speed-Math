import 'package:flutter/material.dart';
import 'package:speed_math_with_ai/app/theme.dart';

/// Clean modern card with soft shadow, crisp border, and subtle tactile press feedback.
class TactileCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const TactileCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 20.0, // AppTheme.radiusLg
  });

  @override
  State<TactileCard> createState() => _TactileCardState();
}

class _TactileCardState extends State<TactileCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cardContent = AnimatedScale(
      scale: (_isPressed && widget.onTap != null) ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.borderColor ?? AppTheme.borderLight,
            width: 1.2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: AppTheme.primaryTint.withValues(alpha: 0.6),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: cardContent,
    );
  }
}
