// lib/features/learn/widgets/addition_static_diagram.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';

/// Place value breakdown model for a single column.
class AdditionPlaceColumn {
  const AdditionPlaceColumn({
    required this.name,
    required this.multiplier,
    required this.aPart,
    required this.bPart,
    required this.sum,
  });

  final String name;
  final int multiplier;
  final int aPart;
  final int bPart;
  final int sum;
}

/// Computes place value columns for any two positive integers A and B.
List<AdditionPlaceColumn> computeAdditionColumns(int a, int b) {
  final maxVal = math.max(a, b);
  int multiplier = 1;
  while (multiplier * 10 <= maxVal && multiplier < 100000) {
    multiplier *= 10;
  }

  final columns = <AdditionPlaceColumn>[];
  while (multiplier >= 1) {
    final aDigit = (a ~/ multiplier) % 10;
    final bDigit = (b ~/ multiplier) % 10;
    final aPart = aDigit * multiplier;
    final bPart = bDigit * multiplier;
    final sum = aPart + bPart;

    String name;
    switch (multiplier) {
      case 10000:
        name = 'Ten-Thousands';
        break;
      case 1000:
        name = 'Thousands';
        break;
      case 100:
        name = 'Hundreds';
        break;
      case 10:
        name = 'Tens';
        break;
      default:
        name = 'Units';
    }

    columns.add(AdditionPlaceColumn(
      name: name,
      multiplier: multiplier,
      aPart: aPart,
      bPart: bPart,
      sum: sum,
    ));

    multiplier ~/= 10;
  }

  return columns;
}

/// Static visual diagram for Addition shortcut.
///
/// Features:
/// - Ruled notebook paper background.
/// - Zoom In / Zoom Out (InteractiveViewer + floating buttons).
/// - Horizontal AND vertical scrolling.
/// - Generous padding preventing border and text overlaps.
/// - Branching downward arrows that bypass column header text.
/// - Downward cone-shaped converging diagonal arrows with '+' in the middle.
/// - Non-overlapping bracketed explanation text.
/// - Left-to-right mental combination steps.
class AdditionStaticDiagram extends StatefulWidget {
  const AdditionStaticDiagram({
    super.key,
    required this.a,
    required this.b,
  });

  final int a;
  final int b;

  static const double colWidth = 240.0;
  static const double marginLeft = 60.0;
  static const double marginRight = 60.0;

  @override
  State<AdditionStaticDiagram> createState() => _AdditionStaticDiagramState();
}

