import 'package:flutter/material.dart';

/// Renders math question text with proper visual formatting across all topics.
///
/// Features:
/// - Stacked fractions (e.g. "3/8 of 640") are drawn with a horizontal fraction bar,
///   never relying on missing font glyphs or awkward slash text.
/// - Exponents, squares, and cubes are drawn with a raised power ([WidgetSpan]),
///   both as standalone expressions ("17²", "2^5") and inside expressions ("23² − 144 ÷ 12 + 7 × 9").
/// - Square roots and cube roots are drawn with a [CustomPainter] radical symbol
///   (check mark hook and overbar, with a small index 3 for cube roots).
/// - Long questions wrap onto multiple lines and remain fully readable at 360px width
///   and 1.3x text scale in both light and dark themes.
/// - Standard operations (+, −, ×, ÷), brackets, %, and ? use verified Poppins font glyphs.
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

    // 3. Expressions containing fractions, powers, or standard text
    final spans = _buildExpressionSpans(trimmed, effectiveStyle);

    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: spans,
      ),
      textAlign: textAlign,
      softWrap: true,
    );
  }

  static List<InlineSpan> _buildExpressionSpans(String text, TextStyle style) {
    // Matches:
    // 1. Fractions: e.g. "3/8" (digits touching slash)
    // 2. Caret exponents: e.g. "23^2" or "2^5"
    // 3. Superscript exponents: e.g. "23²" or "14³"
    final regex = RegExp(r'(\d+/\d+)|(\d+\^\d+)|(\d+[²³])');
    final matches = regex.allMatches(text).toList();

    if (matches.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }

      final matchStr = match.group(0)!;

      if (match.group(1) != null) {
        // Stacked fraction
        final parts = matchStr.split('/');
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _StackedFractionWidget(
              numerator: parts[0],
              denominator: parts[1],
              style: style,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // Caret exponent (base^power)
        final parts = matchStr.split('^');
        spans.addAll(_createPowerSpan(parts[0], parts[1], style));
      } else if (match.group(3) != null) {
        // Superscript exponent (base² or base³)
        final base = matchStr.substring(0, matchStr.length - 1);
        final power = matchStr.endsWith('²') ? '2' : '3';
        spans.addAll(_createPowerSpan(base, power, style));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return spans;
  }

  static List<InlineSpan> _createPowerSpan(
    String base,
    String power,
    TextStyle style,
  ) {
    final baseFontSize = style.fontSize ?? 24.0;
    final expFontSize = (baseFontSize * 0.58).clamp(9.0, 36.0);
    final liftOffset = -baseFontSize * 0.38;

    return [
      TextSpan(text: base, style: style),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Transform.translate(
          offset: Offset(0, liftOffset),
          child: Text(
            power,
            style: style.copyWith(
              fontSize: expFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ];
  }
}

/// Convenience alias for [QuestionTextWidget].
typedef QuestionDisplayWidget = QuestionTextWidget;

/// Draws a stacked mathematical fraction (numerator over denominator with a bar).
class _StackedFractionWidget extends StatelessWidget {
  final String numerator;
  final String denominator;
  final TextStyle style;

  const _StackedFractionWidget({
    required this.numerator,
    required this.denominator,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.onSurface;
    final resolvedColor = style.color ?? themeColor;
    final baseFontSize = style.fontSize ?? 24.0;
    final fracFontSize = (baseFontSize * 0.52).clamp(9.0, 32.0);
    final barThickness = (baseFontSize * 0.07).clamp(1.2, 2.5);

    final fracStyle = style.copyWith(
      fontSize: fracFontSize,
      fontWeight: FontWeight.bold,
      color: resolvedColor,
      height: 1.05,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                numerator,
                style: fracStyle,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2.0),
              height: barThickness,
              decoration: BoxDecoration(
                color: resolvedColor,
                borderRadius: BorderRadius.circular(barThickness / 2),
              ),
            ),
            Center(
              child: Text(
                denominator,
                style: fracStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
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
