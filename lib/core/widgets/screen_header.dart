import 'package:flutter/material.dart';

/// An attractive, consistent screen header drawn with soft gradients,
/// decorative math geometry, title, optional subtitle, and actions.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? badge;
  final Widget? bottom;
  final LinearGradient? gradient;
  final double bottomRadius;
  final EdgeInsetsGeometry padding;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.badge,
    this.bottom,
    this.gradient,
    this.bottomRadius = 24.0,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final activeGradient = gradient ??
        const LinearGradient(
          colors: [
            Color(0xFF4338CA), // Indigo 700
            Color(0xFF4F46E5), // Indigo 600
            Color(0xFF6366F1), // Indigo 500
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: activeGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _HeaderGeometryPainter(),
        child: Padding(
          padding: EdgeInsets.only(
            top: topPadding + 8,
            left: (padding as EdgeInsets).left,
            right: (padding as EdgeInsets).right,
            bottom: (padding as EdgeInsets).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Row (Back button / Title / Actions / Badge)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.86),
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    badge!,
                  ],
                  if (actions != null) ...[
                    const SizedBox(width: 8),
                    ...actions!,
                  ],
                ],
              ),
              if (bottom != null) ...[
                const SizedBox(height: 14),
                bottom!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular glass-styled header action button (e.g. for info, settings, back)
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Subtle lightweight decorative math geometry painter for header background
class _HeaderGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Soft circles in corners
    canvas.drawCircle(Offset(size.width * 0.9, -10), 65, paint);
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.7), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 1.1), 50, paint);

    // Subtle decorative stroke arc
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.85, 20), radius: 55),
      0,
      3.14,
      false,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
