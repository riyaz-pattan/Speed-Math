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

  static const String sqExpEndsIn5 = 'sq_exp_ends_in_5';
  static const String sqExpLowerHalf = 'sq_exp_lower_half';
  static const String sqExpUpperHalf = 'sq_exp_upper_half';

  static const String sqGenEndsIn5 = 'sq_gen_ends_in_5';
  static const String sqGenLowerHalf = 'sq_gen_lower_half';
  static const String sqGenUpperHalf = 'sq_gen_upper_half';

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

  static const String sqrtExpEndsIn5 = 'sqrt_exp_ends_in_5';
  static const String sqrtExpLower = 'sqrt_exp_lower';
  static const String sqrtExpUpper = 'sqrt_exp_upper';

  static const String sqrtGenEndsIn5 = 'sqrt_gen_ends_in_5';
  static const String sqrtGenLower = 'sqrt_gen_lower';
  static const String sqrtGenUpper = 'sqrt_gen_upper';

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

  // --- PERCENTAGES PATTERNS ---
  static const String pctETenFifty = 'pct_e_ten_fifty';
  static const String pctETwentyTwentyfive = 'pct_e_twenty_twentyfive';
  static const String pctMQuarterMult = 'pct_m_quarter_mult';
  static const String pctMTenthMult = 'pct_m_tenth_mult';
  static const String pctMFifthMult = 'pct_m_fifth_mult';
  static const String pctHAddition = 'pct_h_addition';
  static const String pctHSubtraction = 'pct_h_subtraction';

  // --- FRACTIONS PATTERNS ---
  static const String fracESmallDenom = 'frac_e_small_denom';
  static const String fracEMidDenom = 'frac_e_mid_denom';
  static const String fracMBandSmall = 'frac_m_band_small';
  static const String fracMBandMid = 'frac_m_band_mid';
  static const String fracMBandLarge = 'frac_m_band_large';
  static const String fracHAddition = 'frac_h_addition';
  static const String fracHSubtraction = 'frac_h_subtraction';

  // --- SIMPLIFICATION PATTERNS ---
  static const String simpEAddMul = 'simp_e_add_mul';
  static const String simpEMulSub = 'simp_e_mul_sub';
  static const String simpEDiv = 'simp_e_div';
  static const String simpMBrackets = 'simp_m_brackets';
  static const String simpMTwoOps = 'simp_m_two_ops';
  static const String simpHSquareDivMul = 'simp_h_square_div_mul';
  static const String simpHSquareAddSub = 'simp_h_square_add_sub';

  // --- AVERAGES PATTERNS ---
  static const String avgECloseSpread = 'avg_e_close_spread';
  static const String avgEWideSpread = 'avg_e_wide_spread';
  static const String avgMTwoDigit = 'avg_m_two_digit';
  static const String avgMMixedDigits = 'avg_m_mixed_digits';
  static const String avgHFindMissing = 'avg_h_find_missing';

  // --- MISSING NUMBER PATTERNS ---
  static const String misEAddition = 'mis_e_addition';
  static const String misESubtraction = 'mis_e_subtraction';
  static const String misEMultiplication = 'mis_e_multiplication';
  static const String misMMultiplication = 'mis_m_multiplication';
  static const String misMDivision = 'mis_m_division';
  static const String misMSubtraction = 'mis_m_subtraction';
  static const String misHLinear = 'mis_h_linear';
  static const String misHBrackets = 'mis_h_brackets';

  // --- NUMBER SERIES PATTERNS ---
  static const String numEConstantDiff = 'num_e_constant_diff';
  static const String numEGeomSmall = 'num_e_geom_small';
  static const String numEConsecSquares = 'num_e_consec_squares';
  static const String numEConsecCubes = 'num_e_consec_cubes';
  static const String numEOddEven = 'num_e_odd_even';
  static const String numMGrowingDiff = 'num_m_growing_diff';
  static const String numMFibonacci = 'num_m_fibonacci';
  static const String numMMulAddSub = 'num_m_mul_add_sub';
  static const String numMSquareOffset = 'num_m_square_offset';
  static const String numMPrimes = 'num_m_primes';
  static const String numHInterleaved = 'num_h_interleaved';
  static const String numHGrowingMul = 'num_h_growing_mul';
  static const String numHSquareCubeDiff = 'num_h_square_cube_diff';
  static const String numHAlternatingOps = 'num_h_alternating_ops';

  // --- APPROXIMATION PATTERNS ---
  static const String approxEProduct = 'approx_e_product';
  static const String approxETwoOps = 'approx_e_two_ops';
  static const String approxMPercent = 'approx_m_percent';
  static const String approxMSquareRoot = 'approx_m_square_root';
  static const String approxMThreeOps = 'approx_m_three_ops';
  static const String approxHCompoundPercent = 'approx_h_compound_percent';
  static const String approxHPowersDiv = 'approx_h_powers_div';

  // --- UPGRADED FRACTIONS PATTERNS ---
  static const String fracESameDenom = 'frac_e_same_denom';
  static const String fracMMixed = 'frac_m_mixed';
  static const String fracMFractionOfFraction = 'frac_m_frac_of_frac';
  static const String fracHMixedSimp = 'frac_h_mixed_simp';

  // --- UPGRADED AVERAGES PATTERNS ---
  static const String avgEGroupSum = 'avg_e_group_sum';
  static const String avgEConsec = 'avg_e_consec';
  static const String avgMJoinLeave = 'avg_m_join_leave';
  static const String avgMOneRemoved = 'avg_m_one_removed';
  static const String avgHWeighted = 'avg_h_weighted';
  static const String avgHMemberReplaced = 'avg_h_member_replaced';

  // --- FRACTION RECIPROCALS PATTERNS ---
  static const String frRecEUnit = 'fr_rec_e_unit';
  static const String frRecMUnit = 'fr_rec_m_unit';
  static const String frRecHUnit = 'fr_rec_h_unit';

  // --- DERIVED FRACTIONS PATTERNS ---
  static const String frDerEMultiple = 'fr_der_e_multiple';
  static const String frDerMMultiple = 'fr_der_m_multiple';
  static const String frDerHMultiple = 'fr_der_h_multiple';

  // --- FRACTION PERCENTAGES PATTERNS ---
  static const String frPctESimple = 'fr_pct_e_simple';
  static const String frPctMModerate = 'fr_pct_m_moderate';
  static const String frPctHComplex = 'fr_pct_h_complex';

  // --- BASE PERCENTAGES PATTERNS ---
  static const String basePctESimple = 'base_pct_e_simple';
  static const String basePctMModerate = 'base_pct_m_moderate';
  static const String basePctHComplex = 'base_pct_h_complex';

  // --- SPLIT PERCENTAGES PATTERNS ---
  static const String splitPctEFive = 'split_pct_e_five';
  static const String splitPctMDouble = 'split_pct_m_double';
  static const String splitPctHNonRound = 'split_pct_h_nonround';

  // --- POWER OF FIVE PATTERNS ---
  static const String pow5ETimesFive = 'pow5_e_times5';
  static const String pow5MTwentyFive = 'pow5_m_times25';
  static const String pow5HOneTwentyFive = 'pow5_h_times125';

  // --- PATTERN MULTIPLICATION PATTERNS ---
  static const String patMulEEleven = 'pat_mul_e_eleven';
  static const String patMulMEleven = 'pat_mul_m_eleven';
  static const String patMulHNinetyNine = 'pat_mul_h_ninetynine';

  // Linear Equations
  static const String linE1VarAdd = 'linear_1var_add';
  static const String linE1VarMult = 'linear_1var_mult';
  static const String linE1VarStep = 'linear_1var_step';
  static const String linM2VarCompare = 'linear_2var_compare';
  static const String linM2VarSolve = 'linear_2var_solve';
  static const String linHSymmetricSum = 'linear_symmetric_sum';
  static const String linH3VarElim = 'linear_3var_elimination';

  // Quadratic Equations
  static const String quadERoots = 'quad_e_roots';
  static const String quadECompare = 'quad_e_compare';
  static const String quadMRoots = 'quad_m_roots';
  static const String quadMCompare = 'quad_m_compare';
  static const String quadHRoots = 'quad_h_roots';
  static const String quadHCompare = 'quad_h_compare';
  static const String quadRootFinding = 'quad_root_finding';
  static const String quadComparison = 'quad_comparison';

  /// Returns all available patterns for a specific [topic] and [difficulty].
  static List<String> patternsFor(Topic topic, Difficulty difficulty) {
    if (difficulty == Difficulty.expert || difficulty == Difficulty.genius) {
      if (topic == Topic.squares) {
        return difficulty == Difficulty.expert
            ? [sqExpEndsIn5, sqExpLowerHalf, sqExpUpperHalf]
            : [sqGenEndsIn5, sqGenLowerHalf, sqGenUpperHalf];
      }
      if (topic == Topic.squareRoots) {
        return difficulty == Difficulty.expert
            ? [sqrtExpEndsIn5, sqrtExpLower, sqrtExpUpper]
            : [sqrtGenEndsIn5, sqrtGenLower, sqrtGenUpper];
      }
      return patternsFor(topic, Difficulty.hard);
    }

    switch (topic) {
      case Topic.addition:
        switch (difficulty) {
          case Difficulty.easy:
            return [addENoCarry, addEOneCarry, addETwoCarries];
          case Difficulty.medium:
            return [addMNoCarry, addMOneCarry, addMTwoCarries, addMThreeCarries];
          case Difficulty.hard:
            return [addHFewCarries, addHManyCarries];
          default:
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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
            return [];
        }
      case Topic.percentages:
        switch (difficulty) {
          case Difficulty.easy:
            return [pctETenFifty, pctETwentyTwentyfive];
          case Difficulty.medium:
            return [pctMQuarterMult, pctMTenthMult, pctMFifthMult];
          case Difficulty.hard:
            return [pctHAddition, pctHSubtraction];
          default:
            return [];
        }
      case Topic.fractions:
        switch (difficulty) {
          case Difficulty.easy:
            return [fracESmallDenom, fracEMidDenom, fracESameDenom];
          case Difficulty.medium:
            return [
              fracMBandSmall,
              fracMBandMid,
              fracMBandLarge,
              fracMMixed,
              fracMFractionOfFraction,
            ];
          case Difficulty.hard:
            return [fracHAddition, fracHSubtraction, fracHMixedSimp];
          default:
            return [];
        }
      case Topic.simplification:
        switch (difficulty) {
          case Difficulty.easy:
            return [simpEAddMul, simpEMulSub, simpEDiv];
          case Difficulty.medium:
            return [simpMBrackets, simpMTwoOps];
          case Difficulty.hard:
            return [simpHSquareDivMul, simpHSquareAddSub];
          default:
            return [];
        }
      case Topic.averages:
        switch (difficulty) {
          case Difficulty.easy:
            return [avgECloseSpread, avgEWideSpread, avgEGroupSum, avgEConsec];
          case Difficulty.medium:
            return [avgMTwoDigit, avgMMixedDigits, avgMJoinLeave, avgMOneRemoved];
          case Difficulty.hard:
            return [avgHFindMissing, avgHWeighted, avgHMemberReplaced];
          default:
            return [];
        }
      case Topic.missingNumber:
        switch (difficulty) {
          case Difficulty.easy:
            return [misEAddition, misESubtraction, misEMultiplication];
          case Difficulty.medium:
            return [misMMultiplication, misMDivision, misMSubtraction];
          case Difficulty.hard:
            return [misHLinear, misHBrackets];
          default:
            return [];
        }
      case Topic.numberSeries:
        switch (difficulty) {
          case Difficulty.easy:
            return [
              numEConstantDiff,
              numEGeomSmall,
              numEConsecSquares,
              numEConsecCubes,
              numEOddEven,
            ];
          case Difficulty.medium:
            return [
              numMGrowingDiff,
              numMFibonacci,
              numMMulAddSub,
              numMSquareOffset,
              numMPrimes,
            ];
          case Difficulty.hard:
            return [
              numHInterleaved,
              numHGrowingMul,
              numHSquareCubeDiff,
              numHAlternatingOps,
            ];
          default:
            return [];
        }
      case Topic.approximation:
        switch (difficulty) {
          case Difficulty.easy:
            return [approxEProduct, approxETwoOps];
          case Difficulty.medium:
            return [approxMPercent, approxMSquareRoot, approxMThreeOps];
          case Difficulty.hard:
            return [approxHCompoundPercent, approxHPowersDiv];
          default:
            return [];
        }
      case Topic.mixed:
        return [];
      case Topic.fractionReciprocals:
        switch (difficulty) {
          case Difficulty.easy: return [frRecEUnit];
          case Difficulty.medium: return [frRecMUnit];
          case Difficulty.hard: return [frRecHUnit];
          default: return [];
        }
      case Topic.derivedFractions:
        switch (difficulty) {
          case Difficulty.easy: return [frDerEMultiple];
          case Difficulty.medium: return [frDerMMultiple];
          case Difficulty.hard: return [frDerHMultiple];
          default: return [];
        }
      case Topic.fractionPercentages:
        switch (difficulty) {
          case Difficulty.easy: return [frPctESimple];
          case Difficulty.medium: return [frPctMModerate];
          case Difficulty.hard: return [frPctHComplex];
          default: return [];
        }
      case Topic.basePercentages:
        switch (difficulty) {
          case Difficulty.easy: return [basePctESimple];
          case Difficulty.medium: return [basePctMModerate];
          case Difficulty.hard: return [basePctHComplex];
          default: return [];
        }
      case Topic.splitPercentages:
        switch (difficulty) {
          case Difficulty.easy: return [splitPctEFive];
          case Difficulty.medium: return [splitPctMDouble];
          case Difficulty.hard: return [splitPctHNonRound];
          default: return [];
        }
      case Topic.powerOfFive:
        switch (difficulty) {
          case Difficulty.easy: return [pow5ETimesFive];
          case Difficulty.medium: return [pow5MTwentyFive];
          case Difficulty.hard: return [pow5HOneTwentyFive];
          default: return [];
        }
      case Topic.patternMultiplication:
        switch (difficulty) {
          case Difficulty.easy: return [patMulEEleven];
          case Difficulty.medium: return [patMulMEleven];
          case Difficulty.hard: return [patMulHNinetyNine];
          default: return [];
        }
      case Topic.linearEquations:
        switch (difficulty) {
          case Difficulty.easy: return [linE1VarAdd, linE1VarMult, linE1VarStep];
          case Difficulty.medium: return [linM2VarCompare, linM2VarSolve];
          case Difficulty.hard: return [linHSymmetricSum, linH3VarElim];
          default: return [];
        }
      case Topic.quadraticEquations:
        switch (difficulty) {
          case Difficulty.easy: return [quadERoots, quadECompare, quadRootFinding];
          case Difficulty.medium: return [quadMRoots, quadMCompare, quadComparison];
          case Difficulty.hard: return [quadHRoots, quadHCompare];
          default: return [];
        }
    }
  }

  /// All registered patterns.
  static List<String> get allPatterns => _labels.keys.toList();

  /// Map of all pattern codes to human-readable labels.
  static Map<String, String> get allLabels => Map.unmodifiable(_labels);

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

    // Percentages
    pctETenFifty: '10% or 50% of numbers up to 400',
    pctETwentyTwentyfive: '20% or 25% of numbers up to 400',
    pctMQuarterMult: 'Multiples of 25% (25%, 75%) of numbers up to 1000',
    pctMTenthMult: 'Multiples of 10% of numbers up to 1000',
    pctMFifthMult: 'Percentages ending in 5% (15%, 35%, 45%, etc.)',
    pctHAddition: 'Combined percentages (x% of A + y% of B)',
    pctHSubtraction: 'Difference of percentages (x% of A − y% of B)',

    // Fractions
    fracESmallDenom: 'Fractions with small denominator (2 to 4)',
    fracEMidDenom: 'Fractions with denominator (5, 6, 8, 10)',
    fracESameDenom: 'Fractions with the same denominator',
    fracMBandSmall: 'Fractions with denominator 2 to 5',
    fracMBandMid: 'Fractions with denominator 6 to 8',
    fracMBandLarge: 'Fractions with denominator 9 to 12',
    fracMMixed: 'Mixed fractions arithmetic',
    fracMFractionOfFraction: 'Fraction of a fraction (a/b of c/d of N)',
    fracHAddition: 'Adding two fraction values (a/b of N + c/d of M)',
    fracHSubtraction: 'Subtracting fraction values (a/b of N − c/d of M)',
    fracHMixedSimp: 'Mixed fraction multi-term simplification',

    // Simplification
    simpEAddMul: 'a + b × c expressions',
    simpEMulSub: 'a × b − c expressions',
    simpEDiv: 'a + b ÷ c expressions',
    simpMBrackets: 'Expressions with brackets (e.g. (a + b) × c − d)',
    simpMTwoOps: 'Two-operation expressions (e.g. a × b ± c × d)',
    simpHSquareDivMul: 'Expressions with square, division, and multiplication',
    simpHSquareAddSub: 'Expressions with square, addition, and division',

    // Averages
    avgECloseSpread: 'Average of 3 numbers with close spread',
    avgEWideSpread: 'Average of 3 numbers with wider spread',
    avgEGroupSum: 'Total sum from given group average',
    avgEConsec: 'Average of consecutive numbers series',
    avgMTwoDigit: 'Average of 5 two-digit numbers',
    avgMMixedDigits: 'Average of 5 two- and three-digit numbers',
    avgMJoinLeave: 'Average change when a member joins or leaves',
    avgMOneRemoved: 'Find removed or replaced number from average',
    avgHFindMissing: 'Find the missing 5th number from the average',
    avgHWeighted: 'Weighted average of two groups',
    avgHMemberReplaced: 'Member replaced causing average change',

    // Missing Number
    misEAddition: 'Missing addend (? + a = b)',
    misESubtraction: 'Missing minuend (? − a = b)',
    misEMultiplication: 'Missing factor (a × ? = b)',
    misMMultiplication: 'Missing factor with 2-digit numbers (? × a = b)',
    misMDivision: 'Missing dividend (? ÷ a = b)',
    misMSubtraction: 'Missing subtrahend (a − ? = b)',
    misHLinear: 'Linear equation (? × a ± b = c)',
    misHBrackets: 'Equation with brackets ((? ± a) × b = c)',

    // Number Series
    numEConstantDiff: 'Constant difference progression (arithmetic)',
    numEGeomSmall: 'Constant multiplier series (×2 or ×3)',
    numEConsecSquares: 'Consecutive squares series (n²)',
    numEConsecCubes: 'Consecutive cubes series (n³)',
    numEOddEven: 'Consecutive odd or even numbers',
    numMGrowingDiff: 'Growing differences (+3, +5, +7...)',
    numMFibonacci: 'Fibonacci-style addition progression',
    numMMulAddSub: 'Multiply then add/subtract (×n ± k)',
    numMSquareOffset: 'Square offset series (n² ± k)',
    numMPrimes: 'Consecutive prime numbers series',
    numHInterleaved: 'Two interleaved alternating rules series',
    numHGrowingMul: 'Growing multiplier progression (×1, ×2, ×3...)',
    numHSquareCubeDiff: 'Differences that are squares or cubes',
    numHAlternatingOps: 'Alternating operations series (+a, ×b...)',

    // Approximation
    approxEProduct: 'Near-number friendly multiplication',
    approxETwoOps: 'Two operations with friendly rounding (a + b × c)',
    approxMPercent: 'Near-percentage estimation',
    approxMSquareRoot: 'Square root of near-perfect square',
    approxMThreeOps: 'Three operations with friendly rounding',
    approxHCompoundPercent: 'Multi-term estimation with percentage and division',
    approxHPowersDiv: 'Multi-term with squares, division, and products',

    // Linear Equations
    linE1VarAdd: '1-variable linear addition (x + b = c)',
    linE1VarMult: '1-variable linear multiplication (ax = b)',
    linE1VarStep: '2-step 1-variable linear equation (ax + b = c)',
    linM2VarCompare: '2-variable linear system comparison',
    linM2VarSolve: '2-variable linear system solution',
    linHSymmetricSum: 'Symmetric linear system (ax + by = c, bx + ay = d)',
    linH3VarElim: '3-variable linear system elimination',

    // Quadratic Equations
    quadERoots: 'Standard quadratic root finding (x² + bx + c = 0)',
    quadECompare: 'Simple quadratic comparison (x vs y)',
    quadMRoots: 'Quadratic roots with coefficient a > 1',
    quadMCompare: 'Quadratic vs quadratic comparison',
    quadHRoots: 'Advanced quadratic roots',
    quadHCompare: 'Competitive exam equation comparison & CND',
    quadRootFinding: 'Find roots of quadratic equation',
    quadComparison: 'Compare roots of two equations',
  };

  /// Pure function that recomputes the pattern from topic, difficulty, and operands.
  static String patternOf(
    Topic topic,
    Difficulty difficulty,
    List<int> operands,
  ) {
    if (operands.isEmpty) return 'default';

    if (difficulty == Difficulty.expert || difficulty == Difficulty.genius) {
      if (topic == Topic.squares) {
        final base = operands[0];
        if (difficulty == Difficulty.expert) {
          if (base % 10 == 5) return sqExpEndsIn5;
          return base <= 125 ? sqExpLowerHalf : sqExpUpperHalf;
        } else {
          if (base % 10 == 5) return sqGenEndsIn5;
          return base <= 175 ? sqGenLowerHalf : sqGenUpperHalf;
        }
      }
      if (topic == Topic.squareRoots) {
        final root = operands.length > 1 ? operands[1] : operands[0];
        if (difficulty == Difficulty.expert) {
          if (root % 10 == 5) return sqrtExpEndsIn5;
          return root <= 125 ? sqrtExpLower : sqrtExpUpper;
        } else {
          if (root % 10 == 5) return sqrtGenEndsIn5;
          return root <= 175 ? sqrtGenLower : sqrtGenUpper;
        }
      }
      return patternOf(topic, Difficulty.hard, operands);
    }

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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
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
          default:
            return expESquared;
        }

      case Topic.percentages:
        final x = operands.isNotEmpty ? operands[0] : 10;
        switch (difficulty) {
          case Difficulty.easy:
            return (x == 10 || x == 50) ? pctETenFifty : pctETwentyTwentyfive;
          case Difficulty.medium:
            if (x == 25 || x == 75) return pctMQuarterMult;
            if (x % 10 == 0) return pctMTenthMult;
            return pctMFifthMult;
          case Difficulty.hard:
            final isMinus = operands.length > 4 && operands[4] == 1;
            return isMinus ? pctHSubtraction : pctHAddition;
          default:
            return pctETenFifty;
        }

      case Topic.fractions:
        final fType = operands.isNotEmpty ? operands.last : 1;
        switch (difficulty) {
          case Difficulty.easy:
            if (fType == 3) return fracESameDenom;
            final b = operands.length > 1 ? operands[1] : 2;
            return b <= 4 ? fracESmallDenom : fracEMidDenom;
          case Difficulty.medium:
            if (fType == 4) return fracMMixed;
            if (fType == 5) return fracMFractionOfFraction;
            final b = operands.length > 1 ? operands[1] : 2;
            if (b <= 5) return fracMBandSmall;
            if (b <= 8) return fracMBandMid;
            return fracMBandLarge;
          case Difficulty.hard:
            if (fType == 6) return fracHMixedSimp;
            final isMinus = operands.length > 6 && operands[6] == 1;
            return isMinus ? fracHSubtraction : fracHAddition;
          default:
            return fracESmallDenom;
        }

      case Topic.simplification:
        final form = operands.isNotEmpty ? operands.last : 0;
        switch (difficulty) {
          case Difficulty.easy:
            if (form == 1) return simpEAddMul;
            if (form == 2) return simpEMulSub;
            return simpEDiv;
          case Difficulty.medium:
            return (form == 1 || form == 2) ? simpMBrackets : simpMTwoOps;
          case Difficulty.hard:
            return form == 1 ? simpHSquareDivMul : simpHSquareAddSub;
          default:
            return simpEAddMul;
        }

      case Topic.averages:
        final aType = operands.isNotEmpty ? operands.last : 1;
        switch (difficulty) {
          case Difficulty.easy:
            if (aType == 2) return avgEGroupSum;
            if (aType == 3) return avgEConsec;
            if (operands.length >= 3) {
              final spread = (operands[0] - operands[1]).abs() +
                  (operands[1] - operands[2]).abs();
              return spread <= 40 ? avgECloseSpread : avgEWideSpread;
            }
            return avgECloseSpread;
          case Difficulty.medium:
            if (aType == 2) return avgMJoinLeave;
            if (aType == 3) return avgMOneRemoved;
            final has3Digit = operands.any((n) => n >= 100);
            return has3Digit ? avgMMixedDigits : avgMTwoDigit;
          case Difficulty.hard:
            if (aType == 2) return avgHWeighted;
            if (aType == 3) return avgHMemberReplaced;
            return avgHFindMissing;
          default:
            return avgECloseSpread;
        }

      case Topic.missingNumber:
        final op = operands.isNotEmpty ? operands.last : 0;
        switch (difficulty) {
          case Difficulty.easy:
            if (op == 1) return misEAddition;
            if (op == 2) return misESubtraction;
            return misEMultiplication;
          case Difficulty.medium:
            if (op == 1) return misMMultiplication;
            if (op == 2) return misMDivision;
            return misMSubtraction;
          case Difficulty.hard:
            return op == 1 ? misHLinear : misHBrackets;
          default:
            return misEAddition;
        }

      case Topic.numberSeries:
        final ruleId = operands.isNotEmpty ? operands.last : 1;
        switch (difficulty) {
          case Difficulty.easy:
            if (ruleId == 1) return numEConstantDiff;
            if (ruleId == 2) return numEGeomSmall;
            if (ruleId == 3) return numEConsecSquares;
            if (ruleId == 4) return numEConsecCubes;
            return numEOddEven;
          case Difficulty.medium:
            if (ruleId == 1) return numMGrowingDiff;
            if (ruleId == 2) return numMFibonacci;
            if (ruleId == 3) return numMMulAddSub;
            if (ruleId == 4) return numMSquareOffset;
            return numMPrimes;
          case Difficulty.hard:
            if (ruleId == 1) return numHInterleaved;
            if (ruleId == 2) return numHGrowingMul;
            if (ruleId == 3) return numHSquareCubeDiff;
            return numHAlternatingOps;
          default:
            return numEConstantDiff;
        }

      case Topic.approximation:
        final typeId = operands.isNotEmpty ? operands.last : 1;
        switch (difficulty) {
          case Difficulty.easy:
            return typeId == 1 ? approxEProduct : approxETwoOps;
          case Difficulty.medium:
            if (typeId == 1) return approxMPercent;
            if (typeId == 2) return approxMSquareRoot;
            return approxMThreeOps;
          case Difficulty.hard:
            return typeId == 1 ? approxHCompoundPercent : approxHPowersDiv;
          default:
            return approxEProduct;
        }

      case Topic.mixed:
        return 'default';
      case Topic.fractionReciprocals:
        switch (difficulty) {
          case Difficulty.easy: return frRecEUnit;
          case Difficulty.medium: return frRecMUnit;
          case Difficulty.hard: return frRecHUnit;
          default: return frRecEUnit;
        }
      case Topic.derivedFractions:
        switch (difficulty) {
          case Difficulty.easy: return frDerEMultiple;
          case Difficulty.medium: return frDerMMultiple;
          case Difficulty.hard: return frDerHMultiple;
          default: return frDerEMultiple;
        }
      case Topic.fractionPercentages:
        switch (difficulty) {
          case Difficulty.easy: return frPctESimple;
          case Difficulty.medium: return frPctMModerate;
          case Difficulty.hard: return frPctHComplex;
          default: return frPctESimple;
        }
      case Topic.basePercentages:
        switch (difficulty) {
          case Difficulty.easy: return basePctESimple;
          case Difficulty.medium: return basePctMModerate;
          case Difficulty.hard: return basePctHComplex;
          default: return basePctESimple;
        }
      case Topic.splitPercentages:
        switch (difficulty) {
          case Difficulty.easy: return splitPctEFive;
          case Difficulty.medium: return splitPctMDouble;
          case Difficulty.hard: return splitPctHNonRound;
          default: return splitPctEFive;
        }
      case Topic.powerOfFive:
        switch (difficulty) {
          case Difficulty.easy: return pow5ETimesFive;
          case Difficulty.medium: return pow5MTwentyFive;
          case Difficulty.hard: return pow5HOneTwentyFive;
          default: return pow5ETimesFive;
        }
      case Topic.patternMultiplication:
        switch (difficulty) {
          case Difficulty.easy: return patMulEEleven;
          case Difficulty.medium: return patMulMEleven;
          case Difficulty.hard: return patMulHNinetyNine;
          default: return patMulEEleven;
        }
      case Topic.linearEquations:
        switch (difficulty) {
          case Difficulty.easy: return linE1VarStep;
          case Difficulty.medium: return linM2VarSolve;
          case Difficulty.hard: return linH3VarElim;
          default: return linE1VarStep;
        }
      case Topic.quadraticEquations:
        switch (difficulty) {
          case Difficulty.easy: return quadERoots;
          case Difficulty.medium: return quadMCompare;
          case Difficulty.hard: return quadHCompare;
          default: return quadERoots;
        }
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
