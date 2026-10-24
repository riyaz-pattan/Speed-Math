// lib/features/learn/builders/fraction_pct_friends_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_data.dart';

/// Fraction–% Friends: teaches key fraction ↔ percentage pairs.
class FractionPctFriendsBuilder {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF16A34A);
  static const Color _gray = Color(0xFF64748B);

  // [numerator, denominator, pct×10] e.g. [1,2,500] = 50.0%
  static const List<List<int>> _pairs = [
    [1, 2, 500],   // 50%
    [1, 4, 250],   // 25%
    [3, 4, 750],   // 75%
    [1, 8, 125],   // 12.5%
    [3, 8, 375],   // 37.5%
    [5, 8, 625],   // 62.5%
    [7, 8, 875],   // 87.5%
    [1, 3, 333],   // 33.3%
    [2, 3, 667],   // 66.7%
    [1, 5, 200],   // 20%
    [2, 5, 400],   // 40%
    [1, 6, 167],   // 16.7%
    [1, 9, 111],   // 11.1%
  ];

  static List<LessonStep> build(List<int> operands) {
    final idx = (operands.isNotEmpty ? operands[0] : 0) % _pairs.length;
    final pair = _pairs[idx];
    final num = pair[0];
    final den = pair[1];
    final pct10 = pair[2];
    final pctStr = pct10 % 10 == 0 ? '${pct10 ~/ 10}' : '${pct10 ~/ 10}.${pct10 % 10}';

    return [
      LessonStep(
        caption: 'Converting fractions to percentages is easy when you know key pairs.',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 58, startT: 0, endT: 0.4,
              text: '$num/$den = ?%', fontSize: 36, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.4, endT: 1.0,
              text: 'Think: 1 ÷ $den ≈ ${(100 / den).toStringAsFixed(1)}%', fontSize: 20, color: _gray),
        ],
      ),
      LessonStep(
        caption: 'Exact value: $num/$den = $pctStr%',
        elements: [
          DrawElement(type: DrawElementType.fractionBar, x: 30, y: 52, startT: 0, endT: 0.3,
              lineWidth: 28, lineHeight: 2.5, color: _orange),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 80, startT: 0.3, endT: 0.8,
              text: '$num/$den = $pctStr%', fontSize: 32, color: _orange, fontWeight: FontWeight.bold),
        ],
      ),
      LessonStep(
        caption: 'Memorise this pair — it comes up constantly!',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 80, startT: 0, endT: 0.6,
              text: '$num/$den ↔ $pctStr%', fontSize: 30, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 90, startT: 0.6, endT: 1.0,
              highlightWidth: 200, highlightHeight: 44, color: _green),
        ],
      ),
    ];
  }
}
