// lib/features/learn/engine/divisibility_helper.dart
import 'dart:math';

/// Rule categorization for filtering.
enum DivisibilityCategory {
  all,
  basics, // 2, 4, 8
  sums, // 3, 9
  endings, // 5, 10, 25
  primes, // 7, 11, 13
  composites, // 6, 12, 14, 15, 18
}

/// The result of checking divisibility of a number by a specific divisor.
class DivisibilityResult {
  const DivisibilityResult({
    required this.divisor,
    required this.isDivisible,
    required this.ruleTitle,
    required this.shortExplanation,
    required this.detailedWorking,
    required this.whyItWorks,
    required this.category,
    this.proTip,
  });

  final int divisor;
  final bool isDivisible;
  final String ruleTitle;
  final String shortExplanation;
  final String detailedWorking;
  final String whyItWorks;
  final DivisibilityCategory category;
  final String? proTip;
}

/// Engine that evaluates divisibility and produces step-by-step explanations
/// for any positive number without long division.
class DivisibilityHelper {
  DivisibilityHelper._();

  static const List<int> standardDivisors = [
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    18,
    25,
  ];

  /// Tests all standard divisors against [n] and returns structured results.
  static List<DivisibilityResult> checkAll(int n) {
    if (n <= 0) return const [];
    return standardDivisors.map((d) => checkOne(n, d)).toList();
  }

