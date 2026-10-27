// lib/features/learn/builders/multiply_by_99_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Multiply by 9, 99, 999 using the (10^k - 1) shortcut.
class MultiplyBy99Builder {
  static LessonScript build(List<int> operands) {
    final mult = operands.length > 1 ? operands[1] : 99;
    if (mult == 9) return buildX9(operands);
    if (mult == 999) return buildX999(operands);
    return buildX99(operands);
  }

  static LessonScript buildX9(List<int> operands) {
    final n = operands[0];
    final step1 = n * 10;
    final result = n * 9;

    return LessonScript(
      problemText: '$n × 9 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Think: 9 = 10 − 1. So $n × 9 = ($n × 10) − $n.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$n  ×  9  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.45, endT: 0.8,
              text: '9  =  10  −  1',
              fontSize: 24,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 80,
              startT: 0.75, endT: 1.0,
              text: 'round up, subtract',
              color: LessonColors.note,
              fontSize: 16,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Multiply by 10 (just add a zero): $n × 10 = $step1.',
          blockHeight: 100,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.6,
              text: '$n  ×  10  =  $step1',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 40,
              startT: 0.6, endT: 0.9,
              text: 'add one zero',
              color: LessonColors.note,
              fontSize: 16,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Subtract original $n: $step1 − $n = $result.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$step1  −  $n  =  $result',
              fontSize: 30,
              color: LessonColors.carry,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.55, endT: 0.85,
              text: '$n × 9  =  $result',
              fontSize: 30,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 95,
              startT: 0.82, endT: 1.0,
              width: 150,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }

  static LessonScript buildX99(List<int> operands) {
    final n = operands[0];
    final step1 = n * 100;
    final result = n * 99;

    return LessonScript(
      problemText: '$n × 99 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Think: 99 = 100 − 1. So $n × 99 = ($n × 100) − $n.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$n  ×  99  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.45, endT: 0.8,
              text: '99  =  100  −  1',
              fontSize: 24,
              color: LessonColors.note,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 80,
              startT: 0.75, endT: 1.0,
              text: 'round up, subtract',
              color: LessonColors.note,
              fontSize: 16,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Multiply by 100 (add two zeros): $n × 100 = $step1.',
          blockHeight: 100,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.6,
              text: '$n  ×  100  =  $step1',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 220, y: 40,
              startT: 0.6, endT: 0.9,
              text: 'add two zeros',
              color: LessonColors.note,
              fontSize: 16,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Subtract original $n: $step1 − $n = $result.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$step1  −  $n  =  $result',
              fontSize: 28,
              color: LessonColors.carry,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.55, endT: 0.85,
              text: '$n × 99  =  $result',
              fontSize: 30,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 95,
              startT: 0.82, endT: 1.0,
              width: 170,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }

  static LessonScript buildX999(List<int> operands) {
    final n = operands[0];
    final step1 = n * 1000;
    final result = n * 999;

    return LessonScript(
      problemText: '$n × 999 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Think: 999 = 1000 − 1. So $n × 999 = ($n × 1000) − $n.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$n  ×  999  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.45, endT: 0.8,
              text: '999  =  1000  −  1',
              fontSize: 22,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Multiply by 1000 (add three zeros): $n × 1000 = $step1.',
          blockHeight: 100,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 40,
              startT: 0.0, endT: 0.6,
              text: '$n  ×  1000  =  $step1',
              fontSize: 28,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Subtract original $n: $step1 − $n = $result.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$step1  −  $n  =  $result',
              fontSize: 26,
              color: LessonColors.carry,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.55, endT: 0.85,
              text: '$n × 999  =  $result',
              fontSize: 28,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 95,
              startT: 0.82, endT: 1.0,
              width: 185,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}
