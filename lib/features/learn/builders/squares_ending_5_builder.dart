// lib/features/learn/builders/squares_ending_5_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Squares ending in 5: n² = prefix×(prefix+1) followed by 25.
class SquaresEnding5Builder {
  static LessonScript build(List<int> operands) {
    final n = operands[0];
    final prefix = n ~/ 10;
    final leftPart = prefix * (prefix + 1);
    final result = n * n;

    return LessonScript(
      problemText: '$n² = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: '$n ends in 5. Split it: tens digit = $prefix, units = 5.',
          blockHeight: 130,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$n²  =  ?',
              fontSize: 36,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 230, y: 38,
              startT: 0.45, endT: 0.7,
              text: 'tens digit',
              color: LessonColors.note,
              fontSize: 18,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 85,
              startT: 0.5, endT: 0.85,
              text: 'Tens digit → $prefix',
              fontSize: 22,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 115,
              startT: 0.75, endT: 1.0,
              text: 'Units → always 5',
              fontSize: 22,
              color: LessonColors.ones,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Take tens digit $prefix, multiply by (${prefix + 1}) — the next number.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.55,
              text: '$prefix  ×  ${prefix + 1}  =  $leftPart',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 230, y: 40,
              startT: 0.55, endT: 0.85,
              text: 'next number after $prefix',
              color: LessonColors.note,
              fontSize: 17,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 55,
              startT: 0.7, endT: 1.0,
              width: 150,
              strokeWidth: 2.5,
              color: LessonColors.tens,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'The units digit is always 5, so 5² = 25 — always!',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.5,
              text: '5  ×  5  =  25',
              fontSize: 30,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 230, y: 40,
              startT: 0.5, endT: 0.8,
              text: 'always 25',
              color: LessonColors.note,
              fontSize: 17,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 55,
              startT: 0.7, endT: 1.0,
              width: 90,
              strokeWidth: 2.5,
              color: LessonColors.ones,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 4',
          caption: 'Join $leftPart and 25 together → answer = $result',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 35,
              startT: 0.0, endT: 0.35,
              text: '$leftPart',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 90, y: 35,
              startT: 0.2, endT: 0.5,
              text: '|',
              fontSize: 34,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.text,
              x: 108, y: 35,
              startT: 0.3, endT: 0.6,
              text: '25',
              fontSize: 34,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 85,
              startT: 0.6, endT: 0.9,
              text: '$n²  =  $result',
              fontSize: 32,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 98,
              startT: 0.82, endT: 1.0,
              width: 160,
              height: 44,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
      crossArrows: [
        CrossArrow(
          fromBlock: 0, fromX: 55, fromLocalY: 38,
          toBlock: 1, toX: 55, toLocalY: 15,
          color: LessonColors.tens,
          label: '×(next)',
          labelColor: LessonColors.tens,
          curved: true,
          animateOnBlock: 1,
          startT: 0.0, endT: 0.55,
        ),
        CrossArrow(
          fromBlock: 0, fromX: 85, fromLocalY: 38,
          toBlock: 2, toX: 55, toLocalY: 15,
          color: LessonColors.ones,
          label: 'square it',
          labelColor: LessonColors.ones,
          curved: true,
          animateOnBlock: 2,
          startT: 0.0, endT: 0.55,
        ),
      ],
    );
  }
}
