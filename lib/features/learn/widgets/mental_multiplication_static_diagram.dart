// lib/features/learn/widgets/mental_multiplication_static_diagram.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// Step data representation for Mental Multiplication shortcut visual cards.
class MentalMultStepData {
  const MentalMultStepData({
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

/// Helper methods for step computations
String _formatNum(num v) =>
    (v == v.truncate()) ? '${v.truncate()}' : v.toStringAsFixed(2);

String _signStr(int d) => d >= 0 ? '+ $d' : '− ${d.abs()}';
String _devStr(int d) => d >= 0 ? '+$d' : '$d';
String _devDesc(int d) =>
    d >= 0 ? '$d above 100 (+ $d)' : '${d.abs()} below 100 (− ${d.abs()})';

/// Computes the step cards for any mental multiplication shortcut problem.
List<MentalMultStepData> computeMentalMultSteps({
  required String lessonId,
  required int first,
  required int second,
}) {
  final n = first;
  final m = second;

  switch (lessonId) {
    case 'multiply_by_5_25':
      if (m == 125) {
        final half = n / 2;
        final quarter = n / 4;
        final eighth = n / 8;
        final eighthStr = _formatNum(eighth);
        final result = n * 125;
        return [
          const MentalMultStepData(
            stepNumber: 1,
            title: 'Inversion Principle',
            badge: '× 125  ≡  (÷ 8) × 1,000',
            mainFormula: '125 = 1,000 ÷ 8',
            explanation:
                'Instead of multiplying by 125, divide by 8 (halve three times), then multiply by 1,000 (shift 3 decimal places right).',
            resultHighlight: 'Halve 3 times then shift decimal 3 places right',
          ),
          MentalMultStepData(
            stepNumber: 2,
            title: 'Triple Halving (÷ 8)',
            badge: '$n ÷ 8 = $eighthStr',
            mainFormula: '$n → ${_formatNum(half)} → ${_formatNum(quarter)} → $eighthStr',
            explanation:
                'Mentally halve three times:\n1st half: $n ÷ 2 = ${_formatNum(half)}\n2nd half: ${_formatNum(half)} ÷ 2 = ${_formatNum(quarter)}\n3rd half: ${_formatNum(quarter)} ÷ 2 = $eighthStr',
            resultHighlight: 'Working quotient = $eighthStr',
          ),
          MentalMultStepData(
            stepNumber: 3,
            title: 'Shift Decimal 3 Places Right',
            badge: '$eighthStr × 1,000 = $result',
            mainFormula: '$n × 125 = $result',
            explanation:
                'Shift the decimal point 3 places to the right:\n$eighthStr × 1,000 = $result ✓\nComputed entirely in memory!',
            resultHighlight: '$n × 125 = $result',
            isFinal: true,
          ),
        ];
      } else if (m == 75) {
        final quarter = n / 4;
        final quarterStr = _formatNum(quarter);
        final threeQ = (n * 3) / 4;
        final threeQStr = _formatNum(threeQ);
        final result = n * 75;
        return [
          MentalMultStepData(
            stepNumber: 1,
            title: 'Quarter & Triple Shortcut',
            badge: '× 75  ≡  (÷ 4 × 3) × 100',
            mainFormula: '75 = 300 ÷ 4 = (3/4) × 100',
            explanation:
                '75 is 3 quarters of 100. Divide by 4 to get one quarter, triple it to get 3 quarters, then multiply by 100.',
            resultHighlight: 'Find 3/4 of $n then append two zeros',
          ),
          MentalMultStepData(
            stepNumber: 2,
            title: 'Quarter & Triple',
            badge: '($n ÷ 4) × 3 = $threeQStr',
            mainFormula: '$n ÷ 4 = $quarterStr  →  $quarterStr × 3 = $threeQStr',
            explanation:
                '1. Quarter $n: $n ÷ 4 = $quarterStr\n2. Triple: $quarterStr × 3 = $threeQStr\nThree quarters of $n is $threeQStr.',
            resultHighlight: '3/4 Value = $threeQStr',
          ),
          MentalMultStepData(
            stepNumber: 3,
            title: 'Shift Decimal 2 Places Right',
            badge: '$threeQStr × 100 = $result',
            mainFormula: '$n × 75 = $result',
            explanation:
                'Shift the decimal point 2 places to the right:\n$threeQStr × 100 = $result ✓\nLightning fast without scratchpad.',
            resultHighlight: '$n × 75 = $result',
            isFinal: true,
          ),
        ];
      } else if (m == 25) {
        final quarter = n / 4;
        final quarterStr = _formatNum(quarter);
        final result = n * 25;
        return [
          const MentalMultStepData(
            stepNumber: 1,
            title: 'Inversion Principle',
            badge: '× 25  ≡  (÷ 4) × 100',
            mainFormula: '25 = 100 ÷ 4',
            explanation:
                'Instead of multiplying by 25, divide by 4 (halve twice), then multiply by 100 (shift decimal 2 places right).',
            resultHighlight: 'Halve twice then shift decimal 2 places right',
          ),
          MentalMultStepData(
            stepNumber: 2,
            title: 'Halve Twice (÷ 4)',
            badge: '$n ÷ 4 = $quarterStr',
            mainFormula: '$n ÷ 2 = ${_formatNum(n / 2)}  →  ${_formatNum(n / 2)} ÷ 2 = $quarterStr',
            explanation:
                '1st half: $n ÷ 2 = ${_formatNum(n / 2)}\n2nd half: ${_formatNum(n / 2)} ÷ 2 = $quarterStr\nDividing by 4 is two instant mental halvings.',
            resultHighlight: 'Quarter = $quarterStr',
          ),
          MentalMultStepData(
            stepNumber: 3,
            title: 'Shift Decimal 2 Places Right',
            badge: '$quarterStr × 100 = $result',
            mainFormula: '$n × 25 = $result',
            explanation:
                'Shift the decimal point 2 places to the right (or append two zeros):\n$quarterStr × 100 = $result ✓',
            resultHighlight: '$n × 25 = $result',
            isFinal: true,
          ),
        ];
      } else {
        // Default m == 5
        final half = n / 2;
        final halfStr = _formatNum(half);
        final result = n * 5;
        return [
          MentalMultStepData(
            stepNumber: 1,
            title: 'Inversion Principle',
            badge: '× 5  ≡  (÷ 2) × 10',
            mainFormula: '5 = 10 ÷ 2',
            explanation:
                'Instead of multiplying by 5, halve the number first, then multiply by 10 (or append a zero). Halving is 3× faster.',
            resultHighlight: 'Halve $n then shift decimal 1 place right',
          ),
          MentalMultStepData(
            stepNumber: 2,
            title: 'Mental Halving (÷ 2)',
            badge: '$n ÷ 2 = $halfStr',
            mainFormula: '$n ÷ 2 = $halfStr',
            explanation: n % 2 == 0
                ? 'Since $n is even, dividing by 2 gives whole number $halfStr.'
                : '$n is odd: ($n − 1) ÷ 2 = ${(n - 1) ~/ 2}, plus 0.5 gives $halfStr.',
            resultHighlight: 'Half = $halfStr',
          ),
          MentalMultStepData(
            stepNumber: 3,
            title: 'Multiply by 10 (Shift Right)',
            badge: '$halfStr × 10 = $result',
            mainFormula: '$n × 5 = $result',
            explanation:
                'Shift the decimal point 1 place to the right (or add a zero):\n$halfStr × 10 = $result ✓',
            resultHighlight: '$n × 5 = $result',
            isFinal: true,
          ),
        ];
      }

    case 'multiply_by_11':
      final result = n * 11;
      if (n >= 10 && n <= 99) {
        final tens = n ~/ 10;
        final ones = n % 10;
        final sum = tens + ones;
        final hasCarry = sum >= 10;
        final midDigit = sum % 10;
        final finalTens = hasCarry ? tens + 1 : tens;

        return [
          MentalMultStepData(
            stepNumber: 1,
            title: 'Outer Frame Setup',
            badge: 'Outer Digits: $tens [__] $ones',
            mainFormula: 'Frame: $tens  [ __ ]  $ones',
            explanation:
                'Place the first digit ($tens) on the left and the last digit ($ones) on the right, leaving an open blank in the middle.',
            resultHighlight: 'Outer Frame: $tens  _  $ones',
          ),
          MentalMultStepData(
            stepNumber: 2,
            title: hasCarry ? 'Adjacent Sum & Carry' : 'Adjacent Digit Sum',
            badge: '$tens + $ones = $sum ${hasCarry ? "(Carry 1)" : ""}',
            mainFormula: hasCarry
                ? '$tens + $ones = $sum  →  Write $midDigit, Carry 1'
                : '$tens + $ones = $sum  (No Carry)',
            explanation: hasCarry
                ? 'Sum the two digits: $tens + $ones = $sum.\nSince $sum ≥ 10, write $midDigit in the middle blank and carry 1 to $tens ($tens + 1 = $finalTens).'
                : 'Sum the two digits: $tens + $ones = $sum.\nSince $sum < 10, no carry is required. Drop $sum directly into the middle blank!',
            resultHighlight: hasCarry
                ? 'Left becomes $finalTens, Middle digit is $midDigit'
                : 'Middle digit = $sum',
          ),
          MentalMultStepData(
            stepNumber: 3,
            title: 'Final Product Assembly',
            badge: '$finalTens | ${hasCarry ? midDigit : sum} | $ones = $result',
            mainFormula: '$n × 11 = $result',
            explanation: hasCarry
                ? 'Assemble the adjusted digits:\nLeft ($finalTens) + Middle ($midDigit) + Right ($ones) = $result ✓'
                : 'Assemble the digits:\nLeft ($tens) + Middle ($sum) + Right ($ones) = $result ✓',
            resultHighlight: '$n × 11 = $result',
            isFinal: true,
          ),
        ];
      } else {
        // Multi-digit n (e.g. 3-digit)
        final digits = '$n'.split('').map(int.parse).toList();
        return [
          MentalMultStepData(
            stepNumber: 1,
            title: 'Outer Ends Fixed',
            badge: 'First: ${digits.first}, Last: ${digits.last}',
            mainFormula: 'Outer Digits: ${digits.first} [ ... ] ${digits.last}',
            explanation:
                'For multi-digit numbers multiplied by 11, the first digit (${digits.first}) and last digit (${digits.last}) anchor the outside boundaries.',
            resultHighlight: 'Outer anchors: ${digits.first} ... ${digits.last}',
          ),
          MentalMultStepData(
            stepNumber: 2,
            title: 'Adjacent Neighbor Additions',
            badge: 'Add consecutive digit pairs',
            mainFormula: 'Sum pairs right-to-left with carry',
            explanation:
                'Moving from right to left, add each adjacent pair of digits and carry any tens value forward to the next pair on the left.',
            resultHighlight: 'Single-line mental addition cascade',
          ),
          MentalMultStepData(
            stepNumber: 3,
            title: 'Final Product Assembly',
            badge: '$n × 11 = $result',
            mainFormula: '$n × 11 = $result',
            explanation:
                'All adjacent digit sums and carries resolve into the final product:\n$n × 11 = $result ✓',
            resultHighlight: '$n × 11 = $result',
            isFinal: true,
          ),
        ];
      }

    case 'multiply_by_99':
      final k = (m == 9) ? 1 : (m == 999 ? 3 : 2);
      final base = (m == 9) ? 10 : (m == 999 ? 1000 : 100);
      final scaled = n * base;
      final result = n * m;
      final complement = base - n;
      final compStr = complement >= 0
          ? (complement < 10 && k > 1 ? '0$complement' : '$complement')
          : '(${complement.abs()} deficit)';

      final steps = <MentalMultStepData>[
        MentalMultStepData(
          stepNumber: 1,
          title: 'Round-Up Identity',
          badge: '$m  ≡  $base − 1',
          mainFormula: '$n × $m = $n × ($base − 1)',
          explanation:
              'Multiplying by $m is equivalent to multiplying by $base (instant zero append) then subtracting the original number $n once.',
          resultHighlight: 'Formula: ($n × $base) − $n',
        ),
        MentalMultStepData(
          stepNumber: 2,
          title: 'Base Shift (× $base)',
          badge: '$n × $base = $scaled',
          mainFormula: '$n × $base = $scaled',
          explanation:
              'Multiply by $base by simply appending $k zero${k > 1 ? "s" : ""}:\n$n  →  $scaled\nInstant operation requiring zero mental strain.',
          resultHighlight: 'Base Product = $scaled',
        ),
        MentalMultStepData(
          stepNumber: 3,
          title: 'Mental Subtraction (Left-to-Right)',
          badge: '$scaled − $n = $result',
          mainFormula: '$scaled − $n = $result',
          explanation:
              'Subtract $n from $scaled mentally from left to right:\n• Start with $scaled\n• Subtract tens: $scaled − ${(n ~/ 10) * 10} = ${scaled - (n ~/ 10) * 10}\n• Subtract units: ${scaled - (n ~/ 10) * 10} − ${n % 10} = $result',
          resultHighlight: '$n × $m = $result',
          isFinal: complement < 0,
        ),
      ];

      if (complement >= 0) {
        steps.add(
          MentalMultStepData(
            stepNumber: 4,
            title: 'Dual Check (Vedic Complement)',
            badge: 'One Less: ${n - 1} | Comp: $compStr',
            mainFormula: 'Left: $n − 1 = ${n - 1}  |  Right: $compStr',
            explanation:
                'Vedic "By One Less than Before" confirms the answer:\n• Left part: $n − 1 = ${n - 1}\n• Right part: $base − $n = $compStr\nCombined: ${n - 1}$compStr = $result ✓',
            resultHighlight: '$n × $m = $result',
            isFinal: true,
          ),
        );
      }

      return steps;

    case 'near_100_mult':
      final deltaA = n - 100;
      final deltaB = m - 100;
      final leftPart = n + deltaB; // same as m + deltaA
      final rightPart = deltaA * deltaB;
      final result = n * m;

      final rightStr = (rightPart >= 0 && rightPart < 10)
          ? '0$rightPart'
          : '$rightPart';

      return [
        MentalMultStepData(
          stepNumber: 1,
          title: 'Base-100 Deviations',
          badge: 'ΔA: ${_devStr(deltaA)}, ΔB: ${_devStr(deltaB)}',
          mainFormula: '$n = 100 ${_signStr(deltaA)}  |  $m = 100 ${_signStr(deltaB)}',
          explanation:
              'Find how far each number is from base 100:\n• $n is ${_devDesc(deltaA)}\n• $m is ${_devDesc(deltaB)}\nDeviations are small and effortless to manipulate.',
          resultHighlight: 'Deviations: ${_devStr(deltaA)} and ${_devStr(deltaB)}',
        ),
        MentalMultStepData(
          stepNumber: 2,
          title: 'Cross Operation (Left Part)',
          badge: 'Cross Sum: $leftPart',
          mainFormula: '$n + (${_devStr(deltaB)}) = $leftPart  ≡  $m + (${_devStr(deltaA)}) = $leftPart',
          explanation:
              'Cross-combine either number with the other’s deviation. Both cross directions produce the exact same left part:\n• $n + (${_devStr(deltaB)}) = $leftPart\n• $m + (${_devStr(deltaA)}) = $leftPart',
          resultHighlight: 'Left Part = $leftPart',
        ),
        MentalMultStepData(
          stepNumber: 3,
          title: 'Deviation Product (Right Part)',
          badge: '${_devStr(deltaA)} × ${_devStr(deltaB)} = $rightPart',
          mainFormula: '${_devStr(deltaA)} × ${_devStr(deltaB)} = $rightStr',
          explanation:
              'Multiply the deviations:\n${_devStr(deltaA)} × ${_devStr(deltaB)} = $rightPart.\nIMPORTANT: Base 100 has 2 zeros, so the right part MUST occupy exactly 2 digits.${rightPart >= 0 && rightPart < 10 ? ' Pad with a leading zero: $rightStr.' : ''}',
          resultHighlight: 'Right Part = $rightStr',
        ),
        MentalMultStepData(
          stepNumber: 4,
          title: 'Final Product Assembly',
          badge: '$leftPart | $rightStr = $result',
          mainFormula: '$n × $m = $result',
          explanation: (rightPart >= 0)
              ? 'Join the left part and 2-digit right part side by side:\n$leftPart | $rightStr  →  $result ✓\nDone entirely without standard multi-row multiplication!'
              : 'Mixed deviation product is negative ($rightPart). Subtract from left part × 100:\n($leftPart × 100) + ($rightPart) = $result ✓',
          resultHighlight: '$n × $m = $result',
          isFinal: true,
        ),
      ];

    default:
      return [
        MentalMultStepData(
          stepNumber: 1,
          title: 'Speed Multiplication',
          badge: '$n × $m',
          mainFormula: '$n × $m = ${n * m}',
          explanation: 'Standard speed arithmetic shortcut calculation.',
          resultHighlight: '$n × $m = ${n * m}',
          isFinal: true,
        ),
      ];
  }
}

/// Interactive Static Ruled Notebook Diagram for all Mental Multiplication Shortcuts.
/// Supports 2D pan, pinch-to-zoom (0.5x to 2.5x), floating zoom controls, and zero overlap.
class MentalMultiplicationStaticDiagram extends StatefulWidget {
  const MentalMultiplicationStaticDiagram({
    super.key,
    required this.lessonId,
    required this.first,
    required this.second,
  });

  final String lessonId;
  final int first;
  final int second;

  static const double cardWidth = 320.0;
  static const double cardGap = 20.0;
  static const double marginLeft = 50.0;

  @override
  State<MentalMultiplicationStaticDiagram> createState() =>
      _MentalMultiplicationStaticDiagramState();
}

class _MentalMultiplicationStaticDiagramState
    extends State<MentalMultiplicationStaticDiagram> {
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
    final steps = computeMentalMultSteps(
      lessonId: widget.lessonId,
      first: widget.first,
      second: widget.second,
    );

    final canvasWidth = MentalMultiplicationStaticDiagram.marginLeft +
        steps.length *
            (MentalMultiplicationStaticDiagram.cardWidth +
                MentalMultiplicationStaticDiagram.cardGap) +
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
              painter: _MentalMultiplicationDiagramPainter(
                lessonId: widget.lessonId,
                first: widget.first,
                second: widget.second,
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
                      color: const Color(0xFFF3E8FF), // purple-100
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(_currentScale * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C3AED),
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

class _MentalMultiplicationDiagramPainter extends CustomPainter {
  const _MentalMultiplicationDiagramPainter({
    required this.lessonId,
    required this.first,
    required this.second,
    required this.steps,
    required this.width,
    required this.height,
  });

  final String lessonId;
  final int first;
  final int second;
  final List<MentalMultStepData> steps;
  final double width;
  final double height;

  static const Color _lineRuleColor = Color(0xFFFDE68A); // amber-200
  static const Color _marginLineColor = Color(0xFFFCA5A5); // rose-300
  static const Color _purpleAccent = Color(0xFF7C3AED); // purple-600
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
      ..color = _purpleAccent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 24, 330, 28),
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
        text: 'MENTAL MULTIPLICATION SHORTCUT BOARD',
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

    // Equation
    final product = first * second;
    final tpEq = TextPainter(
      text: TextSpan(
        text: '$first  ×  $second  =  $product',
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
        text: 'Interactive mental arithmetic breakdown • Instant mental calculation without scratchpad',
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
      final cardLeft = MentalMultiplicationStaticDiagram.marginLeft +
          i * (MentalMultiplicationStaticDiagram.cardWidth + MentalMultiplicationStaticDiagram.cardGap);

      _drawSingleCard(canvas, cardLeft, cardTop,
          MentalMultiplicationStaticDiagram.cardWidth, cardH, step);
    }

    // Draw connecting arrows between step cards
    for (int i = 0; i < steps.length - 1; i++) {
      final cardLeft1 = MentalMultiplicationStaticDiagram.marginLeft +
          i * (MentalMultiplicationStaticDiagram.cardWidth + MentalMultiplicationStaticDiagram.cardGap);
      final cardLeft2 = cardLeft1 +
          MentalMultiplicationStaticDiagram.cardWidth +
          MentalMultiplicationStaticDiagram.cardGap;

      _drawConnectingStepArrow(
        canvas,
        fromCardLeft: cardLeft1,
        toCardLeft: cardLeft2,
        cardTop: cardTop,
        cardW: MentalMultiplicationStaticDiagram.cardWidth,
      );
    }
  }

  void _drawSingleCard(Canvas canvas, double left, double top, double w,
      double h, MentalMultStepData step) {
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
        : const Color(0xFFF3E8FF);
    final headerTextColor =
        step.isFinal ? _greenAccent : _purpleAccent;

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
          color: _purpleAccent.withValues(alpha: 0.9),
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
      ..color = _purpleAccent.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(startX, y), Offset(endX, y), arrowPaint);

    // Arrowhead pointing right
    final headPaint = Paint()
      ..color = _purpleAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final headPath = Path()
      ..moveTo(endX, y)
      ..lineTo(endX - 7, y - 5)
      ..lineTo(endX - 7, y + 5)
      ..close();
    canvas.drawPath(headPath, headPaint);
  }

  void _drawVictoryBanner(Canvas canvas) {
    const bannerLeft = MentalMultiplicationStaticDiagram.marginLeft;
    const bannerTop = 535.0;
    final bannerW = steps.length *
            (MentalMultiplicationStaticDiagram.cardWidth +
                MentalMultiplicationStaticDiagram.cardGap) -
        MentalMultiplicationStaticDiagram.cardGap;

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
    final product = first * second;
    final tpSummTitle = TextPainter(
      text: TextSpan(
        text: '$first  ×  $second  =  $product',
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
        text: 'Solved using pure mental arithmetic • Eliminates 3 lines of scratchpad multiplication',
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
  bool shouldRepaint(covariant _MentalMultiplicationDiagramPainter oldDelegate) {
    return oldDelegate.first != first ||
        oldDelegate.second != second ||
        oldDelegate.lessonId != lessonId ||
        oldDelegate.steps != steps;
  }
}
