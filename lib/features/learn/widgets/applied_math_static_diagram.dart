// lib/features/learn/widgets/applied_math_static_diagram.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme.dart';

/// Step data representation for Applied Maths shortcut visual cards.
class AppliedMathStepData {
  const AppliedMathStepData({
    required this.stepNumber,
    required this.title,
    required this.badge,
    required this.mainFormula,
    required this.explanation,
    required this.resultHighlight,
    this.subNote,
    this.isFinal = false,
  });

  final int stepNumber;
  final String title;
  final String badge;
  final String mainFormula;
  final String explanation;
  final String resultHighlight;
  final String? subNote;
  final bool isFinal;
}

String _fmt(num v) {
  if (v == v.truncate()) return '${v.truncate()}';
  final s = v.toStringAsFixed(2);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. SPLIT PERCENTAGES STEP CALCULATOR
// ─────────────────────────────────────────────────────────────────────────────

List<AppliedMathStepData> computeSplitPercentagesSteps(num pct, num n) {
  final result = (n * pct) / 100.0;
  final resultStr = _fmt(result);
  final nStr = _fmt(n);
  final pctStr = _fmt(pct);

  final tenPct = n / 10.0;
  final onePct = n / 100.0;
  final fiftyPct = n / 2.0;

  // ── Strategy Selection ─────────────────────────────────────────────────────

  // Strategy 0: Percentages >= 100% (e.g. 150%, 250%, 750%, etc.)
  if (pct >= 100) {
    final hundredsK = pct ~/ 100;
    final hundredsPct = hundredsK * 100;
    final rem = pct - hundredsPct;
    final hundredsVal = (n * hundredsPct) / 100.0;

    if (rem == 0) {
      return [
        AppliedMathStepData(
          stepNumber: 1,
          title: 'Multiple of 100% Anchor',
          badge: '$pctStr%  ≡  $hundredsK × 100%',
          mainFormula: '$pctStr% of $nStr = $hundredsK × $nStr',
          explanation:
              'Any multiple of 100% is simply multiplying the base number $nStr by $hundredsK. 100% of $nStr is $nStr, so $pctStr% is $hundredsK × $nStr.',
          resultHighlight: '$pctStr% = $hundredsK × $nStr',
        ),
        AppliedMathStepData(
          stepNumber: 2,
          title: 'Direct Base Multiplication',
          badge: '$hundredsK × $nStr = $resultStr',
          mainFormula: '$hundredsK × $nStr = $resultStr',
          explanation:
              'Multiply the whole base by $hundredsK:\n$hundredsK × $nStr = $resultStr ✓\nInstant calculation with zero pencil work.',
          resultHighlight: '$pctStr% of $nStr = $resultStr',
          isFinal: true,
        ),
      ];
    }

    final remVal = (n * rem) / 100.0;
    final remStr = _fmt(rem);
    final remValStr = _fmt(remVal);
    final hundredsValStr = _fmt(hundredsVal);

    String remFormula;
    String remExplanation;
    if (rem == 50) {
      remFormula = '50% = $nStr ÷ 2 = $remValStr';
      remExplanation = '50% of any number is half of the base: $nStr ÷ 2 = $remValStr.';
    } else if (rem == 25) {
      remFormula = '25% = $nStr ÷ 4 = $remValStr';
      remExplanation = '25% of any number is one quarter: $nStr ÷ 4 = $remValStr.';
    } else if (rem % 10 == 0) {
      final tensK = (rem ~/ 10);
      remFormula = '$remStr% = $tensK × (10% of $nStr) = $tensK × ${_fmt(tenPct)} = $remValStr';
      remExplanation = '10% of $nStr is ${_fmt(tenPct)}. Multiply by $tensK to get $remValStr.';
    } else {
      remFormula = '$remStr% of $nStr = $remValStr';
      remExplanation = 'Calculate the remainder chunk $remStr% of $nStr = $remValStr.';
    }

    return [
      AppliedMathStepData(
        stepNumber: 1,
        title: 'Benchmark Decomposition',
        badge: '$pctStr%  ≡  $hundredsPct% + $remStr%',
        mainFormula: '$pctStr% of $nStr = ($hundredsPct% + $remStr%) of $nStr',
        explanation:
            'Separate $pctStr% into whole hundreds ($hundredsPct%) and the remainder chunk ($remStr%). Never split hundreds into dozens of tiny 10% slices!',
        resultHighlight: 'Decomposition: $hundredsPct% + $remStr%',
      ),
      AppliedMathStepData(
        stepNumber: 2,
        title: 'Calculate Hundreds: $hundredsPct%',
        badge: '$hundredsPct% of $nStr = $hundredsValStr',
        mainFormula: '$hundredsPct% = $hundredsK × $nStr = $hundredsValStr',
        explanation:
            '100% of $nStr is $nStr.\n$hundredsPct% is $hundredsK × $nStr = $hundredsValStr.\nFast, exact mental multiplication.',
        resultHighlight: '$hundredsPct% Anchor = $hundredsValStr',
      ),
      AppliedMathStepData(
        stepNumber: 3,
        title: 'Calculate Remainder: $remStr%',
        badge: '$remStr% of $nStr = $remValStr',
        mainFormula: remFormula,
        explanation: remExplanation,
        resultHighlight: 'Remainder Chunk = $remValStr',
      ),
      AppliedMathStepData(
        stepNumber: 4,
        title: 'Mental Summation',
        badge: '$hundredsValStr + $remValStr = $resultStr',
        mainFormula: '$pctStr% of $nStr = $hundredsValStr + $remValStr = $resultStr',
        explanation:
            'Add the whole hundreds chunk and the remainder chunk:\n$hundredsValStr + $remValStr = $resultStr ✓',
        resultHighlight: '$pctStr% of $nStr = $resultStr',
        isFinal: true,
      ),
    ];
  }

  // Strategy A: Subtractive from 50% (45% to 49%)
  if (pct >= 45 && pct < 50) {
    final diff = 50 - pct;
    final diffVal = (n * diff) / 100.0;
    return [
      AppliedMathStepData(
        stepNumber: 1,
        title: 'Benchmark Decomposition',
        badge: '$pctStr%  ≡  50% − ${_fmt(diff)}%',
        mainFormula: '$pctStr% of $nStr = (50% − ${_fmt(diff)}%) of $nStr',
        explanation:
            '$pctStr% is just ${_fmt(diff)}% below 50%. It is 3× faster to calculate 50% (half of $nStr) and subtract the small ${_fmt(diff)}% chunk than adding multiple smaller parts.',
        resultHighlight: 'Decomposition: 50% − ${_fmt(diff)}%',
      ),
      AppliedMathStepData(
        stepNumber: 2,
        title: 'Calculate 50% (Halve)',
        badge: '50% of $nStr = ${_fmt(fiftyPct)}',
        mainFormula: '$nStr ÷ 2 = ${_fmt(fiftyPct)}',
        explanation:
            'Finding 50% of any number is simply dividing by 2:\n$nStr ÷ 2 = ${_fmt(fiftyPct)}.\nThis forms your primary mental anchor.',
        resultHighlight: '50% Anchor = ${_fmt(fiftyPct)}',
      ),
      AppliedMathStepData(
        stepNumber: 3,
        title: 'Calculate ${_fmt(diff)}% Chunk',
        badge: '${_fmt(diff)}% of $nStr = ${_fmt(diffVal)}',
        mainFormula: diff == 5
            ? '5% = 50% ÷ 10 = ${_fmt(fiftyPct)} ÷ 10 = ${_fmt(diffVal)}'
            : '${_fmt(diff)}% = ${_fmt(diff)} × (1% of $nStr) = ${_fmt(diff)} × ${_fmt(onePct)} = ${_fmt(diffVal)}',
        explanation: diff == 5
            ? '5% is exactly one-tenth of 50%. Shift the decimal left once: ${_fmt(fiftyPct)} → ${_fmt(diffVal)}.'
            : '1% of $nStr is ${_fmt(onePct)} (shift 2 places left). Multiply by $diff: ${_fmt(diff)} × ${_fmt(onePct)} = ${_fmt(diffVal)}.',
        resultHighlight: 'Subtracted Chunk = ${_fmt(diffVal)}',
      ),
      AppliedMathStepData(
        stepNumber: 4,
        title: 'Mental Subtraction',
        badge: '${_fmt(fiftyPct)} − ${_fmt(diffVal)} = $resultStr',
        mainFormula: '$pctStr% of $nStr = ${_fmt(fiftyPct)} − ${_fmt(diffVal)} = $resultStr',
        explanation:
            'Subtract the small chunk from your 50% anchor:\n${_fmt(fiftyPct)} − ${_fmt(diffVal)} = $resultStr ✓\nCompleted entirely in memory!',
        resultHighlight: '$pctStr% of $nStr = $resultStr',
        isFinal: true,
      ),
    ];
  }

  // Strategy B: Subtractive from 100% (88% to 99%)
  if (pct >= 88 && pct < 100) {
    final diff = 100 - pct;
    final diffVal = (n * diff) / 100.0;
    return [
      AppliedMathStepData(
        stepNumber: 1,
        title: 'Benchmark Decomposition',
        badge: '$pctStr%  ≡  100% − ${_fmt(diff)}%',
        mainFormula: '$pctStr% of $nStr = (100% − ${_fmt(diff)}%) of $nStr',
        explanation:
            '$pctStr% is very close to 100%. Multiplying by $pct is slow; subtracting the ${_fmt(diff)}% deficit from the whole number $nStr takes only 2 seconds.',
        resultHighlight: 'Decomposition: 100% − ${_fmt(diff)}%',
      ),
      AppliedMathStepData(
        stepNumber: 2,
        title: 'Base Anchor (100%)',
        badge: '100% of $nStr = $nStr',
        mainFormula: '100% = $nStr',
        explanation:
            '100% of any number is the number itself ($nStr). No calculation required.',
        resultHighlight: 'Whole Base = $nStr',
      ),
      AppliedMathStepData(
        stepNumber: 3,
        title: 'Calculate Deficit (${_fmt(diff)}%)',
        badge: '${_fmt(diff)}% of $nStr = ${_fmt(diffVal)}',
        mainFormula: diff == 10
            ? '10% = $nStr ÷ 10 = ${_fmt(tenPct)}'
            : diff == 5
                ? '5% = 10% ÷ 2 = ${_fmt(tenPct / 2)}'
                : '${_fmt(diff)} × (1% of $nStr) = ${_fmt(diff)} × ${_fmt(onePct)} = ${_fmt(diffVal)}',
        explanation:
            'Compute the deficit: shift decimal left by 1 place for 10% or 2 places for 1%, then scale by $diff to get ${_fmt(diffVal)}.',
        resultHighlight: 'Deficit Chunk = ${_fmt(diffVal)}',
      ),
      AppliedMathStepData(
        stepNumber: 4,
        title: 'Mental Subtraction',
        badge: '$nStr − ${_fmt(diffVal)} = $resultStr',
        mainFormula: '$pctStr% of $nStr = $nStr − ${_fmt(diffVal)} = $resultStr',
        explanation:
            'Subtract the deficit from the whole base:\n$nStr − ${_fmt(diffVal)} = $resultStr ✓',
        resultHighlight: '$pctStr% of $nStr = $resultStr',
        isFinal: true,
      ),
    ];
  }

  // Strategy C: Compound Decimal Chunk (e.g. 17.5%, 22.5%)
  if (pct == 17.5) {
    final v10 = n * 0.10;
    final v5 = n * 0.05;
    final v25 = n * 0.025;
    return [
      AppliedMathStepData(
        stepNumber: 1,
        title: 'Benchmark Decomposition',
        badge: '17.5%  ≡  10% + 5% + 2.5%',
        mainFormula: '17.5% = 10% + (10% ÷ 2) + (5% ÷ 2)',
        explanation:
            '17.5% appears constantly in percentage calculations. Break it down into half-steps:\n10% → halve to 5% → halve again to 2.5%!',
        resultHighlight: 'Cascade: 10% → 5% → 2.5%',
      ),
      AppliedMathStepData(
        stepNumber: 2,
        title: 'Primary Anchor: 10%',
        badge: '10% of $nStr = ${_fmt(v10)}',
        mainFormula: '$nStr ÷ 10 = ${_fmt(v10)}',
        explanation:
            'Move the decimal point 1 place left: $nStr ÷ 10 = ${_fmt(v10)}.',
        resultHighlight: '10% = ${_fmt(v10)}',
      ),
      AppliedMathStepData(
        stepNumber: 3,
        title: 'Halving Cascade: 5% and 2.5%',
        badge: '5% = ${_fmt(v5)}  |  2.5% = ${_fmt(v25)}',
        mainFormula: '5% = ${_fmt(v10)} ÷ 2 = ${_fmt(v5)}   →   2.5% = ${_fmt(v5)} ÷ 2 = ${_fmt(v25)}',
        explanation:
            'Halve 10% to get 5%: ${_fmt(v10)} ÷ 2 = ${_fmt(v5)}.\nHalve 5% to get 2.5%: ${_fmt(v5)} ÷ 2 = ${_fmt(v25)}.\nZero pencil work needed.',
        resultHighlight: '5% = ${_fmt(v5)},  2.5% = ${_fmt(v25)}',
      ),
      AppliedMathStepData(
        stepNumber: 4,
        title: 'Mental Sum Cascade',
        badge: '${_fmt(v10)} + ${_fmt(v5)} + ${_fmt(v25)} = $resultStr',
        mainFormula: '17.5% of $nStr = ${_fmt(v10)} + ${_fmt(v5)} + ${_fmt(v25)} = $resultStr',
        explanation:
            'Add the three chunks from left to right:\n${_fmt(v10)} + ${_fmt(v5)} = ${_fmt(v10 + v5)}\n${_fmt(v10 + v5)} + ${_fmt(v25)} = $resultStr ✓',
        resultHighlight: '17.5% of $nStr = $resultStr',
        isFinal: true,
      ),
    ];
  }

  // Strategy D: Standard Additive Benchmark Decomposition (with Grouped Multipliers!)
  // Avoids repeating "10% + 10% + 10%" — groups into (k × 10%)
  final List<String> chunkLabels = [];
  final List<double> chunkPcts = [];
  final List<String> chunkFormulas = [];
  final List<double> chunkValues = [];

  double remaining = pct.toDouble();

  // 1. Check for 50% anchor if pct >= 50
  if (remaining >= 50) {
    chunkLabels.add('50%');
    chunkPcts.add(50.0);
    chunkFormulas.add('50% = $nStr ÷ 2 = ${_fmt(fiftyPct)}');
    chunkValues.add(fiftyPct);
    remaining -= 50;
  } else if (remaining >= 25 && remaining < 30) {
    // 25% anchor for 25% or 27.5%
    final qtr = n / 4.0;
    chunkLabels.add('25%');
    chunkPcts.add(25.0);
    chunkFormulas.add('25% = $nStr ÷ 4 = ${_fmt(qtr)}');
    chunkValues.add(qtr);
    remaining -= 25;
  }

  // 2. Check for tens (group into k × 10% instead of repeated 10% + 10% + ...)
  final tensPart = (remaining ~/ 10) * 10;
  if (tensPart > 0) {
    final k = tensPart ~/ 10;
    final val = k * tenPct;
    if (k == 1) {
      chunkLabels.add('10%');
      chunkPcts.add(10.0);
      chunkFormulas.add('10% = $nStr ÷ 10 = ${_fmt(tenPct)}');
      chunkValues.add(tenPct);
    } else {
      chunkLabels.add('$tensPart% ($k × 10%)');
      chunkPcts.add(tensPart.toDouble());
      chunkFormulas.add('$tensPart% = $k × (10% of $nStr) = $k × ${_fmt(tenPct)} = ${_fmt(val)}');
      chunkValues.add(val);
    }
    remaining -= tensPart;
  }

  // 3. Check for 5%
  if (remaining >= 5) {
    final fv = tenPct / 2.0;
    chunkLabels.add('5%');
    chunkPcts.add(5.0);
    chunkFormulas.add('5% = 10% ÷ 2 = ${_fmt(tenPct)} ÷ 2 = ${_fmt(fv)}');
    chunkValues.add(fv);
    remaining -= 5;
  }

  // 4. Remaining single digits (if any, e.g. 1%, 2%, 3%)
  if (remaining > 0) {
    final val = (n * remaining) / 100.0;
    final rStr = _fmt(remaining);
    if (remaining == 1) {
      chunkLabels.add('1%');
      chunkFormulas.add('1% = $nStr ÷ 100 = ${_fmt(onePct)}');
    } else {
      chunkLabels.add('$rStr% ($rStr × 1%)');
      chunkFormulas.add('$rStr% = $rStr × (1% of $nStr) = $rStr × ${_fmt(onePct)} = ${_fmt(val)}');
    }
    chunkPcts.add(remaining);
    chunkValues.add(val);
  }

  final decompStr = chunkLabels.join(' + ');
  final chunkValStrings = chunkValues.map(_fmt).toList();

  return [
    AppliedMathStepData(
      stepNumber: 1,
      title: 'Benchmark Decomposition',
      badge: '$pctStr%  ≡  $decompStr',
      mainFormula: '$pctStr% of $nStr = ($decompStr) of $nStr',
      explanation:
          'Break $pctStr% into grouped mental benchmarks ($decompStr). We compute 10% once, then scale or halve it to find the parts.',
      resultHighlight: 'Decomposition: $decompStr',
    ),
    AppliedMathStepData(
      stepNumber: 2,
      title: 'Calculate 10% Primary Anchor',
      badge: '10% of $nStr = ${_fmt(tenPct)}',
      mainFormula: '$nStr ÷ 10 = ${_fmt(tenPct)}',
      explanation:
          'Shift the decimal point 1 place left:\n$nStr ÷ 10 = ${_fmt(tenPct)}.\nAll tens and 5% chunks are derived instantly from this number!',
      resultHighlight: '10% Anchor = ${_fmt(tenPct)}',
    ),
    AppliedMathStepData(
      stepNumber: 3,
      title: 'Derive Grouped Chunks',
      badge: chunkLabels.asMap().entries.map((e) => '${e.value}: ${chunkValStrings[e.key]}').join('  |  '),
      mainFormula: chunkFormulas.join('\n'),
      explanation:
          'Derive each component without repetitive additions:\n${chunkFormulas.map((f) => '• $f').join('\n')}',
      resultHighlight: 'Values: ${chunkValStrings.join(' + ')}',
    ),
    AppliedMathStepData(
      stepNumber: 4,
      title: 'Mental Summation',
      badge: '${chunkValStrings.join(' + ')} = $resultStr',
      mainFormula: '$pctStr% of $nStr = ${chunkValStrings.join(' + ')} = $resultStr',
      explanation:
          'Sum the chunk values from left to right:\n${chunkValStrings.join(' + ')} = $resultStr ✓\nExact, clean, and completed in memory.',
      resultHighlight: '$pctStr% of $nStr = $resultStr',
      isFinal: true,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. FRACTION TO PERCENTAGE STEP CALCULATOR
// ─────────────────────────────────────────────────────────────────────────────

class _UnitReciprocalInfo {
  const _UnitReciprocalInfo({
    required this.decValue,
    required this.mixedFraction,
    required this.pctLabel,
    required this.speedTip,
  });

  final double decValue;
  final String mixedFraction;
  final String pctLabel;
  final String speedTip;
}

const Map<int, _UnitReciprocalInfo> _unitReciprocals = {
  2: _UnitReciprocalInfo(
    decValue: 50.0,
    mixedFraction: '50%',
    pctLabel: '50%',
    speedTip: 'Half of 100%. Instant recall.',
  ),
  3: _UnitReciprocalInfo(
    decValue: 33.3333,
    mixedFraction: '33⅓%',
    pctLabel: '33.33%',
    speedTip: '100 ÷ 3. Recurring 3s.',
  ),
  4: _UnitReciprocalInfo(
    decValue: 25.0,
    mixedFraction: '25%',
    pctLabel: '25%',
    speedTip: 'Half of 50%. One quarter.',
  ),
  5: _UnitReciprocalInfo(
    decValue: 20.0,
    mixedFraction: '20%',
    pctLabel: '20%',
    speedTip: 'Double of 10%. One fifth.',
  ),
  6: _UnitReciprocalInfo(
    decValue: 16.6667,
    mixedFraction: '16⅔%',
    pctLabel: '16.67%',
    speedTip: 'Half of 33⅓%. Recurring 6s.',
  ),
  7: _UnitReciprocalInfo(
    decValue: 14.2857,
    mixedFraction: '14²⁄₇%',
    pctLabel: '14.28%',
    speedTip: '14 and double is 28 (14.28). Cycled digits.',
  ),
  8: _UnitReciprocalInfo(
    decValue: 12.5,
    mixedFraction: '12½%',
    pctLabel: '12.5%',
    speedTip: 'Half of 25%. One eighth.',
  ),
  9: _UnitReciprocalInfo(
    decValue: 11.1111,
    mixedFraction: '11¹⁄₉%',
    pctLabel: '11.11%',
    speedTip: 'Denominator 9 produces multiples of 11.11%.',
  ),
  10: _UnitReciprocalInfo(
    decValue: 10.0,
    mixedFraction: '10%',
    pctLabel: '10%',
    speedTip: 'Base ten divisor.',
  ),
  11: _UnitReciprocalInfo(
    decValue: 9.0909,
    mixedFraction: '9¹⁄₁₁%',
    pctLabel: '9.09%',
    speedTip: 'Denominator 11 produces multiples of 09.09%.',
  ),
  12: _UnitReciprocalInfo(
    decValue: 8.3333,
    mixedFraction: '8⅓%',
    pctLabel: '8.33%',
    speedTip: 'Half of 16⅔%.',
  ),
  14: _UnitReciprocalInfo(
    decValue: 7.1428,
    mixedFraction: '7¹⁄₇%',
    pctLabel: '7.14%',
    speedTip: 'Half of 14.28%. 7 and double is 14.',
  ),
  15: _UnitReciprocalInfo(
    decValue: 6.6667,
    mixedFraction: '6⅔%',
    pctLabel: '6.67%',
    speedTip: '100 ÷ 15 = 20 ÷ 3.',
  ),
  16: _UnitReciprocalInfo(
    decValue: 6.25,
    mixedFraction: '6¼%',
    pctLabel: '6.25%',
    speedTip: 'Half of 12.5%. One sixteenth.',
  ),
  20: _UnitReciprocalInfo(
    decValue: 5.0,
    mixedFraction: '5%',
    pctLabel: '5%',
    speedTip: 'Half of 10%.',
  ),
  25: _UnitReciprocalInfo(
    decValue: 4.0,
    mixedFraction: '4%',
    pctLabel: '4%',
    speedTip: '100 ÷ 25 = 4.',
  ),
};

List<AppliedMathStepData> computeFractionToPctSteps(int num, int den) {
  final d = den <= 0 ? 1 : den;
  final n = num;
  final double exactPct = (n * 100.0) / d;
  final exactPctStr = '${_fmt(exactPct)}%';

  final unitInfo = _unitReciprocals[d] ??
      _UnitReciprocalInfo(
        decValue: 100.0 / d,
        mixedFraction: '${_fmt(100.0 / d)}%',
        pctLabel: '${_fmt(100.0 / d)}%',
        speedTip: 'Divide 100 by $d.',
      );

  // Strategy A: Unit Fraction (n == 1)
  if (n == 1) {
    return [
      AppliedMathStepData(
        stepNumber: 1,
        title: 'Unit Reciprocal Identity',
        badge: '1/$d  ≡  ${unitInfo.pctLabel}',
        mainFormula: '1/$d = 100% ÷ $d = ${unitInfo.pctLabel}',
        explanation:
            'The reciprocal of $d is the foundational building block for all fractions over $d.\nExact mixed fraction: ${unitInfo.mixedFraction}.',
        resultHighlight: '1/$d = ${unitInfo.pctLabel}',
      ),
      AppliedMathStepData(
        stepNumber: 2,
        title: 'Memory Anchor & Speed Tip',
        badge: unitInfo.speedTip,
        mainFormula: '1/$d = ${unitInfo.mixedFraction} = ${unitInfo.pctLabel}',
        explanation:
            'Memorise this conversion: ${unitInfo.speedTip}\nIn speed calculation, converting 1/$d to ${unitInfo.pctLabel} takes 0 seconds of mental scratch work.',
        resultHighlight: '1/$d = ${unitInfo.pctLabel}',
        isFinal: true,
      ),
    ];
  }

  // Strategy B: Complement Subtraction (n == d - 1, e.g. 5/6, 7/8, 6/7, 11/12)
  if (n == d - 1 && d > 2) {
    return [
      AppliedMathStepData(
        stepNumber: 1,
        title: 'Identify Unit Reciprocal Anchor',
        badge: '1/$d  =  ${unitInfo.pctLabel}',
        mainFormula: '1/$d = ${unitInfo.mixedFraction}  (${unitInfo.pctLabel})',
        explanation:
            'Base reciprocal: 1/$d = ${unitInfo.pctLabel}.\nMemory hook: ${unitInfo.speedTip}',
        resultHighlight: 'Base Unit: 1/$d = ${unitInfo.pctLabel}',
      ),
      AppliedMathStepData(
        stepNumber: 2,
        title: 'The Subtractive Complement Trick',
        badge: '$n/$d  ≡  1 − 1/$d  ≡  100% − ${unitInfo.pctLabel}',
        mainFormula: '$n/$d = 100% − (1/$d) = 100% − ${unitInfo.pctLabel}',
        explanation:
            'Instead of multiplying ${unitInfo.pctLabel} by $n, note that $n/$d is exactly 1 unit fraction away from 100%.\nSubtracting 100% − ${unitInfo.pctLabel} takes 1 second in your head!',
        resultHighlight: 'Formula: 100% − 1/$d',
      ),
      AppliedMathStepData(
        stepNumber: 3,
        title: 'Mental Subtraction',
        badge: '100% − ${unitInfo.pctLabel} = $exactPctStr',
        mainFormula: '100% − ${unitInfo.pctLabel} = $exactPctStr',
        explanation:
            '100% − ${unitInfo.pctLabel} = $exactPctStr ✓\nExact mixed fraction: ${100 - unitInfo.decValue == (100 - unitInfo.decValue).truncate() ? '${(100 - unitInfo.decValue).truncate()}%' : exactPctStr}.',
        resultHighlight: '$n/$d = $exactPctStr',
        isFinal: true,
      ),
    ];
  }

  // Strategy C: Direct Multiplier Scaling (e.g. 3/8, 4/7, 4/9, 5/12, etc.)
  return [
    AppliedMathStepData(
      stepNumber: 1,
      title: 'Identify Unit Reciprocal Anchor',
      badge: '1/$d  =  ${unitInfo.pctLabel}',
      mainFormula: '1/$d = ${unitInfo.mixedFraction}  (${unitInfo.pctLabel})',
      explanation:
          'Base unit reciprocal: 1/$d = ${unitInfo.pctLabel}.\nMemory anchor: ${unitInfo.speedTip}',
      resultHighlight: 'Base Unit: 1/$d = ${unitInfo.pctLabel}',
    ),
    AppliedMathStepData(
      stepNumber: 2,
      title: 'Multiply by Numerator ($n)',
      badge: '$n × (1/$d)  =  $n × ${unitInfo.pctLabel}',
      mainFormula: '$n/$d = $n × (${unitInfo.pctLabel}) = $exactPctStr',
      explanation:
          'Scale the unit percentage by the numerator $n:\n$n × ${unitInfo.pctLabel} = $exactPctStr.\nFor mental speed, multiply integer and fractional parts separately.',
      resultHighlight: '$n × ${unitInfo.pctLabel} = $exactPctStr',
    ),
    AppliedMathStepData(
      stepNumber: 3,
      title: 'Final Percentage & Equivalence',
      badge: '$n/$d  =  $exactPctStr',
      mainFormula: '$n/$d = $exactPctStr',
      explanation:
          '$n/$d = $exactPctStr ✓\nIn speed math exams, replacing $n/$d directly with $exactPctStr allows instant elimination of multiple-choice answers.',
      resultHighlight: '$n/$d = $exactPctStr',
      isFinal: true,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. PERCENTAGE TO FRACTION STEP CALCULATOR (NEW TOPIC)
// ─────────────────────────────────────────────────────────────────────────────

class _PctToFractionPreset {
  const _PctToFractionPreset({
    required this.percentage,
    required this.label,
    required this.num,
    required this.den,
    required this.family,
    required this.baseUnitPct,
    required this.speedRule,
  });

  final double percentage;
  final String label;
  final int num;
  final int den;
  final String family;
  final String baseUnitPct;
  final String speedRule;
}

const List<_PctToFractionPreset> _pctToFractionPresets = [
  _PctToFractionPreset(
    percentage: 12.5,
    label: '12.5%',
    num: 1,
    den: 8,
    family: '1/8 Family',
    baseUnitPct: '12.5%',
    speedRule: '12.5% is the fundamental unit of eighths (1/8).',
  ),
  _PctToFractionPreset(
    percentage: 37.5,
    label: '37.5%',
    num: 3,
    den: 8,
    family: '1/8 Family',
    baseUnitPct: '12.5%',
    speedRule: '37.5% = 3 × 12.5% = 3/8. Replaces complex decimal multiplication with ÷8 ×3.',
  ),
  _PctToFractionPreset(
    percentage: 62.5,
    label: '62.5%',
    num: 5,
    den: 8,
    family: '1/8 Family',
    baseUnitPct: '12.5%',
    speedRule: '62.5% = 5 × 12.5% = 5/8 (or 50% + 12.5%).',
  ),
  _PctToFractionPreset(
    percentage: 87.5,
    label: '87.5%',
    num: 7,
    den: 8,
    family: '1/8 Family',
    baseUnitPct: '12.5%',
    speedRule: '87.5% = 100% − 12.5% = 1 − 1/8 = 7/8.',
  ),
  _PctToFractionPreset(
    percentage: 16.67,
    label: '16.67% (16⅔%)',
    num: 1,
    den: 6,
    family: '1/6 Family',
    baseUnitPct: '16.67%',
    speedRule: '16.67% is 1/6. Dividing by 6 is 5× faster than multiplying decimals.',
  ),
  _PctToFractionPreset(
    percentage: 83.33,
    label: '83.33% (83⅓%)',
    num: 5,
    den: 6,
    family: '1/6 Family',
    baseUnitPct: '16.67%',
    speedRule: '83.33% = 100% − 16.67% = 1 − 1/6 = 5/6.',
  ),
  _PctToFractionPreset(
    percentage: 33.33,
    label: '33.33% (33⅓%)',
    num: 1,
    den: 3,
    family: '1/3 Family',
    baseUnitPct: '33.33%',
    speedRule: '33.33% is exactly 1/3.',
  ),
  _PctToFractionPreset(
    percentage: 66.67,
    label: '66.67% (66⅔%)',
    num: 2,
    den: 3,
    family: '1/3 Family',
    baseUnitPct: '33.33%',
    speedRule: '66.67% = 2 × 33.33% = 2/3.',
  ),
  _PctToFractionPreset(
    percentage: 14.28,
    label: '14.28% (14²⁄₇%)',
    num: 1,
    den: 7,
    family: '1/7 Family',
    baseUnitPct: '14.28%',
    speedRule: '14.28% is 1/7. Key digits: 14 double is 28.',
  ),
  _PctToFractionPreset(
    percentage: 28.57,
    label: '28.57% (28⁴⁄₇%)',
    num: 2,
    den: 7,
    family: '1/7 Family',
    baseUnitPct: '14.28%',
    speedRule: '28.57% = 2 × 14.28% = 2/7.',
  ),
  _PctToFractionPreset(
    percentage: 42.86,
    label: '42.86% (42⁶⁄₇%)',
    num: 3,
    den: 7,
    family: '1/7 Family',
    baseUnitPct: '14.28%',
    speedRule: '42.86% = 3 × 14.28% = 3/7.',
  ),
  _PctToFractionPreset(
    percentage: 57.14,
    label: '57.14% (57¹⁄₇%)',
    num: 4,
    den: 7,
    family: '1/7 Family',
    baseUnitPct: '14.28%',
    speedRule: '57.14% = 4 × 14.28% = 4/7.',
  ),
  _PctToFractionPreset(
    percentage: 11.11,
    label: '11.11% (11¹⁄₉%)',
    num: 1,
    den: 9,
    family: '1/9 Family',
    baseUnitPct: '11.11%',
    speedRule: '11.11% is 1/9. Repeating digits indicate 9 in the denominator.',
  ),
  _PctToFractionPreset(
    percentage: 44.44,
    label: '44.44% (44⁴⁄₉%)',
    num: 4,
    den: 9,
    family: '1/9 Family',
    baseUnitPct: '11.11%',
    speedRule: '44.44% = 4 × 11.11% = 4/9.',
  ),
  _PctToFractionPreset(
    percentage: 9.09,
    label: '9.09% (9¹⁄₁₁%)',
    num: 1,
    den: 11,
    family: '1/11 Family',
    baseUnitPct: '9.09%',
    speedRule: '9.09% is 1/11. Multiples of 9 indicate denominator 11.',
  ),
  _PctToFractionPreset(
    percentage: 8.33,
    label: '8.33% (8⅓%)',
    num: 1,
    den: 12,
    family: '1/12 Family',
    baseUnitPct: '8.33%',
    speedRule: '8.33% is 1/12 (half of 1/6 = 16.67%).',
  ),
  _PctToFractionPreset(
    percentage: 6.25,
    label: '6.25% (6¼%)',
    num: 1,
    den: 16,
    family: '1/16 Family',
    baseUnitPct: '6.25%',
    speedRule: '6.25% is 1/16 (half of 12.5%).',
  ),
  _PctToFractionPreset(
    percentage: 18.75,
    label: '18.75% (18¾%)',
    num: 3,
    den: 16,
    family: '1/16 Family',
    baseUnitPct: '6.25%',
    speedRule: '18.75% = 3 × 6.25% = 3/16.',
  ),
  _PctToFractionPreset(
    percentage: 112.5,
    label: '112.5%',
    num: 9,
    den: 8,
    family: '1/8 Family',
    baseUnitPct: '12.5%',
    speedRule: '112.5% = 100% + 12.5% = 1 + 1/8 = 9/8.',
  ),
  _PctToFractionPreset(
    percentage: 75.0,
    label: '75%',
    num: 3,
    den: 4,
    family: '1/4 Family',
    baseUnitPct: '25%',
    speedRule: '75% = 3 × 25% = 3/4.',
  ),
  _PctToFractionPreset(
    percentage: 45.0,
    label: '45%',
    num: 9,
    den: 20,
    family: 'Direct Simplification',
    baseUnitPct: '5%',
    speedRule: '45% = 45/100 = 9/20.',
  ),
];

List<AppliedMathStepData> computePctToFractionSteps(num percentage, int examBase) {
  final pctDouble = percentage.toDouble();
  final examN = examBase <= 0 ? 640 : examBase;

  // Find matching preset by closest percentage
  final preset = _pctToFractionPresets.firstWhere(
    (p) => (p.percentage - pctDouble).abs() < 0.2,
    orElse: () {
      // Fallback: simplify percentage / 100
      final intPct = pctDouble.round();
      final gcdVal = intPct.gcd(100);
      return _PctToFractionPreset(
        percentage: pctDouble,
        label: '${_fmt(pctDouble)}%',
        num: intPct ~/ gcdVal,
        den: 100 ~/ gcdVal,
        family: 'Standard Rational Simplification',
        baseUnitPct: '${_fmt(100.0 / (100 ~/ gcdVal))}%',
        speedRule: '$pctDouble% = $intPct/100 = ${intPct ~/ gcdVal}/${100 ~/ gcdVal}.',
      );
    },
  );

  final num = preset.num;
  final den = preset.den;
  final examResult = (examN * num) ~/ den;

  return [
    AppliedMathStepData(
      stepNumber: 1,
      title: 'Identify Benchmark Reciprocal Family',
      badge: preset.family,
      mainFormula: '${preset.label}  belongs to  ${preset.family}',
      explanation:
          'In speed arithmetic, never compute decimal percentages manually. Recognize the benchmark unit:\nBase unit: 1/$den = ${preset.baseUnitPct}.\nMemory hook: ${preset.speedRule}',
      resultHighlight: 'Benchmark Family: ${preset.family}',
    ),
    AppliedMathStepData(
      stepNumber: 2,
      title: 'Decomposition & Scaling',
      badge: num == 1
          ? '${preset.label}  =  1/$den'
          : '${preset.label}  =  $num × (1/$den)  =  $num/$den',
      mainFormula: num == 1
          ? '${preset.label} = 1/$den'
          : '${preset.label} = $num × (${preset.baseUnitPct}) = $num/$den',
      explanation: num == 1
          ? '${preset.label} is directly the unit reciprocal 1/$den.'
          : '${preset.label} is $num times the unit fraction 1/$den:\n$num × (1/$den) = $num/$den.',
      resultHighlight: 'Irreducible Fraction: $num/$den',
    ),
    AppliedMathStepData(
      stepNumber: 3,
      title: 'Irreducible Fraction Result',
      badge: '${preset.label}  ≡  $num/$den',
      mainFormula: '${preset.label} = $num/$den',
      explanation:
          'The fraction $num/$den is the exact, simplified representation of ${preset.label}.\nCommit this pair to heart for instantaneous recall.',
      resultHighlight: '${preset.label} = $num/$den',
    ),
    AppliedMathStepData(
      stepNumber: 4,
      title: 'Speed Exam Application',
      badge: '${preset.label} of $examN = $examResult',
      mainFormula: '($num/$den) × $examN = $num × ($examN ÷ $den) = $examResult',
      explanation:
          'How this shortcut saves minutes in speed tests:\nCalculate ${preset.label} of $examN:\n1. Divide $examN by $den = ${examN ~/ den}\n2. Multiply by $num = $examResult ✓\nTurned an intimidating decimal multiplication into 2 seconds of mental arithmetic!',
      resultHighlight: 'Exam Answer = $examResult',
      isFinal: true,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET: AppliedMathStaticDiagram
// ─────────────────────────────────────────────────────────────────────────────

class AppliedMathStaticDiagram extends StatefulWidget {
  const AppliedMathStaticDiagram({
    super.key,
    required this.lessonId,
    required this.operands,
  });

  final String lessonId;
  final List<int> operands;

  static const double cardWidth = 330.0;
  static const double cardGap = 20.0;
  static const double marginLeft = 50.0;

  @override
  State<AppliedMathStaticDiagram> createState() =>
      _AppliedMathStaticDiagramState();
}

class _AppliedMathStaticDiagramState extends State<AppliedMathStaticDiagram> {
  final TransformationController _transformController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() => _currentScale = scale);
    }
  }

  void _zoomIn() {
    final next = math.min(2.5, _currentScale + 0.25);
    _setScale(next);
  }

  void _zoomOut() {
    final next = math.max(0.5, _currentScale - 0.25);
    _setScale(next);
  }

  void _resetZoom() => _setScale(1.0);

  void _setScale(double targetScale) {
    HapticFeedback.selectionClick();
    final matrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    _transformController.value = matrix;
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  List<AppliedMathStepData> _getSteps() {
    final ops = widget.operands;
    if (widget.lessonId == 'split_percentages') {
      final pct = ops.isNotEmpty ? ops[0] : 15;
      final n = ops.length > 1 ? ops[1] : 240;
      return computeSplitPercentagesSteps(pct, n);
    } else if (widget.lessonId == 'percentage_to_fraction') {
      // ops[0] is percentage * 100 (e.g. 3750 for 37.5%) or direct percentage
      final rawPct = ops.isNotEmpty ? ops[0] : 3750;
      final pct = rawPct > 500 ? (rawPct / 100.0) : rawPct.toDouble();
      final examBase = ops.length > 1 ? ops[1] : 640;
      return computePctToFractionSteps(pct, examBase);
    } else {
      // fraction_pct_friends (Fraction to Percentage)
      // ops[0] is numerator, ops[1] is denominator
      final num = ops.isNotEmpty ? ops[0] : 3;
      final den = ops.length > 1 ? ops[1] : 8;
      return computeFractionToPctSteps(num, den);
    }
  }

  (String, String, String) _getHeaderStrings() {
    final ops = widget.operands;
    if (widget.lessonId == 'split_percentages') {
      final pct = ops.isNotEmpty ? ops[0] : 15;
      final n = ops.length > 1 ? ops[1] : 240;
      final res = (n * pct) / 100.0;
      return (
        'SPLIT PERCENTAGES SHORTCUT',
        '$pct% of $n = ${_fmt(res)}',
        'Decompose into 50%, 25%, 10%, 5%, 1% benchmarks for rapid mental calculation',
      );
    } else if (widget.lessonId == 'percentage_to_fraction') {
      final rawPct = ops.isNotEmpty ? ops[0] : 3750;
      final pct = rawPct > 500 ? (rawPct / 100.0) : rawPct.toDouble();
      final examBase = ops.length > 1 ? ops[1] : 640;
      final steps = computePctToFractionSteps(pct, examBase);
      final finalHighlight = steps.last.resultHighlight;
      return (
        'PERCENTAGE TO FRACTION SHORTCUT',
        '${_fmt(pct)}%  →  Simplest Fraction',
        '$finalHighlight • Turn complex decimals into instantaneous mental division',
      );
    } else {
      final num = ops.isNotEmpty ? ops[0] : 3;
      final den = ops.length > 1 ? ops[1] : 8;
      final pct = (num * 100.0) / den;
      return (
        'FRACTION TO PERCENTAGE SHORTCUT',
        '$num/$den  =  ${_fmt(pct)}%',
        'Unit reciprocal scaling & complement subtraction for competitive speed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();
    final (headerBadge, headerEquation, headerSub) = _getHeaderStrings();

    final canvasWidth = AppliedMathStaticDiagram.marginLeft +
        steps.length *
            (AppliedMathStaticDiagram.cardWidth +
                AppliedMathStaticDiagram.cardGap) +
        60.0;
    const canvasHeight = 650.0;

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(120),
          minScale: 0.5,
          maxScale: 2.5,
          child: Container(
            width: canvasWidth,
            height: canvasHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5), // Cream Notebook Paper
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.borderLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomPaint(
              size: Size(canvasWidth, canvasHeight),
              painter: _AppliedMathDiagramPainter(
                lessonId: widget.lessonId,
                steps: steps,
                headerBadge: headerBadge,
                headerEquation: headerEquation,
                headerSub: headerSub,
                width: canvasWidth,
                height: canvasHeight,
              ),
            ),
          ),
        ),

        // Floating Zoom Controls
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ZoomBtn(icon: Icons.remove_rounded, onTap: _zoomOut),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${(_currentScale * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _ZoomBtn(icon: Icons.add_rounded, onTap: _zoomIn),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER FOR APPLIED MATH DIAGRAM
// ─────────────────────────────────────────────────────────────────────────────

class _AppliedMathDiagramPainter extends CustomPainter {
  const _AppliedMathDiagramPainter({
    required this.lessonId,
    required this.steps,
    required this.headerBadge,
    required this.headerEquation,
    required this.headerSub,
    required this.width,
    required this.height,
  });

  final String lessonId;
  final List<AppliedMathStepData> steps;
  final String headerBadge;
  final String headerEquation;
  final String headerSub;
  final double width;
  final double height;

  static const Color _lineRuleColor = Color(0xFFFDE68A); // amber-200
  static const Color _marginLineColor = Color(0xFFFCA5A5); // rose-300
  static const Color _accentColor = Color(0xFF8B5CF6); // purple-500
  static const Color _greenAccent = Color(0xFF16A34A);

  @override
  void paint(Canvas canvas, Size size) {
    _drawNotebookPaper(canvas, size);
    _drawHeaderSection(canvas);
    _drawStepCards(canvas);
    _drawVictoryBanner(canvas);
  }

  void _drawNotebookPaper(Canvas canvas, Size size) {
    // Ruled lines every 30px
    final rulePaint = Paint()
      ..color = _lineRuleColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    final count = (size.height / 30).ceil();
    for (int i = 1; i <= count; i++) {
      final y = i * 30.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rulePaint);
    }

    // Left vertical margin line
    final marginPaint = Paint()
      ..color = _marginLineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(32, 0), Offset(32, size.height), marginPaint);
  }

  void _drawHeaderSection(Canvas canvas) {
    // Badge pill
    final badgePaint = Paint()
      ..color = _accentColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 24, 310, 28),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, badgePaint);

    final badgeBorder = Paint()
      ..color = _accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, badgeBorder);

    final tpBadge = TextPainter(
      text: TextSpan(
        text: headerBadge,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _accentColor,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpBadge.paint(
        canvas,
        Offset(50 + (310 - tpBadge.width) / 2,
            24 + (28 - tpBadge.height) / 2));

    // Equation
    final tpEq = TextPainter(
      text: TextSpan(
        text: headerEquation,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpEq.paint(canvas, const Offset(50, 62));

    // Subtitle
    final tpSub = TextPainter(
      text: TextSpan(
        text: headerSub,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpSub.paint(canvas, const Offset(50, 96));
  }

  void _drawStepCards(Canvas canvas) {
    const cardTop = 130.0;
    const cardH = 390.0;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final cardLeft = AppliedMathStaticDiagram.marginLeft +
          i * (AppliedMathStaticDiagram.cardWidth +
                  AppliedMathStaticDiagram.cardGap);

      _drawSingleCard(canvas, cardLeft, cardTop,
          AppliedMathStaticDiagram.cardWidth, cardH, step);
    }

    // Connecting arrows
    for (int i = 0; i < steps.length - 1; i++) {
      final cardLeft1 = AppliedMathStaticDiagram.marginLeft +
          i * (AppliedMathStaticDiagram.cardWidth +
                  AppliedMathStaticDiagram.cardGap);
      final cardLeft2 = cardLeft1 +
          AppliedMathStaticDiagram.cardWidth +
          AppliedMathStaticDiagram.cardGap;

      _drawConnectingStepArrow(
        canvas,
        fromCardLeft: cardLeft1,
        toCardLeft: cardLeft2,
        cardTop: cardTop,
        cardW: AppliedMathStaticDiagram.cardWidth,
      );
    }
  }

  void _drawSingleCard(Canvas canvas, double left, double top, double w,
      double h, AppliedMathStepData step) {
    final cardRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h), const Radius.circular(16));

    // Shadow
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Background
    canvas.drawRRect(cardRRect, Paint()..color = Colors.white);

    // Border
    final borderColor = step.isFinal
        ? _greenAccent.withValues(alpha: 0.4)
        : AppTheme.borderLight;
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = step.isFinal ? 1.8 : 1.2,
    );

    double curY = top + 14;

    // 1. Step Pill + Badge
    final tpStep = TextPainter(
      text: TextSpan(
        text: 'STEP ${step.stepNumber}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: step.isFinal ? _greenAccent : _accentColor,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final stepBadgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 14, curY, tpStep.width + 12, 20),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      stepBadgeRRect,
      Paint()
        ..color = (step.isFinal ? _greenAccent : _accentColor)
            .withValues(alpha: 0.1),
    );
    tpStep.paint(canvas, Offset(left + 20, curY + 3));

    final tpBadge = TextPainter(
      text: TextSpan(
        text: step.badge,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: w - tpStep.width - 45);
    tpBadge.paint(canvas, Offset(left + tpStep.width + 30, curY + 3));

    curY += 28;

    // 2. Card Title
    final tpTitle = TextPainter(
      text: TextSpan(
        text: step.title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 28);
    tpTitle.paint(canvas, Offset(left + 14, curY));

    curY += tpTitle.height + 10;

    // 3. Main Formula Card
    final formulaRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 12, curY, w - 24, 60),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      formulaRRect,
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRRect(
      formulaRRect,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final tpFormula = TextPainter(
      text: TextSpan(
        text: step.mainFormula,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: step.isFinal ? _greenAccent : const Color(0xFF1E293B),
          fontFamily: 'Courier',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: w - 40);
    tpFormula.paint(
      canvas,
      Offset(left + 12 + (w - 24 - tpFormula.width) / 2,
          curY + (60 - tpFormula.height) / 2),
    );

    curY += 70;

    // 4. Mental thought box
    final expRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 12, curY, w - 24, 130),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      expRRect,
      Paint()..color = const Color(0xFFFFFBEB), // amber-50
    );
    canvas.drawRRect(
      expRRect,
      Paint()
        ..color = const Color(0xFFFDE68A).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final tpLabel = TextPainter(
      text: const TextSpan(
        text: 'How to calculate mentally:',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFFB45309), // amber-700
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLabel.paint(canvas, Offset(left + 20, curY + 8));

    final tpExp = TextPainter(
      text: TextSpan(
        text: step.explanation,
        style: const TextStyle(
          fontSize: 11,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: Color(0xFF78350F), // amber-900
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 5,
      ellipsis: '...',
    )..layout(maxWidth: w - 40);
    tpExp.paint(canvas, Offset(left + 20, curY + 26));

    curY += 140;

    // 5. Result Highlight Strip
    final stripRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 12, curY, w - 24, 40),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      stripRRect,
      Paint()
        ..color = (step.isFinal ? _greenAccent : _accentColor)
            .withValues(alpha: 0.12),
    );

    final tpStrip = TextPainter(
      text: TextSpan(
        text: step.resultHighlight,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: step.isFinal ? _greenAccent : _accentColor,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: w - 36);
    tpStrip.paint(
      canvas,
      Offset(left + 12 + (w - 24 - tpStrip.width) / 2,
          curY + (40 - tpStrip.height) / 2),
    );
  }

  void _drawConnectingStepArrow(
    Canvas canvas, {
    required double fromCardLeft,
    required double toCardLeft,
    required double cardTop,
    required double cardW,
  }) {
    // Arrow runs horizontally in the middle of the card gap
    final startX = fromCardLeft + cardW;
    final endX = toCardLeft;
    const arrowY = 320.0;

    final arrowPaint = Paint()
      ..color = _accentColor.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(startX + 2, arrowY), Offset(endX - 2, arrowY), arrowPaint);

    // Arrow Head
    final headPaint = Paint()
      ..color = _accentColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final headPath = Path()
      ..moveTo(endX, arrowY)
      ..lineTo(endX - 7, arrowY - 4.5)
      ..lineTo(endX - 7, arrowY + 4.5)
      ..close();
    canvas.drawPath(headPath, headPaint);
  }

  void _drawVictoryBanner(Canvas canvas) {
    const bannerTop = 540.0;
    final bannerW = width - 100;
    const bannerH = 75.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(50, bannerTop, bannerW, bannerH),
      const Radius.circular(14),
    );

    // Background
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xFFF0FDF4), // green-50
    );

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _greenAccent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Banner Text
    final tpVictoryTitle = TextPainter(
      text: const TextSpan(
        text: 'SPEED MATH VICTORY SUMMARY',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: _greenAccent,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpVictoryTitle.paint(canvas, const Offset(70, bannerTop + 14));

    final tpVictoryBody = TextPainter(
      text: TextSpan(
        text: switch (lessonId) {
          'split_percentages' =>
            'By breaking arbitrary percentages into friendly 50%, 25%, 10%, 5%, and 1% benchmarks, you eliminate slow decimal long multiplication completely!',
          'percentage_to_fraction' =>
            'Converting repeating or benchmark percentages into simplified fractions allows you to solve complicated exam questions in 2 seconds through simple division!',
          _ =>
            'Knowing standard fraction-to-percentage conversions by heart saves minutes during speed tests and guarantees instant, accurate answers!',
        },
        style: const TextStyle(
          fontSize: 11,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: Color(0xFF166534), // green-800
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: bannerW - 40);
    tpVictoryBody.paint(canvas, const Offset(70, bannerTop + 34));
  }

  @override
  bool shouldRepaint(_AppliedMathDiagramPainter oldDelegate) {
    return oldDelegate.lessonId != lessonId ||
        oldDelegate.steps != steps ||
        oldDelegate.headerEquation != headerEquation;
  }
}
