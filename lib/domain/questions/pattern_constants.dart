import 'dart:math';
import '../../core/enums/enums.dart';

/// Constants, labels, and mapping logic for question patterns across all topics and difficulties.
class PatternConstants {
  // --- ADDITION PATTERNS ---
  static const String addENoCarry = 'add_e_no_carry';
  static const String addEOneCarry = 'add_e_one_carry';
  static const String addETwoCarries = 'add_e_two_carries';

  static const String addMNoCarry = 'add_m_no_carry';
  static const String addMOneCarry = 'add_m_one_carry';
  static const String addMTwoCarries = 'add_m_two_carries';
  static const String addMThreeCarries = 'add_m_three_carries';

  static const String addHFewCarries = 'add_h_few_carries';
  static const String addHManyCarries = 'add_h_many_carries';

  // --- SUBTRACTION PATTERNS ---
  static const String subENoBorrow = 'sub_e_no_borrow';
  static const String subEOneBorrow = 'sub_e_one_borrow';

  static const String subMNoBorrow = 'sub_m_no_borrow';
  static const String subMOneBorrow = 'sub_m_one_borrow';
  static const String subMTwoBorrows = 'sub_m_two_borrows';

  static const String subHFewBorrows = 'sub_h_few_borrows';
  static const String subHTwoBorrows = 'sub_h_two_borrows';
  static const String subHThreeBorrows = 'sub_h_three_borrows';

  // --- MULTIPLICATION PATTERNS ---
  static const String mulESmallDigit = 'mul_e_small_digit';
  static const String mulEMidDigit = 'mul_e_mid_digit';
  static const String mulEHighDigit = 'mul_e_high_digit';

  static const String mulMSmallOnes = 'mul_m_small_ones';
  static const String mulMMidOnes = 'mul_m_mid_ones';
  static const String mulMHighOnes = 'mul_m_high_ones';

  static const String mulHSmallOnes = 'mul_h_small_ones';
  static const String mulHMidOnes = 'mul_h_mid_ones';
  static const String mulHHighOnes = 'mul_h_high_ones';

  // --- DIVISION PATTERNS ---
  static const String divESmallDivisor = 'div_e_small_divisor';
  static const String divEMidDivisor = 'div_e_mid_divisor';
  static const String divELargeDivisor = 'div_e_large_divisor';

  static const String divMSingleDigit = 'div_m_single_digit';
  static const String divMTwoDigit = 'div_m_two_digit';

  static const String divHSmallDivisor = 'div_h_small_divisor';
  static const String divHMidDivisor = 'div_h_mid_divisor';
  static const String divHLargeDivisor = 'div_h_large_divisor';

  // --- SQUARES PATTERNS ---
  static const String sqEEndsIn5 = 'sq_e_ends_in_5';
  static const String sqELowerHalf = 'sq_e_lower_half';
  static const String sqEUpperHalf = 'sq_e_upper_half';

  static const String sqMEndsIn5 = 'sq_m_ends_in_5';
  static const String sqMLowerHalf = 'sq_m_lower_half';
  static const String sqMUpperHalf = 'sq_m_upper_half';

  static const String sqHEndsIn5 = 'sq_h_ends_in_5';
  static const String sqHLowerHalf = 'sq_h_lower_half';
  static const String sqHUpperHalf = 'sq_h_upper_half';

  // --- CUBES PATTERNS ---
  static const String cubeELower = 'cube_e_lower';
  static const String cubeEUpper = 'cube_e_upper';

  static const String cubeMEndsIn5 = 'cube_m_ends_in_5';
  static const String cubeMLower = 'cube_m_lower';
  static const String cubeMUpper = 'cube_m_upper';

  static const String cubeHEndsIn5 = 'cube_h_ends_in_5';
  static const String cubeHLower = 'cube_h_lower';
  static const String cubeHUpper = 'cube_h_upper';

  // --- SQUARE ROOTS PATTERNS ---
  static const String sqrtEEndsIn5 = 'sqrt_e_ends_in_5';
  static const String sqrtELower = 'sqrt_e_lower';
  static const String sqrtEUpper = 'sqrt_e_upper';

  static const String sqrtMEndsIn5 = 'sqrt_m_ends_in_5';
  static const String sqrtMLower = 'sqrt_m_lower';
  static const String sqrtMUpper = 'sqrt_m_upper';

  static const String sqrtHEndsIn5 = 'sqrt_h_ends_in_5';
  static const String sqrtHLower = 'sqrt_h_lower';
  static const String sqrtHUpper = 'sqrt_h_upper';

