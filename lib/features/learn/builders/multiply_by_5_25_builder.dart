// lib/features/learn/builders/multiply_by_5_25_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_data.dart';

/// × 5 trick: n/2 × 10.  × 25 trick: n/4 × 100.
class MultiplyBy5And25Builder {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF16A34A);
  static const Color _gray = Color(0xFF64748B);

  static List<LessonStep> build(List<int> operands) {
    final n = operands[0];
    final mult = operands.length > 1 ? operands[1] : 5;
    return mult == 25 ? _times25(n) : _times5(n);
  }

  static List<LessonStep> _times5(int n) {
    final half = n / 2;
    final halfStr = half == half.truncateToDouble() ? '${half.truncate()}' : '$half';
    final result = n * 5;
    return [
      LessonStep(
        caption: 'To multiply $n × 5, use the ÷2 then ×10 trick.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.45,
              text: '$n × 5 = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.45, endT: 0.85,
              text: '5 = 10 ÷ 2', fontSize: 22, color: _gray),
          DrawElement(type: DrawElementType.arrow, x: 180, y: 98, startT: 0.85, endT: 1.0,
              arrowEnd: const Offset(220, 98), color: _orange),
        ],
      ),
      LessonStep(
        caption: 'Step 1: Halve $n → $halfStr',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 80, startT: 0, endT: 0.6,
              text: '$n ÷ 2 = $halfStr', fontSize: 32, color: _orange, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.underline, x: 30, y: 88, startT: 0.6, endT: 1.0,
              lineWidth: 110, lineHeight: 2.5, color: _orange),
        ],
      ),
      LessonStep(
        caption: 'Step 2: Multiply by 10 (shift decimal right). $n × 5 = $result',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 72, startT: 0, endT: 0.5,
              text: '$halfStr × 10 = $result', fontSize: 30, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 115, startT: 0.5, endT: 1.0,
              text: '$n × 5 = $result', fontSize: 28, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 124, startT: 0.7, endT: 1.0,
              highlightWidth: 130, highlightHeight: 40, color: _green),
        ],
      ),
    ];
  }

  static List<LessonStep> _times25(int n) {
    final quarter = n / 4;
    final qStr = quarter == quarter.truncateToDouble() ? '${quarter.truncate()}' : '$quarter';
    final result = n * 25;
    return [
      LessonStep(
        caption: 'To multiply $n × 25, use the ÷4 then ×100 trick.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.45,
              text: '$n × 25 = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.45, endT: 1.0,
              text: '25 = 100 ÷ 4', fontSize: 22, color: Color(0xFF64748B)),
        ],
      ),
      LessonStep(
        caption: 'Step 1: Divide $n by 4 → $qStr',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 80, startT: 0, endT: 0.6,
              text: '$n ÷ 4 = $qStr', fontSize: 32, color: _orange, fontWeight: FontWeight.bold),
        ],
      ),
      LessonStep(
        caption: 'Step 2: Multiply by 100 (add two zeros). $n × 25 = $result',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 72, startT: 0, endT: 0.5,
              text: '$qStr × 100 = $result', fontSize: 28, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 112, startT: 0.5, endT: 1.0,
              text: '$n × 25 = $result', fontSize: 28, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 120, startT: 0.7, endT: 1.0,
              highlightWidth: 145, highlightHeight: 40, color: _green),
        ],
      ),
    ];
  }
}
