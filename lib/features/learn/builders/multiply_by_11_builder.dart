// lib/features/learn/builders/multiply_by_11_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_data.dart';

/// × 11 trick: place digit-sum between the two end digits.
class MultiplyBy11Builder {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFF97316);
  static const Color _red = Color(0xFFDC2626);
  static const Color _green = Color(0xFF16A34A);
  static const Color _gray = Color(0xFF64748B);

  static List<LessonStep> build(List<int> operands) {
    final n = operands[0];
    final tens = n ~/ 10;
    final ones = n % 10;
    final mid = tens + ones;
    final result = n * 11;
    return mid < 10 ? _simple(n, tens, ones, mid, result) : _carry(n, tens, ones, mid, result);
  }

  static List<LessonStep> _simple(int n, int tens, int ones, int mid, int result) => [
        LessonStep(
          caption: 'For $n × 11: write the outer digits and insert their sum in the middle.',
          elements: [
            DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.45,
                text: '$n × 11 = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
            DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.45, endT: 1.0,
                text: 'Write: $tens _ $ones', fontSize: 26, color: _gray),
          ],
        ),
        LessonStep(
          caption: 'Sum the digits: $tens + $ones = $mid. Insert it in the blank.',
          elements: [
            DrawElement(type: DrawElementType.writtenText, x: 30, y: 70, startT: 0, endT: 0.5,
                text: '$tens + $ones = $mid', fontSize: 28, color: _orange, fontWeight: FontWeight.bold),
            DrawElement(type: DrawElementType.arrow, x: 118, y: 58, startT: 0.5, endT: 0.8,
                arrowEnd: const Offset(155, 95), color: _orange),
            DrawElement(type: DrawElementType.writtenText, x: 140, y: 115, startT: 0.8, endT: 1.0,
                text: '$tens$mid$ones', fontSize: 36, color: _green, fontWeight: FontWeight.bold),
          ],
        ),
        LessonStep(
          caption: '$n × 11 = $result ✓',
          elements: [
            DrawElement(type: DrawElementType.writtenText, x: 30, y: 88, startT: 0, endT: 0.6,
                text: '$n × 11 = $result', fontSize: 36, color: _green, fontWeight: FontWeight.bold),
            DrawElement(type: DrawElementType.highlight, x: 20, y: 98, startT: 0.6, endT: 1.0,
                highlightWidth: 215, highlightHeight: 48, color: _green),
          ],
        ),
      ];

  static List<LessonStep> _carry(int n, int tens, int ones, int mid, int result) {
    final newTens = tens + 1;
    final midDigit = mid % 10;
    return [
      LessonStep(
        caption: 'For $n × 11: write outer digits and insert their sum.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.45,
              text: '$n × 11 = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.45, endT: 1.0,
              text: 'Write: $tens _ $ones', fontSize: 26, color: Color(0xFF64748B)),
        ],
      ),
      LessonStep(
        caption: '$tens + $ones = $mid (≥10). Write $midDigit, carry 1 → $tens becomes $newTens.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.4,
              text: '$tens + $ones = $mid', fontSize: 28, color: _orange, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 104, startT: 0.4, endT: 0.7,
              text: 'carry 1 → $tens becomes $newTens', fontSize: 20, color: _red),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 145, startT: 0.7, endT: 1.0,
              text: '$newTens$midDigit$ones', fontSize: 36, color: _green, fontWeight: FontWeight.bold),
        ],
      ),
      LessonStep(
        caption: '$n × 11 = $result ✓',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 88, startT: 0, endT: 0.6,
              text: '$n × 11 = $result', fontSize: 36, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 98, startT: 0.6, endT: 1.0,
              highlightWidth: 215, highlightHeight: 48, color: _green),
        ],
      ),
    ];
  }
}
