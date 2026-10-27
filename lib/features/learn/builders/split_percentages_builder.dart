// lib/features/learn/builders/split_percentages_builder.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

/// Split Percentages: decompose % into whole hundreds, 50%, grouped tens (k × 10%), 5%, and 1% chunks.
/// e.g. 15% of 240 = 10% (24) + 5% (12) = 36
/// e.g. 35% of 240 = 30% (3 × 24 = 72) + 5% (12) = 84
/// e.g. 750% of 240 = 700% (7 × 240 = 1680) + 50% (120) = 1800
class SplitPercentagesBuilder {
  static LessonScript build(List<int> operands) {
    final pct = operands[0];
    final n = operands[1];
    final tenPct = (n / 10).round();
    final fivePct = (tenPct / 2).round();
    final result = (n * pct / 100).round();

    // Decomposition parts
    final List<String> parts = [];
    final List<String> partValues = [];
    int rem = pct;

    // 1. Hundreds
    if (rem >= 100) {
      final hCount = rem ~/ 100;
      final hVal = hCount * n;
      parts.add('${hCount * 100}% ($hCount × 100%)');
      partValues.add('$hVal');
      rem %= 100;
    }

    // 2. 50%
    if (rem >= 50) {
      final fiftyVal = n ~/ 2;
      parts.add('50%');
      partValues.add('$fiftyVal');
      rem -= 50;
    }

    // 3. Grouped tens
    final tens = (rem ~/ 10) * 10;
    if (tens > 0) {
      final k = tens ~/ 10;
      final tVal = k * tenPct;
      if (k == 1) {
        parts.add('10%');
      } else {
        parts.add('$tens% ($k × 10%)');
      }
      partValues.add('$tVal');
      rem -= tens;
    }

    // 4. 5%
    if (rem >= 5) {
      parts.add('5%');
      partValues.add('$fivePct');
      rem -= 5;
    }

    // 5. Units
    if (rem > 0) {
      final uVal = (n * rem / 100).round();
      parts.add('$rem%');
      partValues.add('$uVal');
    }

    final decomp = parts.join(' + ');
    final sumStr = partValues.join(' + ');

    return LessonScript(
      problemText: '$pct% of $n = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1',
          caption: 'Break $pct% down into friendly chunks: $decomp.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.45,
              text: '$pct%  of  $n  =  ?',
              fontSize: 34,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 80,
              startT: 0.45, endT: 0.8,
              text: '$pct%  =  $decomp',
              fontSize: 22,
              color: LessonColors.note,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 230, y: 80,
              startT: 0.75, endT: 1.0,
              text: 'easy chunks',
              color: LessonColors.note,
              fontSize: 16,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2',
          caption: 'Find 10% of $n: move decimal 1 place left → $tenPct.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.55,
              text: '10%  of  $n  =  $tenPct',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 210, y: 38,
              startT: 0.55, endT: 0.85,
              text: 'anchor value',
              color: LessonColors.note,
              fontSize: 16,
            ),
            BElement(
              type: BElementType.underline,
              x: 36, y: 52,
              startT: 0.7, endT: 1.0,
              width: 155,
              strokeWidth: 2.5,
              color: LessonColors.tens,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3',
          caption: 'Derive parts from primary anchors: $decomp.',
          blockHeight: 110,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.7,
              text: 'Parts:  $sumStr',
              fontSize: 26,
              color: LessonColors.ones,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 4',
          caption: 'Sum the parts: $sumStr = $result.',
          blockHeight: 120,
          elements: [
            BElement(
              type: BElementType.text,
              x: 36, y: 38,
              startT: 0.0, endT: 0.5,
              text: '$sumStr  =  $result',
              fontSize: 30,
              color: LessonColors.tens,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.text,
              x: 36, y: 82,
              startT: 0.55, endT: 0.85,
              text: '$pct% of $n  =  $result',
              fontSize: 30,
              color: LessonColors.result,
              fontWeight: FontWeight.bold,
            ),
            BElement(
              type: BElementType.highlight,
              x: 26, y: 95,
              startT: 0.82, endT: 1.0,
              width: 180,
              height: 42,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}
