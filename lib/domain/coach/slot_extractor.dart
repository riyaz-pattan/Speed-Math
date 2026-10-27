import '../../core/enums/enums.dart';
import 'coach_slots.dart';

/// Pure Dart entity responsible for parsing semantic parameters (slots)
/// from a normalized user query.
abstract final class SlotExtractor {
  SlotExtractor._();

  static const List<int> _allowedQuestionCounts = [10, 20, 30, 50];
  static const List<int> _allowedMinutes = [1, 2, 3, 5, 10];

  /// Extracts structured slots from [normalizedText].
  static CoachSlots extract(String normalizedText) {
    if (normalizedText.isEmpty) return const CoachSlots();

    final topic = _extractTopic(normalizedText);
    final difficulty = _extractDifficulty(normalizedText);
    final minutes = _extractMinutes(normalizedText);
    final questionCount = _extractQuestionCount(normalizedText, hasMinutes: minutes != null);
    final timeWord = _extractTimeWord(normalizedText);

    return CoachSlots(
      topic: topic,
      difficulty: difficulty,
      questionCount: questionCount,
      minutes: minutes,
      timeWord: timeWord,
    );
  }

  static Topic? _extractTopic(String text) {
    // Multi-word topics first
    if (text.contains('square roots') || text.contains('square root')) {
      return Topic.squareRoots;
    }
    if (text.contains('cube roots') || text.contains('cube root')) {
      return Topic.cubeRoots;
    }
    if (text.contains('missing number') || text.contains('missing numbers')) {
      return Topic.missingNumber;
    }
    if (text.contains('number series') ||
        text.contains('number pattern') ||
        text.contains('number patterns') ||
        text.contains('next number')) {
      return Topic.numberSeries;
    }
    if (text.contains('linear equation') ||
        text.contains('linear equations') ||
        text.contains('linear')) {
      return Topic.linearEquations;
    }
    if (text.contains('quadratic equation') ||
        text.contains('quadratic equations') ||
        text.contains('quadratic') ||
        text.contains('quadratics')) {
      return Topic.quadraticEquations;
    }

    final words = text.split(' ');
    for (final word in words) {
      switch (word) {
        case 'addition':
          return Topic.addition;
        case 'subtraction':
          return Topic.subtraction;
        case 'multiplication':
          return Topic.multiplication;
        case 'division':
          return Topic.division;
        case 'squares':
          return Topic.squares;
        case 'cubes':
          return Topic.cubes;
        case 'exponents':
          return Topic.exponents;
        case 'percentages':
        case 'percentage':
        case 'percent':
          return Topic.percentages;
        case 'fractions':
        case 'fraction':
          return Topic.fractions;
        case 'simplification':
        case 'simplifications':
        case 'simplify':
        case 'bodmas':
          return Topic.simplification;
        case 'averages':
        case 'average':
          if (text.contains('average speed') ||
              text.contains('average time') ||
              text.contains('avg speed') ||
              text.contains('avg time')) {
            break;
          }
          return Topic.averages;
        case 'missing':
        case 'unknown':
          return Topic.missingNumber;
        case 'series':
        case 'sequence':
        case 'progression':
          return Topic.numberSeries;
        case 'approximation':
        case 'approx':
        case 'estimate':
        case 'estimation':
          return Topic.approximation;
      }
    }
    return null;
  }

  static Difficulty? _extractDifficulty(String text) {
    final words = text.split(' ');
    for (final word in words) {
      switch (word) {
        case 'easy':
        case 'simple':
        case 'basic':
          return Difficulty.easy;
        case 'medium':
        case 'normal':
        case 'moderate':
          return Difficulty.medium;
        case 'hard':
        case 'tough':
        case 'difficult':
        case 'advanced':
          return Difficulty.hard;
      }
    }
    return null;
  }

  static int? _extractMinutes(String text) {
    final minMatch = RegExp(r'(\d+)\s*(?:minutes|minute)\b').firstMatch(text);
    if (minMatch != null) {
      final parsed = int.tryParse(minMatch.group(1) ?? '');
      if (parsed != null) return _snapTo(parsed, _allowedMinutes);
    }
    return null;
  }

  static int? _extractQuestionCount(String text, {required bool hasMinutes}) {
    final qMatch = RegExp(r'(\d+)\s*(?:questions|question)\b').firstMatch(text);
    if (qMatch != null) {
      final parsed = int.tryParse(qMatch.group(1) ?? '');
      if (parsed != null) return _snapTo(parsed, _allowedQuestionCounts);
    }

    // If query has no minutes, check for standalone numbers (e.g. "practice squares 20")
    if (!hasMinutes) {
      final numMatches = RegExp(r'\b(\d+)\b').allMatches(text);
      for (final match in numMatches) {
        final parsed = int.tryParse(match.group(1) ?? '');
        if (parsed != null && parsed >= 5 && parsed <= 100) {
          return _snapTo(parsed, _allowedQuestionCounts);
        }
      }
    }

    return null;
  }

  static String? _extractTimeWord(String text) {
    if (text.contains('this week')) return 'this_week';
    if (text.contains('last week') || text.contains('past week')) return 'last_week';
    if (text.contains('today')) return 'today';
    return null;
  }

  static int _snapTo(int value, List<int> options) {
    int closest = options.first;
    int minDiff = (value - closest).abs();
    for (final opt in options) {
      final diff = (value - opt).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = opt;
      }
    }
    return closest;
  }
}
