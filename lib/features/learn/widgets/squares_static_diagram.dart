// lib/features/learn/widgets/squares_static_diagram.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// Step data representation for Squaring shortcut visual cards.
class SquareStepData {
  const SquareStepData({
    required this.stepNumber,
    required this.title,
    required this.badge,
    required this.mainFormula,
    required this.explanation,
    required this.resultHighlight,
    this.subNote,
    this.isFinal = false,
  });

  final int stepNumber;
  final String title;
  final String badge;
  final String mainFormula;
  final String explanation;
  final String resultHighlight;
  final String? subNote;
  final bool isFinal;
}

String _devStr(int d) => d >= 0 ? '+$d' : '$d';
String _signStr(int d) => d >= 0 ? '+ $d' : '− ${d.abs()}';
String _pad2(int v) => v < 10 ? '0$v' : '$v';

/// Computes the step cards for any squaring problem.
List<SquareStepData> computeSquaresSteps({
  required String lessonId,
  required int number,
}) {
  final n = number;
  final result = n * n;

  switch (lessonId) {
    case 'squares_ending_5':
      final tens = n ~/ 10;
      final next = tens + 1;
      final leftPart = tens * next;
      return [
        SquareStepData(
          stepNumber: 1,
          title: 'Split Tens & Units Digits',
          badge: 'Tens: $tens  |  Units: 5',
          mainFormula: 'Frame: $tens  [ __ ]  5',
          explanation:
              'Identify the tens digit ($tens) and the units digit (5).\nBecause the units digit is 5, the square is guaranteed to terminate in 25.',
          resultHighlight: 'Leading Digit: $tens, Ending: 5',
        ),
        SquareStepData(
          stepNumber: 2,
          title: 'Multiply by (Tens + 1)',
          badge: '$tens × ($tens + 1) = $leftPart',
          mainFormula: '$tens × $next = $leftPart',
          explanation:
              'Take the leading tens digit ($tens), add 1 to get $next, and multiply them:\n$tens × $next = $leftPart.\nThis produces the left part of the final answer!',
          resultHighlight: 'Left Part = $leftPart',
        ),
        const SquareStepData(
          stepNumber: 3,
          title: 'Constant Units Square (5²)',
          badge: '5² = 25 (Always)',
          mainFormula: 'Right Part = 25',
          explanation:
              'Square the units digit:\n5² = 25.\nIn Vedic Ekadhikena Purvena, any number ending in 5 always ends in 25.',
          resultHighlight: 'Right Part = 25',
        ),
        SquareStepData(
          stepNumber: 4,
          title: 'Join Left & Right Parts',
          badge: '$leftPart | 25 = $result',
          mainFormula: '$n² = $result',
          explanation:
              'Join the left part ($leftPart) and the constant ending (25) side-by-side:\n$leftPart | 25  →  $result ✓\nInstant mental calculation in 2 seconds!',
          resultHighlight: '$n² = $result',
          isFinal: true,
        ),
      ];

    case 'squares_base_50':
      final d = n - 50;
      final dSquared = d * d;
      final rawLeft = 25 + d;
      final carry = dSquared >= 100 ? dSquared ~/ 100 : 0;
      final finalRightNum = dSquared % 100;
      final finalRight = _pad2(finalRightNum);
      final finalLeft = rawLeft + carry;

      return [
        SquareStepData(
          stepNumber: 1,
          title: 'Base-50 Deviation',
          badge: 'Δ = $n − 50 = ${_devStr(d)}',
          mainFormula: '$n = 50 ${_signStr(d)}',
          explanation:
              'Find how far $n deviates from base 50:\n$n − 50 = ${_devStr(d)} (${d >= 0 ? "$d above 50" : "${d.abs()} below 50"}).',
          resultHighlight: 'Deviation d = ${_devStr(d)}',
        ),
        SquareStepData(
          stepNumber: 2,
          title: 'Half-Base Left Part (25 + d)',
          badge: '25 + (${_devStr(d)}) = $rawLeft',
          mainFormula: 'Left = 25 + (${_devStr(d)}) = $rawLeft',
          explanation:
              'Since (50 + d)² = 2500 + 100d + d² = 100(25 + d) + d², the left part always starts from 25!\nAdd the deviation directly to 25:\n25 + (${_devStr(d)}) = $rawLeft.',
          resultHighlight: 'Working Left Part = $rawLeft',
        ),
        SquareStepData(
          stepNumber: 3,
          title: 'Deviation Square (d²)',
          badge: '(${_devStr(d)})² = $dSquared',
          mainFormula: 'Right = (${_devStr(d)})² = $dSquared',
          explanation:
              'Square the deviation: (${_devStr(d)})² = $dSquared.\nMust occupy exactly 2 digits.${dSquared < 10 ? " Pad with zero: $finalRight." : ""}${carry > 0 ? " Carry $carry to the left part!" : ""}',
          resultHighlight: 'Right Part = $finalRight ${carry > 0 ? "(Carry $carry)" : ""}',
        ),
        SquareStepData(
          stepNumber: 4,
          title: 'Final Product Assembly',
          badge: '$finalLeft | $finalRight = $result',
          mainFormula: '$n² = $result',
          explanation: carry > 0
              ? 'Add carry $carry to left part ($rawLeft + $carry = $finalLeft) and append $finalRight:\n$finalLeft | $finalRight  →  $result ✓'
              : 'Join Left and Right side-by-side:\n$finalLeft | $finalRight  →  $result ✓',
          resultHighlight: '$n² = $result',
          isFinal: true,
        ),
      ];

    case 'squares_base_100':
      final d = n - 100;
      final dSquared = d * d;
      final rawLeft = n + d;
      final carry = dSquared >= 100 ? dSquared ~/ 100 : 0;
      final finalRightNum = dSquared % 100;
      final finalRight = _pad2(finalRightNum);
      final finalLeft = rawLeft + carry;

      return [
        SquareStepData(
          stepNumber: 1,
          title: 'Base-100 Deviation',
          badge: 'Δ = $n − 100 = ${_devStr(d)}',
          mainFormula: '$n = 100 ${_signStr(d)}',
          explanation:
              'Find how far $n is from reference base 100:\n$n − 100 = ${_devStr(d)} (${d >= 0 ? "$d above 100" : "${d.abs()} below 100"}).',
          resultHighlight: 'Deviation d = ${_devStr(d)}',
        ),
        SquareStepData(
          stepNumber: 2,
          title: 'Adjust Number (N + d)',
          badge: '$n + (${_devStr(d)}) = $rawLeft',
          mainFormula: 'Left = $n + (${_devStr(d)}) = $rawLeft',
          explanation:
              'Add the deviation directly to the number itself:\n$n + (${_devStr(d)}) = $rawLeft.\nAlgebraically: (100 + d)² = 100(N + d) + d²!',
          resultHighlight: 'Working Left Part = $rawLeft',
        ),
        SquareStepData(
          stepNumber: 3,
          title: 'Deviation Square (d²)',
          badge: '(${_devStr(d)})² = $dSquared',
          mainFormula: 'Right = (${_devStr(d)})² = $dSquared',
          explanation:
              'Square the deviation: (${_devStr(d)})² = $dSquared.\nBase 100 has 2 zeros, so the right part must take exactly 2 digits.${dSquared < 10 ? " Pad with zero: $finalRight." : ""}${carry > 0 ? " Carry $carry to the left part!" : ""}',
          resultHighlight: 'Right Part = $finalRight ${carry > 0 ? "(Carry $carry)" : ""}',
        ),
        SquareStepData(
          stepNumber: 4,
          title: 'Final Product Assembly',
          badge: '$finalLeft | $finalRight = $result',
          mainFormula: '$n² = $result',
          explanation: carry > 0
              ? 'Add carry $carry to left part ($rawLeft + $carry = $finalLeft) and append $finalRight:\n$finalLeft | $finalRight  →  $result ✓'
              : 'Join Left and Right side-by-side:\n$finalLeft | $finalRight  →  $result ✓',
          resultHighlight: '$n² = $result',
          isFinal: true,
        ),
      ];

    case 'squares_base_150':
      final d = n - 150;
      final dSquared = d * d;
      final sum = n + d;
      final rawLeft = (sum * 1.5).round();
      final carry = dSquared >= 100 ? dSquared ~/ 100 : 0;
      final finalRightNum = dSquared % 100;
      final finalRight = _pad2(finalRightNum);
      final finalLeft = rawLeft + carry;

      return [
        SquareStepData(
          stepNumber: 1,
          title: 'Base-150 Deviation',
          badge: 'Δ = $n − 150 = ${_devStr(d)}',
          mainFormula: '$n = 150 ${_signStr(d)}',
          explanation:
              'Find the difference from base 150:\n$n − 150 = ${_devStr(d)} (${d >= 0 ? "$d above 150" : "${d.abs()} below 150"}).',
          resultHighlight: 'Deviation d = ${_devStr(d)}',
        ),
        SquareStepData(
          stepNumber: 2,
          title: 'Add Deviation (N + d)',
          badge: '$n + (${_devStr(d)}) = $sum',
          mainFormula: 'Sum = $n + (${_devStr(d)}) = $sum',
          explanation:
              'Add the deviation to the original number:\n$n + (${_devStr(d)}) = $sum.',
          resultHighlight: 'Subtotal = $sum',
        ),
        SquareStepData(
          stepNumber: 3,
          title: 'Scale by 1.5 (Add Half)',
          badge: '$sum × 1.5 = $rawLeft',
          mainFormula: '$sum + ($sum ÷ 2) = $rawLeft',
          explanation:
              'Base 150 is 1.5 times Base 100. Multiply by 1.5 by simply adding half of $sum:\n$sum + ${sum ~/ 2} = $rawLeft.',
          resultHighlight: 'Working Left Part = $rawLeft',
        ),
        SquareStepData(
          stepNumber: 4,
          title: 'Square Deviation & Assemble',
          badge: '$finalLeft | $finalRight = $result',
          mainFormula: '$n² = $result',
          explanation:
              'Square deviation: (${_devStr(d)})² = $dSquared (2 digits: $finalRight).\n${carry > 0 ? "Add carry $carry to $rawLeft ($finalLeft) and append $finalRight:\n" : ""}Join Left and Right:\n$finalLeft | $finalRight  →  $result ✓',
          resultHighlight: '$n² = $result',
          isFinal: true,
        ),
      ];

    case 'squares_base_200':
      final d = n - 200;
      final dSquared = d * d;
      final sum = n + d;
      final rawLeft = sum * 2;
      final carry = dSquared >= 100 ? dSquared ~/ 100 : 0;
      final finalRightNum = dSquared % 100;
      final finalRight = _pad2(finalRightNum);
      final finalLeft = rawLeft + carry;

      return [
        SquareStepData(
          stepNumber: 1,
          title: 'Base-200 Deviation',
          badge: 'Δ = $n − 200 = ${_devStr(d)}',
          mainFormula: '$n = 200 ${_signStr(d)}',
          explanation:
              'Find the difference from base 200:\n$n − 200 = ${_devStr(d)} (${d >= 0 ? "$d above 200" : "${d.abs()} below 200"}).',
          resultHighlight: 'Deviation d = ${_devStr(d)}',
        ),
        SquareStepData(
          stepNumber: 2,
          title: 'Add Deviation (N + d)',
          badge: '$n + (${_devStr(d)}) = $sum',
          mainFormula: 'Sum = $n + (${_devStr(d)}) = $sum',
          explanation:
              'Add the deviation to the number:\n$n + (${_devStr(d)}) = $sum.',
          resultHighlight: 'Subtotal = $sum',
        ),
        SquareStepData(
          stepNumber: 3,
          title: 'Double for Base 200 (× 2)',
          badge: '$sum × 2 = $rawLeft',
          mainFormula: 'Left = $sum × 2 = $rawLeft',
          explanation:
              'Base 200 is 2 times base 100. Double the subtotal:\n$sum × 2 = $rawLeft.',
          resultHighlight: 'Working Left Part = $rawLeft',
        ),
        SquareStepData(
          stepNumber: 4,
          title: 'Square Deviation & Assemble',
          badge: '$finalLeft | $finalRight = $result',
          mainFormula: '$n² = $result',
          explanation:
              'Square deviation: (${_devStr(d)})² = $dSquared (2 digits: $finalRight).\n${carry > 0 ? "Add carry $carry to $rawLeft ($finalLeft) and append $finalRight:\n" : ""}Join Left and Right:\n$finalLeft | $finalRight  →  $result ✓',
          resultHighlight: '$n² = $result',
          isFinal: true,
        ),
      ];

    case 'squares_base_25':
      final d = n - 25;
      final shift = 50 * d;
      final subtotal = 625 + shift;
      final dSquared = d * d;

      return [
        SquareStepData(
          stepNumber: 1,
          title: 'Base-25 Deviation',
          badge: 'Δ = $n − 25 = ${_devStr(d)}',
          mainFormula: '$n = 25 ${_signStr(d)}',
          explanation:
              'Find difference from base 25:\n$n − 25 = ${_devStr(d)} (${d >= 0 ? "$d above 25" : "${d.abs()} below 25"}).',
          resultHighlight: 'Deviation d = ${_devStr(d)}',
        ),
        SquareStepData(
          stepNumber: 2,
          title: 'Algebraic Shift (50 × d)',
          badge: '50 × (${_devStr(d)}) = $shift',
          mainFormula: '(25 + d)² = 625 + 50d + d²',
          explanation:
              'Since 25² = 625, expanding (25 + d)² gives:\n625 + 50d + d².\nMultiply the deviation by 50:\n50 × (${_devStr(d)}) = $shift.',
          resultHighlight: 'Round Shift = $shift',
        ),
        SquareStepData(
          stepNumber: 3,
          title: 'Main Base Subtotal (625 + 50d)',
          badge: '625 + ($shift) = $subtotal',
          mainFormula: 'Subtotal = 625 + ($shift) = $subtotal',
          explanation:
              'Add the round 50-shift to 625:\n625 + ($shift) = $subtotal.',
          resultHighlight: 'Subtotal = $subtotal',
        ),
        SquareStepData(
          stepNumber: 4,
          title: 'Add d² for Final Answer',
          badge: '$subtotal + $dSquared = $result',
          mainFormula: '$n² = $result',
          explanation:
              'Add (${_devStr(d)})² = $dSquared to the subtotal:\n$subtotal + $dSquared = $result ✓\nPure mental math with zero scratchpad writing!',
          resultHighlight: '$n² = $result',
          isFinal: true,
        ),
      ];

    default:
      return [
        SquareStepData(
          stepNumber: 1,
          title: 'Square Calculation',
          badge: '$n²',
          mainFormula: '$n² = $result',
          explanation: 'Standard speed arithmetic square calculation.',
          resultHighlight: '$n² = $result',
          isFinal: true,
        ),
      ];
  }
}

