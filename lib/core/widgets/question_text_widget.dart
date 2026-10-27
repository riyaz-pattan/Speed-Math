import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/question_font_constants.dart';

/// Renders math question text with proper visual formatting, responsive font sizing,
/// and measured line-fitting across all topics without throwing layout exceptions.
class QuestionTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  /// Global tracking for the Question Gallery diagnostic screen.
  static bool trackFallbacks = false;
  static final Set<String> fallbackQuestions = <String>{};

  const QuestionTextWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
  });

  /// Determines whether [text] is a word problem sentence or a math expression.
  static bool isSentence(String text) {
    // Math expressions and equations may contain single-variable letters (e.g., x, y, z)
    // combined with coefficients, exponents, and operators.
    // Replace non-alpha characters with spaces, then inspect whole words.
    final wordsOnly = text.replaceAll(RegExp(r'[^a-zA-Z\s]'), ' ');
    final words = wordsOnly.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    for (final word in words) {
      final lower = word.toLowerCase();
      // Ignore common math abbreviations, labels, or short particles
      if (['of', 'approx', 'ans', 'find', 'sum', 'i', 'ii', 'iii', 'iv', 'v'].contains(lower)) {
        continue;
      }
      if (lower.length >= 2) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final themeColor = Theme.of(context).colorScheme.onSurface;
    final resolvedColor = style?.color ?? defaultStyle.color ?? themeColor;
    final effectiveStyle = defaultStyle.merge(style).copyWith(color: resolvedColor);
    final trimmed = text.trim();

    try {
      // 1. Explicit font size specified (e.g. compact review list or history row)
      if (style?.fontSize != null) {
        if (trimmed.contains('\n')) {
          final lines = trimmed.split('\n');
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _buildTokenRow(
                    _parseTokens(lines[i].trim()),
                    effectiveStyle,
                    style!.fontSize!,
                    textAlign,
                  ),
                ),
              ],
            ],
          );
        }
        final tokens = _parseTokens(trimmed);
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildTokenRow(tokens, effectiveStyle, style!.fontSize!, textAlign),
        );
      }

      // 2. Dynamic measured layout
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width - 24;

          if (trimmed.contains('\n')) {
            return _buildMultiLineWidget(trimmed, effectiveStyle, maxWidth, textAlign);
          } else if (isSentence(trimmed)) {
            return _buildSentenceWidget(trimmed, effectiveStyle, maxWidth, textAlign);
          } else {
            return _buildExpressionWidget(trimmed, effectiveStyle, maxWidth, textAlign);
          }
        },
      );
    } catch (e, stack) {
      debugPrint('QuestionTextWidget fallback used for "$text": $e\n$stack');
      if (trackFallbacks) {
        fallbackQuestions.add(trimmed);
      }
      return _buildFallback(trimmed, effectiveStyle);
    }
  }

  Widget _buildMultiLineWidget(
    String text,
    TextStyle style,
    double maxWidth,
    TextAlign align,
  ) {
    final lines = text.split('\n');
    double bestSize = 26.0;

    for (double size = 26.0; size >= 18.0; size -= 1.0) {
      bool allFit = true;
      for (final line in lines) {
        final tokens = _parseTokens(line.trim());
        if (_measureTokensWidth(tokens, style, size) > maxWidth) {
          allFit = false;
          break;
        }
      }
      if (allFit) {
        bestSize = size;
        break;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildTokenRow(_parseTokens(lines[i].trim()), style, bestSize, align),
          ),
        ],
      ],
    );
  }

  Widget _buildExpressionWidget(
    String text,
    TextStyle style,
    double maxWidth,
    TextAlign align,
  ) {
    final tokens = _parseTokens(text);

    // Step A: Try single line fit from 54sp down to 30sp
    double oneLineSize = QuestionFontConstants.expressionPreferredSize;
    bool fitsOnOneLine = false;

    for (double size = QuestionFontConstants.expressionPreferredSize;
        size >= QuestionFontConstants.expressionOneLineMinSize;
        size -= 2.0) {
      final width = _measureTokensWidth(tokens, style, size);
      if (width <= maxWidth) {
        oneLineSize = size;
        fitsOnOneLine = true;
        break;
      }
    }

    if (fitsOnOneLine) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: _buildTokenRow(tokens, style, oneLineSize, align),
      );
    }

    // Step B: Break into 2 balanced lines at top-level operator or comma
    final breakPair = _findBestBreakPoint(text);
    if (breakPair == null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: _buildTokenRow(
          tokens,
          style,
          QuestionFontConstants.expressionOneLineMinSize,
          align,
        ),
      );
    }

    final (line1, line2) = breakPair;
    final tokens1 = _parseTokens(line1);
    final tokens2 = _parseTokens(line2);

    double twoLinesSize = QuestionFontConstants.expressionTwoLinesMinSize;

    for (double size = QuestionFontConstants.expressionTwoLinesMaxSize;
        size >= QuestionFontConstants.expressionTwoLinesMinSize;
        size -= 1.0) {
      final w1 = _measureTokensWidth(tokens1, style, size);
      final w2 = _measureTokensWidth(tokens2, style, size);

      if (w1 <= maxWidth && w2 <= maxWidth) {
        twoLinesSize = size;
        break;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildTokenRow(tokens1, style, twoLinesSize, align),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildTokenRow(tokens2, style, twoLinesSize, align),
        ),
      ],
    );
  }

  Widget _buildSentenceWidget(
    String text,
    TextStyle style,
    double maxWidth,
    TextAlign align,
  ) {
    double sentenceSize = QuestionFontConstants.sentenceMinSize;
    final plainText = text.replaceAll('²', '^2').replaceAll('³', '^3');

    for (double size = QuestionFontConstants.sentenceMaxSize;
        size >= QuestionFontConstants.sentenceMinSize;
        size -= 1.0) {
      final painter = TextPainter(
        text: TextSpan(
          text: plainText,
          style: style.copyWith(fontSize: size),
        ),
        textDirection: TextDirection.ltr,
        maxLines: QuestionFontConstants.sentenceMaxLines,
      )..layout(maxWidth: maxWidth);

      if (!painter.didExceedMaxLines) {
        sentenceSize = size;
        break;
      }
    }

    final tokens = _parseTokens(text);
    return Text.rich(
      TextSpan(
        style: style.copyWith(fontSize: sentenceSize),
        children: tokens.map((t) => t.buildSpan(style, sentenceSize)).toList(),
      ),
      textAlign: align,
      maxLines: QuestionFontConstants.sentenceMaxLines,
      softWrap: true,
    );
  }

  Widget _buildFallback(String rawText, TextStyle style) {
    final clean = rawText
        .replaceAll('²', '^2')
        .replaceAll('³', '^3')
        .replaceAll('∛', 'cbrt(')
        .replaceAll('³√', 'cbrt(')
        .replaceAll('√', 'sqrt(');
    final safeText = clean.contains('(') && !clean.contains(')') ? '$clean)' : clean;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        safeText,
        style: style.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        textAlign: textAlign,
      ),
    );
  }

  static double _measureTokensWidth(
    List<_Token> tokens,
    TextStyle style,
    double fontSize,
  ) {
    double total = 0.0;
    for (final t in tokens) {
      total += t.measureWidth(style, fontSize);
    }
    return total;
  }

  static Widget _buildTokenRow(
    List<_Token> tokens,
    TextStyle style,
    double fontSize,
    TextAlign align,
  ) {
    final widgets = tokens.map((t) => t.buildWidget(style, fontSize)).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: widgets,
    );
  }

  static (String, String)? _findBestBreakPoint(String text) {
    if (text.length <= 12) return null;

    final candidates = <int>[];
    int bracketDepth = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '(') {
        bracketDepth++;
      } else if (char == ')') {
        bracketDepth = max(0, bracketDepth - 1);
      } else if (bracketDepth == 0) {
        if (char == ',') {
          candidates.add(i);
        } else if (char == '+' ||
            char == '−' ||
            char == '-' ||
            char == '×' ||
            char == '*' ||
            char == '÷' ||
            char == '≈' ||
            char == '=') {
          if (i > 0 && i < text.length - 1) {
            candidates.add(i);
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    final middle = text.length / 2.0;
    candidates.sort((a, b) => (a - middle).abs().compareTo((b - middle).abs()));
    final bestIndex = candidates.first;
    final char = text[bestIndex];

    if (char == ',') {
      return (text.substring(0, bestIndex + 1).trim(), text.substring(bestIndex + 1).trim());
    } else {
      return (text.substring(0, bestIndex).trim(), text.substring(bestIndex).trim());
    }
  }

  static List<_Token> _parseTokens(String text) {
    final regex = RegExp(
      r'((?<=\b|\()(\d+)[_\s](\d+/\d+))|(\d+/\d+)|(\d+\^\d+)|(\d+[²³])|(³√\d+|∛\d+|√\d+)',
    );
    final matches = regex.allMatches(text).toList();
    if (matches.isEmpty) {
      return [_TextToken(text)];
    }

    final tokens = <_Token>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        tokens.add(_TextToken(text.substring(lastEnd, match.start)));
      }

      if (match.group(1) != null) {
        // Mixed fraction
        final whole = match.group(2)!;
        final fracParts = match.group(3)!.split('/');
        tokens.add(_FractionToken(
          whole: whole,
          numerator: fracParts[0],
          denominator: fracParts[1],
        ));
      } else if (match.group(4) != null) {
        // Standard fraction
        final fracParts = match.group(4)!.split('/');
        tokens.add(_FractionToken(
          numerator: fracParts[0],
          denominator: fracParts[1],
        ));
      } else if (match.group(5) != null) {
        // Caret exponent
        final parts = match.group(5)!.split('^');
        tokens.add(_PowerToken(parts[0], parts[1]));
      } else if (match.group(6) != null) {
        // Superscript exponent
        final str = match.group(6)!;
        final base = str.substring(0, str.length - 1);
        final power = str.endsWith('²') ? '2' : '3';
        tokens.add(_PowerToken(base, power));
      } else if (match.group(7) != null) {
        // Radical
        final str = match.group(7)!;
        final isCube = str.startsWith('³√') || str.startsWith('∛');
        final rad = str.replaceFirst(RegExp(r'^(³√|∛|√)'), '');
        tokens.add(_RadicalToken(radicand: rad, isCubeRoot: isCube));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      tokens.add(_TextToken(text.substring(lastEnd)));
    }

    return tokens;
  }
}

