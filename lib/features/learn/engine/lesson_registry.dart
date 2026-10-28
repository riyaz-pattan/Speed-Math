// lib/features/learn/engine/lesson_registry.dart
import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';
import '../builders/add_in_parts_builder.dart';
import '../builders/division_builders.dart';
import '../builders/fraction_pct_friends_builder.dart';
import '../builders/multiplication_builder.dart';
import '../builders/multiply_by_11_builder.dart';
import '../builders/multiply_by_5_25_builder.dart';
import '../builders/multiply_by_99_builder.dart';
import '../builders/near_100_mult_builder.dart';
import '../builders/split_percentages_builder.dart';
import '../builders/squares_ending_5_builder.dart';
import '../builders/subtraction_builder.dart';
import 'lesson_block.dart';

/// Central registry for all Learn section lessons.
class LessonRegistry {
  LessonRegistry._();

  static final List<LessonMeta> all = [
    // ── Arithmetic Main Topics ─────────────────────────────────────────────
    LessonMeta(
      id: 'add_in_parts',
      title: 'Addition',
      category: 'Arithmetic',
      durationLabel: '1 min',
      relatedTopic: Topic.addition,
      icon: Icons.add_circle_outline_rounded,
      iconColor: const Color(0xFF10B981), // Emerald Green
      whyItWorks:
          'Breaking numbers into tens and ones lets you do two simple additions mentally instead of hard scratchpad additions.',
      commonMistake: 'Forgetting to add the ones part after adding the tens.',
      featuredOperands: const [42, 45],
      builder: AddInPartsBuilder.build,
      generateOperands: (rng) => [20 + rng.nextInt(60), 11 + rng.nextInt(69)],
    ),

    LessonMeta(
      id: 'subtract_in_parts',
      title: 'Subtraction',
      category: 'Arithmetic',
      durationLabel: '1 min',
      relatedTopic: Topic.subtraction,
      icon: Icons.remove_circle_outline_rounded,
      iconColor: const Color(0xFF0284C7), // Sky/Ocean Blue
      whyItWorks:
          'Left-to-right subtraction processes place values directly without scratchpad borrowing, solving deficits cleanly.',
      commonMistake:
          'Borrowing right-to-left mentally instead of taking the whole tens/hundreds difference and adjusting.',
      featuredOperands: const [83, 47],
      builder: SubtractionBuilder.build,
      generateOperands: (rng) {
        final a = 35 + rng.nextInt(60);
        final b = 12 + rng.nextInt(a - 20);
        return [a, b];
      },
    ),

    LessonMeta(
      id: 'multiplication_hub',
      title: 'Multiplication',
      category: 'Arithmetic',
      durationLabel: '7 techniques',
      relatedTopic: Topic.multiplication,
      icon: Icons.close_rounded,
      iconColor: const Color(0xFF7C3AED), // Royal Purple
      whyItWorks:
          'The Vertically & Crosswise (Criss-Cross) method calculates units, cross-products, and higher places directly into a single line, eliminating multi-line scratchpad additions.',
      commonMistake:
          'Forgetting to add the carry from the previous step to the cross-product sum.',
      featuredOperands: const [23, 42],
      builder: MultiplicationBuilder.build,
      generateOperands: (rng) => [15 + rng.nextInt(75), 12 + rng.nextInt(75)],
    ),

    LessonMeta(
      id: 'division_hub',
      title: 'Division',
      category: 'Arithmetic',
      durationLabel: 'Handbook & 5 shortcuts',
      relatedTopic: Topic.division,
      icon: Icons.safety_divider_rounded,
      iconColor: const Color(0xFFD97706), // Warm Amber
      whyItWorks:
          'Divisibility rules and multiplicative inversion convert difficult multi-digit divisions into fast mental multiplication and single-digit checks.',
      commonMistake:
          'Dividing by composite divisors directly without factoring them into single-digit chunks.',
      featuredOperands: const [340, 5],
      builder: DivideBy5And25Builder.build,
      generateOperands: (rng) => [340, 5],
    ),

    // ── Individual Multiplication Sub-Lessons ───────────────────────────────
    LessonMeta(
      id: 'multiply_2x2',
      title: '2-Digit Multiplication',
      category: 'Multiplication Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.multiplication,
      icon: Icons.close_rounded,
      iconColor: const Color(0xFF7C3AED),
      whyItWorks:
          'The Vertically & Crosswise (Criss-Cross) method calculates units, cross-products, and tens directly into a single line, eliminating multi-line scratchpad additions.',
      commonMistake:
          'Forgetting to add the carry from the previous step to the cross-product sum.',
      featuredOperands: const [23, 42],
      builder: MultiplicationBuilder.build,
      generateOperands: (rng) => [15 + rng.nextInt(75), 12 + rng.nextInt(75)],
    ),

    LessonMeta(
      id: 'multiply_3x2',
      title: '3×2 Digit Multiplication',
      category: 'Multiplication Sub',
      durationLabel: '2 min',
      relatedTopic: Topic.multiplication,
      icon: Icons.close_rounded,
      iconColor: const Color(0xFF7C3AED),
      whyItWorks:
          'Expanding the crosswise pattern to 4 stages allows multiplying any 3-digit by 2-digit number in a single row without zero-padding scratch lines.',
      commonMistake:
          'Mixing up the inner vertical digit and the outer diagonal digit during the hundreds step.',
      featuredOperands: const [312, 42],
      builder: MultiplicationBuilder.build,
      generateOperands: (rng) =>
          [110 + rng.nextInt(780), 12 + rng.nextInt(75)],
    ),

    LessonMeta(
      id: 'multiply_3x3',
      title: '3-Digit Multiplication',
      category: 'Multiplication Sub',
      durationLabel: '2 min',
      relatedTopic: Topic.multiplication,
      icon: Icons.close_rounded,
      iconColor: const Color(0xFF7C3AED),
      whyItWorks:
          'The 5-step star crosswise algorithm (1 → 2 → 3 → 2 → 1) computes 3-digit products directly by place values, holding carries in memory.',
      commonMistake:
          'Leaving out the middle vertical product in the 3-way star step.',
      featuredOperands: const [123, 321],
      builder: MultiplicationBuilder.build,
      generateOperands: (rng) =>
          [110 + rng.nextInt(780), 110 + rng.nextInt(780)],
    ),

    // ── Individual Division Sub-Lessons ─────────────────────────────────────
    LessonMeta(
      id: 'divide_by_5_25',
      title: 'Divide by 5, 25 & 125',
      category: 'Division Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.division,
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFFD97706),
      whyItWorks:
          '5 = 10÷2, 25 = 100÷4, and 125 = 1000÷8. Inverting to multiplication by 2, 4, or 8 and shifting the decimal point is instant mentally.',
      commonMistake:
          'Shifting the decimal point the wrong number of places or in the wrong direction.',
      featuredOperands: const [340, 5],
      builder: DivideBy5And25Builder.build,
      generateOperands: (rng) => [50 + rng.nextInt(900), 5],
    ),

