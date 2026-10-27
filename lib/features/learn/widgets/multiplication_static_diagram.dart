// lib/features/learn/widgets/multiplication_static_diagram.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Single product term in a criss-cross step (e.g., A[1] × B[0]).
class MultTerm {
  const MultTerm({
    required this.topDigit,
    required this.bottomDigit,
    required this.topIdx,
    required this.bottomIdx,
    required this.product,
  });

  final int topDigit;
  final int bottomDigit;
  final int topIdx; // 0 = units, 1 = tens, 2 = hundreds
  final int bottomIdx;
  final int product;
}

/// Data model for one step in the Criss-Cross multiplication diagram.
class MultStepData {
  const MultStepData({
    required this.stepNumber,
    required this.totalSteps,
    required this.name,
    required this.patternType,
    required this.terms,
    required this.sumTerms,
    required this.carryIn,
    required this.totalWithCarry,
    required this.digitWritten,
    required this.carryOut,
    required this.isFinalStep,
    required this.runningAnswerDigits,
  });

  final int stepNumber; // 1-based
  final int totalSteps;
  final String name; // e.g. "Step 1: Units Column"
  final String patternType; // "Vertical (|)", "Crosswise (X)", "Star Cross (*)"
  final List<MultTerm> terms;
  final int sumTerms;
  final int carryIn;
  final int totalWithCarry;
  final String digitWritten; // usually single digit, but may be multi-digit in final step
  final int carryOut;
  final List<String?> runningAnswerDigits; // e.g. [null, null, '6', '6']
  final bool isFinalStep;
}

/// Computes the complete Criss-Cross steps for multiplying any two positive
/// integers A and B (up to 3 digits each).
List<MultStepData> computeMultiplicationSteps(int a, int b) {
  // Extract digits (0 = units, 1 = tens, 2 = hundreds)
  final aDigits = <int>[];
  var tempA = a;
  while (tempA > 0) {
    aDigits.add(tempA % 10);
    tempA ~/= 10;
  }
  if (aDigits.isEmpty) aDigits.add(0);

  final bDigits = <int>[];
  var tempB = b;
  while (tempB > 0) {
    bDigits.add(tempB % 10);
    tempB ~/= 10;
  }
  if (bDigits.isEmpty) bDigits.add(0);

  final numA = aDigits.length;
  final numB = bDigits.length;
  final totalSteps = (numA + numB) - 1;

  final finalProduct = a * b;
  final productStr = '$finalProduct';
  final finalAnswerLen = productStr.length;

  final steps = <MultStepData>[];
  var carry = 0;
  final accumulatedDigits = <String>[];

  for (var k = 0; k < totalSteps; k++) {
    final terms = <MultTerm>[];
    var sum = 0;

    // Convolution: all pairs (i, j) where i + j == k
    for (var i = 0; i < numA; i++) {
      final j = k - i;
      if (j >= 0 && j < numB) {
        final prod = aDigits[i] * bDigits[j];
        terms.add(MultTerm(
          topDigit: aDigits[i],
          bottomDigit: bDigits[j],
          topIdx: i,
          bottomIdx: j,
          product: prod,
        ));
        sum += prod;
      }
    }

    final totalWithCarry = sum + carry;
    final isFinal = (k == totalSteps - 1);
    final String written;
    final int nextCarry;

    if (isFinal) {
      written = '$totalWithCarry';
      nextCarry = 0;
    } else {
      written = '${totalWithCarry % 10}';
      nextCarry = totalWithCarry ~/ 10;
    }

    accumulatedDigits.insert(0, written);

    // Build running answer placeholder array
    final running = List<String?>.filled(finalAnswerLen, null);
    final currentAccumStr = accumulatedDigits.join();
    final startIdx = finalAnswerLen - currentAccumStr.length;
    for (var idx = 0; idx < currentAccumStr.length; idx++) {
      if (startIdx + idx >= 0 && startIdx + idx < finalAnswerLen) {
        running[startIdx + idx] = currentAccumStr[idx];
      }
    }

    // Step naming and pattern description
    String stepName;
    String patternType;
    if (k == 0) {
      stepName = 'Units Column';
      patternType = 'Vertical (|)';
    } else if (k == 1) {
      stepName = totalSteps == 3 ? 'Crosswise Product' : 'Right Crosswise';
      patternType = 'Crosswise (X)';
    } else if (k == 2) {
      if (totalSteps == 3) {
        stepName = 'Tens Column';
        patternType = 'Vertical (|)';
      } else if (totalSteps == 4) {
        stepName = 'Left Crosswise';
        patternType = 'Crosswise (X)';
      } else {
        stepName = 'Star 3-Way Cross';
        patternType = 'Star Cross (*)';
      }
    } else if (k == 3) {
      if (totalSteps == 4) {
        stepName = 'Leftmost Column';
        patternType = 'Vertical (|)';
      } else {
        stepName = 'Left Crosswise';
        patternType = 'Crosswise (X)';
      }
    } else {
      stepName = 'Leftmost Column';
      patternType = 'Vertical (|)';
    }

    steps.add(MultStepData(
      stepNumber: k + 1,
      totalSteps: totalSteps,
      name: 'Step ${k + 1}: $stepName',
      patternType: patternType,
      terms: terms,
      sumTerms: sum,
      carryIn: carry,
      totalWithCarry: totalWithCarry,
      digitWritten: written,
      carryOut: nextCarry,
      isFinalStep: isFinal,
      runningAnswerDigits: running,
    ));

    carry = nextCarry;
  }

  return steps;
}

