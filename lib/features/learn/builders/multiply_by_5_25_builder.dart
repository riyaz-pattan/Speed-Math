// lib/features/learn/builders/multiply_by_5_25_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Multiply by 5, 25, 75, or 125.
class MultiplyBy5And25Builder {
  static LessonScript build(List<int> operands) {
    final mult = operands.length > 1 ? operands[1] : 5;
    if (mult == 25) return buildX25(operands);
    if (mult == 75) return buildX75(operands);
    if (mult == 125) return buildX125(operands);
    return buildX5(operands);
  }

  static LessonScript buildX5(List<int> operands) {
    final n = operands[0];
    final result = n * 5;
    final half = n / 2;
    final halfStr = half == half.truncateToDouble() ? '${half.truncate()}' : '$half';

    return LessonScript(
      problemText: '$n × 5 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Key insight: 5 = 10 ÷ 2. So multiply by 10, then halve.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.4,
              text: '$n  ×  5  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.4, endT: 0.8,
              text: '5  =  10  ÷  2',
              fontSize: 24,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.arrow,
              x: 170, y: 80,
              x2: 210, y2: 80,
              startT: 0.75, endT: 1.0,
              color: LessonColors.arrowColor,
              label: 'trick',
              labelColor: LessonColors.arrowColor,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Halve $n → $halfStr',
          blockHeight: 100,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.55,
              text: '$n  ÷  2  =  $halfStr',
              fontSize: 30,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 54,
              startT: 0.65, endT: 1.0,
              width: 130,
              strokeWidth: 2.5,
              color: LessonColors.ones,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Multiply by 10 → move decimal right (or add a zero for whole numbers).',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$halfStr  ×  10  =  $result',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.55, endT: 0.85,
              text: '$n × 5  =  $result',
              fontSize: 30,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 95,
              startT: 0.82, endT: 1.0,
              width: 145,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }

  static LessonScript buildX25(List<int> operands) {
    final n = operands[0];
    final result = n * 25;
    final quarter = n / 4;
    final quarterStr = quarter == quarter.truncateToDouble() ? '${quarter.truncate()}' : '$quarter';

    return LessonScript(
      problemText: '$n × 25 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Key insight: 25 = 100 ÷ 4. Divide by 4, multiply by 100.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.4,
              text: '$n  ×  25  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.4, endT: 0.8,
              text: '25  =  100  ÷  4',
              fontSize: 24,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Divide $n by 4 → $quarterStr',
          blockHeight: 100,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.55,
              text: '$n  ÷  4  =  $quarterStr',
              fontSize: 30,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 54,
              startT: 0.65, endT: 1.0,
              width: 140,
              strokeWidth: 2.5,
              color: LessonColors.ones,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Multiply by 100 → add two zeros.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$quarterStr  ×  100  =  $result',
              fontSize: 28,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.55, endT: 0.85,
              text: '$n × 25  =  $result',
              fontSize: 30,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 95,
              startT: 0.82, endT: 1.0,
              width: 160,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }

  static LessonScript buildX75(List<int> operands) {
    final n = operands[0];
    final result = n * 75;
    final x100 = n * 100;
    final x25 = n * 25;

    return LessonScript(
      problemText: '$n × 75 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Key insight: 75 = 100 − 25. So n×75 = n×100 − n×25.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.4,
              text: '$n  ×  75  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.4, endT: 0.8,
              text: '75  =  100  −  25',
              fontSize: 24,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: '$n × 100 = $x100. Then $n × 25 = $x25 (use ÷4 × 100 trick).',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$n × 100 = $x100',
              fontSize: 26,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 78,
              startT: 0.45, endT: 0.85,
              text: '$n × 25  = $x25',
              fontSize: 26,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Subtract: $x100 − $x25 = $result.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$x100  −  $x25  =  $result',
              fontSize: 28,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.55, endT: 0.85,
              text: '$n × 75  =  $result',
              fontSize: 30,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 95,
              startT: 0.82, endT: 1.0,
              width: 165,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }

  static LessonScript buildX125(List<int> operands) {
    final n = operands[0];
    final result = n * 125;
    final eighth = n / 8;
    final eighthStr = eighth == eighth.truncateToDouble() ? '${eighth.truncate()}' : '$eighth';

    return LessonScript(
      problemText: '$n × 125 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Key insight: 125 = 1000 ÷ 8. Divide by 8, multiply by 1000.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.4,
              text: '$n  ×  125  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.4, endT: 0.8,
              text: '125  =  1000  ÷  8',
              fontSize: 22,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Divide $n by 8 → $eighthStr',
          blockHeight: 100,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.55,
              text: '$n  ÷  8  =  $eighthStr',
              fontSize: 30,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 54,
              startT: 0.65, endT: 1.0,
              width: 140,
              strokeWidth: 2.5,
              color: LessonColors.ones,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Multiply by 1000 → add three zeros.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$eighthStr × 1000 = $result',
              fontSize: 26,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.55, endT: 0.85,
              text: '$n × 125  =  $result',
              fontSize: 30,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 95,
              startT: 0.82, endT: 1.0,
              width: 180,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}