  /// Evaluates single divisor rule against [n] with transparent workings.
  static DivisibilityResult checkOne(int n, int d) {
    final s = '$n';
    final len = s.length;

    switch (d) {
      // ─── 2: Last digit is even ──────────────────────────────────────────
      case 2:
        final last = n % 10;
        final pass = last % 2 == 0;
        return DivisibilityResult(
          divisor: 2,
          isDivisible: pass,
          ruleTitle: 'Even Units Digit',
          shortExplanation:
              pass ? 'Ends in $last (even)' : 'Ends in $last (odd)',
          detailedWorking:
              'Last digit is $last. Since $last is ${pass ? "even (0,2,4,6,8)" : "odd"}, $n is ${pass ? "" : "not "}divisible by 2.',
          whyItWorks:
              'Every multiple of 10 is divisible by 2 (10 = 2 × 5). Only the units digit remains.',
          category: DivisibilityCategory.basics,
          proTip: 'Look only at the final digit — ignore everything before it.',
        );

      // ─── 3: Sum of all digits is a multiple of 3 ────────────────────────
      case 3:
        final digits = s.split('').map(int.parse).toList();
        final sum = digits.reduce((a, b) => a + b);
        final pass = sum % 3 == 0;
        final digitStr = digits.join(' + ');
        return DivisibilityResult(
          divisor: 3,
          isDivisible: pass,
          ruleTitle: 'Sum of Digits',
          shortExplanation: 'Digit sum = $sum (${pass ? "multiple of 3" : "not div by 3"})',
          detailedWorking:
              'Sum of digits: $digitStr = $sum. Since $sum ${pass ? "is divisible by 3 ($sum = 3 × ${sum ~/ 3})" : "leaves remainder ${sum % 3} when divided by 3"}, $n is ${pass ? "" : "not "}divisible by 3.',
          whyItWorks:
              'Each power of 10 leaves remainder 1 mod 3 (10 = 9+1, 100 = 99+1), so each digit contributes its face value.',
          category: DivisibilityCategory.sums,
          proTip: 'You can cast out 3, 6, and 9 while adding to keep the mental sum small!',
        );

      // ─── 4: Last 2 digits form a multiple of 4 ──────────────────────────
      case 4:
        final last2 = n % 100;
        final pass = last2 % 4 == 0;
        final last2Str = s.length >= 2 ? s.substring(s.length - 2) : s;
        final tens = (last2 ~/ 10);
        final units = last2 % 10;
        final shortcut = 2 * tens + units;
        return DivisibilityResult(
          divisor: 4,
          isDivisible: pass,
          ruleTitle: 'Last 2 Digits',
          shortExplanation: 'Last 2 digits "$last2Str" (${pass ? "divisible by 4" : "not div by 4"})',
          detailedWorking:
              'Inspect the last two digits: $last2Str. Since $last2 ${pass ? "= 4 × ${last2 ~/ 4}" : "leaves remainder ${last2 % 4} when divided by 4"}, $n is ${pass ? "" : "not "}divisible by 4.\n(Mental shortcut: 2×tens + units = 2($tens) + $units = $shortcut ${pass ? "is a multiple of 4" : "is not a multiple of 4"}).',
          whyItWorks:
              '100 is fully divisible by 4 (100 = 4 × 25). Hundreds and above contribute zero remainder.',
          category: DivisibilityCategory.basics,
          proTip: 'Quick check: if the tens digit is even, units must be 0, 4, 8. If tens is odd, units must be 2, 6.',
        );

      // ─── 5: Last digit is 0 or 5 ─────────────────────────────────────────
      case 5:
        final last = n % 10;
        final pass = last == 0 || last == 5;
        return DivisibilityResult(
          divisor: 5,
          isDivisible: pass,
          ruleTitle: 'Ends in 0 or 5',
          shortExplanation:
              pass ? 'Units digit is $last' : 'Units digit is $last (not 0 or 5)',
          detailedWorking:
              'The units place is $last. A number is divisible by 5 if and only if it ends in 0 or 5.',
          whyItWorks:
              '10 is a multiple of 5 (10 = 5 × 2). Only the units digit can leave a remainder.',
          category: DivisibilityCategory.endings,
        );

      // ─── 6: Divisible by both 2 AND 3 ───────────────────────────────────
      case 6:
        final pass2 = (n % 10) % 2 == 0;
        final sum = s.split('').map(int.parse).reduce((a, b) => a + b);
        final pass3 = sum % 3 == 0;
        final pass = pass2 && pass3;
        final reason = pass
            ? 'Even AND digit sum $sum is divisible by 3'
            : (!pass2 ? 'Fails Rule 2 (odd number)' : 'Fails Rule 3 (digit sum $sum not divisible by 3)');
        return DivisibilityResult(
          divisor: 6,
          isDivisible: pass,
          ruleTitle: 'Composite (2 and 3)',
          shortExplanation: reason,
          detailedWorking:
              'Rule 2 check (even): ${pass2 ? "PASS (ends in ${n % 10})" : "FAIL (odd)"}.\nRule 3 check (digit sum): ${pass3 ? "PASS (sum = $sum)" : "FAIL (sum = $sum)"}.\nResult: ${pass ? "Both conditions satisfied ✓" : "Failed one or more conditions ✗"}.',
          whyItWorks:
              '6 = 2 × 3. Since 2 and 3 are co-prime, any multiple of 6 must satisfy both rules simultaneously.',
          category: DivisibilityCategory.composites,
          proTip: 'Always check if the number is even first. If it is odd, rule 6 fails instantly without adding digits!',
        );

      // ─── 7: Truncate & Double Trick ──────────────────────────────────────
      case 7:
        var curr = n;
        final stepsLog = <String>[];
        while (curr >= 70) {
          final last = curr % 10;
          final rest = curr ~/ 10;
          final next = rest - 2 * last;
          stepsLog.add('$rest − 2($last) = $next');
          curr = next.abs();
        }
        final pass = curr % 7 == 0;
        return DivisibilityResult(
          divisor: 7,
          isDivisible: pass,
          ruleTitle: 'Truncate & Double',
          shortExplanation:
              pass ? 'Reduced to $curr (multiple of 7)' : 'Reduced to $curr (not div by 7)',
          detailedWorking:
              'Double the last digit and subtract from the remaining number:\n${stepsLog.take(3).join('\n')}\nFinal value: $curr ${pass ? "is divisible by 7" : "is not divisible by 7"}.',
          whyItWorks:
              'Notice (10a + b) - 21b = 10(a - 2b). Since 21 is a multiple of 7, (10a + b) is divisible by 7 if and only if (a - 2b) is divisible by 7.',
          category: DivisibilityCategory.primes,
          proTip: 'For large 6+ digit numbers, group digits in threes from right to left and take the alternating sum!',
        );

      // ─── 8: Last 3 digits form a multiple of 8 ──────────────────────────
      case 8:
        final last3 = n % 1000;
        final pass = last3 % 8 == 0;
        final last3Str = s.length >= 3 ? s.substring(s.length - 3) : s;
        final h = (last3 ~/ 100) % 10;
        final t = (last3 ~/ 10) % 10;
        final u = last3 % 10;
        final isHEven = h % 2 == 0;
        final shortcutVal = isHEven ? (t * 10 + u) : (t * 10 + u + 4);
        return DivisibilityResult(
          divisor: 8,
          isDivisible: pass,
          ruleTitle: 'Last 3 Digits',
          shortExplanation: 'Last 3 digits "$last3Str" (${pass ? "divisible by 8" : "not div by 8"})',
          detailedWorking:
              'Look at the last 3 digits: $last3Str.\nSince $last3 ${pass ? "= 8 × ${last3 ~/ 8}" : "leaves remainder ${last3 % 8} when divided by 8"}, $n is ${pass ? "" : "not "}divisible by 8.\n(Mental shortcut: Hundreds digit $h is ${isHEven ? "even → test last 2 digits ($shortcutVal)" : "odd → test last 2 digits + 4 ($shortcutVal)"}).',
          whyItWorks:
              '1,000 is divisible by 8 (1,000 = 8 × 125). All thousands and higher places contribute zero remainder.',
          category: DivisibilityCategory.basics,
          proTip: 'If the hundreds digit is even, check only the last 2 digits. If hundreds is odd, add 4 to the last 2 digits!',
        );

      // ─── 9: Sum of digits is a multiple of 9 ────────────────────────────
      case 9:
        final digits = s.split('').map(int.parse).toList();
        final sum = digits.reduce((a, b) => a + b);
        final digitalRoot = (sum - 1) % 9 + 1;
        final pass = sum % 9 == 0;
        return DivisibilityResult(
          divisor: 9,
          isDivisible: pass,
          ruleTitle: 'Sum of Digits = 9',
          shortExplanation: 'Digit sum = $sum (Digital Root = $digitalRoot)',
          detailedWorking:
              'Sum of digits: ${digits.join(" + ")} = $sum.\nSince $sum ${pass ? "= 9 × ${sum ~/ 9}" : "is not a multiple of 9"}, $n is ${pass ? "" : "not "}divisible by 9.',
          whyItWorks:
              'Powers of 10 minus 1 (like 9, 99, 999) are entirely divisible by 9. Every digit contributes exactly its face value mod 9.',
          category: DivisibilityCategory.sums,
          proTip: 'Cast out 9s: pair digits that sum to 9 (e.g. 7+2, 5+4) and eliminate them mentally!',
        );

      // ─── 10: Ends in 0 ───────────────────────────────────────────────────
      case 10:
        final last = n % 10;
        final pass = last == 0;
        return DivisibilityResult(
          divisor: 10,
          isDivisible: pass,
          ruleTitle: 'Ends in 0',
          shortExplanation: pass ? 'Ends in 0' : 'Ends in $last (not 0)',
          detailedWorking:
              'Units digit is $last. A whole number is divisible by 10 if and only if its units digit is 0.',
          whyItWorks: 'Base-10 positional notation.',
          category: DivisibilityCategory.endings,
        );

      // ─── 11: Alternating Sum of Digits ──────────────────────────────────
      case 11:
        int oddSum = 0;
        int evenSum = 0;
        final oddParts = <int>[];
        final evenParts = <int>[];
        for (int i = 0; i < len; i++) {
          final digit = int.parse(s[len - 1 - i]);
          if (i % 2 == 0) {
            oddSum += digit;
            oddParts.add(digit);
          } else {
            evenSum += digit;
            evenParts.add(digit);
          }
        }
        final diff = oddSum - evenSum;
        final pass = diff % 11 == 0;
        return DivisibilityResult(
          divisor: 11,
          isDivisible: pass,
          ruleTitle: 'Alternating Digit Sum',
          shortExplanation:
              'Difference ($oddSum − $evenSum = $diff) ${pass ? "is divisible by 11" : "is not div by 11"}',
          detailedWorking:
              'Sum of odd-position digits (from right): ${oddParts.join(" + ")} = $oddSum.\nSum of even-position digits: ${evenParts.join(" + ")} = $evenSum.\nDifference: $oddSum − $evenSum = $diff.\nSince $diff ${pass ? "is 0 or a multiple of 11" : "is not a multiple of 11"}, $n is ${pass ? "" : "not "}divisible by 11.',
          whyItWorks:
              'Powers of 10 alternate between +1 and -1 (10 ≡ -1 mod 11, 100 ≡ +1, 1000 ≡ -1).',
          category: DivisibilityCategory.primes,
          proTip: 'If difference is negative, add 11 (e.g. -11 or 0 are both multiples of 11).',
        );

      // ─── 12: Divisible by 3 AND 4 ────────────────────────────────────────
      case 12:
        final pass3 = checkOne(n, 3).isDivisible;
        final pass4 = checkOne(n, 4).isDivisible;
        final pass = pass3 && pass4;
        return DivisibilityResult(
          divisor: 12,
          isDivisible: pass,
          ruleTitle: 'Composite (3 and 4)',
          shortExplanation: pass
              ? 'Passes both Rule 3 and Rule 4'
              : (!pass3 && !pass4
                  ? 'Fails both Rule 3 and Rule 4'
                  : (!pass3 ? 'Fails Rule 3 (digit sum)' : 'Fails Rule 4 (last 2 digits)')),
          detailedWorking:
              'Rule 3 (sum of digits): ${pass3 ? "PASS" : "FAIL"}.\nRule 4 (last 2 digits): ${pass4 ? "PASS" : "FAIL"}.\nSince 3 and 4 are co-prime, $n must pass both to be divisible by 12.',
          whyItWorks: '12 = 3 × 4 (co-prime factors).',
          category: DivisibilityCategory.composites,
        );

      // ─── 13: Osculator +4 Trick ─────────────────────────────────────────
      case 13:
        var curr = n;
        final stepsLog = <String>[];
        while (curr >= 130) {
          final last = curr % 10;
          final rest = curr ~/ 10;
          final next = rest + 4 * last;
          stepsLog.add('$rest + 4($last) = $next');
          curr = next;
        }
        final pass = curr % 13 == 0;
        return DivisibilityResult(
          divisor: 13,
          isDivisible: pass,
          ruleTitle: 'Osculator (+4 × last digit)',
          shortExplanation:
              pass ? 'Reduced to $curr (multiple of 13)' : 'Reduced to $curr (not div by 13)',
          detailedWorking:
              'Multiply the last digit by 4 and add to the remaining number:\n${stepsLog.take(3).join('\n')}\nFinal value: $curr ${pass ? "is divisible by 13 ($curr = 13 × ${curr ~/ 13})" : "is not divisible by 13"}.',
          whyItWorks:
              'Notice (10a + b) + 39b = 10(a + 4b). Since 39 is a multiple of 13, adding 4×units tests divisibility.',
          category: DivisibilityCategory.primes,
          proTip: 'Remember: for 7 you subtract 2× units, for 13 you add 4× units!',
        );

      // ─── 14: Even AND Divisible by 7 ────────────────────────────────────
      case 14:
        final pass2 = (n % 10) % 2 == 0;
        final pass7 = checkOne(n, 7).isDivisible;
        final pass = pass2 && pass7;
        return DivisibilityResult(
          divisor: 14,
          isDivisible: pass,
          ruleTitle: 'Composite (2 and 7)',
          shortExplanation: pass ? 'Even and divisible by 7' : (!pass2 ? 'Not even' : 'Not divisible by 7'),
          detailedWorking:
              'Rule 2 (even units digit): ${pass2 ? "PASS" : "FAIL"}.\nRule 7 (truncate & double): ${pass7 ? "PASS" : "FAIL"}.\nResult: ${pass ? "Divisible by 14" : "Not divisible by 14"}.',
          whyItWorks: '14 = 2 × 7 (co-prime factors).',
          category: DivisibilityCategory.composites,
        );

      // ─── 15: Divisible by 3 AND 5 ────────────────────────────────────────
      case 15:
        final pass3 = checkOne(n, 3).isDivisible;
        final pass5 = checkOne(n, 5).isDivisible;
        final pass = pass3 && pass5;
        return DivisibilityResult(
          divisor: 15,
          isDivisible: pass,
          ruleTitle: 'Composite (3 and 5)',
          shortExplanation: pass
              ? 'Ends in 0 or 5 and digit sum is multiple of 3'
              : (!pass5 ? 'Does not end in 0 or 5' : 'Digit sum not divisible by 3'),
          detailedWorking:
              'Rule 5 (ends in 0 or 5): ${pass5 ? "PASS" : "FAIL"}.\nRule 3 (sum of digits): ${pass3 ? "PASS" : "FAIL"}.\nResult: ${pass ? "Divisible by 15" : "Not divisible by 15"}.',
          whyItWorks: '15 = 3 × 5 (co-prime factors).',
          category: DivisibilityCategory.composites,
        );

      // ─── 18: Even AND Divisible by 9 ────────────────────────────────────
      case 18:
        final pass2 = (n % 10) % 2 == 0;
        final pass9 = checkOne(n, 9).isDivisible;
        final pass = pass2 && pass9;
        return DivisibilityResult(
          divisor: 18,
          isDivisible: pass,
          ruleTitle: 'Composite (2 and 9)',
          shortExplanation: pass ? 'Even and digit sum is multiple of 9' : (!pass2 ? 'Odd number' : 'Digit sum not divisible by 9'),
          detailedWorking:
              'Rule 2 (even): ${pass2 ? "PASS" : "FAIL"}.\nRule 9 (digit sum multiple of 9): ${pass9 ? "PASS" : "FAIL"}.\nResult: ${pass ? "Divisible by 18" : "Not divisible by 18"}.',
          whyItWorks: '18 = 2 × 9 (co-prime factors).',
          category: DivisibilityCategory.composites,
        );

      // ─── 25: Last 2 digits are 00, 25, 50, 75 ───────────────────────────
      case 25:
        final last2 = n % 100;
        final pass = last2 == 0 || last2 == 25 || last2 == 50 || last2 == 75;
        final last2Str = s.length >= 2 ? s.substring(s.length - 2) : s;
        return DivisibilityResult(
          divisor: 25,
          isDivisible: pass,
          ruleTitle: 'Ends in 00, 25, 50, 75',
          shortExplanation: pass ? 'Ends in $last2Str' : 'Ends in $last2Str (not 00, 25, 50, 75)',
          detailedWorking:
              'The last two digits are $last2Str. Since 100 is a multiple of 25, only the last two digits determine divisibility.\nMust end in 00, 25, 50, or 75.',
          whyItWorks: '100 = 25 × 4. Hundreds and above leave zero remainder.',
          category: DivisibilityCategory.endings,
        );

      default:
        final pass = n % d == 0;
        return DivisibilityResult(
          divisor: d,
          isDivisible: pass,
          ruleTitle: 'Divisibility by $d',
          shortExplanation: pass ? 'Divisible by $d' : 'Not divisible by $d',
          detailedWorking: '$n ÷ $d = ${n ~/ d} R ${n % d}',
          whyItWorks: 'Standard division check.',
          category: DivisibilityCategory.all,
        );
    }
  }