  // --- CUBE ROOTS PATTERNS ---
  static const String cbrtELower = 'cbrt_e_lower';
  static const String cbrtEUpper = 'cbrt_e_upper';

  static const String cbrtMEndsIn5 = 'cbrt_m_ends_in_5';
  static const String cbrtMLower = 'cbrt_m_lower';
  static const String cbrtMUpper = 'cbrt_m_upper';

  static const String cbrtHEndsIn5 = 'cbrt_h_ends_in_5';
  static const String cbrtHLower = 'cbrt_h_lower';
  static const String cbrtHUpper = 'cbrt_h_upper';

  // --- EXPONENTS PATTERNS ---
  static const String expESquared = 'exp_e_squared';
  static const String expECubed = 'exp_e_cubed';

  static const String expMLowPower = 'exp_m_low_power';
  static const String expMHighPower = 'exp_m_high_power';

  static const String expHSmallBase = 'exp_h_small_base';
  static const String expHLargeBase = 'exp_h_large_base';

  /// Returns all available patterns for a specific [topic] and [difficulty].
  static List<String> patternsFor(Topic topic, Difficulty difficulty) {
    switch (topic) {
      case Topic.addition:
        switch (difficulty) {
          case Difficulty.easy:
            return [addENoCarry, addEOneCarry, addETwoCarries];
          case Difficulty.medium:
            return [addMNoCarry, addMOneCarry, addMTwoCarries, addMThreeCarries];
          case Difficulty.hard:
            return [addHFewCarries, addHManyCarries];
          case Difficulty.mixed:
            return [];
        }
      case Topic.subtraction:
        switch (difficulty) {
          case Difficulty.easy:
            return [subENoBorrow, subEOneBorrow];
          case Difficulty.medium:
            return [subMNoBorrow, subMOneBorrow, subMTwoBorrows];
          case Difficulty.hard:
            return [subHFewBorrows, subHTwoBorrows, subHThreeBorrows];
          case Difficulty.mixed:
            return [];
        }
      case Topic.multiplication:
        switch (difficulty) {
          case Difficulty.easy:
            return [mulESmallDigit, mulEMidDigit, mulEHighDigit];
          case Difficulty.medium:
            return [mulMSmallOnes, mulMMidOnes, mulMHighOnes];
          case Difficulty.hard:
            return [mulHSmallOnes, mulHMidOnes, mulHHighOnes];
          case Difficulty.mixed:
            return [];
        }
      case Topic.division:
        switch (difficulty) {
          case Difficulty.easy:
            return [divESmallDivisor, divEMidDivisor, divELargeDivisor];
          case Difficulty.medium:
            return [divMSingleDigit, divMTwoDigit];
          case Difficulty.hard:
            return [divHSmallDivisor, divHMidDivisor, divHLargeDivisor];
          case Difficulty.mixed:
            return [];
        }
      case Topic.squares:
        switch (difficulty) {
          case Difficulty.easy:
            return [sqEEndsIn5, sqELowerHalf, sqEUpperHalf];
          case Difficulty.medium:
            return [sqMEndsIn5, sqMLowerHalf, sqMUpperHalf];
          case Difficulty.hard:
            return [sqHEndsIn5, sqHLowerHalf, sqHUpperHalf];
          case Difficulty.mixed:
            return [];
        }
      case Topic.cubes:
        switch (difficulty) {
          case Difficulty.easy:
            return [cubeELower, cubeEUpper];
          case Difficulty.medium:
            return [cubeMEndsIn5, cubeMLower, cubeMUpper];
          case Difficulty.hard:
            return [cubeHEndsIn5, cubeHLower, cubeHUpper];
          case Difficulty.mixed:
            return [];
        }
      case Topic.squareRoots:
        switch (difficulty) {
          case Difficulty.easy:
            return [sqrtEEndsIn5, sqrtELower, sqrtEUpper];
          case Difficulty.medium:
            return [sqrtMEndsIn5, sqrtMLower, sqrtMUpper];
          case Difficulty.hard:
            return [sqrtHEndsIn5, sqrtHLower, sqrtHUpper];
          case Difficulty.mixed:
            return [];
        }
      case Topic.cubeRoots:
        switch (difficulty) {
          case Difficulty.easy:
            return [cbrtELower, cbrtEUpper];
          case Difficulty.medium:
            return [cbrtMEndsIn5, cbrtMLower, cbrtMUpper];
          case Difficulty.hard:
            return [cbrtHEndsIn5, cbrtHLower, cbrtHUpper];
          case Difficulty.mixed:
            return [];
        }
      case Topic.exponents:
        switch (difficulty) {
          case Difficulty.easy:
            return [expESquared, expECubed];
          case Difficulty.medium:
            return [expMLowPower, expMHighPower];
          case Difficulty.hard:
            return [expHSmallBase, expHLargeBase];
          case Difficulty.mixed:
            return [];
        }
      case Topic.mixed:
        return [];
    }
  }