    LessonMeta(
      id: 'divide_by_9_99',
      title: 'Division by 9 & 99',
      category: 'Division Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.division,
      icon: Icons.alt_route_rounded,
      iconColor: const Color(0xFFD97706),
      whyItWorks:
          'When dividing by 9, the quotient digits are simply the running sums of the dividend digits.',
      commonMistake:
          'Forgetting that the last running sum is the remainder, not part of the quotient.',
      featuredOperands: const [1214, 9],
      builder: DivideBy9And99Builder.build,
      generateOperands: (rng) => [100 + rng.nextInt(8900), 9],
    ),

    LessonMeta(
      id: 'factor_division',
      title: 'Factor Division',
      category: 'Division Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.division,
      icon: Icons.call_split_rounded,
      iconColor: const Color(0xFFD97706),
      whyItWorks:
          'Decomposing a composite 2-digit divisor into single-digit factors allows fast sequential division.',
      commonMistake:
          'Dividing by factors that do not multiply to the original divisor.',
      featuredOperands: const [1620, 45],
      builder: FactorDivisionBuilder.build,
      generateOperands: (rng) => [45 * (10 + rng.nextInt(40)), 45],
    ),

    LessonMeta(
      id: 'reciprocal_division',
      title: 'Reciprocal & Decimals',
      category: 'Division Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.division,
      icon: Icons.swap_horiz_rounded,
      iconColor: const Color(0xFFD97706),
      whyItWorks:
          'Dividing by decimals like 0.5, 0.25, and 2.5 is equivalent to multiplying by their whole number reciprocals 2, 4, and 0.4.',
      commonMistake:
          'Confusing dividing by 0.5 (which doubles) with dividing by 2 (which halves).',
      featuredOperands: const [140, 2],
      builder: ReciprocalDivisionBuilder.build,
      generateOperands: (rng) => [10 * (5 + rng.nextInt(35)), 2],
    ),