/// Base token interface for measured text layout.
sealed class _Token {
  double measureWidth(TextStyle baseStyle, double fontSize);
  Widget buildWidget(TextStyle baseStyle, double fontSize);
  InlineSpan buildSpan(TextStyle baseStyle, double fontSize);
}

class _TextToken extends _Token {
  final String text;
  _TextToken(this.text);

  @override
  double measureWidth(TextStyle baseStyle, double fontSize) {
    if (text.isEmpty) return 0.0;
    final tp = TextPainter(
      text: TextSpan(text: text, style: baseStyle.copyWith(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tp.width;
  }

  @override
  Widget buildWidget(TextStyle baseStyle, double fontSize) {
    return Text(
      text,
      style: baseStyle.copyWith(fontSize: fontSize),
    );
  }

  @override
  InlineSpan buildSpan(TextStyle baseStyle, double fontSize) {
    return TextSpan(
      text: text,
      style: baseStyle.copyWith(fontSize: fontSize),
    );
  }
}

class _PowerToken extends _Token {
  final String base;
  final String power;
  _PowerToken(this.base, this.power);

  @override
  double measureWidth(TextStyle baseStyle, double fontSize) {
    final expFontSize = (fontSize * 0.58).clamp(9.0, 36.0);
    final baseTp = TextPainter(
      text: TextSpan(text: base, style: baseStyle.copyWith(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final expTp = TextPainter(
      text: TextSpan(
        text: power,
        style: baseStyle.copyWith(fontSize: expFontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return baseTp.width + expTp.width + 1.0;
  }

  @override
  Widget buildWidget(TextStyle baseStyle, double fontSize) {
    final expFontSize = (fontSize * 0.58).clamp(9.0, 36.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          base,
          style: baseStyle.copyWith(fontSize: fontSize),
        ),
        Transform.translate(
          offset: Offset(1, -fontSize * 0.36),
          child: Text(
            power,
            style: baseStyle.copyWith(
              fontSize: expFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  InlineSpan buildSpan(TextStyle baseStyle, double fontSize) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: buildWidget(baseStyle, fontSize),
    );
  }
}

class _FractionToken extends _Token {
  final String? whole;
  final String numerator;
  final String denominator;

  _FractionToken({
    this.whole,
    required this.numerator,
    required this.denominator,
  });

  @override
  double measureWidth(TextStyle baseStyle, double fontSize) {
    final fracFontSize = (fontSize * 0.52).clamp(11.0, 32.0);
    final numTp = TextPainter(
      text: TextSpan(
        text: numerator,
        style: baseStyle.copyWith(fontSize: fracFontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final denTp = TextPainter(
      text: TextSpan(
        text: denominator,
        style: baseStyle.copyWith(fontSize: fracFontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final fracWidth = max(numTp.width, denTp.width) + 8.0;

    if (whole != null && whole!.isNotEmpty) {
      final wholeTp = TextPainter(
        text: TextSpan(text: whole, style: baseStyle.copyWith(fontSize: fontSize)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      return wholeTp.width + 4.0 + fracWidth;
    }

    return fracWidth;
  }

  @override
  Widget buildWidget(TextStyle baseStyle, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (whole != null && whole!.isNotEmpty) ...[
          Text(whole!, style: baseStyle.copyWith(fontSize: fontSize)),
          const SizedBox(width: 4),
        ],
        _StackedFractionWidget(
          numerator: numerator,
          denominator: denominator,
          style: baseStyle.copyWith(fontSize: fontSize),
        ),
      ],
    );
  }

  @override
  InlineSpan buildSpan(TextStyle baseStyle, double fontSize) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: buildWidget(baseStyle, fontSize),
    );
  }
}

class _RadicalToken extends _Token {
  final String radicand;
  final bool isCubeRoot;

  _RadicalToken({
    required this.radicand,
    required this.isCubeRoot,
  });

  @override
  double measureWidth(TextStyle baseStyle, double fontSize) {
    final tickWidth = (fontSize * 0.45).clamp(10.0, 26.0);
    final radTp = TextPainter(
      text: TextSpan(text: radicand, style: baseStyle.copyWith(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return tickWidth + (fontSize * 0.08) + radTp.width + (fontSize * 0.1);
  }

  @override
  Widget buildWidget(TextStyle baseStyle, double fontSize) {
    return _RadicalTextWidget(
      radicand: radicand,
      isCubeRoot: isCubeRoot,
      style: baseStyle.copyWith(fontSize: fontSize),
    );
  }

  @override
  InlineSpan buildSpan(TextStyle baseStyle, double fontSize) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: buildWidget(baseStyle, fontSize),
    );
  }
}

/// Draws a cleanly stacked fraction with a centered horizontal divider bar.
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
    final baseFontSize = style.fontSize ?? 24.0;
    final fracFontSize = (baseFontSize * 0.52).clamp(11.0, 32.0);
    final barThickness = (baseFontSize * 0.06).clamp(1.5, 3.0);
    final resolvedColor = style.color ?? const Color(0xFF0F172A);

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
    final strokeColor = style.color ?? const Color(0xFF0F172A);

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
          style: style.copyWith(fontSize: fontSize),
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
    final startY = size.height * 0.58;
    final hookX = tickWidth * 0.28;
    final hookY = size.height * 0.52;
    path.moveTo(0, startY);
    path.lineTo(hookX, hookY);

    final bottomX = tickWidth * 0.55;
    final bottomY = size.height - (strokeWidth / 2);
    path.lineTo(bottomX, bottomY);

    final topX = tickWidth;
    final topY = topPadding;
    path.lineTo(topX, topY);

    final overbarEndX = size.width;
    path.lineTo(overbarEndX, topY);

    canvas.drawPath(path, paint);

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
