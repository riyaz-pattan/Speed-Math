// lib/features/learn/builders/near_100_mult_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Near-100 Multiplication: cross subtraction + gap product.
/// e.g. 97 × 94: gaps 3 and 6 → 97 − 6 = 91, 3 × 6 = 18 → 9118
class Near100MultBuilder {
  static LessonScript build(List<int> operands) {
    final a = operands[0];
    final b = operands[1];
    final gapA = 100 - a;
    final gapB = 100 - b;
    final leftPart = a - gapB;
    final rightPart = gapA * gapB;
    final rightStr = rightPart < 10 ? '0$rightPart' : '$rightPart';
    final result = a * b;

    return LessonScript(
      problemText: '$a × $b = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Find how far each number is below 100 (the "deficits").',
          blockHeight: 130,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.4,
              text: '$a  ×  $b  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 78,
              startT: 0.4, endT: 0.7,
              text: '$a  is  100  −  $gapA',
              fontSize: 22,
              color: LessonColors.ones,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 108,
              startT: 0.7, endT: 1.0,
              text: '$b  is  100  −  $gapB',
              fontSize: 22,
              color: LessonColors.ones,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 92,
              startT: 0.75, endT: 1.0,
              text: 'deficits from 100',
              color: LessonColors.note,
              fontSize: 16,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Cross-subtract: take $a and subtract $b\'s gap ($gapB): $a − $gapB = $leftPart.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.55,
              text: '$a  −  $gapB  =  $leftPart',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 38,
              startT: 0.55, endT: 0.85,
              text: 'cross subtract',
              color: LessonColors.note,
              fontSize: 16,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.6, endT: 0.9,
              text: 'Left part of answer:  $leftPart',
              fontSize: 22,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Multiply the deficits: $gapA × $gapB = $rightPart (always 2 digits: $rightStr).',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.55,
              text: '$gapA  ×  $gapB  =  $rightPart',
              fontSize: 30,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 38,
              startT: 0.55, endT: 0.85,
              text: 'multiply deficits',
              color: LessonColors.note,
              fontSize: 16,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.6, endT: 0.9,
              text: 'Right part (2 digits):  $rightStr',
              fontSize: 22,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 4',
          caption: 'Join left part $leftPart and right part $rightStr → $result ✓',
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
              x: 95, y: 35,
              startT: 0.2, endT: 0.45,
              text: '|',
              fontSize: 34,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.text,
              x: 115, y: 35,
              startT: 0.35, endT: 0.65,
              text: rightStr,
              fontSize: 34,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 85,
              startT: 0.6, endT: 0.9,
              text: '$a × $b  =  $result',
              fontSize: 32,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 98,
              startT: 0.8, endT: 1.0,
              width: 175,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
      crossArrows: [
        CrossArrow(
          fromBlock: 0, fromX: 130, fromLocalY: 108,
          toBlock: 1, toX: 85, toLocalY: 20,
          color: LessonColors.tens,
          label: 'subtract',
          labelColor: LessonColors.tens,
          curved: true,
          animateOnBlock: 1,
          startT: 0.0, endT: 0.55,
        ),
      ],
    );
  }
}