/// Interactive Static Ruled Notebook Diagram for all Squaring Shortcuts.
/// Supports 2D pan, pinch-to-zoom (0.5x to 2.5x), floating zoom controls, and zero overlap.
class SquaresStaticDiagram extends StatefulWidget {
  const SquaresStaticDiagram({
    super.key,
    required this.lessonId,
    required this.number,
  });

  final String lessonId;
  final int number;

  static const double cardWidth = 320.0;
  static const double cardGap = 20.0;
  static const double marginLeft = 50.0;

  @override
  State<SquaresStaticDiagram> createState() => _SquaresStaticDiagramState();
}

class _SquaresStaticDiagramState extends State<SquaresStaticDiagram> {
  final TransformationController _transformController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() => _currentScale = scale);
    }
  }

  void _zoomIn() {
    final next = math.min(2.5, _currentScale + 0.25);
    _setScale(next);
  }

  void _zoomOut() {
    final next = math.max(0.5, _currentScale - 0.25);
    _setScale(next);
  }

  void _resetZoom() => _setScale(1.0);

  void _setScale(double targetScale) {
    HapticFeedback.selectionClick();
    final matrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    _transformController.value = matrix;
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = computeSquaresSteps(
      lessonId: widget.lessonId,
      number: widget.number,
    );

    final canvasWidth = SquaresStaticDiagram.marginLeft +
        steps.length *
            (SquaresStaticDiagram.cardWidth + SquaresStaticDiagram.cardGap) +
        50.0;
    const canvasHeight = 640.0;

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(120),
          minScale: 0.5,
          maxScale: 2.5,
          child: Container(
            width: canvasWidth,
            height: canvasHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5), // Cream Notebook Paper
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.borderLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomPaint(
              size: Size(canvasWidth, canvasHeight),
              painter: _SquaresDiagramPainter(
                lessonId: widget.lessonId,
                number: widget.number,
                steps: steps,
                width: canvasWidth,
                height: canvasHeight,
              ),
            ),
          ),
        ),

        // Floating Zoom Controls
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ZoomBtn(icon: Icons.remove_rounded, onTap: _zoomOut),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5), // orange-100
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(_currentScale * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _ZoomBtn(icon: Icons.add_rounded, onTap: _zoomIn),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }
}

