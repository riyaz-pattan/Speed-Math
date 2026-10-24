// lib/features/learn/builders/squares_ending_5_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_data.dart';

/// Squares ending in 5: n² = prefix×(prefix+1) followed by 25.
class SquaresEnding5Builder {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF16A34A);
  static const Color _gray = Color(0xFF64748B);

  static List<LessonStep> build(List<int> operands) {
    final n = operands[0];
    final prefix = n ~/ 10;
    final leftPart = prefix * (prefix + 1);
    final result = n * n;

    return [
      LessonStep(
        caption: '$n ends in 5! Shortcut: take the leading digit, multiply by (itself+1), then append 25.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.45,
              text: '$n² = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.45, endT: 1.0,
              text: 'Leading digit: $prefix', fontSize: 22, color: _gray),
        ],
      ),
      LessonStep(
        caption: 'Multiply: $prefix × (${prefix + 1}) = $leftPart',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 80, startT: 0, endT: 0.6,
              text: '$prefix × ${prefix + 1} = $leftPart', fontSize: 30, color: _orange, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.underline, x: 30, y: 88, startT: 0.6, endT: 1.0,
              lineWidth: 125, lineHeight: 2.5, color: _orange),
        ],
      ),
      LessonStep(
        caption: 'Append 25 → $leftPart|25 = $result',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 72, startT: 0, endT: 0.5,
              text: '$leftPart | 25 = $result', fontSize: 30, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 115, startT: 0.5, endT: 1.0,
              text: '$n² = $result', fontSize: 30, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 124, startT: 0.7, endT: 1.0,
              highlightWidth: 125, highlightHeight: 40, color: _green),
        ],
      ),
    ];
  }
}