class _AdditionStaticDiagramState extends State<AdditionStaticDiagram> {
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
    final columns = computeAdditionColumns(widget.a, widget.b);
    final n = columns.length;
    final canvasWidth =
        AdditionStaticDiagram.marginLeft + n * AdditionStaticDiagram.colWidth + AdditionStaticDiagram.marginRight;
    final canvasHeight = 440.0 + (n - 1) * 95.0 + 140.0;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF5), // cream paper
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
              painter: _AdditionDiagramPainter(
                a: widget.a,
                b: widget.b,
                columns: columns,
                width: canvasWidth,
                height: canvasHeight,
              ),
            ),
          ),
        ),

        // Floating zoom controls & hint pill at top-right
        Positioned(
          top: 10,
          right: 10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ZoomButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Zoom out',
                      onPressed: _zoomOut,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _resetZoom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(_currentScale * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _ZoomButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Zoom in',
                      onPressed: _zoomIn,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom-left hint pill
        Positioned(
          bottom: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.pinch_rounded, size: 14, color: AppTheme.textSecondary),
                SizedBox(width: 4),
                Text(
                  'Pinch to zoom • Drag to explore',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }
}

class _AdditionDiagramPainter extends CustomPainter {
  _AdditionDiagramPainter({
    required this.a,
    required this.b,
    required this.columns,
    required this.width,
    required this.height,
  });

  final int a;
  final int b;
  final List<AdditionPlaceColumn> columns;
  final double width;
  final double height;

  static const Color _bg = Color(0xFFFFFDF5);
  static const Color _ruleColor = Color(0xFFF3E7D3);
  static const Color _marginLineColor = Color(0xFFF0D4D4);

  static const Color _tensColor = Color(0xFF2563EB); // blue
  static const Color _onesColor = Color(0xFFF97316); // orange
  static const Color _resultColor = Color(0xFF16A34A); // green
  static const Color _noteColor = Color(0xFF64748B); // warm slate
  static const Color _headingColor = Color(0xFF1E293B);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw notebook ruled lines & red left margin
    _drawNotebookPaper(canvas, size);

    // 2. Step 1 Badge & Problem header with comfortable spacing
    final topMidX = size.width / 2;
    const badgeY = 36.0;
    _drawPill(
      canvas,
      Offset(topMidX, badgeY),
      'STEP 1: BREAK DOWN BY PLACE VALUE',
      _tensColor,
      fontSize: 11,
    );

    const problemCardY = badgeY + 36.0;
    _drawProblemHeader(canvas, topMidX, problemCardY);

    // 3. For each place column: draw header, terms, cone arrows, subtotal, and bracket
    final n = columns.length;
    final colCenters = <double>[];
    const columnContentStartY = problemCardY + 45.0;

    for (int i = 0; i < n; i++) {
      final cx = AdditionStaticDiagram.marginLeft +
          i * AdditionStaticDiagram.colWidth +
          AdditionStaticDiagram.colWidth / 2;
      colCenters.add(cx);
      _drawPlaceColumn(canvas, columns[i], cx, topMidX, columnContentStartY);
    }

    // 4. Draw Step 2: Combine Left-to-Right
    _drawCombinationSteps(canvas, colCenters, size.width);
  }

  void _drawNotebookPaper(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _bg,
    );

    // Ruled lines every 28 px
    final rulePaint = Paint()
      ..color = _ruleColor
      ..strokeWidth = 0.8;
    for (double y = 28.0; y < size.height; y += 28.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }

    // Red left margin line
    canvas.drawLine(
      const Offset(28.0, 0),
      Offset(28.0, size.height),
      Paint()
        ..color = _marginLineColor
        ..strokeWidth = 1.2,
    );
  }

  void _drawProblemHeader(Canvas canvas, double midX, double topY) {
    final text = '$a  +  $b  =  ?';

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 30,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: _headingColor,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(midX, topY + tp.height / 2),
        width: tp.width + 52,
        height: tp.height + 18,
      ),
      const Radius.circular(12),
    );

    // Card shadow & background
    canvas.drawRRect(
      cardRect,
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = _tensColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    tp.paint(canvas, Offset(midX - tp.width / 2, topY + 9));
  }

  void _drawPlaceColumn(
    Canvas canvas,
    AdditionPlaceColumn col,
    double cx,
    double problemMidX,
    double startY,
  ) {
    // 1. Column header pill at top of column space
    final headerY = startY + 22.0;
    _drawPill(
      canvas,
      Offset(cx, headerY),
      '${col.name.toUpperCase()} (×${col.multiplier})',
      _tensColor,
      fontSize: 11,
      isFilled: false,
    );

    // 2. Terms Y position (with clean distance below header)
    final termY = headerY + 48.0;
    final leftTermX = cx - 48.0;
    final rightTermX = cx + 48.0;

    // 3. Branching arrows that bypass the column header text:
    // Route from problem base: goes down, steps horizontally towards termX, then down into term card!
    _drawSteppedBranchingArrow(
      canvas,
      from: Offset(problemMidX + (leftTermX - problemMidX) * 0.3, startY),
      to: Offset(leftTermX, termY - 22),
      color: _tensColor.withValues(alpha: 0.65),
    );

    _drawSteppedBranchingArrow(
      canvas,
      from: Offset(problemMidX + (rightTermX - problemMidX) * 0.3, startY),
      to: Offset(rightTermX, termY - 22),
      color: _tensColor.withValues(alpha: 0.65),
    );

    // 4. Draw the two decomposed numbers (A part and B part)
    _drawTermCard(canvas, leftTermX, termY, '${col.aPart}', 'from $a');
    _drawTermCard(canvas, rightTermX, termY, '${col.bPart}', 'from $b');

    // 5. Cone-shaped downward diagonal arrows pointing to Subtotal!
    final coneTopY = termY + 24.0;
    final coneBottomY = coneTopY + 58.0;

    // Left cone arrow (slanted down-right)
    _drawStraightArrow(
      canvas,
      from: Offset(leftTermX, coneTopY),
      to: Offset(cx - 12, coneBottomY - 8),
      color: _onesColor,
      strokeWidth: 2.2,
    );

    // Right cone arrow (slanted down-left)
    _drawStraightArrow(
      canvas,
      from: Offset(rightTermX, coneTopY),
      to: Offset(cx + 12, coneBottomY - 8),
      color: _onesColor,
      strokeWidth: 2.2,
    );

    // Plus symbol badge in the center between the cone arrows
    final plusY = (coneTopY + coneBottomY) / 2 - 2;
    _drawCircleBadge(canvas, Offset(cx, plusY), '+', _onesColor);

    // 6. Subtotal card at cone bottom
    final subtotalY = coneBottomY + 14.0;
    _drawSubtotalCard(canvas, cx, subtotalY, '${col.sum}');

    // 7. Explanatory bracket note under subtotal (comfortable spacing, zero overlap)
    final bracketY = subtotalY + 38.0;
    final bracketText = '[ ${col.name}:  ${col.aPart} + ${col.bPart} = ${col.sum} ]';
    _drawBracketText(canvas, cx, bracketY, bracketText);
  }

  void _drawCombinationSteps(
    Canvas canvas,
    List<double> colCenters,
    double canvasWidth,
  ) {
    const dividerY = 356.0;

    // Separator line
    canvas.drawLine(
      Offset(40, dividerY),
      Offset(canvasWidth - 40, dividerY),
      Paint()
        ..color = _ruleColor
        ..strokeWidth = 1.5,
    );

    // Section title
    final midX = canvasWidth / 2;
    _drawPill(
      canvas,
      Offset(midX, dividerY + 20),
      'STEP 2: COMBINE LEFT-TO-RIGHT (MENTAL SPEED METHOD)',
      _resultColor,
      fontSize: 11,
    );

    // Perform Left-to-Right mental addition
    final n = columns.length;
    double currentY = dividerY + 60.0;
    int accumulator = columns[0].sum;

    if (n == 2) {
      // 2-digit sum (e.g. 40+40=80, 2+5=7 -> 80 + 7 = 87)
      final s0 = columns[0].sum;
      final s1 = columns[1].sum;
      final finalAns = s0 + s1;

      // Cone arrows from col 0 subtotal and col 1 subtotal down to combination
      _drawStraightArrow(
        canvas,
        from: Offset(colCenters[0], dividerY - 14),
        to: Offset(midX - 35, currentY),
        color: _tensColor,
        strokeWidth: 2.2,
      );
      _drawStraightArrow(
        canvas,
        from: Offset(colCenters[1], dividerY - 14),
        to: Offset(midX + 35, currentY),
        color: _onesColor,
        strokeWidth: 2.2,
      );
      _drawCircleBadge(canvas, Offset(midX, currentY - 16), '+', _resultColor);

      // Combination line
      _drawComboCard(
        canvas,
        midX,
        currentY + 16,
        '$s0  +  $s1  =  $finalAns',
        '[ Combine Tens and Units:  $s0 + $s1 = $finalAns ]',
      );

      // Final Answer Banner
      currentY += 72.0;
      _drawFinalAnswerBanner(canvas, midX, currentY, finalAns);
    } else {
      // Multi-column sum (3-digit, 4-digit, etc.)
      for (int i = 1; i < n; i++) {
        final nextTerm = columns[i].sum;
        final nextAcc = accumulator + nextTerm;
        final stepTitle = 'Step 2.$i: ${columns[i - 1].name} total + ${columns[i].name}';

        _drawComboCard(
          canvas,
          midX,
          currentY,
          '$accumulator  +  $nextTerm  =  $nextAcc',
          '[ $stepTitle:  $accumulator + $nextTerm = $nextAcc ]',
        );

        accumulator = nextAcc;
        currentY += 72.0;
      }

      // Final Answer Banner
      _drawFinalAnswerBanner(canvas, midX, currentY + 8.0, accumulator);
    }
  }

  void _drawTermCard(
    Canvas canvas,
    double x,
    double y,
    String value,
    String origin,
  ) {
    final tpVal = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: _tensColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: math.max(tpVal.width + 24, 52),
        height: 34,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(cardRect, Paint()..color = const Color(0xFFEFF6FF));
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = _tensColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    tpVal.paint(canvas, Offset(x - tpVal.width / 2, y - tpVal.height / 2));

    // Small origin note (e.g. "from 42")
    final tpOrigin = TextPainter(
      text: TextSpan(
        text: '($origin)',
        style: const TextStyle(
          fontSize: 9,
          fontStyle: FontStyle.italic,
          color: _noteColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpOrigin.paint(canvas, Offset(x - tpOrigin.width / 2, y - 24));
  }

  void _drawSubtotalCard(Canvas canvas, double cx, double y, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 22,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: _onesColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, y),
        width: math.max(tp.width + 32, 64),
        height: 38,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(cardRect, Paint()..color = const Color(0xFFFFF7ED));
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = _onesColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    tp.paint(canvas, Offset(cx - tp.width / 2, y - tp.height / 2));
  }

  void _drawBracketText(Canvas canvas, double cx, double y, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          color: _noteColor,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  void _drawComboCard(
    Canvas canvas,
    double midX,
    double y,
    String mathText,
    String bracketText,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: mathText,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: _headingColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(midX, y),
        width: math.max(tp.width + 44, 220),
        height: 42,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(cardRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = _resultColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    tp.paint(canvas, Offset(midX - tp.width / 2, y - tp.height / 2));

    _drawBracketText(canvas, midX, y + 27, bracketText);
  }

  void _drawFinalAnswerBanner(
    Canvas canvas,
    double midX,
    double y,
    int finalAns,
  ) {
    final text = 'Final Answer:  $finalAns ✓';

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 22,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(midX, y),
        width: tp.width + 48,
        height: 50,
      ),
      const Radius.circular(14),
    );

    // Green victory fill
    canvas.drawRRect(cardRect, Paint()..color = _resultColor);
    tp.paint(canvas, Offset(midX - tp.width / 2, y - tp.height / 2));

    // Explanatory badge
    final tipTp = TextPainter(
      text: const TextSpan(
        text: '[ Left-to-right mental calculation complete — no pencil carrying needed! ]',
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          color: _noteColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tipTp.paint(canvas, Offset(midX - tipTp.width / 2, y + 34));
  }

  void _drawStraightArrow(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required Color color,
    double strokeWidth = 2.0,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(from, to, paint);

    // Arrowhead
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const headLen = 7.0;
    canvas.drawLine(
      to,
      Offset(to.dx - headLen * math.cos(angle - math.pi / 6),
          to.dy - headLen * math.sin(angle - math.pi / 6)),
      paint,
    );
    canvas.drawLine(
      to,
      Offset(to.dx - headLen * math.cos(angle + math.pi / 6),
          to.dy - headLen * math.sin(angle + math.pi / 6)),
      paint,
    );
  }

  /// Draws an elbowed (stepped) arrow that cleanly bypasses any header text
  void _drawSteppedBranchingArrow(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required Color color,
    double strokeWidth = 1.5,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Smooth bezier curve down and around to the term
    final midY = from.dy + (to.dy - from.dy) * 0.45;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
    canvas.drawPath(path, paint);

    // Downward arrowhead pointing straight into term card
    const headLen = 6.0;
    final ap = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      to,
      Offset(to.dx - headLen * 0.5, to.dy - headLen),
      ap,
    );
    canvas.drawLine(
      to,
      Offset(to.dx + headLen * 0.5, to.dy - headLen),
      ap,
    );
  }

  void _drawCircleBadge(
    Canvas canvas,
    Offset center,
    String symbol,
    Color color,
  ) {
    const radius = 11.0;
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawPill(
    Canvas canvas,
    Offset center,
    String text,
    Color color, {
    double fontSize = 11,
    bool isFilled = true,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: tp.width + 18,
        height: tp.height + 10,
      ),
      const Radius.circular(16),
    );

    if (isFilled) {
      canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.12));
    } else {
      canvas.drawRRect(rrect, Paint()..color = Colors.white);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_AdditionDiagramPainter old) {
    return old.a != a || old.b != b;
  }
}
