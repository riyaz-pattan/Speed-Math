// lib/features/learn/widgets/division_static_diagram.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// Step data representation for Division shortcut visual cards.
class DivisionStepData {
  const DivisionStepData({
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

/// Computes the step cards for any division shortcut problem.
List<DivisionStepData> computeDivisionSteps({
  required String lessonId,
  required int dividend,
  required num divisor,
}) {
  final n = dividend;
  final d = divisor;

  switch (lessonId) {
    case 'divide_by_5_25':
      if (d == 125) {
        final x8 = n * 8;
        final resStr = (x8 % 1000 == 0) ? '${x8 ~/ 1000}' : '${x8 / 1000}';
        return [
          const DivisionStepData(
            stepNumber: 1,
            title: 'Inversion Principle',
            badge: '÷ 125  ≡  (× 8) ÷ 1000',
            mainFormula: '125 = 1000 ÷ 8',
            explanation:
                'Instead of dividing by 125, multiply the dividend by 8, then divide by 1,000.',
            resultHighlight: 'Multiply by 8 then shift decimal 3 places left',
          ),
          DivisionStepData(
            stepNumber: 2,
            title: 'Triple Double (× 8)',
            badge: '$n × 8 = $x8',
            mainFormula: '$n × 2 = ${n * 2} → ${n * 4} → $x8',
            explanation:
                'Mentally double three times:\n1st double: ${n * 2}\n2nd double: ${n * 4}\n3rd double: $x8',
            resultHighlight: '$n × 8 = $x8',
          ),
          DivisionStepData(
            stepNumber: 3,
            title: 'Shift Decimal 3 Places Left',
            badge: '$x8 ÷ 1000 = $resStr',
            mainFormula: '$x8 ÷ 1000 = $resStr',
            explanation:
                'Move the decimal point 3 places to the left:\n$x8  →  $resStr',
            resultHighlight: '$n ÷ 125 = $resStr',
            isFinal: true,
          ),
        ];
      } else if (d == 25) {
        final x4 = n * 4;
        final resStr = (x4 % 100 == 0) ? '${x4 ~/ 100}' : '${x4 / 100}';
        return [
          const DivisionStepData(
            stepNumber: 1,
            title: 'Inversion Principle',
            badge: '÷ 25  ≡  (× 4) ÷ 100',
            mainFormula: '25 = 100 ÷ 4',
            explanation:
                'Instead of dividing by 25, multiply by 4 (double twice), then divide by 100.',
            resultHighlight: 'Multiply by 4 then shift decimal 2 places left',
          ),
          DivisionStepData(
            stepNumber: 2,
            title: 'Double Twice (× 4)',
            badge: '$n × 4 = $x4',
            mainFormula: '$n × 2 = ${n * 2}  →  ${n * 2} × 2 = $x4',
            explanation:
                '1st double: $n × 2 = ${n * 2}\n2nd double: ${n * 2} × 2 = $x4',
            resultHighlight: '$n × 4 = $x4',
          ),
          DivisionStepData(
            stepNumber: 3,
            title: 'Shift Decimal 2 Places Left',
            badge: '$x4 ÷ 100 = $resStr',
            mainFormula: '$x4 ÷ 100 = $resStr',
            explanation:
                'Move the decimal point 2 places left:\n$x4  →  $resStr',
            resultHighlight: '$n ÷ 25 = $resStr',
            isFinal: true,
          ),
        ];
      } else {
        // Default d == 5
        final x2 = n * 2;
        final resStr = (x2 % 10 == 0) ? '${x2 ~/ 10}' : '${x2 / 10}';
        return [
          const DivisionStepData(
            stepNumber: 1,
            title: 'Inversion Principle',
            badge: '÷ 5  ≡  (× 2) ÷ 10',
            mainFormula: '5 = 10 ÷ 2',
            explanation:
                'Dividing by 5 is identical to doubling the number and shifting the decimal point 1 place left.',
            resultHighlight: 'Multiply by 2 then shift decimal 1 place left',
          ),
          DivisionStepData(
            stepNumber: 2,
            title: 'Double the Number (× 2)',
            badge: '$n × 2 = $x2',
            mainFormula: '$n × 2 = $x2',
            explanation:
                'Double each place value from left to right:\n$n × 2 = $x2',
            resultHighlight: 'Doubled = $x2',
          ),
          DivisionStepData(
            stepNumber: 3,
            title: 'Shift Decimal 1 Place Left',
            badge: '$x2 ÷ 10 = $resStr',
            mainFormula: '$x2 ÷ 10 = $resStr',
            explanation:
                'Move the decimal point 1 place left:\n$x2  →  $resStr',
            resultHighlight: '$n ÷ 5 = $resStr',
            isFinal: true,
          ),
        ];
      }

    case 'divide_by_9_99':
      final intDiv = d.toInt();
      if (intDiv == 99) {
        final quotient = n ~/ 99;
        final rem = n % 99;
        return [
          const DivisionStepData(
            stepNumber: 1,
            title: 'Vedic 2-Digit Sum Rule',
            badge: 'All from 9 and last from 10',
            mainFormula: '99 = 100 − 1',
            explanation:
                'Split the dividend into 2-digit pairs from the right and add running sums.',
            resultHighlight: '2-digit block running addition',
          ),
          DivisionStepData(
            stepNumber: 2,
            title: 'Compute 2-Digit Running Sums',
            badge: 'Quotient = $quotient',
            mainFormula: '$n ÷ 99 = $quotient R $rem',
            explanation:
                'Running block sum gives:\nQuotient = $quotient\nRemainder = $rem',
            resultHighlight: 'Quotient = $quotient,  Rem = $rem',
          ),
          DivisionStepData(
            stepNumber: 3,
            title: 'Assembly & Exact Result',
            badge: '$n ÷ 99 = $quotient.${rem.toString().padLeft(2, "0")}...',
            mainFormula: '$quotient + $rem/99',
            explanation:
                'Since $rem/99 = 0.${rem.toString().padLeft(2, "0")}$rem..., the decimal repeats seamlessly.',
            resultHighlight: '$n ÷ 99 = $quotient R $rem',
            isFinal: true,
          ),
        ];
      } else {
        // d == 9
        final digits = '$n'.split('').map(int.parse).toList();
        final running = <int>[];
        var curr = 0;
        for (final digit in digits) {
          curr += digit;
          running.add(curr);
        }
        final quotient = n ~/ 9;
        final rem = n % 9;
        return [
          const DivisionStepData(
            stepNumber: 1,
            title: 'Vedic Running Sum Setup',
            badge: 'Quotient = Running Digit Sums',
            mainFormula: '1/9 = 0.1111...',
            explanation:
                'No long division needed! Bring down the 1st digit, then add each subsequent digit to the running sum.',
            resultHighlight: 'Bring down 1st digit → add continuously',
          ),
          DivisionStepData(
            stepNumber: 2,
            title: 'Running Sum Cascade',
            badge: 'Digits: ${digits.join(" + ")}',
            mainFormula: 'Sums: ${running.join(" → ")}',
            explanation:
                'Cascade breakdown:\n${List.generate(digits.length, (i) {
                  return i == 0
                      ? '1st: ${digits[0]}'
                      : 'Step ${i + 1}: ${running[i - 1]} + ${digits[i]} = ${running[i]}';
                }).join('\n')}',
            resultHighlight: 'Last sum is Remainder = $rem',
          ),
          DivisionStepData(
            stepNumber: 3,
            title: 'Final Quotient & Remainder',
            badge: '$n ÷ 9 = $quotient R $rem',
            mainFormula: 'Quotient = $quotient,  Rem = $rem',
            explanation:
                'Combine quotient digits and remainder:\n$n ÷ 9 = $quotient with remainder $rem  ($quotient.${rem}66...)',
            resultHighlight: '$n ÷ 9 = $quotient R $rem',
            isFinal: true,
          ),
        ];
      }

    case 'factor_division':
      final intDiv = d.toInt();
      // Decompose into f1 and f2
      int f1 = 9;
      int f2 = 5;
      for (int i = 9; i >= 2; i--) {
        if (intDiv % i == 0 && (intDiv ~/ i) <= 9) {
          f1 = i;
          f2 = intDiv ~/ i;
          break;
        }
      }
      final q1 = n ~/ f1;
      final finalQ = q1 ~/ f2;
      final rem = n % intDiv;
      return [
        DivisionStepData(
          stepNumber: 1,
          title: 'Factor Decomposition',
          badge: '$intDiv = $f1 × $f2',
          mainFormula: '$intDiv = $f1 × $f2',
          explanation:
              'Decompose the 2-digit composite divisor $intDiv into single-digit factors $f1 and $f2.',
          resultHighlight: 'Split into $f1 and $f2',
        ),
        DivisionStepData(
          stepNumber: 2,
          title: 'First Division (÷ $f1)',
          badge: '$n ÷ $f1 = $q1',
          mainFormula: '$n ÷ $f1 = $q1',
          explanation:
              'Divide the dividend by the first single-digit factor:\n$n ÷ $f1 = $q1',
          resultHighlight: 'Intermediate = $q1',
        ),
        DivisionStepData(
          stepNumber: 3,
          title: 'Second Division (÷ $f2)',
          badge: '$q1 ÷ $f2 = $finalQ',
          mainFormula: '$q1 ÷ $f2 = $finalQ ${rem > 0 ? "R $rem" : ""}',
          explanation:
              'Divide the intermediate result by the second factor:\n$q1 ÷ $f2 = $finalQ\n\nNo multi-digit scratch division needed!',
          resultHighlight: '$n ÷ $intDiv = $finalQ',
          isFinal: true,
        ),
      ];

    case 'reciprocal_division':
      final doubleDiv = d.toDouble();
      num multiplier = 4;
      num postDivisor = 10;
      if ((doubleDiv - 0.5).abs() < 0.01) {
        multiplier = 2;
        postDivisor = 1;
      } else if ((doubleDiv - 0.25).abs() < 0.01) {
        multiplier = 4;
        postDivisor = 1;
      } else if ((doubleDiv - 0.2).abs() < 0.01) {
        multiplier = 5;
        postDivisor = 1;
      } else if ((doubleDiv - 0.125).abs() < 0.01) {
        multiplier = 8;
        postDivisor = 1;
      } else if ((doubleDiv - 2.5).abs() < 0.01) {
        multiplier = 4;
        postDivisor = 10;
      }

      final multiplied = n * multiplier;
      final finalRes = (postDivisor == 1) ? multiplied : (multiplied / postDivisor);
      final finalStr = (finalRes == finalRes.truncate()) ? '${finalRes.truncate()}' : '$finalRes';

      return [
        DivisionStepData(
          stepNumber: 1,
          title: 'Reciprocal Principle',
          badge: '÷ $d  ≡  × $multiplier ${postDivisor > 1 ? "÷ $postDivisor" : ""}',
          mainFormula: '1 / $d = ${1 / doubleDiv}',
          explanation:
              'Dividing by a decimal fraction is converted into whole-number multiplication.',
          resultHighlight: 'Multiply by $multiplier ${postDivisor > 1 ? "and divide by $postDivisor" : ""}',
        ),
        DivisionStepData(
          stepNumber: 2,
          title: 'Mental Whole Multiplication',
          badge: '$n × $multiplier = $multiplied',
          mainFormula: '$n × $multiplier = $multiplied',
          explanation:
              'Perform single-digit multiplication:\n$n × $multiplier = $multiplied',
          resultHighlight: 'Product = $multiplied',
        ),
        DivisionStepData(
          stepNumber: 3,
          title: 'Decimal Normalization',
          badge: '$multiplied ${postDivisor > 1 ? "÷ $postDivisor = $finalStr" : "= $finalStr"}',
          mainFormula: '$n ÷ $d = $finalStr',
          explanation:
              'Adjust the decimal point:\n$multiplied ${postDivisor > 1 ? "÷ $postDivisor = $finalStr" : "= $finalStr"}',
          resultHighlight: '$n ÷ $d = $finalStr',
          isFinal: true,
        ),
      ];

    case 'flag_division':
      final intDiv = d.toInt();
      final baseDiv = intDiv ~/ 10;
      final flag = intDiv % 10;
      final quotient = n ~/ intDiv;
      final rem = n % intDiv;
      return [
        DivisionStepData(
          stepNumber: 1,
          title: 'Set Base & Flag Digits',
          badge: 'Base: $baseDiv, Flag: ^$flag',
          mainFormula: 'Divisor $intDiv → Base $baseDiv, Flag ^$flag',
          explanation:
              'Split the 2-digit divisor into Main Divisor ($baseDiv) and Flag Digit ($flag).',
          resultHighlight: 'Main Divisor = $baseDiv, Flag = $flag',
        ),
        DivisionStepData(
          stepNumber: 2,
          title: 'Single-Line Straight Division',
          badge: 'Divide by $baseDiv, Adjust by Flag',
          mainFormula: 'Divide by $baseDiv → Subtract (Flag × Q)',
          explanation:
              'Step 1: Divide by Base ($baseDiv).\nStep 2: Adjust working remainder by subtracting (Flag $flag × Quotient digit).',
          resultHighlight: 'Quotient = $quotient',
        ),
        DivisionStepData(
          stepNumber: 3,
          title: 'Final Result Assembly',
          badge: '$n ÷ $intDiv = $quotient R $rem',
          mainFormula: '$n ÷ $intDiv = $quotient R $rem',
          explanation:
              'Check: $intDiv × $quotient + $rem = ${intDiv * quotient + rem} ✓\nCompleted without any scratchpad long division lines.',
          resultHighlight: '$n ÷ $intDiv = $quotient R $rem',
          isFinal: true,
        ),
      ];

    default:
      final q = n ~/ d;
      final rem = (n % d).toInt();
      return [
        DivisionStepData(
          stepNumber: 1,
          title: 'Division Shortcut',
          badge: '$n ÷ $d',
          mainFormula: '$n ÷ $d = $q R $rem',
          explanation: 'Standard speed division calculation.',
          resultHighlight: '$n ÷ $d = $q',
          isFinal: true,
        ),
      ];
  }
}