  /// Human-readable label for a given [pattern].
  static String labelFor(String pattern) {
    return _labels[pattern] ?? pattern;
  }

  static const Map<String, String> _labels = {
    // Addition
    addENoCarry: '2-digit additions without carries',
    addEOneCarry: '2-digit additions with 1 carry',
    addETwoCarries: '2-digit additions with 2 carries',
    addMNoCarry: '3-digit additions without carries',
    addMOneCarry: '3-digit additions with 1 carry',
    addMTwoCarries: '3-digit additions with 2 carries',
    addMThreeCarries: '3-digit additions with 3 carries',
    addHFewCarries: '3-number additions with 0 to 2 carries',
    addHManyCarries: '3-number additions with 3 or more carries',

    // Subtraction
    subENoBorrow: '2-digit subtractions without borrows',
    subEOneBorrow: '2-digit subtractions with 1 borrow',
    subMNoBorrow: '3-digit subtractions without borrows',
    subMOneBorrow: '3-digit subtractions with 1 borrow',
    subMTwoBorrows: '3-digit subtractions with 2 borrows',
    subHFewBorrows: '4-digit subtractions with 0 to 1 borrow',
    subHTwoBorrows: '4-digit subtractions with 2 borrows',
    subHThreeBorrows: '4-digit subtractions with 3 borrows',

    // Multiplication
    mulESmallDigit: '2-digit × 1-digit (multiplier 2 to 4)',
    mulEMidDigit: '2-digit × 1-digit (multiplier 5 to 6)',
    mulEHighDigit: '2-digit × 1-digit (multiplier 7 to 9)',
    mulMSmallOnes: '2-digit × 2-digit (smaller factor ending in 0 to 3)',
    mulMMidOnes: '2-digit × 2-digit (smaller factor ending in 4 to 6)',
    mulMHighOnes: '2-digit × 2-digit (smaller factor ending in 7 to 9)',
    mulHSmallOnes: '3-digit × 2-digit (multiplier ending in 0 to 3)',
    mulHMidOnes: '3-digit × 2-digit (multiplier ending in 4 to 6)',
    mulHHighOnes: '3-digit × 2-digit (multiplier ending in 7 to 9)',

    // Division
    divESmallDivisor: '2-digit ÷ 1-digit (divisor 2 to 4)',
    divEMidDivisor: '2-digit ÷ 1-digit (divisor 5 to 6)',
    divELargeDivisor: '2-digit ÷ 1-digit (divisor 7 to 9)',
    divMSingleDigit: '3-digit ÷ 1-digit',
    divMTwoDigit: '2-digit ÷ 2-digit',
    divHSmallDivisor: '4-digit ÷ 2-digit (divisor 11 to 30)',
    divHMidDivisor: '4-digit ÷ 2-digit (divisor 31 to 60)',
    divHLargeDivisor: '4-digit ÷ 2-digit (divisor 61 to 99)',

    // Squares
    sqEEndsIn5: 'Squares ending in 5 (up to 20)',
    sqELowerHalf: 'Squares from 2 to 10',
    sqEUpperHalf: 'Squares from 11 to 20',
    sqMEndsIn5: 'Squares ending in 5 (21 to 50)',
    sqMLowerHalf: 'Squares from 21 to 35',
    sqMUpperHalf: 'Squares from 36 to 50',
    sqHEndsIn5: 'Squares ending in 5 (51 to 99)',
    sqHLowerHalf: 'Squares from 51 to 75',
    sqHUpperHalf: 'Squares from 76 to 99',

    // Cubes
    cubeELower: 'Cubes from 2 to 5',
    cubeEUpper: 'Cubes from 6 to 10',
    cubeMEndsIn5: 'Cube of 15',
    cubeMLower: 'Cubes from 11 to 14',
    cubeMUpper: 'Cubes from 16 to 20',
    cubeHEndsIn5: 'Cubes ending in 5 (25, 35)',
    cubeHLower: 'Cubes from 21 to 28',
    cubeHUpper: 'Cubes from 29 to 35',

    // Square Roots
    sqrtEEndsIn5: 'Square roots ending in 5 (up to 20)',
    sqrtELower: 'Square roots from 2 to 10',
    sqrtEUpper: 'Square roots from 11 to 20',
    sqrtMEndsIn5: 'Square roots ending in 5 (21 to 50)',
    sqrtMLower: 'Square roots from 21 to 35',
    sqrtMUpper: 'Square roots from 36 to 50',
    sqrtHEndsIn5: 'Square roots ending in 5 (51 to 99)',
    sqrtHLower: 'Square roots from 51 to 75',
    sqrtHUpper: 'Square roots from 76 to 99',

    // Cube Roots
    cbrtELower: 'Cube roots from 2 to 5',
    cbrtEUpper: 'Cube roots from 6 to 10',
    cbrtMEndsIn5: 'Cube root of 3375 (root 15)',
    cbrtMLower: 'Cube roots from 11 to 14',
    cbrtMUpper: 'Cube roots from 16 to 20',
    cbrtHEndsIn5: 'Cube roots ending in 5 (25, 35)',
    cbrtHLower: 'Cube roots from 21 to 28',
    cbrtHUpper: 'Cube roots from 29 to 35',

    // Exponents
    expESquared: 'Powers with exponent 2 (squares)',
    expECubed: 'Powers with exponent 3 (cubes)',
    expMLowPower: 'Exponents with power 2 or 3',
    expMHighPower: 'Exponents with power 4 or 5',
    expHSmallBase: 'Exponents with bases 2 to 5',
    expHLargeBase: 'Exponents with bases 6 to 15',
  };

