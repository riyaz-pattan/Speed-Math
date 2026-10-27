// lib/features/learn/builders/add_in_parts_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Add in Parts: 47 + 38 → (47 + 30) + 8 = 77 + 8 = 85
class AddInPartsBuilder {
  static LessonScript build(List<int> operands) {
    final a = operands[0];
    final b = operands[1];
    final bTens = (b ~/ 10) * 10;
    final bOnes = b % 10;
    final mid = a + bTens;
    final result = a + b;

    return LessonScript(
      problemText: '$a + $b = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Split $b into tens and ones: $bTens + $bOnes.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.4,
              text: '$a  +  $b  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.4, endT: 0.75,
              text: 'Split $b  =  $bTens  +  $bOnes',
              fontSize: 22,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 88,
              startT: 0.72, endT: 1.0,
              width: 180,
              strokeWidth: 2.0,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Add the tens first: $a + $bTens = $mid. Easy!',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.55,
              text: '$a  +  $bTens  =  $mid',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 220, y: 40,
              startT: 0.55, endT: 0.85,
              text: 'just add tens',
              color: LessonColors.note,
              fontSize: 17,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 54,
              startT: 0.7, endT: 1.0,
              width: 140,
              strokeWidth: 2.5,
              color: LessonColors.tens,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Now add the ones: $mid + $bOnes = $result.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.5,
              text: '$mid  +  $bOnes  =  $result',
              fontSize: 30,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 85,
              startT: 0.55, endT: 0.85,
              text: '$a + $b  =  $result',
              fontSize: 28,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 96,
              startT: 0.8, endT: 1.0,
              width: 140,
              height: 40,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}
