// lib/features/learn/engine/lesson_registry.dart
import 'package:flutter/material.dart';
import '../../../core/enums/enums.dart';
import 'lesson_data.dart';
import '../builders/add_in_parts_builder.dart';
import '../builders/multiply_by_5_25_builder.dart';
import '../builders/multiply_by_11_builder.dart';
import '../builders/multiply_by_99_builder.dart';
import '../builders/near_100_mult_builder.dart';
import '../builders/squares_ending_5_builder.dart';
import '../builders/split_percentages_builder.dart';
import '../builders/fraction_pct_friends_builder.dart';

/// Central registry for all Learn section lessons.
class LessonRegistry {
  LessonRegistry._();

  static final List<LessonMeta> all = [
    // ── Arithmetic ──────────────────────────────────────────────────────────
    LessonMeta(
      id: 'add_in_parts',
      title: 'Add in Parts',
      category: 'Arithmetic',
      durationLabel: '1 min',
      relatedTopic: Topic.addition,
      icon: Icons.add_circle_outline_rounded,
      whyItWorks:
          'Breaking a number into tens and ones lets you do two simple additions instead of one hard one.',
      commonMistake: 'Forgetting to add the ones part after adding the tens.',
      featuredOperands: const [47, 38],
      featuredBuilder: AddInPartsBuilder.build,
      generateOperands: (rng) => [20 + rng.nextInt(60), 11 + rng.nextInt(69)],
    ),

    // ── Mental Shortcuts ────────────────────────────────────────────────────
    LessonMeta(
      id: 'multiply_by_5_25',
      title: 'Multiply by 5 & 25',
      category: 'Mental Shortcuts',
      durationLabel: '1 min',
      relatedTopic: Topic.powerOfFive,
      icon: Icons.close_rounded,
      whyItWorks: '5 = 10÷2 and 25 = 100÷4. Dividing first then multiplying by a round number is faster.',
      commonMistake: 'Forgetting to multiply by 10 (or 100) after dividing.',
      featuredOperands: const [48, 5],
      featuredBuilder: MultiplyBy5And25Builder.build,
      generateOperands: (rng) {
        final useQ = rng.nextBool();
        final mult = useQ ? 25 : 5;
        final n = useQ ? (4 * (2 + rng.nextInt(20))) : (2 * (5 + rng.nextInt(40)));
        return [n, mult];
      },
    ),

    LessonMeta(
      id: 'multiply_by_11',
      title: 'Multiply by 11',
      category: 'Mental Shortcuts',
      durationLabel: '1 min',
      relatedTopic: Topic.patternMultiplication,
      icon: Icons.close_rounded,
      whyItWorks:
          '11 × n = 10n + n. The middle digit is the sum of the two outer digits.',
      commonMistake: 'Forgetting to carry when the digit sum is 10 or more.',
      featuredOperands: const [35],
      featuredBuilder: MultiplyBy11Builder.build,
      generateOperands: (rng) => [10 + rng.nextInt(80)],
    ),

    LessonMeta(
      id: 'multiply_by_99',
      title: 'Multiply by 99',
      category: 'Mental Shortcuts',
      durationLabel: '1 min',
      relatedTopic: Topic.patternMultiplication,
      icon: Icons.close_rounded,
      whyItWorks: 'n × 99 = n × 100 − n. Multiplying by 100 is instant; subtracting n is easy.',
      commonMistake: 'Subtracting the wrong number — subtract n, not 1.',
      featuredOperands: const [47],
      featuredBuilder: MultiplyBy99Builder.build,
      generateOperands: (rng) => [10 + rng.nextInt(90)],
    ),

    LessonMeta(
      id: 'near_100_mult',
      title: 'Near-100 Multiplication',
      category: 'Mental Shortcuts',
      durationLabel: '2 min',
      icon: Icons.close_rounded,
      whyItWorks:
          'Both numbers are near 100, so their gaps are small and easy to multiply.',
      commonMistake:
          'Forgetting to zero-pad the right part when the gap product is less than 10.',
      featuredOperands: const [97, 94],
      featuredBuilder: Near100MultBuilder.build,
      generateOperands: (rng) => [91 + rng.nextInt(9), 91 + rng.nextInt(9)],
    ),

    // ── Powers & Roots ──────────────────────────────────────────────────────
    LessonMeta(
      id: 'squares_ending_5',
      title: 'Squares Ending in 5',
      category: 'Powers & Roots',
      durationLabel: '1 min',
      relatedTopic: Topic.squares,
      icon: Icons.star_outline_rounded,
      whyItWorks:
          'Any number ending in 5 squares to 100×k(k+1)+25 — always ending in 25!',
      commonMistake:
          'Using the wrong leading digit — use the part before the 5.',
      featuredOperands: const [35],
      featuredBuilder: SquaresEnding5Builder.build,
      generateOperands: (rng) {
        const bases = [15, 25, 35, 45, 55, 65, 75, 85, 95];
        return [bases[rng.nextInt(bases.length)]];
      },
    ),

    // ── Applied Maths ───────────────────────────────────────────────────────
    LessonMeta(
      id: 'split_percentages',
      title: 'Split Percentages',
      category: 'Applied Maths',
      durationLabel: '1 min',
      relatedTopic: Topic.splitPercentages,
      icon: Icons.percent_rounded,
      whyItWorks:
          'Any percentage can be split into 10%, 5%, and 1% chunks — all easy to compute.',
      commonMistake:
          'Adding parts incorrectly, or miscounting how many 10% chunks fit.',
      featuredOperands: const [15, 240],
      featuredBuilder: SplitPercentagesBuilder.build,
      generateOperands: (rng) {
        const pcts = [5, 10, 15, 20, 25, 30];
        const ns = [120, 160, 200, 240, 280, 300, 320, 360, 400, 480];
        return [pcts[rng.nextInt(pcts.length)], ns[rng.nextInt(ns.length)]];
      },
    ),

    LessonMeta(
      id: 'fraction_pct_friends',
      title: 'Fraction–% Friends',
      category: 'Applied Maths',
      durationLabel: '2 min',
      relatedTopic: Topic.fractionReciprocals,
      icon: Icons.swap_horiz_rounded,
      whyItWorks:
          'Knowing key fraction ↔ % pairs by heart cuts computation time to zero.',
      commonMistake: 'Confusing 1/6 (≈16.7%) with 1/8 (12.5%).',
      featuredOperands: const [3], // index 3 → 1/8 = 12.5%
      featuredBuilder: FractionPctFriendsBuilder.build,
      generateOperands: (rng) => [rng.nextInt(13)],
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
    return null;
  }

  /// Returns lessons linked to the given topic.
  static List<LessonMeta> forTopic(Topic topic) =>
      all.where((l) => l.relatedTopic == topic).toList();

  /// Distinct categories in display order.
  static const List<String> categories = [
    'Arithmetic',
    'Mental Shortcuts',
    'Powers & Roots',
    'Applied Maths',
  ];
}
