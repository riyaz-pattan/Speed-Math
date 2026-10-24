// lib/features/learn/builders/add_in_parts_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_data.dart';

/// Add in Parts: 47 + 38 → (47+30)+8 = 77+8 = 85
class AddInPartsBuilder {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF16A34A);
  static const Color _gray = Color(0xFF64748B);

  static List<LessonStep> build(List<int> operands) {
    final a = operands[0];
    final b = operands[1];
    final bTens = (b ~/ 10) * 10;
    final bOnes = b % 10;
    final mid = a + bTens;
    final result = a + b;

    return [
      LessonStep(
        caption: 'We need to add $a + $b. Split $b into tens and ones.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.5,
              text: '$a + $b = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 110, startT: 0.5, endT: 1.0,
              text: '$b = $bTens + $bOnes', fontSize: 22, color: _gray),
        ],
      ),
      LessonStep(
        caption: 'Add the tens first: $a + $bTens = $mid',
        elements: [
          DrawElement(type: DrawElementType.staticText, x: 30, y: 55, startT: 0, endT: 0,
              text: '$a + $b', fontSize: 28, color: _blue.withValues(alpha: 0.4), fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 100, startT: 0, endT: 0.55,
              text: '$a + $bTens = $mid', fontSize: 30, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.underline, x: 30, y: 108, startT: 0.55, endT: 1.0,
              lineWidth: 130, lineHeight: 2.5, color: _orange),
        ],
      ),
      LessonStep(
        caption: 'Now add the ones: $mid + $bOnes = $result',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 95, startT: 0, endT: 0.6,
              text: '$mid + $bOnes = $result', fontSize: 32, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 104, startT: 0.6, endT: 1.0,
              highlightWidth: 200, highlightHeight: 44, color: _green),
        ],
      ),
    ];
  }
}