  /// Generates a drill question for the Speed Drill.
  static DrillQuestion generateDrillQuestion(Random rng, int difficultyLevel) {
    // difficultyLevel: 1=beginner, 2=easy, 3=medium, 4=hard, 5=expert, 6=genius
    final List<int> divisorPool;
    final int minDigits;
    final int maxDigits;

    switch (difficultyLevel) {
      case 1:
        divisorPool = [2, 5, 10];
        minDigits = 2;
        maxDigits = 3;
      case 2:
        divisorPool = [3, 4, 9];
        minDigits = 3;
        maxDigits = 4;
      case 3:
        divisorPool = [6, 8, 11];
        minDigits = 3;
        maxDigits = 4;
      case 4:
        divisorPool = [7, 12, 15, 25];
        minDigits = 3;
        maxDigits = 5;
      case 5:
        divisorPool = [13, 14, 18];
        minDigits = 3;
        maxDigits = 5;
      default:
        divisorPool = [6, 7, 8, 9, 11, 12, 13, 14, 15, 18, 25];
        minDigits = 4;
        maxDigits = 6;
    }

    final divisor = divisorPool[rng.nextInt(divisorPool.length)];
    final isTrueCase = rng.nextBool();

    int n;
    final scale = pow(10, minDigits + rng.nextInt(maxDigits - minDigits + 1)).toInt();
    if (isTrueCase) {
      final k = (scale / divisor).round() + rng.nextInt(scale ~/ 2 + 1);
      n = k * divisor;
    } else {
      final k = (scale / divisor).round() + rng.nextInt(scale ~/ 2 + 1);
      final rem = 1 + rng.nextInt(divisor - 1);
      n = k * divisor + rem;
    }

    final result = checkOne(n, divisor);

    return DrillQuestion(
      number: n,
      divisor: divisor,
      isDivisible: isTrueCase,
      ruleTitle: result.ruleTitle,
      explanation: result.detailedWorking,
    );
  }
}

/// Represents one question in the Divisibility Speed Drill.
class DrillQuestion {
  const DrillQuestion({
    required this.number,
    required this.divisor,
    required this.isDivisible,
    required this.ruleTitle,
    required this.explanation,
  });

  final int number;
  final int divisor;
  final bool isDivisible;
  final String ruleTitle;
  final String explanation;
}
