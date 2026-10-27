// lib/features/learn/builders/multiplication_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';
import '../widgets/multiplication_static_diagram.dart';

/// Builds whiteboard script blocks for Criss-Cross multiplication lessons.
class MultiplicationBuilder {
  static LessonScript build(List<int> operands) {
    assert(operands.length >= 2);
    final a = operands[0];
    final b = operands[1];
    final product = a * b;

    final steps = computeMultiplicationSteps(a, b);
    final blocks = <LessonBlock>[];

    for (final s in steps) {
      final termsText = s.terms.length == 1
          ? '${s.terms.first.topDigit} × ${s.terms.first.bottomDigit} = ${s.terms.first.product}'
          : s.terms
              .map((t) => '(${t.topDigit}×${t.bottomDigit})')
              .join(' + ');

      final String actionText;
      if (s.isFinalStep) {
        actionText = 'Write $product (Complete)';
      } else {
        actionText = s.carryOut > 0
            ? 'Write ${s.digitWritten}, carry ${s.carryOut}'
            : 'Write ${s.digitWritten}';
      }

      blocks.add(
        LessonBlock(
          stepTitle: 'Step ${s.stepNumber}',
          caption: '${s.name} (${s.patternType}): $termsText = ${s.sumTerms}'
              '${s.carryIn > 0 ? " + carry ${s.carryIn} = ${s.totalWithCarry}" : ""}. $actionText.',
          blockHeight: 125,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36,
              y: 38,
              startT: 0.0,
              endT: 0.45,
              text: '${s.name}: $termsText',
              fontSize: 26,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36,
              y: 78,
              startT: 0.45,
              endT: 0.85,
              text: s.carryIn > 0
                  ? '= ${s.sumTerms} + carry ${s.carryIn} = ${s.totalWithCarry} → $actionText'
                  : '= ${s.sumTerms} → $actionText',
              fontSize: 22,
              color: s.isFinalStep ? LessonColors.result : LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.underline,
              x: 36,
              y: 86,
              startT: 0.8,
              endT: 1.0,
              width: 240,
              strokeWidth: 2.0,
              color: s.isFinalStep ? LessonColors.result : LessonColors.ones,
            ),
          ],
        ),
      );
    }

    return LessonScript(
      problemText: '$a × $b = $product',
      blocks: blocks,
    );
  }
}