/// Static visual diagram for Speed Multiplication (Criss-Cross / Urdhva Tiryagbhyam).
///
/// Features:
/// - Ruled cream notebook paper with amber lines.
/// - Full pinch-to-zoom (0.5x to 2.5x) and 2D pan via InteractiveViewer.
/// - Floating zoom controls (+, −, 1:1, scale %).
/// - Clear step-by-step card progression from right to left (Units to Leftmost).
/// - Active crosswise / vertical connecting arrows between operand digits.
/// - Step subtotal, carry handling, and single-line running answer.
/// - Victory banner displaying the final product.
class MultiplicationStaticDiagram extends StatefulWidget {
  const MultiplicationStaticDiagram({
    super.key,
    required this.a,
    required this.b,
  });

  final int a;
  final int b;

  static const double cardWidth = 270.0;
  static const double cardGap = 20.0;
  static const double marginLeft = 50.0;
  static const double marginRight = 50.0;

  @override
  State<MultiplicationStaticDiagram> createState() =>
      _MultiplicationStaticDiagramState();
}

class _MultiplicationStaticDiagramState
    extends State<MultiplicationStaticDiagram> {
  final TransformationController _transCtrl = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transCtrl.addListener(() {
      final s = _transCtrl.value.getMaxScaleOnAxis();
      if (s != _currentScale) {
        setState(() => _currentScale = s);
      }
    });
  }

  @override
  void dispose() {
    _transCtrl.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.25).clamp(0.5, 2.5);
    _setScale(newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.25).clamp(0.5, 2.5);
    _setScale(newScale);
  }

  void _resetZoom() {
    _transCtrl.value = Matrix4.identity();
    setState(() => _currentScale = 1.0);
  }

  void _setScale(double targetScale) {
    final matrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    _transCtrl.value = matrix;
    setState(() => _currentScale = targetScale);
  }

  @override
  Widget build(BuildContext context) {
    // Normalise so A has >= digits than B for cleaner visual alignment
    final topA = math.max(widget.a, widget.b);
    final botB = math.min(widget.a, widget.b);

    final steps = computeMultiplicationSteps(topA, botB);
    final n = steps.length;
    final canvasWidth = MultiplicationStaticDiagram.marginLeft +
        n * MultiplicationStaticDiagram.cardWidth +
        (n - 1) * MultiplicationStaticDiagram.cardGap +
        MultiplicationStaticDiagram.marginRight;
    const canvasHeight = 620.0;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF5), // cream notebook paper
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.borderLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InteractiveViewer(
            transformationController: _transCtrl,
            minScale: 0.5,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(80),
            constrained: false,
            child: CustomPaint(
              size: Size(canvasWidth, canvasHeight),
              painter: _MultiplicationDiagramPainter(
                a: topA,
                b: botB,
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
                      color: AppTheme.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(_currentScale * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
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

class _MultiplicationDiagramPainter extends CustomPainter {
  const _MultiplicationDiagramPainter({
    required this.a,
    required this.b,
    required this.steps,
    required this.width,
    required this.height,
  });

  final int a;
  final int b;
  final List<MultStepData> steps;
  final double width;
  final double height;

  static const Color _lineRuleColor = Color(0xFFFDE68A); // amber-200
  static const Color _marginLineColor = Color(0xFFFCA5A5); // rose-300
  static const Color _cardBgColor = Colors.white;
  static const Color _blueAccent = Color(0xFF2563EB); // indigo-600
  static const Color _orangeAccent = Color(0xFFF97316); // orange-500
  static const Color _greenAccent = Color(0xFF16A34A); // green-600
  static const Color _purpleAccent = Color(0xFF7C3AED); // purple-600

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
      ..color = _purpleAccent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 24, 280, 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, titlePaint);

    final titleBorder = Paint()
      ..color = _purpleAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, titleBorder);

    final tpTitle = TextPainter(
      text: const TextSpan(
        text: 'CRISS-CROSS MULTIPLICATION',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _purpleAccent,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpTitle.paint(canvas, const Offset(64, 30));

    // Equation Banner
    final tpEq = TextPainter(
      text: TextSpan(
        text: '$a  ×  $b  =  ${a * b}',
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
        text:
            'Universal speed math method • Single line result from right to left',
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
      final cardLeft = MultiplicationStaticDiagram.marginLeft +
          i * (MultiplicationStaticDiagram.cardWidth +
                  MultiplicationStaticDiagram.cardGap);

      _drawSingleCard(canvas, cardLeft, cardTop,
          MultiplicationStaticDiagram.cardWidth, cardH, step);
    }

    // Draw carry connector arrows between adjacent cards
    for (int i = 0; i < steps.length - 1; i++) {
      final step = steps[i];
      final nextStep = steps[i + 1];
      if (step.carryOut > 0) {
        final cardLeft1 = MultiplicationStaticDiagram.marginLeft +
            i * (MultiplicationStaticDiagram.cardWidth +
                    MultiplicationStaticDiagram.cardGap);
        final cardLeft2 = cardLeft1 +
            MultiplicationStaticDiagram.cardWidth +
            MultiplicationStaticDiagram.cardGap;

        _drawInterCardCarryArrow(
          canvas,
          fromCardLeft: cardLeft1,
          toCardLeft: cardLeft2,
          cardTop: cardTop,
          cardW: MultiplicationStaticDiagram.cardWidth,
          carryValue: step.carryOut,
          nextStep: nextStep,
        );
      }
    }
  }

  void _drawInterCardCarryArrow(
    Canvas canvas, {
    required double fromCardLeft,
    required double toCardLeft,
    required double cardTop,
    required double cardW,
    required int carryValue,
    required MultStepData nextStep,
  }) {
    // Start at the carry badge of card 1
    final startX = fromCardLeft + 14 + 120 + 80; // inside carry badge
    final startY = cardTop + 172 + 125 - 20;

    // Dynamically calculate the EXACT vertical center of "+ carry" in card 2
    final buffer = StringBuffer();
    if (nextStep.terms.length == 1) {
      final t = nextStep.terms.first;
      buffer.write('${t.topDigit} × ${t.bottomDigit} = ${t.product}');
    } else {
      final parts = nextStep.terms
          .map((t) => '(${t.topDigit}×${t.bottomDigit})')
          .join(' + ');
      final values = nextStep.terms.map((t) => '${t.product}').join(' + ');
      buffer.write('$parts\n= $values = ${nextStep.sumTerms}');
    }

    final tpFormula = TextPainter(
      text: TextSpan(
        text: buffer.toString(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: cardW - 28 - 20);

    final boxTop = cardTop + 172;
    final carryY = boxTop + 12 + tpFormula.height + 6;
    final endY = carryY + 7.5; // Exactly centered on the "+ carry" line!
    final endX = toCardLeft + 14 + 8; // Points right at the start of "+ carry"

    final arrowColor = _purpleAccent;
    final path = Path()..moveTo(startX, startY);

    // Smooth S-curve across the gap
    final cp1 = Offset(startX + 35, startY + 10);
    final cp2 = Offset(endX - 35, endY);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, endX, endY);

    final curvePaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.85)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, curvePaint);

    // Arrowhead pointing towards endX, endY
    const headLen = 8.0;
    final angle = math.atan2(endY - cp2.dy, endX - cp2.dx);
    final headPaint = Paint()
      ..color = arrowColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(endX, endY),
      Offset(
        endX - headLen * math.cos(angle - math.pi / 6),
        endY - headLen * math.sin(angle - math.pi / 6),
      ),
      headPaint,
    );
    canvas.drawLine(
      Offset(endX, endY),
      Offset(
        endX - headLen * math.cos(angle + math.pi / 6),
        endY - headLen * math.sin(angle + math.pi / 6),
      ),
      headPaint,
    );

    // Small carry pill label in the gap
    final midX = (startX + endX) / 2;
    final midY = (startY + endY) / 2 - 12;

    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(midX, midY), width: 54, height: 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      badgeRRect,
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      badgeRRect,
      Paint()
        ..color = arrowColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final tpBadge = TextPainter(
      text: TextSpan(
        text: '+$carryValue carry',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: arrowColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpBadge.paint(
      canvas,
      Offset(midX - tpBadge.width / 2, midY - tpBadge.height / 2),
    );
  }

  void _drawSingleCard(Canvas canvas, double left, double top, double w,
      double h, MultStepData step) {
    final cardRect = Rect.fromLTWH(left, top, w, h);
    final cardRRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(16));

    // Card shadow
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Card background
    canvas.drawRRect(
      cardRRect,
      Paint()..color = _cardBgColor,
    );

    // Card border
    final borderColor = step.isFinalStep
        ? _greenAccent.withValues(alpha: 0.4)
        : AppTheme.borderLight;
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = step.isFinalStep ? 1.8 : 1.2,
    );

    // Step Header Badge
    final headerBgColor = step.isFinalStep
        ? _greenAccent.withValues(alpha: 0.1)
        : _blueAccent.withValues(alpha: 0.08);
    final headerTextColor =
        step.isFinalStep ? _greenAccent : _blueAccent;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 12, top + 12, w - 24, 28),
        const Radius.circular(8),
      ),
      Paint()..color = headerBgColor,
    );

    final tpHeader = TextPainter(
      text: TextSpan(
        text: '${step.name.toUpperCase()} • ${step.patternType}',
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

    // ── Digit Visual Grid with Connection Arrows ──
    _drawDigitGridWithArrows(canvas, left + 16, top + 50, w - 32, 110, step);

    // ── Calculation Details Box ──
    _drawCalculationBox(canvas, left + 14, top + 172, w - 28, 125, step);

    // ── Running Result Strip ──
    _drawRunningAnswerStrip(canvas, left + 14, top + 310, w - 28, 65, step);
  }

  void _drawDigitGridWithArrows(Canvas canvas, double gridLeft, double gridTop,
      double gridW, double gridH, MultStepData step) {
    // Inner box container
    final boxRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gridLeft, gridTop, gridW, gridH),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      boxRRect,
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRRect(
      boxRRect,
      Paint()
        ..color = AppTheme.borderLight.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Extract digits for top and bottom numbers
    final aStr = '$a';
    final bStr = '$b';
    final maxLen = math.max(aStr.length, bStr.length);

    // Pad with spaces for visual right-alignment
    final padA = aStr.padLeft(maxLen, ' ');
    final padB = bStr.padLeft(maxLen, ' ');

    final colSpacing = gridW / (maxLen + 1.2);
    final topY = gridTop + 24.0;
    final botY = gridTop + gridH - 24.0;

    // Multiply sign
    final tpTimes = TextPainter(
      text: const TextSpan(
        text: '×',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpTimes.paint(canvas, Offset(gridLeft + 12, botY - 12));

    // Calculate center coordinates for each digit column
    final colCenters = <int, double>{};
    for (int idx = 0; idx < maxLen; idx++) {
      // Index from right: 0 is units, 1 is tens, 2 is hundreds
      final rightIdx = maxLen - 1 - idx;
      final x = gridLeft + 42 + idx * colSpacing;
      colCenters[rightIdx] = x;
    }

    // Determine which digits are active in this step
    final activeTopIdxs = step.terms.map((t) => t.topIdx).toSet();
    final activeBotIdxs = step.terms.map((t) => t.bottomIdx).toSet();

    // 1. Draw connection lines & directional arrowheads (stopping cleanly outside digits)
    for (int tIdx = 0; tIdx < step.terms.length; tIdx++) {
      final term = step.terms[tIdx];
      final x1 = colCenters[term.topIdx] ?? gridLeft + 50;
      final x2 = colCenters[term.bottomIdx] ?? gridLeft + 50;

      final isVertical = term.topIdx == term.bottomIdx;
      final lineColor = isVertical ? _blueAccent : _orangeAccent;

      final linePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.9)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      // Compute directional vector between digits
      final dx = x2 - x1;
      final dy = botY - topY;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist > 30) {
        final ux = dx / dist;
        final uy = dy / dist;

        // Clear 17.0 logical pixels from center of digit so lines stop outside the digit bounding box
        const clearance = 17.0;
        final startX = x1 + clearance * ux;
        final startY = topY + clearance * uy;
        final endX = x2 - clearance * ux;
        final endY = botY - clearance * uy;

        // Draw connection line
        canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);

        // Draw arrowheads at both ends pointing towards the digits
        const headLen = 6.5;
        final headPaint = Paint()
          ..color = lineColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        // Arrowhead pointing towards top digit (at startX, startY)
        final topAngle = math.atan2(-uy, -ux);
        canvas.drawLine(
          Offset(startX, startY),
          Offset(
            startX - headLen * math.cos(topAngle - math.pi / 5),
            startY - headLen * math.sin(topAngle - math.pi / 5),
          ),
          headPaint,
        );
        canvas.drawLine(
          Offset(startX, startY),
          Offset(
            startX - headLen * math.cos(topAngle + math.pi / 5),
            startY - headLen * math.sin(topAngle + math.pi / 5),
          ),
          headPaint,
        );

        // Arrowhead pointing towards bottom digit (at endX, endY)
        final botAngle = math.atan2(uy, ux);
        canvas.drawLine(
          Offset(endX, endY),
          Offset(
            endX - headLen * math.cos(botAngle - math.pi / 5),
            endY - headLen * math.sin(botAngle - math.pi / 5),
          ),
          headPaint,
        );
        canvas.drawLine(
          Offset(endX, endY),
          Offset(
            endX - headLen * math.cos(botAngle + math.pi / 5),
            endY - headLen * math.sin(botAngle + math.pi / 5),
          ),
          headPaint,
        );
      }
    }

    // 2. Draw the digits
    for (int idx = 0; idx < maxLen; idx++) {
      final rightIdx = maxLen - 1 - idx;
      final x = colCenters[rightIdx] ?? gridLeft + 50;

      final charA = padA[idx];
      final charB = padB[idx];

      final isTopActive = activeTopIdxs.contains(rightIdx) && charA != ' ';
      final isBotActive = activeBotIdxs.contains(rightIdx) && charB != ' ';

      // Top digit
      if (charA != ' ') {
        final tpA = TextPainter(
          text: TextSpan(
            text: charA,
            style: TextStyle(
              fontSize: 20,
              fontWeight: isTopActive ? FontWeight.w900 : FontWeight.w600,
              color: isTopActive ? _blueAccent : const Color(0xFF94A3B8),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tpA.paint(canvas, Offset(x - tpA.width / 2, topY - tpA.height / 2));
      }

      // Bottom digit
      if (charB != ' ') {
        final tpB = TextPainter(
          text: TextSpan(
            text: charB,
            style: TextStyle(
              fontSize: 20,
              fontWeight: isBotActive ? FontWeight.w900 : FontWeight.w600,
              color: isBotActive ? _orangeAccent : const Color(0xFF94A3B8),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tpB.paint(canvas, Offset(x - tpB.width / 2, botY - tpB.height / 2));
      }
    }
  }

  void _drawCalculationBox(Canvas canvas, double boxLeft, double boxTop,
      double boxW, double boxH, MultStepData step) {
    final boxRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft, boxTop, boxW, boxH),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      boxRRect,
      Paint()..color = const Color(0xFFF1F5F9), // slate-100
    );

    // Terms text: e.g. "3 × 2 = 6" or "(2×2) + (3×4) = 4 + 12 = 16"
    final buffer = StringBuffer();
    if (step.terms.length == 1) {
      final t = step.terms.first;
      buffer.write('${t.topDigit} × ${t.bottomDigit} = ${t.product}');
    } else {
      final parts = step.terms
          .map((t) => '(${t.topDigit}×${t.bottomDigit})')
          .join(' + ');
      final values = step.terms.map((t) => '${t.product}').join(' + ');
      buffer.write('$parts\n= $values = ${step.sumTerms}');
    }

    final tpFormula = TextPainter(
      text: TextSpan(
        text: buffer.toString(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          height: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: boxW - 20);
    tpFormula.paint(canvas, Offset(boxLeft + 10, boxTop + 10));

    // Carry note if applicable
    final carryY = boxTop + 12 + tpFormula.height + 6;
    if (step.carryIn > 0) {
      final tpCarry = TextPainter(
        text: TextSpan(
          text: '+ carry ${step.carryIn} = ${step.totalWithCarry}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _purpleAccent,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpCarry.paint(canvas, Offset(boxLeft + 10, carryY));
    }

    // Action Badges (Write & Carry)
    final badgeY = boxTop + boxH - 32;

    // Write badge (green)
    final writeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxLeft + 8, badgeY, 105, 24),
      const Radius.circular(6),
    );
    canvas.drawRRect(writeRRect, Paint()..color = _greenAccent.withValues(alpha: 0.15));
    canvas.drawRRect(
      writeRRect,
      Paint()
        ..color = _greenAccent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final tpWrite = TextPainter(
      text: TextSpan(
        text: 'Write  ${step.digitWritten}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _greenAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpWrite.paint(canvas, Offset(boxLeft + 18, badgeY + 5));

    // Carry badge (amber/purple)
    if (!step.isFinalStep) {
      final carryOutRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft + 120, badgeY, 100, 24),
        const Radius.circular(6),
      );
      final hasCarry = step.carryOut > 0;
      final cColor = hasCarry ? _orangeAccent : const Color(0xFF64748B);
      canvas.drawRRect(
          carryOutRRect, Paint()..color = cColor.withValues(alpha: 0.12));
      canvas.drawRRect(
        carryOutRRect,
        Paint()
          ..color = cColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      final tpNextCarry = TextPainter(
        text: TextSpan(
          text: hasCarry ? 'Carry  ${step.carryOut} →' : 'No carry',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: cColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpNextCarry.paint(canvas, Offset(boxLeft + 128, badgeY + 5));
    }
  }

  void _drawRunningAnswerStrip(Canvas canvas, double stripLeft, double stripTop,
      double stripW, double stripH, MultStepData step) {
    final stripRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(stripLeft, stripTop, stripW, stripH),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      stripRRect,
      Paint()..color = const Color(0xFFFFFBEB), // amber-50
    );
    canvas.drawRRect(
      stripRRect,
      Paint()
        ..color = const Color(0xFFFDE68A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Label
    final tpLabel = TextPainter(
      text: const TextSpan(
        text: 'Single-line result so far:',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB45309), // amber-700
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLabel.paint(canvas, Offset(stripLeft + 10, stripTop + 7));

    // Digits boxes
    final digits = step.runningAnswerDigits;
    final boxCount = digits.length;
    const boxSize = 26.0;
    const boxGap = 5.0;
    final totalBoxesW = boxCount * boxSize + (boxCount - 1) * boxGap;
    final startX = stripLeft + (stripW - totalBoxesW) / 2;
    final boxY = stripTop + 28.0;

    for (int d = 0; d < boxCount; d++) {
      final val = digits[d];
      final bx = startX + d * (boxSize + boxGap);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, boxY, boxSize, boxSize),
        const Radius.circular(6),
      );

      final isFilled = val != null;
      final fillPaint = Paint()
        ..color = isFilled ? Colors.white : Colors.white.withValues(alpha: 0.5);
      canvas.drawRRect(rrect, fillPaint);

      final borderPaint = Paint()
        ..color = isFilled ? _greenAccent : const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isFilled ? 1.5 : 1.0;
      canvas.drawRRect(rrect, borderPaint);

      final tpDigit = TextPainter(
        text: TextSpan(
          text: val ?? '',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: _greenAccent,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpDigit.paint(canvas,
          Offset(bx + (boxSize - tpDigit.width) / 2, boxY + (boxSize - tpDigit.height) / 2));
    }
  }

  void _drawVictoryBanner(Canvas canvas) {
    const bannerTop = 535.0;
    const bannerH = 65.0;
    final bannerW = math.max(440.0, width - 100.0);

    final bannerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(50, bannerTop, bannerW, bannerH),
      const Radius.circular(12),
    );

    // Green celebration fill
    canvas.drawRRect(
      bannerRRect,
      Paint()..color = const Color(0xFFDCFCE7), // green-100
    );
    canvas.drawRRect(
      bannerRRect,
      Paint()
        ..color = _greenAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Check icon representation
    final iconPaint = Paint()
      ..color = _greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(70, bannerTop + 33), const Offset(76, bannerTop + 40), iconPaint);
    canvas.drawLine(const Offset(76, bannerTop + 40), const Offset(88, bannerTop + 24), iconPaint);

    final tpDone = TextPainter(
      text: TextSpan(
        text: '$a  ×  $b  =  ${a * b}',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _greenAccent,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpDone.paint(canvas, const Offset(98, bannerTop + 14));

    final tpNote = TextPainter(
      text: const TextSpan(
        text: 'Calculated directly in a single row — no intermediate scratch lines!',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF15803D), // green-700
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpNote.paint(canvas, const Offset(98, bannerTop + 38));
  }

  @override
  bool shouldRepaint(covariant _MultiplicationDiagramPainter oldDelegate) {
    return oldDelegate.a != a ||
        oldDelegate.b != b ||
        oldDelegate.steps != steps;
  }
}
