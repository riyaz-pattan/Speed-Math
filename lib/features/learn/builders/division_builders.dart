// lib/features/learn/builders/division_builders.dart
import 'package:flutter/material.dart';
import '../engine/lesson_block.dart';

// ─── 1. Divide by 5, 25 & 125 (Double-and-Shift Trick) ───────────────────────

class DivideBy5And25Builder {
  DivideBy5And25Builder._();

  static LessonScript build(List<int> operands) {
    final n = operands.isNotEmpty ? operands[0] : 340;
    final d = operands.length > 1 ? operands[1] : 5;

    if (d == 25) {
      return buildDiv25([n, 25]);
    } else if (d == 125) {
      return buildDiv125([n, 125]);
    }
    return buildDiv5([n, 5]);
  }

  static LessonScript buildDiv5(List<int> operands) {
    final n = operands.isNotEmpty ? operands[0] : 340;
    final doubled = n * 2;
    final hasDecimal = doubled % 10 != 0;
    final resultStr = hasDecimal ? '${doubled / 10}' : '${doubled ~/ 10}';

    return LessonScript(
      problemText: '$n ÷ 5 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1: The Multiplicative Inversion Trick',
          caption: 'Instead of dividing by 5, double the number and divide by 10.',
          blockHeight: 180,
          elements: [
            const BElement(
              type: BElementType.text,
              x: 16,
              y: 28,
              startT: 0.0,
              endT: 0.3,
              text: 'Shortcut Principle:',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: LessonColors.heading,
            ),
            const BElement(
              type: BElementType.text,
              x: 20,
              y: 58,
              startT: 0.2,
              endT: 0.5,
              text: 'N ÷ 5  =  (N × 2) ÷ 10',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            const BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 92,
              startT: 0.4,
              endT: 0.8,
              text: 'Multiplying by 2 is instant in your head. Dividing by 10 simply shifts the decimal point one place left!',
              fontSize: 14,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2: Double the Number',
          caption: 'Multiply $n by 2 to get $doubled.',
          blockHeight: 170,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.4,
              text: '$n × 2 = $doubled',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: LessonColors.ones,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 75,
              startT: 0.4,
              endT: 0.8,
              text: 'Quick breakdown: double each place value from left to right.',
              fontSize: 13,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3: Move Decimal Left 1 Place',
          caption: 'Divide $doubled by 10 to get $resultStr.',
          blockHeight: 190,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.4,
              text: '$doubled ÷ 10 = $resultStr',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            BElement(
              type: BElementType.text,
              x: 20,
              y: 75,
              startT: 0.4,
              endT: 0.8,
              text: 'Therefore: $n ÷ 5 = $resultStr ✓',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.result,
            ),
            const BElement(
              type: BElementType.highlight,
              x: 16,
              y: 65,
              startT: 0.7,
              endT: 1.0,
              width: 310,
              height: 48,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }

  static LessonScript buildDiv25(List<int> operands) {
    final n = operands.isNotEmpty ? operands[0] : 612;
    final quadrupled = n * 4;
    final hasDecimal = quadrupled % 100 != 0;
    final resultStr = hasDecimal ? '${quadrupled / 100}' : '${quadrupled ~/ 100}';

    return LessonScript(
      problemText: '$n ÷ 25 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1: The ÷ 25 Inversion Shortcut',
          caption: 'Since 25 = 100 ÷ 4, dividing by 25 is multiplying by 4 and shifting 2 places left.',
          blockHeight: 170,
          elements: [
            const BElement(
              type: BElementType.text,
              x: 20,
              y: 40,
              startT: 0.0,
              endT: 0.4,
              text: 'N ÷ 25  =  (N × 4) ÷ 100',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            const BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 80,
              startT: 0.3,
              endT: 0.8,
              text: 'Double twice (×2 then ×2), then move the decimal point two digits left.',
              fontSize: 14,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2: Quadruple (Double Twice)',
          caption: '$n × 2 = ${n * 2}, and ${n * 2} × 2 = $quadrupled.',
          blockHeight: 180,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.4,
              text: '1st double: $n × 2 = ${n * 2}',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LessonColors.heading,
            ),
            BElement(
              type: BElementType.text,
              x: 16,
              y: 65,
              startT: 0.4,
              endT: 0.8,
              text: '2nd double: ${n * 2} × 2 = $quadrupled',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: LessonColors.ones,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3: Move Decimal Left 2 Places',
          caption: '$quadrupled ÷ 100 = $resultStr.',
          blockHeight: 180,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.5,
              text: '$quadrupled ÷ 100 = $resultStr',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            BElement(
              type: BElementType.text,
              x: 20,
              y: 75,
              startT: 0.5,
              endT: 0.9,
              text: 'Answer: $n ÷ 25 = $resultStr ✓',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.result,
            ),
            const BElement(
              type: BElementType.highlight,
              x: 16,
              y: 65,
              startT: 0.7,
              endT: 1.0,
              width: 310,
              height: 48,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }

  static LessonScript buildDiv125(List<int> operands) {
    final n = operands.isNotEmpty ? operands[0] : 750;
    final x8 = n * 8;
    final hasDecimal = x8 % 1000 != 0;
    final resultStr = hasDecimal ? '${x8 / 1000}' : '${x8 ~/ 1000}';

    return LessonScript(
      problemText: '$n ÷ 125 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1: The ÷ 125 Inversion Shortcut',
          caption: 'Since 125 = 1000 ÷ 8, dividing by 125 is multiplying by 8 and dividing by 1000.',
          blockHeight: 170,
          elements: [
            const BElement(
              type: BElementType.text,
              x: 20,
              y: 40,
              startT: 0.0,
              endT: 0.4,
              text: 'N ÷ 125  =  (N × 8) ÷ 1000',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            const BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 80,
              startT: 0.3,
              endT: 0.8,
              text: 'Double 3 times (×2, ×2, ×2), then move the decimal point 3 digits left.',
              fontSize: 14,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2: Multiply by 8 (Triple Double)',
          caption: '$n × 8 = $x8.',
          blockHeight: 180,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.4,
              text: '$n × 2 = ${n * 2} → ${n * 4} → $x8',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.ones,
            ),
            const BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 75,
              startT: 0.4,
              endT: 0.8,
              text: 'Double 1st: ×2, Double 2nd: ×4, Double 3rd: ×8.',
              fontSize: 13,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3: Shift 3 Places Left',
          caption: '$x8 ÷ 1000 = $resultStr.',
          blockHeight: 180,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.5,
              text: '$x8 ÷ 1000 = $resultStr',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            BElement(
              type: BElementType.text,
              x: 20,
              y: 75,
              startT: 0.5,
              endT: 0.9,
              text: 'Answer: $n ÷ 125 = $resultStr ✓',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 2. Division by 9 & 99 (Vedic Running Sum / Nikhilam) ────────────────────

class DivideBy9And99Builder {
  DivideBy9And99Builder._();

  static LessonScript build(List<int> operands) {
    final n = operands.isNotEmpty ? operands[0] : 1214;
    return buildDiv9([n, 9]);
  }

  static LessonScript buildDiv9(List<int> operands) {
    final n = operands.isNotEmpty ? operands[0] : 1214;
    final s = '$n';
    final digits = s.split('').map(int.parse).toList();

    // Compute running sums
    final running = <int>[];
    var currentSum = 0;
    for (int i = 0; i < digits.length; i++) {
      currentSum += digits[i];
      running.add(currentSum);
    }

    final quotientDigits = running.sublist(0, running.length - 1);
    final remainder = running.last;
    final quotient = n ~/ 9;
    final exactRem = n % 9;

    return LessonScript(
      problemText: '$n ÷ 9 = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1: The Vedic Running Sum Rule',
          caption: 'When dividing by 9, quotient digits are the running sums of the dividend digits!',
          blockHeight: 180,
          elements: [
            const BElement(
              type: BElementType.text,
              x: 16,
              y: 28,
              startT: 0.0,
              endT: 0.3,
              text: 'No division is needed — only simple addition!',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: LessonColors.heading,
            ),
            BElement(
              type: BElementType.text,
              x: 20,
              y: 58,
              startT: 0.2,
              endT: 0.6,
              text: 'Dividend:  ${digits.join("   ")}',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            const BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 92,
              startT: 0.4,
              endT: 0.8,
              text: 'Bring down the 1st digit, then add each digit to the running total.',
              fontSize: 13,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2: Calculate Running Sums',
          caption: 'Quotient digits: ${quotientDigits.join(", ")}, Remainder: $remainder',
          blockHeight: 200,
          elements: [
            ...List.generate(digits.length, (idx) {
              final d = digits[idx];
              final r = running[idx];
              final isLast = idx == digits.length - 1;
              final label = isLast
                  ? 'Last (Remainder): $r'
                  : 'Digit ${idx + 1}: ${idx == 0 ? "$d" : "${running[idx - 1]} + $d = $r"}';
              return BElement(
                type: BElementType.text,
                x: 16,
                y: 28.0 + idx * 32.0,
                startT: 0.1 * idx,
                endT: 0.1 * idx + 0.3,
                text: label,
                fontSize: 16,
                fontWeight: isLast ? FontWeight.w900 : FontWeight.w700,
                color: isLast ? LessonColors.carry : LessonColors.ones,
              );
            }),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3: Combine Quotient and Remainder',
          caption: 'Quotient = $quotient, Remainder = $exactRem.',
          blockHeight: 180,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.5,
              text: 'Quotient = $quotient',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            BElement(
              type: BElementType.text,
              x: 16,
              y: 65,
              startT: 0.3,
              endT: 0.7,
              text: 'Remainder = $exactRem  ($exactRem/9 = ${(exactRem / 9).toStringAsFixed(2)}...)',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: LessonColors.carry,
            ),
            BElement(
              type: BElementType.text,
              x: 20,
              y: 105,
              startT: 0.6,
              endT: 1.0,
              text: '$n ÷ 9 = $quotient R $exactRem ✓',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 3. Factor Division (Splitting Composite Divisors) ───────────────────────

class FactorDivisionBuilder {
  FactorDivisionBuilder._();

  static LessonScript build(List<int> operands) {
    final n = operands.isNotEmpty ? operands[0] : 1620;
    final d = operands.length > 1 ? operands[1] : 45;

    // Find two nice 1-digit factors (f1, f2)
    int f1 = 9;
    int f2 = 5;
    if (d == 36) {
      f1 = 6;
      f2 = 6;
    } else if (d == 24) {
      f1 = 8;
      f2 = 3;
    } else if (d == 18) {
      f1 = 9;
      f2 = 2;
    } else if (d == 15) {
      f1 = 5;
      f2 = 3;
    } else if (d == 14) {
      f1 = 7;
      f2 = 2;
    }

    final mid = n ~/ f1;
    final result = mid ~/ f2;

    return LessonScript(
      problemText: '$n ÷ $d = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1: Decompose the Divisor',
          caption: 'Instead of dividing by $d, split $d into factors $f1 and $f2.',
          blockHeight: 170,
          elements: [
            BElement(
              type: BElementType.text,
              x: 20,
              y: 35,
              startT: 0.0,
              endT: 0.4,
              text: '$d = $f1 × $f2',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 75,
              startT: 0.3,
              endT: 0.8,
              text: 'Dividing sequentially by single digits is vastly faster than 2-digit long division!',
              fontSize: 14,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2: Divide by the First Factor ($f1)',
          caption: '$n ÷ $f1 = $mid.',
          blockHeight: 170,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.5,
              text: '$n ÷ $f1 = $mid',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: LessonColors.ones,
            ),
            const BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 75,
              startT: 0.4,
              endT: 0.8,
              text: 'Single-digit division can easily be completed left-to-right mentally.',
              fontSize: 13,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 3: Divide by the Second Factor ($f2)',
          caption: '$mid ÷ $f2 = $result.',
          blockHeight: 180,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.5,
              text: '$mid ÷ $f2 = $result',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            BElement(
              type: BElementType.text,
              x: 20,
              y: 75,
              startT: 0.5,
              endT: 0.9,
              text: 'Final Answer: $n ÷ $d = $result ✓',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.result,
            ),
            const BElement(
              type: BElementType.highlight,
              x: 16,
              y: 65,
              startT: 0.7,
              endT: 1.0,
              width: 310,
              height: 48,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 4. Reciprocal & Fraction Replacement Shortcut ───────────────────────────

class ReciprocalDivisionBuilder {
  ReciprocalDivisionBuilder._();

  static LessonScript build(List<int> operands) {
    final n = operands.isNotEmpty ? operands[0] : 140;

    return LessonScript(
      problemText: '$n ÷ 2.5 = ?',
      blocks: [
        const LessonBlock(
          stepTitle: 'Step 1: Decimal to Fraction Inversion',
          caption: 'Dividing by decimals is converted to whole multiplications.',
          blockHeight: 190,
          elements: [
            BElement(
              type: BElementType.text,
              x: 20,
              y: 30,
              startT: 0.0,
              endT: 0.3,
              text: 'Golden Reciprocal Pairs:',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: LessonColors.heading,
            ),
            BElement(
              type: BElementType.text,
              x: 20,
              y: 60,
              startT: 0.2,
              endT: 0.6,
              text: '÷ 0.5  →  × 2\n÷ 0.25 →  × 4\n÷ 2.5   →  × 4 ÷ 10 (or × 0.4)\n÷ 0.125 →  × 8',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2: Apply to $n ÷ 2.5',
          caption: '$n × 4 = ${n * 4}, then divide by 10.',
          blockHeight: 180,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 30,
              startT: 0.0,
              endT: 0.4,
              text: 'Multiply by 4: $n × 4 = ${n * 4}',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.ones,
            ),
            BElement(
              type: BElementType.text,
              x: 16,
              y: 70,
              startT: 0.4,
              endT: 0.8,
              text: 'Divide by 10: ${n * 4} ÷ 10 = ${n * 4 ~/ 10}',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            BElement(
              type: BElementType.text,
              x: 20,
              y: 110,
              startT: 0.6,
              endT: 1.0,
              text: 'Result: $n ÷ 2.5 = ${n * 4 ~/ 10} ✓',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 5. Straight Division / Flag Method (Dhvajanka) ──────────────────────────

class FlagDivisionBuilder {
  FlagDivisionBuilder._();

  static LessonScript build(List<int> operands) {
    final a = operands.isNotEmpty ? operands[0] : 4536;
    final b = operands.length > 1 ? operands[1] : 54;

    // 4536 ÷ 54: Base divisor = 5, Flag = 4
    final baseDiv = b ~/ 10;
    final flag = b % 10;
    final quotient = a ~/ b;
    final remainder = a % b;

    return LessonScript(
      problemText: '$a ÷ $b = ?',
      blocks: [
        LessonBlock(
          stepTitle: 'Step 1: Set Up Base & Flag Digit',
          caption: 'Split the divisor $b into Main Divisor ($baseDiv) and Flag Digit ($flag).',
          blockHeight: 180,
          elements: [
            BElement(
              type: BElementType.text,
              x: 20,
              y: 30,
              startT: 0.0,
              endT: 0.4,
              text: 'Divisor $b → Base: $baseDiv,  Flag: ^$flag',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: LessonColors.tens,
            ),
            const BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 70,
              startT: 0.3,
              endT: 0.8,
              text: 'The Flag Method turns any multi-digit division into easy single-digit division by the Base, with a small mental cross-subtraction from the Flag!',
              fontSize: 13,
              color: LessonColors.note,
            ),
          ],
        ),
        LessonBlock(
          stepTitle: 'Step 2: Single-Line Straight Division',
          caption: 'Divide by $baseDiv, then adjust by subtracting (Flag × Quotient).',
          blockHeight: 190,
          elements: [
            BElement(
              type: BElementType.text,
              x: 16,
              y: 28,
              startT: 0.0,
              endT: 0.4,
              text: 'Quotient = $quotient',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: LessonColors.ones,
            ),
            BElement(
              type: BElementType.text,
              x: 16,
              y: 65,
              startT: 0.4,
              endT: 0.8,
              text: 'Remainder = $remainder',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: LessonColors.carry,
            ),
            BElement(
              type: BElementType.sideNote,
              x: 20,
              y: 100,
              startT: 0.6,
              endT: 1.0,
              text: 'Check: $b × $quotient + $remainder = ${b * quotient + remainder} ✓',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: LessonColors.result,
            ),
          ],
        ),
      ],
    );
  }
}
