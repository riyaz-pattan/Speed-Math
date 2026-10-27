// lib/features/learn/builders/subtraction_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Builds whiteboard script blocks for the "Subtract in Parts" lesson.
/// Technique: Left-to-Right Place Value Subtraction (resolving deficits mentally).
class SubtractionBuilder {
  static LessonScript build(List<int> operands) {
    assert(operands.length >= 2);
    final a = operands[0];
    final b = operands[1];
    final result = a - b;

    // Place value breakdown
    final aTens = (a ~/ 10) * 10;
    final aOnes = a % 10;
    final bTens = (b ~/ 10) * 10;
    final bOnes = b % 10;

    final tensDiff = aTens - bTens;
    final onesDiff = aOnes - bOnes;

    return LessonScript(
      problemText: '$a − $b = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Split $a and $b into place values (tens & units).',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36,
              y: 38,
              startT: 0.0,
              endT: 0.4,
              text: '$a  −  $b  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36,
              y: 80,
              startT: 0.4,
              endT: 0.75,
              text: '$a = $aTens + $aOnes   |   $b = $bTens + $bOnes',
              fontSize: 20,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.underline,
              x: 36,
              y: 88,
              startT: 0.72,
              endT: 1.0,
              width: 260,
              strokeWidth: 2.0,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Subtract the tens first: $aTens − $bTens = $tensDiff.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36,
              y: 40,
              startT: 0.0,
              endT: 0.55,
              text: '$aTens  −  $bTens  =  $tensDiff',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 220,
              y: 40,
              startT: 0.55,
              endT: 0.85,
              text: 'hold tens',
              color: LessonColors.note,
              fontSize: 17,
            ),
            BElement(
              type: BElementType.underline,
              x: 36,
              y: 54,
              startT: 0.7,
              endT: 1.0,
              width: 140,
              strokeWidth: 2.5,
              color: LessonColors.tens,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: onesDiff >= 0
              ? 'Units: $aOnes − $bOnes = $onesDiff. Combine: $tensDiff + $onesDiff = $result.'
              : 'Units: $aOnes − $bOnes = $onesDiff (deficit of ${-onesDiff}). Adjust: $tensDiff − ${-onesDiff} = $result.',
          blockHeight: 130,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36,
              y: 38,
              startT: 0.0,
              endT: 0.5,
              text: onesDiff >= 0
                  ? '$aOnes  −  $bOnes  =  $onesDiff'
                  : '$aOnes  −  $bOnes  =  $onesDiff  (deficit ${-onesDiff})',
              fontSize: 26,
              color: onesDiff >= 0 ? LessonColors.ones : LessonColors.carry,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36,
              y: 85,
              startT: 0.55,
              endT: 0.85,
              text: onesDiff >= 0
                  ? '$tensDiff  +  $onesDiff  =  $result'
                  : '$tensDiff  −  ${-onesDiff}  =  $result',
              fontSize: 32,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 30,
              y: 85,
              startT: 0.8,
              endT: 1.0,
              width: 170,
              height: 40,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}
