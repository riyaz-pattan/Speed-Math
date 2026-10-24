// lib/features/learn/builders/split_percentages_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_data.dart';

/// Split Percentages: 15% of N = 10% + 5%.
class SplitPercentagesBuilder {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _orange = Color(0xFFF97316);
  static const Color _green = Color(0xFF16A34A);
  static const Color _gray = Color(0xFF64748B);

  static List<LessonStep> build(List<int> operands) {
    final pct = operands[0];
    final n = operands[1];
    final tenPct = n ~/ 10;
    final fivePct = tenPct ~/ 2;
    final result = n * pct ~/ 100;

    // Build decomposition string
    final List<String> parts = [];
    int rem = pct;
    while (rem >= 10) { parts.add('10%'); rem -= 10; }
    if (rem >= 5) { parts.add('5%'); rem -= 5; }
    if (rem > 0) parts.add('$rem%');
    final decomp = parts.join(' + ');

    return [
      LessonStep(
        caption: '$pct% of $n — split into easy parts!',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 65, startT: 0, endT: 0.45,
              text: '$pct% of $n = ?', fontSize: 34, color: _blue, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 108, startT: 0.45, endT: 1.0,
              text: '$pct% = $decomp', fontSize: 22, color: _gray),
        ],
      ),
      LessonStep(
        caption: '10% of $n = $tenPct (move decimal left once).',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 80, startT: 0, endT: 0.6,
              text: '10% of $n = $tenPct', fontSize: 28, color: _orange, fontWeight: FontWeight.bold),
        ],
      ),
      LessonStep(
        caption: '5% = half of 10% = $fivePct. Add all parts → $pct% of $n = $result',
        elements: [
          DrawElement(type: DrawElementType.writtenText, x: 30, y: 80, startT: 0, endT: 0.5,
              text: '$pct% of $n = $result', fontSize: 32, color: _green, fontWeight: FontWeight.bold),
          DrawElement(type: DrawElementType.highlight, x: 20, y: 90, startT: 0.5, endT: 1.0,
              highlightWidth: 195, highlightHeight: 44, color: _green),
        ],
      ),
    ];
  }
}
