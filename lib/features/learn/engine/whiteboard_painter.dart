// lib/features/learn/engine/whiteboard_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'lesson_data.dart';

/// CustomPainter that renders whiteboard lesson steps.
/// Past steps drawn at 45% opacity. Current step animated by [stepProgress].
/// All text via TextPainter — never WidgetSpan.
class WhiteboardPainter extends CustomPainter {
  WhiteboardPainter({
    required this.steps,
    required this.currentStepIndex,
    required this.stepProgress,
    this.disableAnimations = false,
  });

  final List<LessonStep> steps;
  final int currentStepIndex;
  final double stepProgress;
  final bool disableAnimations;

  static const double _logicalWidth = 360;
  static const Color _bgColor = Color(0xFFFFFBF0);
  static const Color _ruleColor = Color(0xFFFDE68A);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _logicalWidth;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _bgColor,
    );

    // Ruled lines every 32 logical units
    final rulePaint = Paint()
      ..color = _ruleColor
      ..strokeWidth = 1.0;
    final rulesCount = (size.height / (32 * scale)).ceil() + 2;
    for (int i = 1; i <= rulesCount; i++) {
      final y = i * 32 * scale;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }

    // Past steps at reduced opacity
    for (int i = 0; i < currentStepIndex && i < steps.length; i++) {
      _drawStep(canvas, size, scale, steps[i], 1.0, alpha: 0.4);
    }

    // Current step
    if (currentStepIndex < steps.length) {
      final progress = disableAnimations ? 1.0 : stepProgress;
      _drawStep(canvas, size, scale, steps[currentStepIndex], progress, alpha: 1.0);
    }
  }

  void _drawStep(Canvas canvas, Size size, double scale, LessonStep step,
      double progress, {required double alpha}) {
    for (final el in step.elements) {
      final localT = _localT(progress, el.startT, el.endT);
      if (localT <= 0) continue;
      try {
        _drawElement(canvas, size, scale, el, localT, alpha);
      } catch (e) {
        debugPrint('WhiteboardPainter: element error: $e');
      }
    }
  }

  double _localT(double progress, double startT, double endT) {
    if (endT <= startT) return progress >= startT ? 1.0 : 0.0;
    if (progress <= startT) return 0.0;
    if (progress >= endT) return 1.0;
    return (progress - startT) / (endT - startT);
  }

  void _drawElement(Canvas canvas, Size size, double scale, DrawElement el,
      double t, double alpha) {
    final x = el.x * scale;
    final y = el.y * scale;
    final color = el.color.withValues(alpha: el.color.a * alpha);

    switch (el.type) {
      case DrawElementType.writtenText:
        _drawText(canvas, size, scale, el, x, y, alpha, clip: t);
      case DrawElementType.staticText:
        _drawText(canvas, size, scale, el, x, y, alpha, clip: 1.0);
      case DrawElementType.underline:
      case DrawElementType.fractionBar:
        final paint = Paint()
          ..color = color
          ..strokeWidth = el.lineHeight * scale
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x, y), Offset(x + el.lineWidth * scale * t, y), paint);
      case DrawElementType.highlight:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y - el.highlightHeight * scale * 0.75,
                el.highlightWidth * scale, el.highlightHeight * scale),
            Radius.circular(6 * scale),
          ),
          Paint()..color = color.withValues(alpha: color.a * t * 0.22),
        );
      case DrawElementType.arrow:
        if (el.arrowEnd == null) return;
        _drawArrow(canvas, scale, el, x, y, color, t);
    }
  }

  void _drawText(Canvas canvas, Size size, double scale, DrawElement el,
      double x, double y, double alpha, {required double clip}) {
    final fontSize = el.fontSize * scale;
    final color = el.color.withValues(alpha: el.color.a * alpha);

    final tp = TextPainter(
      text: TextSpan(
        text: el.text ?? '',
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontFamily: el.fontFamily,
          fontWeight: el.fontWeight,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - x);

    if (clip < 1.0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(
          x, y - fontSize * 1.2, tp.width * clip + 4 * scale, tp.height + 8 * scale));
    }
    tp.paint(canvas, Offset(x, y - tp.height * 0.85));
    if (clip < 1.0) canvas.restore();
  }

  void _drawArrow(Canvas canvas, double scale, DrawElement el, double startX,
      double startY, Color color, double t) {
    final endX = el.arrowEnd!.dx * scale;
    final endY = el.arrowEnd!.dy * scale;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final cx = startX + (endX - startX) * t;
    final cy = startY + (endY - startY) * t;
    canvas.drawLine(Offset(startX, startY), Offset(cx, cy), paint);
    if (t >= 0.9) {
      final angle = math.atan2(endY - startY, endX - startX);
      final h = 8.0 * scale;
      final ap = Paint()
        ..color = color
        ..strokeWidth = 2 * scale
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, cy),
          Offset(cx - h * math.cos(angle - math.pi / 6), cy - h * math.sin(angle - math.pi / 6)), ap);
      canvas.drawLine(Offset(cx, cy),
          Offset(cx - h * math.cos(angle + math.pi / 6), cy - h * math.sin(angle + math.pi / 6)), ap);
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter old) =>
      old.currentStepIndex != currentStepIndex ||
      old.stepProgress != stepProgress ||
      old.steps != steps ||
      old.disableAnimations != disableAnimations;
}