    LessonMeta(
      id: 'flag_division',
      title: 'Straight Division',
      category: 'Division Sub',
      durationLabel: '2 min',
      relatedTopic: Topic.division,
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFFD97706),
      whyItWorks:
          'The Dhvajanka (Flag) method breaks divisors into a 1-digit Base and a Flag digit for single-line straight division.',
      commonMistake:
          'Forgetting to subtract the Flag adjustment from the working dividend.',
      featuredOperands: const [4536, 54],
      builder: FlagDivisionBuilder.build,
      generateOperands: (rng) => [54 * (20 + rng.nextInt(80)), 54],
    ),

    // ── Mental Shortcuts (Multiplication Sub-Lessons) ──────────────────────
    LessonMeta(
      id: 'multiply_by_5_25',
      title: 'Multiply by 5, 25 & 125',
      category: 'Multiplication Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.powerOfFive,
      icon: Icons.flash_on_rounded,
      iconColor: const Color(0xFF7C3AED),
      whyItWorks:
          '5 = 10÷2, 25 = 100÷4, 75 = 100−25, and 125 = 1000÷8. Dividing then multiplying by round powers of 10 is much faster.',
      commonMistake:
          'Forgetting to multiply by 10, 100 or 1000 after dividing.',
      featuredOperands: const [48, 5],
      builder: MultiplyBy5And25Builder.build,
      generateOperands: (rng) {
        final mults = [5, 25, 75, 125];
        final mult = mults[rng.nextInt(mults.length)];
        return [4 * (3 + rng.nextInt(25)), mult];
      },
      variants: [
        LessonVariant(
          variantId: 'x5',
          displayName: '× 5',
          featuredOperands: const [48, 5],
          builder: MultiplyBy5And25Builder.buildX5,
          generateOperands: (rng) => [2 * (5 + rng.nextInt(45)), 5],
        ),
        LessonVariant(
          variantId: 'x25',
          displayName: '× 25',
          featuredOperands: const [48, 25],
          builder: MultiplyBy5And25Builder.buildX25,
          generateOperands: (rng) => [4 * (3 + rng.nextInt(25)), 25],
        ),
        LessonVariant(
          variantId: 'x75',
          displayName: '× 75',
          featuredOperands: const [32, 75],
          builder: MultiplyBy5And25Builder.buildX75,
          generateOperands: (rng) => [4 * (3 + rng.nextInt(20)), 75],
        ),
        LessonVariant(
          variantId: 'x125',
          displayName: '× 125',
          featuredOperands: const [24, 125],
          builder: MultiplyBy5And25Builder.buildX125,
          generateOperands: (rng) => [8 * (2 + rng.nextInt(15)), 125],
        ),
      ],
    ),

    LessonMeta(
      id: 'multiply_by_11',
      title: 'Multiply by 11',
      category: 'Multiplication Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.patternMultiplication,
      icon: Icons.add_link_rounded,
      iconColor: const Color(0xFF7C3AED),
      whyItWorks:
          '11 × n = 10n + n. The middle digit is the sum of the two outer digits.',
      commonMistake: 'Forgetting to carry when the digit sum is 10 or more.',
      featuredOperands: const [35],
      builder: MultiplyBy11Builder.build,
      generateOperands: (rng) => [10 + rng.nextInt(85)],
    ),

    LessonMeta(
      id: 'multiply_by_99',
      title: 'Multiply by 9, 99 & 999',
      category: 'Multiplication Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.patternMultiplication,
      icon: Icons.filter_9_plus_rounded,
      iconColor: const Color(0xFF7C3AED),
      whyItWorks:
          'n × (10^k − 1) = n × 10^k − n. Multiplying by 10, 100, or 1000 is instant; then subtract n.',
      commonMistake: 'Subtracting 1 instead of subtracting the original number n.',
      featuredOperands: const [47, 99],
      builder: MultiplyBy99Builder.build,
      generateOperands: (rng) {
        final mults = [9, 99, 999];
        final mult = mults[rng.nextInt(mults.length)];
        return [10 + rng.nextInt(90), mult];
      },
      variants: [
        LessonVariant(
          variantId: 'x9',
          displayName: '× 9',
          featuredOperands: const [47, 9],
          builder: MultiplyBy99Builder.buildX9,
          generateOperands: (rng) => [10 + rng.nextInt(90), 9],
        ),
        LessonVariant(
          variantId: 'x99',
          displayName: '× 99',
          featuredOperands: const [47, 99],
          builder: MultiplyBy99Builder.buildX99,
          generateOperands: (rng) => [10 + rng.nextInt(90), 99],
        ),
        LessonVariant(
          variantId: 'x999',
          displayName: '× 999',
          featuredOperands: const [47, 999],
          builder: MultiplyBy99Builder.buildX999,
          generateOperands: (rng) => [10 + rng.nextInt(90), 999],
        ),
      ],
    ),

    LessonMeta(
      id: 'near_100_mult',
      title: 'Near-100 Multiplication',
      category: 'Multiplication Sub',
      durationLabel: '2 min',
      icon: Icons.radar_rounded,
      iconColor: const Color(0xFF7C3AED),
      whyItWorks:
          'Both numbers are near 100, so their gaps are small and easy to multiply.',
      commonMistake:
          'Forgetting to zero-pad the right part when the gap product is less than 10.',
      featuredOperands: const [97, 94],
      builder: Near100MultBuilder.build,
      generateOperands: (rng) => [91 + rng.nextInt(9), 91 + rng.nextInt(9)],
    ),

    // ── Powers & Roots Hub ──────────────────────────────────────────────────
    LessonMeta(
      id: 'squares_hub',
      title: 'Squares',
      category: 'Powers & Roots',
      durationLabel: '6 shortcuts',
      relatedTopic: Topic.squares,
      icon: Icons.superscript_rounded,
      iconColor: const Color(0xFFEA580C),
      whyItWorks:
          'The Base Method and Vedic Ekadhikena reduce multi-digit squaring to single-step additions and small deviation products.',
      commonMistake:
          'Forgetting to pad deviation squares to 2 digits or carrying over when d² ≥ 100.',
      featuredOperands: const [35],
      builder: SquaresEnding5Builder.build,
      generateOperands: (rng) => [35],
    ),

    // ── Individual Squaring Sub-Lessons ─────────────────────────────────────
    LessonMeta(
      id: 'squares_ending_5',
      title: 'Squares Ending in 5',
      category: 'Squares Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.squares,
      icon: Icons.star_outline_rounded,
      iconColor: const Color(0xFFEA580C),
      whyItWorks:
          'Any number ending in 5 squares to 100×k(k+1)+25 — always ending in 25!',
      commonMistake:
          'Using the wrong leading digit — use the part before the 5.',
      featuredOperands: const [35],
      builder: SquaresEnding5Builder.build,
      generateOperands: (rng) {
        const bases = [15, 25, 35, 45, 55, 65, 75, 85, 95];
        return [bases[rng.nextInt(bases.length)]];
      },
    ),

    LessonMeta(
      id: 'squares_base_25',
      title: 'Base 25 Squares',
      category: 'Squares Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.squares,
      icon: Icons.filter_2_rounded,
      iconColor: const Color(0xFFEA580C),
      whyItWorks:
          'Expanding (25 + d)² = 625 + 50d + d² reduces mental squaring to adding multiples of 50.',
      commonMistake: 'Subtracting instead of adding when deviation is positive.',
      featuredOperands: const [24],
      builder: SquaresEnding5Builder.build,
      generateOperands: (rng) => [21 + rng.nextInt(9)],
    ),

    LessonMeta(
      id: 'squares_base_50',
      title: 'Base 50 Squares',
      category: 'Squares Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.squares,
      icon: Icons.filter_5_rounded,
      iconColor: const Color(0xFFEA580C),
      whyItWorks:
          'Since (50 + d)² = 100(25 + d) + d², the left part is simply 25 ± d.',
      commonMistake: 'Adding d to 50 instead of 25 for the left part.',
      featuredOperands: const [46],
      builder: SquaresEnding5Builder.build,
      generateOperands: (rng) => [41 + rng.nextInt(18)],
    ),

    LessonMeta(
      id: 'squares_base_100',
      title: 'Base 100 Squares',
      category: 'Squares Sub',
      durationLabel: '1 min',
      relatedTopic: Topic.squares,
      icon: Icons.filter_9_plus_rounded,
      iconColor: const Color(0xFFEA580C),
      whyItWorks:
          'Since (100 + d)² = 100(N + d) + d², adding the deviation to N gives the left part.',
      commonMistake: 'Forgetting to zero-pad the right part when d² < 10.',
      featuredOperands: const [96],
      builder: SquaresEnding5Builder.build,
      generateOperands: (rng) => [91 + rng.nextInt(18)],
    ),

    LessonMeta(
      id: 'squares_base_150',
      title: 'Base 150 Squares',
      category: 'Squares Sub',
      durationLabel: '2 min',
      relatedTopic: Topic.squares,
      icon: Icons.looks_one_rounded,
      iconColor: const Color(0xFFEA580C),
      whyItWorks:
          'Base 150 is 1.5× base 100. Adding half of (N + d) scales the left part easily.',
      commonMistake: 'Forgetting to multiply (N + d) by 1.5.',
      featuredOperands: const [146],
      builder: SquaresEnding5Builder.build,
      generateOperands: (rng) => [141 + rng.nextInt(18)],
    ),

    LessonMeta(
      id: 'squares_base_200',
      title: 'Base 200 Squares',
      category: 'Squares Sub',
      durationLabel: '2 min',
      relatedTopic: Topic.squares,
      icon: Icons.looks_two_rounded,
      iconColor: const Color(0xFFEA580C),
      whyItWorks:
          'Base 200 is 2× base 100. Doubling (N + d) gives the exact left part.',
      commonMistake: 'Forgetting to double (N + d) before joining with d².',
      featuredOperands: const [196],
      builder: SquaresEnding5Builder.build,
      generateOperands: (rng) => [191 + rng.nextInt(18)],
    ),

    // ── Applied Maths ───────────────────────────────────────────────────────
    LessonMeta(
      id: 'split_percentages',
      title: 'Split Percentages',
      category: 'Applied Maths',
      durationLabel: '1 min',
      relatedTopic: Topic.splitPercentages,
      icon: Icons.percent_rounded,
      iconColor: const Color(0xFF8B5CF6),
      whyItWorks:
          'Any percentage can be split into 50%, 25%, 10%, 5%, and 1% benchmarks — eliminating slow decimal multiplication.',
      commonMistake:
          'Adding parts incorrectly, or subtracting the wrong deficit from the 50% or 100% anchor.',
      featuredOperands: const [15, 240],
      builder: SplitPercentagesBuilder.build,
      generateOperands: (rng) {
        const pcts = [15, 25, 35, 45, 48, 55, 65, 75, 85, 95, 99];
        const ns = [120, 160, 200, 240, 250, 280, 320, 360, 400, 420, 480, 500, 600, 640, 720, 800];
        return [pcts[rng.nextInt(pcts.length)], ns[rng.nextInt(ns.length)]];
      },
    ),

    LessonMeta(
      id: 'fraction_pct_friends',
      title: 'Fraction to Percentage',
      category: 'Applied Maths',
      durationLabel: '2 min',
      relatedTopic: Topic.fractionReciprocals,
      icon: Icons.swap_horiz_rounded,
      iconColor: const Color(0xFF8B5CF6),
      whyItWorks:
          'Knowing key fraction ↔ percentage conversions by heart cuts computation time to zero.',
      commonMistake: 'Confusing 1/6 (≈16.67%) with 1/8 (12.5%) or 1/7 (14.28%).',
      featuredOperands: const [3, 8],
      builder: FractionPctFriendsBuilder.build,
      generateOperands: (rng) {
        const pool = [
          [1, 2], [1, 3], [2, 3], [1, 4], [3, 4],
          [1, 5], [2, 5], [3, 5], [4, 5],
          [1, 6], [5, 6],
          [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7],
          [1, 8], [3, 8], [5, 8], [7, 8],
          [1, 9], [2, 9], [4, 9], [5, 9], [7, 9], [8, 9],
          [1, 11], [2, 11], [3, 11], [4, 11], [5, 11],
          [1, 12], [5, 12], [7, 12], [11, 12],
          [1, 16], [3, 16], [5, 16], [7, 16],
        ];
        return pool[rng.nextInt(pool.length)];
      },
    ),

    LessonMeta(
      id: 'percentage_to_fraction',
      title: 'Percentage to Fraction',
      category: 'Applied Maths',
      durationLabel: '2 min',
      relatedTopic: Topic.fractionReciprocals,
      icon: Icons.sync_alt_rounded,
      iconColor: const Color(0xFF8B5CF6),
      whyItWorks:
          'Replacing decimal percentages with simplest fractions turns complex multiplications into instant single-digit divisions.',
      commonMistake:
          'Forgetting the base unit family (e.g. confusing 37.5% from 1/8 with 1/6 or 1/7).',
      featuredOperands: const [3750, 640],
      builder: FractionPctFriendsBuilder.build,
      generateOperands: (rng) {
        const pool = [
          [3750, 640],
          [6250, 480],
          [8750, 560],
          [1250, 720],
          [1667, 726],
          [8333, 360],
          [3333, 450],
          [6667, 270],
          [1428, 490],
          [2857, 350],
          [4444, 270],
          [1111, 630],
          [909, 330],
          [833, 288],
          [625, 640],
          [1875, 480],
          [25, 440],
          [75, 520],
        ];
        return pool[rng.nextInt(pool.length)];
      },
    ),

    // ── Algebra & Equations Hub ───────────────────────────────────────────
    LessonMeta(
      id: 'quadratic_hub',
      title: 'Quadratic & Linear Equations',
      category: 'Algebra & Equations',
      durationLabel: 'Handbook & Sign Tricks',
      relatedTopic: Topic.quadraticEquations,
      icon: Icons.functions_rounded,
      iconColor: const Color(0xFF6366F1), // Indigo
      whyItWorks:
          'Sign table analysis and the 2-second CND rule let you determine root relations and signs without full factorization.',
      commonMistake:
          'Confusing x² = 16 (±4) with y = √16 (+4), or dividing by leading coefficients instead of cross-multiplying.',
      featuredOperands: const [1, -5, 6],
      builder: AddInPartsBuilder.build,
      generateOperands: (rng) => [1, -5, 6],
    ),
  ];

  /// Returns lessons in the given category.
  static List<LessonMeta> forCategory(String category) =>
      all.where((l) => l.category == category).toList();

  /// Finds a lesson by ID, or null.
  static LessonMeta? findById(String id) {
    for (final l in all) {
      if (l.id == id) return l;
    }
    if (id == 'multiply_by_9_99_999') {
      return findById('multiply_by_99');
    }
    return null;
  }

  /// Returns lessons linked to the given topic.
  static List<LessonMeta> forTopic(Topic topic) =>
      all.where((l) => l.relatedTopic == topic).toList();

  /// Distinct categories in display order.
  static const List<String> categories = [
    'Arithmetic',
    'Powers & Roots',
    'Applied Maths',
    'Algebra & Equations',
  ];

  /// Matches a question's topic, operands, and optional pattern to the most relevant Learn trick.
  static ({LessonMeta lesson, List<int> operands, String? variantId})? findLessonForQuestion({
    required Topic topic,
    required List<int> operands,
    String pattern = '',
  }) {
    switch (topic) {
      case Topic.addition:
        final l = findById('add_in_parts');
        if (l != null) return (lesson: l, operands: operands, variantId: null);
        break;

      case Topic.subtraction:
        final l = findById('subtract_in_parts');
        if (l != null) return (lesson: l, operands: operands, variantId: null);
        break;

      case Topic.multiplication:
      case Topic.patternMultiplication:
      case Topic.powerOfFive:
        if (operands.length >= 2) {
          final a = operands[0];
          final b = operands[1];
          if (a == 11 || b == 11 || pattern.contains('eleven')) {
            final l = findById('multiply_by_11');
            if (l != null) return (lesson: l, operands: [a == 11 ? b : a, 11], variantId: null);
          }
          if (b == 5 || a == 5 || b == 25 || a == 25 || b == 125 || a == 125 || topic == Topic.powerOfFive) {
            final l = findById('multiply_by_5_25');
            final mult = (b == 5 || b == 25 || b == 125) ? b : ((a == 5 || a == 25 || a == 125) ? a : 5);
            final n = (mult == b) ? a : b;
            if (l != null) return (lesson: l, operands: [n, mult], variantId: 'x$mult');
          }
          if (b == 9 || a == 9 || b == 99 || a == 99 || b == 999 || a == 999 || pattern.contains('ninetynine')) {
            final l = findById('multiply_by_99');
            final mult = (b == 9 || b == 99 || b == 999) ? b : ((a == 9 || a == 99 || a == 999) ? a : 99);
            final n = (mult == b) ? a : b;
            if (l != null) return (lesson: l, operands: [n, mult], variantId: 'x$mult');
          }
          if (a >= 88 && a <= 112 && b >= 88 && b <= 112) {
            final l = findById('near_100_mult');
            if (l != null) return (lesson: l, operands: [a, b], variantId: null);
          }
          final lenA = '$a'.length;
          final lenB = '$b'.length;
          if (lenA >= 3 && lenB >= 3) {
            final l = findById('multiply_3x3');
            if (l != null) return (lesson: l, operands: [a, b], variantId: null);
          } else if ((lenA >= 3 && lenB >= 2) || (lenA >= 2 && lenB >= 3)) {
            final l = findById('multiply_3x2');
            if (l != null) return (lesson: l, operands: [a, b], variantId: null);
          } else {
            final l = findById('multiply_2x2');
            if (l != null) return (lesson: l, operands: [a, b], variantId: null);
          }
        }
        break;

      case Topic.division:
        if (operands.length >= 2) {
          final div = operands[1];
          if (div == 5 || div == 25) {
            final l = findById('divide_by_5_25');
            if (l != null) return (lesson: l, operands: operands, variantId: 'd$div');
          } else if (div == 9 || div == 99) {
            final l = findById('divide_by_9_99');
            if (l != null) return (lesson: l, operands: operands, variantId: 'd$div');
          } else if (div > 3 && (div % 2 == 0 || div % 3 == 0 || div % 5 == 0)) {
            final l = findById('factor_division');
            if (l != null) return (lesson: l, operands: operands, variantId: null);
          } else {
            final l = findById('divide_by_5_25');
            if (l != null) return (lesson: l, operands: operands, variantId: null);
          }
        }
        break;

      case Topic.squares:
        if (operands.isNotEmpty) {
          final n = operands[0];
          // 1. Ending in 5 (e.g. 15, 25, 35, 45, 65...)
          if (n % 10 == 5) {
            final l = findById('squares_ending_5');
            if (l != null) return (lesson: l, operands: [n], variantId: null);
          }
          // 2. Base 50 deviation (31 to 69, including 36!)
          else if (n >= 31 && n <= 69) {
            final l = findById('squares_base_50');
            if (l != null) return (lesson: l, operands: [n], variantId: null);
          }
          // 3. Base 100 deviation (70 to 129)
          else if (n >= 70 && n <= 129) {
            final l = findById('squares_base_100');
            if (l != null) return (lesson: l, operands: [n], variantId: null);
          }
          // 4. Base 150 deviation (130 to 174)
          else if (n >= 130 && n <= 174) {
            final l = findById('squares_base_150');
            if (l != null) return (lesson: l, operands: [n], variantId: null);
          }
          // 5. Base 200 deviation (175 to 225)
          else if (n >= 175 && n <= 225) {
            final l = findById('squares_base_200');
            if (l != null) return (lesson: l, operands: [n], variantId: null);
          }
          // 6. Base 25 deviation (21 to 30)
          else if (n >= 21 && n <= 30) {
            final l = findById('squares_base_25');
            if (l != null) return (lesson: l, operands: [n], variantId: null);
          }
          // 7. General two-digit squaring via Criss-Cross 2x2 multiplication (n x n)
          else if (n >= 10 && n <= 99) {
            final l = findById('multiply_2x2');
            if (l != null) return (lesson: l, operands: [n, n], variantId: null);
          }
          // 8. General three-digit squaring via 3x3 multiplication (n x n)
          else if (n >= 100 && n <= 999) {
            final l = findById('multiply_3x3');
            if (l != null) return (lesson: l, operands: [n, n], variantId: null);
          }
        }
        break;

      case Topic.splitPercentages:
      case Topic.percentages:
      case Topic.basePercentages:
        final l = findById('split_percentages');
        if (l != null) return (lesson: l, operands: operands, variantId: null);
        break;

      case Topic.fractionPercentages:
      case Topic.fractionReciprocals:
      case Topic.derivedFractions:
      case Topic.fractions:
        final l = findById('fraction_pct_friends');
        if (l != null) return (lesson: l, operands: operands, variantId: null);
        break;

      case Topic.quadraticEquations:
      case Topic.linearEquations:
        final l = findById('quadratic_hub');
        if (l != null) return (lesson: l, operands: operands, variantId: null);
        break;

      default:
        final lessons = forTopic(topic);
        if (lessons.isNotEmpty) {
          return (lesson: lessons.first, operands: operands, variantId: null);
        }
        break;
    }
    return null;
  }
}
