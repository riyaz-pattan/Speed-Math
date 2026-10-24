// lib/features/learn/builders/near_100_mult_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_data.dart';

/// Near-100 Multiplication: (100−a)(100−b) cross method.
/// e.g. 97×94: gaps 3 & 6, cross = 97−6=91, product 3×6=18 → 9118
class Near100MultBuilder {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF16A34A);
  static const Color _gray = Color(0xFF64748B);

  static List<LessonStep> build(List<int> operands) {
    final a = operands[0];
    final b = operands[1];
    final gapA = 100 - a;
    final gapB = 100 - b;
    final leftPart = a - gapB;
    final rightPart = gapA * gapB;
    final rightStr = rightPart < 10 ? '0$rightPart' : '$rightPart';
    final result = a * b;

    return [
      LessonStep(
        caption: 'Both $a and $b are close to 100. Find the gap of each from 100.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.4,
              text: '$a × $b = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.4, endT: 0.7,
              text: '$a = 100 − $gapA', fontSize: 22, color: _orange),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 140, startT: 0.7, endT: 1.0,
              text: '$b = 100 − $gapB', fontSize: 22, color: _orange),
        ],
      ),
      LessonStep(
        caption: 'Cross-subtract: $a − $gapB = $leftPart. This is the LEFT part of the answer.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 72, startT: 0, endT: 0.6,
              text: '$a − $gapB = $leftPart', fontSize: 30, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 112, startT: 0.6, endT: 1.0,
              text: 'Left part: $leftPart', fontSize: 22, color: _gray),
        ],
      ),
      LessonStep(
        caption: 'Multiply the gaps: $gapA × $gapB = $rightPart. Zero-pad to 2 digits → $rightStr.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 72, startT: 0, endT: 0.6,
              text: '$gapA × $gapB = $rightPart', fontSize: 28, color: _orange, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 112, startT: 0.6, endT: 1.0,
              text: 'Right part: $rightStr', fontSize: 22, color: _gray),
        ],
      ),
      LessonStep(
        caption: 'Join the parts: $leftPart | $rightStr = $result ✓',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 88, startT: 0, endT: 0.6,
              text: '$a × $b = $result', fontSize: 36, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 97, startT: 0.6, endT: 1.0,
              highlightWidth: 215, highlightHeight: 48, color: _green),
        ],
      ),
    ];
  }
}
