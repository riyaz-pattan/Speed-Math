import 'dart:math';
import '../../core/enums/enums.dart';
import '../questions/pattern_constants.dart';
import 'pattern_skill.dart';

/// Pure Dart utility for selecting question patterns according to adaptive rules.
class PatternPicker {
  /// Selects a pattern for [topic] and [difficulty] using the 60/40 rule and diversity constraint.
  static String pickPattern({
    required Topic topic,
    required Difficulty difficulty,
    required bool focusWeakAreas,
    required Map<String, PatternSkill> patternSkills,
    required Random random,
    List<String>? recentPatterns,
  }) {
    final patterns = PatternConstants.patternsFor(topic, difficulty);
    if (patterns.isEmpty) return 'default';
    if (patterns.length == 1) return patterns.first;

    String chosenPattern;
    if (!focusWeakAreas) {
      // With focus OFF: patterns evenly
      chosenPattern = patterns[random.nextInt(patterns.length)];
    } else {
      final roll = random.nextDouble();
      if (roll < 0.60) {
        // 60% weighted by (1.05 - mastery) (patterns with no data count as 0.5)
        final weights = <double>[];
        for (final pat in patterns) {
          final key = '${topic.name}:${difficulty.name}:$pat';
          final skill = patternSkills[key];
          final mastery = (skill != null && skill.attemptsCount > 0)
              ? skill.mastery
              : 0.5;
          weights.add(max(0.05, 1.05 - mastery));
        }
        final totalWeight = weights.reduce((a, b) => a + b);
        var r = random.nextDouble() * totalWeight;
        int idx = 0;
        for (int i = 0; i < patterns.length; i++) {
          r -= weights[i];
          if (r <= 0) {
            idx = i;
            break;
          }
        }
        chosenPattern = patterns[idx];
      } else {
        // 40% pick evenly to keep variety
        chosenPattern = patterns[random.nextInt(patterns.length)];
      }
    }

    // Diversity constraint: Do not repeat the same pattern more than twice consecutively
    if (recentPatterns != null && recentPatterns.length >= 2) {
      final last2 = recentPatterns.sublist(recentPatterns.length - 2);
      if (last2.every((p) => p == chosenPattern)) {
        final others = patterns.where((p) => p != chosenPattern).toList();
        if (others.isNotEmpty) {
          chosenPattern = others[random.nextInt(others.length)];
        }
      }
    }

    // Diversity rule: In any 10 questions in a row there must be at least 2 different patterns
    if (recentPatterns != null && recentPatterns.length >= 9) {
      final last9 = recentPatterns.sublist(recentPatterns.length - 9);
      final firstPat = last9.first;
      final allSame = last9.every((p) => p == firstPat);
      if (allSame && chosenPattern == firstPat) {
        final others = patterns.where((p) => p != firstPat).toList();
        if (others.isNotEmpty) {
          chosenPattern = others[random.nextInt(others.length)];
        }
      }
    }

    return chosenPattern;
  }
}
