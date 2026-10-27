// lib/features/learn/builders/fraction_pct_friends_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Fraction–% Friends: key fraction ↔ percentage conversions.
class FractionPctFriendsBuilder {
  // [numerator, denominator, pct×10]
  static const List<List<int>> _pairs = [
    [1, 2, 500], // 50%
    [1, 4, 250], // 25%
    [3, 4, 750], // 75%
    [1, 8, 125], // 12.5%
    [3, 8, 375], // 37.5%
    [5, 8, 625], // 62.5%
    [7, 8, 875], // 87.5%
    [1, 3, 333], // 33.3%
    [2, 3, 667], // 66.7%
    [1, 5, 200], // 20%
    [2, 5, 400], // 40%
    [1, 6, 167], // 16.7%
    [1, 9, 111], // 11.1%
  ];

  static LessonScript build(List<int> operands) {
    final int num;
    final int den;
    final String pctStr;
    if (operands.length >= 2) {
      num = operands[0];
      den = operands[1];
      final pct = (num * 100.0) / den;
      pctStr = pct == pct.truncate() ? '${pct.truncate()}%' : '${pct.toStringAsFixed(1)}%';
    } else {
      final idx = (operands.isNotEmpty ? operands[0] : 0) % _pairs.length;
      final pair = _pairs[idx];
      num = pair[0];
      den = pair[1];
      final pct10 = pair[2];
      pctStr = pct10 % 10 == 0
          ? '${pct10 ~/ 10}%'
          : '${(pct10 / 10).toStringAsFixed(1)}%';
    }

    return LessonScript(
      problemText: '$num/$den = ?%',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Convert $num/$den into a percentage.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$num / $den  =  ? %',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.45, endT: 0.8,
              text: 'Think:  1 / $den  =  ${(100 / den).toStringAsFixed(1)}%',
              fontSize: 22,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 80,
              startT: 0.75, endT: 1.0,
              text: 'unit reciprocal',
              color: LessonColors.note,
              fontSize: 16,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Multiply by $num: $num × (1/$den) = $pctStr.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.6,
              text: '$num  ×  ( 1 / $den )  =  $pctStr',
              fontSize: 28,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 52,
              startT: 0.65, endT: 1.0,
              width: 170,
              strokeWidth: 2.5,
              color: LessonColors.ones,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Memorise this friend: $num/$den ↔ $pctStr! Instant recall saves test time.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.6,
              text: '$num / $den  ↔  $pctStr',
              fontSize: 32,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 50,
              startT: 0.6, endT: 1.0,
              width: 180,
              height: 44,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}