  /// Pure function that recomputes the pattern from topic, difficulty, and operands.
  static String patternOf(
    Topic topic,
    Difficulty difficulty,
    List<int> operands,
  ) {
    if (operands.isEmpty) return 'default';

    switch (topic) {
      case Topic.addition:
        final carries = countAdditionCarries(operands);
        switch (difficulty) {
          case Difficulty.easy:
            if (carries == 0) return addENoCarry;
            if (carries == 1) return addEOneCarry;
            return addETwoCarries;
          case Difficulty.medium:
            if (carries == 0) return addMNoCarry;
            if (carries == 1) return addMOneCarry;
            if (carries == 2) return addMTwoCarries;
            return addMThreeCarries;
          case Difficulty.hard:
            return carries <= 2 ? addHFewCarries : addHManyCarries;
          case Difficulty.mixed:
            return addENoCarry;
        }

      case Topic.subtraction:
        final a = operands[0];
        final b = operands.length > 1 ? operands[1] : 0;
        final borrows = countSubtractionBorrows(a, b);
        switch (difficulty) {
          case Difficulty.easy:
            return borrows == 0 ? subENoBorrow : subEOneBorrow;
          case Difficulty.medium:
            if (borrows == 0) return subMNoBorrow;
            if (borrows == 1) return subMOneBorrow;
            return subMTwoBorrows;
          case Difficulty.hard:
            if (borrows <= 1) return subHFewBorrows;
            if (borrows == 2) return subHTwoBorrows;
            return subHThreeBorrows;
          case Difficulty.mixed:
            return subENoBorrow;
        }

      case Topic.multiplication:
        final a = operands[0];
        final b = operands.length > 1 ? operands[1] : 1;
        switch (difficulty) {
          case Difficulty.easy:
            final multiplier = min(a, b);
            if (multiplier <= 4) return mulESmallDigit;
            if (multiplier <= 6) return mulEMidDigit;
            return mulEHighDigit;
          case Difficulty.medium:
            final smaller = min(a, b);
            final ones = smaller % 10;
            if (ones <= 3) return mulMSmallOnes;
            if (ones <= 6) return mulMMidOnes;
            return mulMHighOnes;
          case Difficulty.hard:
            final multiplier = min(a, b);
            final ones = multiplier % 10;
            if (ones <= 3) return mulHSmallOnes;
            if (ones <= 6) return mulHMidOnes;
            return mulHHighOnes;
          case Difficulty.mixed:
            return mulESmallDigit;
        }

      case Topic.division:
        final divisor = operands.length > 1 ? operands[1] : 1;
        switch (difficulty) {
          case Difficulty.easy:
            if (divisor <= 4) return divESmallDivisor;
            if (divisor <= 6) return divEMidDivisor;
            return divELargeDivisor;
          case Difficulty.medium:
            return divisor <= 9 ? divMSingleDigit : divMTwoDigit;
          case Difficulty.hard:
            if (divisor <= 30) return divHSmallDivisor;
            if (divisor <= 60) return divHMidDivisor;
            return divHLargeDivisor;
          case Difficulty.mixed:
            return divESmallDivisor;
        }

      case Topic.squares:
        final base = operands[0];
        switch (difficulty) {
          case Difficulty.easy:
            if (base % 10 == 5) return sqEEndsIn5;
            return base <= 10 ? sqELowerHalf : sqEUpperHalf;
          case Difficulty.medium:
            if (base % 10 == 5) return sqMEndsIn5;
            return base <= 35 ? sqMLowerHalf : sqMUpperHalf;
          case Difficulty.hard:
            if (base % 10 == 5) return sqHEndsIn5;
            return base <= 75 ? sqHLowerHalf : sqHUpperHalf;
          case Difficulty.mixed:
            return sqELowerHalf;
        }

      case Topic.cubes:
        final base = operands[0];
        switch (difficulty) {
          case Difficulty.easy:
            return base <= 5 ? cubeELower : cubeEUpper;
          case Difficulty.medium:
            if (base == 15) return cubeMEndsIn5;
            return base <= 14 ? cubeMLower : cubeMUpper;
          case Difficulty.hard:
            if (base % 10 == 5) return cubeHEndsIn5;
            return base <= 28 ? cubeHLower : cubeHUpper;
          case Difficulty.mixed:
            return cubeELower;
        }

      case Topic.squareRoots:
        final root = operands.length > 1
            ? operands[1]
            : sqrt(operands[0]).round();
        switch (difficulty) {
          case Difficulty.easy:
            if (root % 10 == 5) return sqrtEEndsIn5;
            return root <= 10 ? sqrtELower : sqrtEUpper;
          case Difficulty.medium:
            if (root % 10 == 5) return sqrtMEndsIn5;
            return root <= 35 ? sqrtMLower : sqrtMUpper;
          case Difficulty.hard:
            if (root % 10 == 5) return sqrtHEndsIn5;
            return root <= 75 ? sqrtHLower : sqrtHUpper;
          case Difficulty.mixed:
            return sqrtELower;
        }

      case Topic.cubeRoots:
        final root = operands.length > 1
            ? operands[1]
            : pow(operands[0], 1 / 3).round();
        switch (difficulty) {
          case Difficulty.easy:
            return root <= 5 ? cbrtELower : cbrtEUpper;
          case Difficulty.medium:
            if (root == 15) return cbrtMEndsIn5;
            return root <= 14 ? cbrtMLower : cbrtMUpper;
          case Difficulty.hard:
            if (root % 10 == 5) return cbrtHEndsIn5;
            return root <= 28 ? cbrtHLower : cbrtHUpper;
          case Difficulty.mixed:
            return cbrtELower;
        }

      case Topic.exponents:
        final base = operands[0];
        final power = operands.length > 1 ? operands[1] : 2;
        switch (difficulty) {
          case Difficulty.easy:
            return power == 2 ? expESquared : expECubed;
          case Difficulty.medium:
            return power <= 3 ? expMLowPower : expMHighPower;
          case Difficulty.hard:
            return base <= 5 ? expHSmallBase : expHLargeBase;
          case Difficulty.mixed:
            return expESquared;
        }

      case Topic.mixed:
        return 'default';
    }
  }

  /// Calculates the number of carries when adding [operands] in column addition.
  static int countAdditionCarries(List<int> operands) {
    if (operands.length < 2) return 0;
    int carries = 0;
    int currentCarry = 0;
    final ops = List<int>.from(operands);

    while (ops.any((x) => x > 0) || currentCarry > 0) {
      int sum = currentCarry;
      for (int i = 0; i < ops.length; i++) {
        sum += ops[i] % 10;
        ops[i] = ops[i] ~/ 10;
      }
      currentCarry = sum ~/ 10;
      if (currentCarry > 0) {
        carries++;
      }
    }
    return carries;
  }

  /// Calculates the number of borrows when subtracting [b] from [a] ($a \ge b$).
  static int countSubtractionBorrows(int a, int b) {
    if (a < b) return 0;
    int borrows = 0;
    int currentBorrow = 0;
    int remA = a;
    int remB = b;

    while (remA > 0 || remB > 0) {
      final digitA = (remA % 10) - currentBorrow;
      final digitB = remB % 10;
      remA ~/= 10;
      remB ~/= 10;

      if (digitA < digitB) {
        currentBorrow = 1;
        borrows++;
      } else {
        currentBorrow = 0;
      }
    }
    return borrows;
  }
}