/// Interactive Static Ruled Notebook Diagram for all Division Shortcuts.
class DivisionStaticDiagram extends StatefulWidget {
  const DivisionStaticDiagram({
    super.key,
    required this.lessonId,
    required this.dividend,
    required this.divisor,
  });

  final String lessonId;
  final int dividend;
  final num divisor;

  static const double cardWidth = 320.0;
  static const double cardGap = 20.0;
  static const double marginLeft = 50.0;

  @override
  State<DivisionStaticDiagram> createState() => _DivisionStaticDiagramState();
}

class _DivisionStaticDiagramState extends State<DivisionStaticDiagram> {
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
    final steps = computeDivisionSteps(
      lessonId: widget.lessonId,
      dividend: widget.dividend,
      divisor: widget.divisor,
    );

    const cardW = DivisionStaticDiagram.cardWidth;
    const gap = DivisionStaticDiagram.cardGap;
    const leftMargin = DivisionStaticDiagram.marginLeft;

    final canvasWidth =
        leftMargin + steps.length * cardW + (steps.length - 1) * gap + 100.0;
    const canvasHeight = 620.0;

    return Stack(
      children: [
        // Interactive 2D pan and pinch-to-zoom
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(120),
          constrained: false,
          child: Container(
            width: canvasWidth,
            height: canvasHeight,
            color: const Color(0xFFFFFDF5), // Cream notebook paper
            child: CustomPaint(
              size: Size(canvasWidth, canvasHeight),
              painter: _DivisionDiagramPainter(
                lessonId: widget.lessonId,
                dividend: widget.dividend,
                divisor: widget.divisor,
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
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(_currentScale * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
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

class _DivisionDiagramPainter extends CustomPainter {
  const _DivisionDiagramPainter({
    required this.lessonId,
    required this.dividend,
    required this.divisor,
    required this.steps,
    required this.width,
    required this.height,
  });

  final String lessonId;
  final int dividend;
  final num divisor;
  final List<DivisionStepData> steps;
  final double width;
  final double height;

  static const Color _lineRuleColor = Color(0xFFFDE68A); // amber-200
  static const Color _marginLineColor = Color(0xFFFCA5A5); // rose-300
  static const Color _themeAmber = Color(0xFFD97706);
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
      ..color = _themeAmber.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 24, 280, 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, titlePaint);

    final titleBorder = Paint()
      ..color = _themeAmber.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, titleBorder);

    final tpTitle = TextPainter(
      text: const TextSpan(
        text: 'SPEED DIVISION SHORTCUT BOARD',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _themeAmber,
          letterSpacing: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpTitle.paint(canvas, const Offset(64, 30));

    // Equation
    final dStr = divisor == divisor.truncate() ? '${divisor.truncate()}' : '$divisor';
    final tpEq = TextPainter(
      text: TextSpan(
        text: '$dividend  ÷  $dStr  =  ${_computeAnswer()}',
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
        text: 'Interactive mental arithmetic breakdown • Zero long division scratchpad needed',
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

  String _computeAnswer() {
    if (divisor == 0) return '0';
    final res = dividend / divisor;
    return (res == res.truncate()) ? '${res.truncate()}' : res.toStringAsFixed(2);
  }

  void _drawStepCards(Canvas canvas) {
    const cardTop = 130.0;
    const cardH = 390.0;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final cardLeft = DivisionStaticDiagram.marginLeft +
          i * (DivisionStaticDiagram.cardWidth + DivisionStaticDiagram.cardGap);

      _drawSingleCard(canvas, cardLeft, cardTop,
          DivisionStaticDiagram.cardWidth, cardH, step);
    }

    // Draw connecting arrows between step cards
    for (int i = 0; i < steps.length - 1; i++) {
      final cardLeft1 = DivisionStaticDiagram.marginLeft +
          i * (DivisionStaticDiagram.cardWidth + DivisionStaticDiagram.cardGap);
      final cardLeft2 = cardLeft1 +
          DivisionStaticDiagram.cardWidth +
          DivisionStaticDiagram.cardGap;

      _drawConnectingStepArrow(
        canvas,
        fromCardLeft: cardLeft1,
        toCardLeft: cardLeft2,
        cardTop: cardTop,
        cardW: DivisionStaticDiagram.cardWidth,
        stepNum: i + 1,
      );
    }
  }

  void _drawSingleCard(Canvas canvas, double left, double top, double w,
      double h, DivisionStepData step) {
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
        : const Color(0xFFFEF3C7);
    final headerTextColor =
        step.isFinal ? _greenAccent : _themeAmber;

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
      Rect.fromLTWH(left + 14, top + 52, w - 28, 80),
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
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: _blueAccent,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 40);
    tpFormula.paint(canvas, Offset(left + 22, top + 64));

    final tpBadge = TextPainter(
      text: TextSpan(
        text: step.badge,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _themeAmber.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 40);
    tpBadge.paint(canvas, Offset(left + 22, top + 98));

    // Working & Mental Explanation Box
    final expRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 14, top + 144, w - 28, 140),
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
    tpLabel.paint(canvas, Offset(left + 22, top + 154));

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
    tpExp.paint(canvas, Offset(left + 22, top + 174));

    // Result Highlight Strip at bottom of card
    final resRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 14, top + 296, w - 28, 76),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      resRRect,
      Paint()
        ..color = step.isFinal
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFFFBEB),
    );
    canvas.drawRRect(
      resRRect,
      Paint()
        ..color = step.isFinal
            ? const Color(0xFF86EFAC)
            : const Color(0xFFFDE68A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final tpResLabel = TextPainter(
      text: TextSpan(
        text: step.isFinal ? 'Final Answer:' : 'Step ${step.stepNumber} Result:',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: step.isFinal ? const Color(0xFF15803D) : const Color(0xFFB45309),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpResLabel.paint(canvas, Offset(left + 24, top + 306));

    final tpRes = TextPainter(
      text: TextSpan(
        text: step.resultHighlight,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: step.isFinal ? _greenAccent : AppTheme.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 48);
    tpRes.paint(canvas, Offset(left + 24, top + 326));
  }

  void _drawConnectingStepArrow(
    Canvas canvas, {
    required double fromCardLeft,
    required double toCardLeft,
    required double cardTop,
    required double cardW,
    required int stepNum,
  }) {
    final startX = fromCardLeft + cardW - 6;
    final startY = cardTop + 334;
    final endX = toCardLeft + 6;
    final endY = cardTop + 90;

    final path = Path()..moveTo(startX, startY);
    final cp1 = Offset(startX + 25, startY);
    final cp2 = Offset(endX - 25, endY);
    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, endX, endY);

    final curvePaint = Paint()
      ..color = _themeAmber.withValues(alpha: 0.8)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, curvePaint);

    // Arrowhead at endX, endY
    const headLen = 8.0;
    final angle = math.atan2(endY - cp2.dy, endX - cp2.dx);
    final headPaint = Paint()
      ..color = _themeAmber
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
  }

  void _drawVictoryBanner(Canvas canvas) {
    const bannerTop = 535.0;
    const bannerH = 65.0;
    final bannerW = math.max(440.0, width - 100.0);

    final bannerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(50, bannerTop, bannerW, bannerH),
      const Radius.circular(12),
    );

    canvas.drawRRect(bannerRRect, Paint()..color = const Color(0xFFDCFCE7));
    canvas.drawRRect(
      bannerRRect,
      Paint()
        ..color = _greenAccent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final iconPaint = Paint()
      ..color = _greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(70, bannerTop + 33), const Offset(76, bannerTop + 40), iconPaint);
    canvas.drawLine(const Offset(76, bannerTop + 40), const Offset(88, bannerTop + 24), iconPaint);

    final dStr = divisor == divisor.truncate() ? '${divisor.truncate()}' : '$divisor';
    final tpDone = TextPainter(
      text: TextSpan(
        text: '$dividend  ÷  $dStr  =  ${_computeAnswer()}',
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
        text: 'Solved using pure mental arithmetic — fast, verified, and scratchpad-free!',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF15803D),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpNote.paint(canvas, const Offset(98, bannerTop + 38));
  }

  @override
  bool shouldRepaint(covariant _DivisionDiagramPainter oldDelegate) {
    return oldDelegate.dividend != dividend ||
        oldDelegate.divisor != divisor ||
        oldDelegate.steps != steps ||
        oldDelegate.lessonId != lessonId;
  }
}
