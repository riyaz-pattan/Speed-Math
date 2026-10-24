// lib/features/learn/builders/multiply_by_99_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_data.dart';

/// × 99 trick: n × 99 = n × 100 – n
class MultiplyBy99Builder {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFF97316);
  static const Color _red = Color(0xFFDC2626);
  static const Color _green = Color(0xFF16A34A);

  static List<LessonStep> build(List<int> operands) {
    final n = operands[0];
    final step1 = n * 100;
    final result = n * 99;
    return [
      LessonStep(
        caption: '$n × 99 — use the "round up, subtract" trick.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.45,
              text: '$n × 99 = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.45, endT: 1.0,
              text: '99 = 100 − 1', fontSize: 24, color: Color(0xFF64748B)),
        ],
      ),
      LessonStep(
        caption: 'Step 1: $n × 100 = $step1 (easy — add two zeros!)',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 80, startT: 0, endT: 0.6,
              text: '$n × 100 = $step1', fontSize: 30, color: _orange, fontWeight: FontWeight.bold),
        ],
      ),
      LessonStep(
        caption: 'Step 2: Subtract $n → $step1 – $n = $result',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 72, startT: 0, endT: 0.5,
              text: '$step1 − $n = $result', fontSize: 30, color: _red, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 115, startT: 0.5, endT: 1.0,
              text: '$n × 99 = $result', fontSize: 28, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 124, startT: 0.7, endT: 1.0,
              highlightWidth: 165, highlightHeight: 40, color: _green),
        ],
      ),
    ];
  }
}
