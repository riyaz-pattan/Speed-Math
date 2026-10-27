// lib/features/learn/builders/multiply_by_11_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Multiply by 11 trick: place digit-sum between outer digits.
class MultiplyBy11Builder {
  static LessonScript build(List<int> operands) {
    final n = operands[0];
    final tens = n ~/ 10;
    final ones = n % 10;
    final mid = tens + ones;
    final result = n * 11;

    return mid < 10
        ? _buildSimple(n, tens, ones, mid, result)
        : _buildWithCarry(n, tens, ones, mid, result);
  }

  static LessonScript _buildSimple(
      int n, int tens, int ones, int mid, int result) {
    return LessonScript(
      problemText: '$n × 11 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Write the outer digits $tens and $ones with a blank space in between.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$n  ×  11  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.45, endT: 0.8,
              text: 'Write:  $tens  _  $ones',
              fontSize: 28,
              color: LessonColors.note,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 80,
              startT: 0.75, endT: 1.0,
              text: 'outer digits',
              color: LessonColors.note,
              fontSize: 17,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Add the two digits: $tens + $ones = $mid. Place $mid in the middle blank.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$tens  +  $ones  =  $mid',
              fontSize: 30,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 38,
              startT: 0.5, endT: 0.8,
              text: 'digit sum',
              color: LessonColors.note,
              fontSize: 17,
            ),
            BElement(
              type: BElementType.arrow,
              x: 120, y: 48,
              x2: 150, y2: 82,
              startT: 0.55, endT: 0.85,
              color: LessonColors.arrowColor,
              label: 'insert',
              labelColor: LessonColors.arrowColor,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.7, endT: 1.0,
              text: 'Fill middle:  $tens$mid$ones',
              fontSize: 26,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: '$n × 11 = $result ✓ Fast and simple!',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.6,
              text: '$n  ×  11  =  $result',
              fontSize: 32,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 50,
              startT: 0.6, endT: 1.0,
              width: 170,
              height: 44,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
      crossArrows: [
        CrossArrow(
          fromBlock: 0, fromX: 110, fromLocalY: 80,
          toBlock: 1, toX: 55, toLocalY: 20,
          color: LessonColors.arrowColor,
          label: 'sum digits',
          labelColor: LessonColors.arrowColor,
          curved: true,
          animateOnBlock: 1,
          startT: 0.0, endT: 0.5,
        ),
      ],
    );
  }

  static LessonScript _buildWithCarry(
      int n, int tens, int ones, int mid, int result) {
    final newTens = tens + 1;
    final midDigit = mid % 10;

    return LessonScript(
      problemText: '$n × 11 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Write the outer digits $tens and $ones with a blank space.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$n  ×  11  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.45, endT: 0.8,
              text: 'Write:  $tens  _  $ones',
              fontSize: 28,
              color: LessonColors.note,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 80,
              startT: 0.75, endT: 1.0,
              text: 'outer digits',
              color: LessonColors.note,
              fontSize: 17,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Sum: $tens + $ones = $mid (≥ 10). Keep $midDigit in middle, carry 1 to tens: $tens + 1 = $newTens.',
          blockHeight: 130,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$tens  +  $ones  =  $mid',
              fontSize: 30,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 38,
              startT: 0.45, endT: 0.7,
              text: '≥ 10: carry 1',
              color: LessonColors.carry,
              fontSize: 17,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.5, endT: 0.85,
              text: 'Carry 1:  ($tens+1) | $midDigit | $ones  →  $newTens$midDigit$ones',
              fontSize: 22,
              color: LessonColors.carry,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 94,
              startT: 0.75, endT: 1.0,
              width: 220,
              strokeWidth: 2.5,
              color: LessonColors.carry,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: '$n × 11 = $result ✓ Carry handled smoothly!',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.6,
              text: '$n  ×  11  =  $result',
              fontSize: 32,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 50,
              startT: 0.6, endT: 1.0,
              width: 175,
              height: 44,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}
