import '../../core/enums/enums.dart';
import '../questions/pattern_constants.dart';
import 'pattern_skill.dart';

/// Helper to generate grounded natural language insights about user's weakest patterns.
class PatternWeaknessHelper {
  /// Analyzes [patternSkills] for [topic] and [difficulty].
  ///
  /// Returns a friendly, truthful sentence comparing the weakest pattern to other
  /// patterns if and only if the weakest pattern has at least 8 attempts.
  /// Returns null if no pattern has >= 8 attempts.
  static String? findWeakestPatternInsight({
    required Topic topic,
    required Difficulty difficulty,
    required List<PatternSkill> patternSkills,
  }) {
    // 1. Filter patterns belonging to this topic and difficulty with >= 8 attempts
    final candidates = patternSkills.where((p) =>
        p.topic == topic &&
        p.difficulty == difficulty &&
        p.attemptsCount >= 8).toList();

    if (candidates.isEmpty) return null;

    // 2. Find weakest pattern (lowest mastery, tie-breaker: highest avgTimeMsEma)
    candidates.sort((a, b) {
      final cmp = a.mastery.compareTo(b.mastery);
      if (cmp != 0) return cmp;
      return b.avgTimeMsEma.compareTo(a.avgTimeMsEma);
    });

    final weakest = candidates.first;
    final weakLabel = PatternConstants.labelFor(weakest.pattern);

    // 3. Find other patterns in this topic+difficulty that have been attempted
    final others = patternSkills.where((p) =>
        p.topic == topic &&
        p.difficulty == difficulty &&
        p.pattern != weakest.pattern &&
        p.attemptsCount > 0).toList();

    final wSec = (weakest.avgTimeMsEma / 1000).toStringAsFixed(1);
    final wAcc = (weakest.accuracyEma * 100).round();

    if (others.isNotEmpty) {
      final othersWithTime = others.where((p) => p.avgTimeMsEma > 0).toList();
      if (othersWithTime.isNotEmpty && weakest.avgTimeMsEma > 0) {
        final avgOtherTimeMs = othersWithTime.map((p) => p.avgTimeMsEma).reduce((a, b) => a + b) / othersWithTime.length;
        final oSec = (avgOtherTimeMs / 1000).toStringAsFixed(1);

        if (weakest.avgTimeMsEma >= 1.8 * avgOtherTimeMs) {
          return '$weakLabel takes an average of $wSec s, twice as slow as other ${topic.displayName.toLowerCase()} questions.';
        } else if (othersWithTime.length == 1) {
          final otherLabel = PatternConstants.labelFor(othersWithTime.first.pattern);
          return '$weakLabel questions take you $wSec s vs $oSec s for $otherLabel.';
        } else {
          return '$weakLabel questions take you $wSec s vs $oSec s on average for other types.';
        }
      }

      final othersWithAcc = others.where((p) => p.attemptsCount >= 3).toList();
      if (othersWithAcc.isNotEmpty) {
        final avgOtherAcc = ((othersWithAcc.map((p) => p.accuracyEma).reduce((a, b) => a + b) / othersWithAcc.length) * 100).round();
        if (avgOtherAcc - wAcc >= 12) {
          return '$weakLabel accuracy is $wAcc% vs $avgOtherAcc% on other types.';
        }
      }
    }

    // Fallback if no other patterns to compare against
    if (weakest.avgTimeMsEma > 0) {
      return '$weakLabel takes an average of $wSec s ($wAcc% accuracy).';
    }
    return '$weakLabel has an accuracy of $wAcc% across ${weakest.attemptsCount} attempts.';
  }
}
