import 'package:flutter/material.dart';

/// Renders math question text with proper visual formatting across all topics.
///
/// Features:
/// - Exponents, squares, and cubes are drawn with a raised power ([WidgetSpan]),
///   never relying on unicode superscripts that may be absent from bundled fonts.
/// - Square roots and cube roots are drawn with a [CustomPainter] radical symbol
///   (check mark hook and overbar, with a small index 3 for cube roots),
///   never relying on font glyphs (such as '∛' or '√') that draw empty boxes on Android.
/// - Standard operations (+, −, ×, ÷) use verified Poppins font glyphs.
class QuestionTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const QuestionTextWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final themeColor = Theme.of(context).colorScheme.onSurface;
    final resolvedColor = style?.color ?? defaultStyle.color ?? themeColor;
    final effectiveStyle = defaultStyle.merge(style).copyWith(color: resolvedColor);
    final trimmed = text.trim();

    // 1. Cube roots: starts with '∛' or '³√' or '3√'
    if (trimmed.startsWith('∛') || trimmed.startsWith('³√') || trimmed.startsWith('3√')) {
      final radicand = trimmed.replaceFirst(RegExp(r'^(∛|³√|3√)\s*'), '');
      return _RadicalTextWidget(
        radicand: radicand,
        isCubeRoot: true,
        style: effectiveStyle,
      );
    }

    // 2. Square roots: starts with '√'
    if (trimmed.startsWith('√')) {
      final radicand = trimmed.substring(1).trim();
      return _RadicalTextWidget(
        radicand: radicand,
        isCubeRoot: false,
        style: effectiveStyle,
      );
    }

    // 3. Exponents written as 'base^power'
    if (trimmed.contains('^')) {
      final parts = trimmed.split('^');
      if (parts.length == 2) {
        return _PowerTextWidget(
          base: parts[0].trim(),
          power: parts[1].trim(),
          style: effectiveStyle,
          textAlign: textAlign,
        );
      }
    }

    // 4. Squaring written with superscript '²'
    if (trimmed.endsWith('²')) {
      final base = trimmed.substring(0, trimmed.length - 1).trim();
      return _PowerTextWidget(
        base: base,
        power: '2',
        style: effectiveStyle,
        textAlign: textAlign,
      );
    }

    // 5. Cubing written with superscript '³'
    if (trimmed.endsWith('³')) {
      final base = trimmed.substring(0, trimmed.length - 1).trim();
      return _PowerTextWidget(
        base: base,
        power: '3',
        style: effectiveStyle,
        textAlign: textAlign,
      );
    }

    // 6. Standard expressions (addition, subtraction, multiplication, division)
    return Text(
      trimmed,
      style: effectiveStyle,
      textAlign: textAlign,
    );
  }
}

/// Convenience alias for [QuestionTextWidget].
typedef QuestionDisplayWidget = QuestionTextWidget;

/// Draws base with raised power text without unicode superscripts.
class _PowerTextWidget extends StatelessWidget {
  final String base;
  final String power;
  final TextStyle style;
  final TextAlign textAlign;

  const _PowerTextWidget({
    required this.base,
    required this.power,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.onSurface;
    final resolvedColor = style.color ?? themeColor;
    final resolvedStyle = style.copyWith(color: resolvedColor);
    final baseFontSize = resolvedStyle.fontSize ?? 24.0;
    final expFontSize = (baseFontSize * 0.58).clamp(9.0, 48.0);
    final liftOffset = -baseFontSize * 0.38;

    return Text.rich(
      TextSpan(
        style: resolvedStyle,
        children: [
          TextSpan(
            text: base,
            style: resolvedStyle,
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Transform.translate(
              offset: Offset(0, liftOffset),
              child: Text(
                power,
                style: resolvedStyle.copyWith(
                  fontSize: expFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}

/// Draws radical sign with [CustomPainter] and wraps radicand in padding.
class _RadicalTextWidget extends StatelessWidget {
  final String radicand;
  final bool isCubeRoot;
  final TextStyle style;

  const _RadicalTextWidget({
    required this.radicand,
    required this.isCubeRoot,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 24.0;
    final strokeColor = style.color ?? Theme.of(context).colorScheme.onSurface;

    final strokeWidth = (fontSize * 0.08).clamp(1.5, 3.5);
    final tickWidth = (fontSize * 0.45).clamp(10.0, 26.0);
    final topPadding = (fontSize * 0.16).clamp(3.0, 10.0);

    return CustomPaint(
      painter: _RadicalPainter(
        color: strokeColor,
        strokeWidth: strokeWidth,
        tickWidth: tickWidth,
        topPadding: topPadding,
        isCubeRoot: isCubeRoot,
        fontSize: fontSize,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: tickWidth + fontSize * 0.08,
          top: topPadding + strokeWidth * 0.8,
          right: fontSize * 0.1,
          bottom: 2,
        ),
        child: Text(
          radicand,
          style: style,
        ),
      ),
    );
  }
}

class _RadicalPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double tickWidth;
  final double topPadding;
  final bool isCubeRoot;
  final double fontSize;

  _RadicalPainter({
    required this.color,
    required this.strokeWidth,
    required this.tickWidth,
    required this.topPadding,
    required this.isCubeRoot,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // 1. Opening hook on left
    final startY = size.height * 0.58;
    final hookX = tickWidth * 0.28;
    final hookY = size.height * 0.52;
    path.moveTo(0, startY);
    path.lineTo(hookX, hookY);

    // 2. Down to bottom notch
    final bottomX = tickWidth * 0.55;
    final bottomY = size.height - (strokeWidth / 2);
    path.lineTo(bottomX, bottomY);

    // 3. Up to top bar
    final topX = tickWidth;
    final topY = topPadding;
    path.lineTo(topX, topY);

    // 4. Overbar extending across the radicand text width
    final overbarEndX = size.width;
    path.lineTo(overbarEndX, topY);

    canvas.drawPath(path, paint);

    // If cube root, draw small index '3' inside the radical notch
    if (isCubeRoot) {
      final indexFontSize = (fontSize * 0.38).clamp(8.0, 18.0);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '3',
          style: TextStyle(
            color: color,
            fontSize: indexFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final indexOffsetY = (topPadding - indexFontSize * 0.5).clamp(0.0, topPadding);
      textPainter.paint(canvas, Offset(0, indexOffsetY));
    }
  }

  @override
  bool shouldRepaint(covariant _RadicalPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.tickWidth != tickWidth ||
      oldDelegate.isCubeRoot != isCubeRoot ||
      oldDelegate.fontSize != fontSize;
}