// ─── Custom Painter ──────────────────────────────────────────────────────────

class _SquaresDiagramPainter extends CustomPainter {
  const _SquaresDiagramPainter({
    required this.lessonId,
    required this.number,
    required this.steps,
    required this.width,
    required this.height,
  });

  final String lessonId;
  final int number;
  final List<SquareStepData> steps;
  final double width;
  final double height;

  static const Color _lineRuleColor = Color(0xFFFDE68A); // amber-200
  static const Color _marginLineColor = Color(0xFFFCA5A5); // rose-300
  static const Color _orangeAccent = Color(0xFFEA580C); // orange-600
  static const Color _blueAccent = Color(0xFF2563EB);
  static const Color _greenAccent = Color(0xFF16A34A);

  @override
  void paint(Canvas canvas, Size size) {
    _drawNotebookPaper(canvas, size);
    _drawHeaderSection(canvas);
    _drawStepCards(canvas);
    _drawVictoryBanner(canvas);
  }

  void _drawNotebookPaper(Canvas canvas, Size size) {
    // Ruled lines every 30px
    final rulePaint = Paint()
      ..color = _lineRuleColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    final count = (size.height / 30).ceil();
    for (int i = 1; i <= count; i++) {
      final y = i * 30.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }

    // Left vertical margin line
    final marginPaint = Paint()
      ..color = _marginLineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(32, 0), Offset(32, size.height), marginPaint);
  }

  void _drawHeaderSection(Canvas canvas) {
    // Title Badge
    final titlePaint = Paint()
      ..color = _orangeAccent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 24, 300, 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, titlePaint);

    final titleBorder = Paint()
      ..color = _orangeAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, titleBorder);

    final tpTitle = TextPainter(
      text: const TextSpan(
        text: 'SPEED SQUARING SHORTCUT BOARD',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _orangeAccent,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpTitle.paint(canvas, const Offset(64, 30));

    // Equation
    final result = number * number;
    final tpEq = TextPainter(
      text: TextSpan(
        text: '$number²  =  $result',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpEq.paint(canvas, const Offset(50, 62));

    final tpSub = TextPainter(
      text: TextSpan(
        text: 'Interactive mental arithmetic breakdown • Zero scratchpad multi-line multiplication',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSub.paint(canvas, const Offset(50, 96));
  }

  void _drawStepCards(Canvas canvas) {
    const cardTop = 130.0;
    const cardH = 390.0;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final cardLeft = SquaresStaticDiagram.marginLeft +
          i * (SquaresStaticDiagram.cardWidth + SquaresStaticDiagram.cardGap);

      _drawSingleCard(canvas, cardLeft, cardTop,
          SquaresStaticDiagram.cardWidth, cardH, step);
    }

    // Draw connecting arrows between step cards
    for (int i = 0; i < steps.length - 1; i++) {
      final cardLeft1 = SquaresStaticDiagram.marginLeft +
          i * (SquaresStaticDiagram.cardWidth + SquaresStaticDiagram.cardGap);
      final cardLeft2 = cardLeft1 +
          SquaresStaticDiagram.cardWidth +
          SquaresStaticDiagram.cardGap;

      _drawConnectingStepArrow(
        canvas,
        fromCardLeft: cardLeft1,
        toCardLeft: cardLeft2,
        cardTop: cardTop,
        cardW: SquaresStaticDiagram.cardWidth,
      );
    }
  }

  void _drawSingleCard(Canvas canvas, double left, double top, double w,
      double h, SquareStepData step) {
    final cardRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h), const Radius.circular(16));

    // Shadow
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Background
    canvas.drawRRect(cardRRect, Paint()..color = Colors.white);

    // Border
    final borderColor = step.isFinal
        ? _greenAccent.withValues(alpha: 0.4)
        : AppTheme.borderLight;
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = step.isFinal ? 1.8 : 1.2,
    );

    // Header badge
    final headerBgColor = step.isFinal
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFEDD5);
    final headerTextColor =
        step.isFinal ? _greenAccent : _orangeAccent;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 12, top + 12, w - 24, 28),
        const Radius.circular(8),
      ),
      Paint()..color = headerBgColor,
    );

    final tpHeader = TextPainter(
      text: TextSpan(
        text: 'STEP ${step.stepNumber}: ${step.title.toUpperCase()}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: headerTextColor,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 32);
    tpHeader.paint(canvas, Offset(left + 20, top + 19));

    // Step Formula Box
    final formulaRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 14, top + 50, w - 28, 80),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      formulaRRect,
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRRect(
      formulaRRect,
      Paint()
        ..color = AppTheme.borderLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final tpFormula = TextPainter(
      text: TextSpan(
        text: step.mainFormula,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: _blueAccent,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 40);
    tpFormula.paint(canvas, Offset(left + 22, top + 62));

    final tpBadge = TextPainter(
      text: TextSpan(
        text: step.badge,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _orangeAccent.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 40);
    tpBadge.paint(canvas, Offset(left + 22, top + 98));

    // Working & Mental Explanation Box
    final expRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 14, top + 140, w - 28, 142),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      expRRect,
      Paint()..color = const Color(0xFFF1F5F9), // slate-100
    );

    final tpLabel = TextPainter(
      text: const TextSpan(
        text: 'How to do it mentally:',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLabel.paint(canvas, Offset(left + 22, top + 150));

    final tpExp = TextPainter(
      text: TextSpan(
        text: step.explanation,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          height: 1.35,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 44);
    tpExp.paint(canvas, Offset(left + 22, top + 170));

    // Result Highlight Strip at bottom of card
    final resRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 14, top + 294, w - 28, 78),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      resRRect,
      Paint()..color = step.isFinal ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
    );
    canvas.drawRRect(
      resRRect,
      Paint()
        ..color = step.isFinal ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final tpResLabel = TextPainter(
      text: TextSpan(
        text: step.isFinal ? 'FINAL ANSWER' : 'KEY RESULT',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: step.isFinal ? _greenAccent : const Color(0xFFB45309),
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpResLabel.paint(canvas, Offset(left + 22, top + 304));

    final tpRes = TextPainter(
      text: TextSpan(
        text: step.resultHighlight,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: step.isFinal ? const Color(0xFF15803D) : const Color(0xFF92400E),
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 44);
    tpRes.paint(canvas, Offset(left + 22, top + 326));
  }

  void _drawConnectingStepArrow(
    Canvas canvas, {
    required double fromCardLeft,
    required double toCardLeft,
    required double cardTop,
    required double cardW,
  }) {
    final startX = fromCardLeft + cardW + 3;
    final endX = toCardLeft - 3;
    final y = cardTop + 195.0;

    final arrowPaint = Paint()
      ..color = _orangeAccent.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, y), Offset(endX, y), arrowPaint);

    // Arrowhead pointing right
    final headPaint = Paint()
      ..color = _orangeAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final headPath = Path()
      ..moveTo(endX, y)
      ..lineTo(endX - 7, y - 5)
      ..lineTo(endX - 7, y + 5)
      ..close();
    canvas.drawPath(headPath, headPaint);
  }

  void _drawVictoryBanner(Canvas canvas) {
    const bannerLeft = SquaresStaticDiagram.marginLeft;
    const bannerTop = 535.0;
    final bannerW = steps.length *
            (SquaresStaticDiagram.cardWidth +
                SquaresStaticDiagram.cardGap) -
        SquaresStaticDiagram.cardGap;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bannerLeft, bannerTop, bannerW, 76),
      const Radius.circular(16),
    );

    // Fill
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFF0FDF4)); // green-50

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _greenAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Check / Trophy Icon Badge
    final iconBg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(bannerLeft + 16, bannerTop + 16, 44, 44),
      const Radius.circular(12),
    );
    canvas.drawRRect(iconBg, Paint()..color = _greenAccent.withValues(alpha: 0.15));

    final tpIcon = TextPainter(
      text: const TextSpan(
        text: '✓',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: _greenAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpIcon.paint(canvas, const Offset(bannerLeft + 30, bannerTop + 24));

    // Summary Text
    final result = number * number;
    final tpSummTitle = TextPainter(
      text: TextSpan(
        text: '$number²  =  $result',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: Color(0xFF15803D),
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSummTitle.paint(canvas, const Offset(bannerLeft + 72, bannerTop + 18));

    final tpSummSub = TextPainter(
      text: const TextSpan(
        text: 'Solved using speed math shortcuts • Instant mental square with zero scratchpad work',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF166534),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSummSub.paint(canvas, const Offset(bannerLeft + 72, bannerTop + 42));
  }

  @override
  bool shouldRepaint(covariant _SquaresDiagramPainter oldDelegate) {
    return oldDelegate.number != number ||
        oldDelegate.lessonId != lessonId ||
        oldDelegate.steps != steps;
  }
}
