import 'dart:convert';
import 'dart:math' as math;
import 'coach_constants.dart';
import 'coach_intent.dart';
import 'coach_slots.dart';
import 'slot_extractor.dart';
import 'text_normalizer.dart';

/// Result produced by an [IntentClassifier].
class IntentClassificationResult {
  final CoachIntent intent;
  final double confidence;
  final CoachSlots slots;
  final String rawMessage;
  final String normalizedMessage;

  const IntentClassificationResult({
    required this.intent,
    required this.confidence,
    required this.slots,
    required this.rawMessage,
    required this.normalizedMessage,
  });

  @override
  String toString() =>
      'IntentClassificationResult(intent: ${intent.name}, confidence: ${confidence.toStringAsFixed(2)}, slots: $slots)';
}

/// Abstract contract for intent classification.
/// Allows swapping pure Dart n-gram engine with TFLite or other models in future phases.
abstract interface class IntentClassifier {
  Future<void> initialize({
    String? jsonString,
    Future<String> Function(String path)? assetLoader,
  });
  Future<IntentClassificationResult> classify(
    String rawMessage, {
    CoachIntent? previousIntent,
  });
}

/// Internal pre-indexed example phrase representation for fast vector math.
class _IndexedExample {
  final CoachIntent intent;
  final String normalizedText;
  final Set<String> words;
  final Map<String, double> wordTfIdf;
  final double wordVectorNorm;
  final Set<String> char3grams;

  _IndexedExample({
    required this.intent,
    required this.normalizedText,
    required this.words,
    required this.wordTfIdf,
    required this.wordVectorNorm,
    required this.char3grams,
  });
}

/// Pure Dart intent classifier utilizing character 3-grams and word TF-IDF cosine similarity.
///
/// Features:
/// - Sub-15 ms latency on mobile hardware.
/// - Robust typo tolerance and short-form handling.
/// - Contextual follow-up slot carryover.
/// - Memory-efficient precomputed index loaded once from assets.
class NgramIntentClassifier implements IntentClassifier {
  bool _initialized = false;
  final List<_IndexedExample> _examples = [];
  final Map<String, double> _idfMap = {};

  bool get isInitialized => _initialized;

  @override
  Future<void> initialize({
    String? jsonString,
    Future<String> Function(String path)? assetLoader,
  }) async {
    if (_initialized && jsonString == null && assetLoader == null) return;

    final String content;
    if (jsonString != null) {
      content = jsonString;
    } else if (assetLoader != null) {
      content = await assetLoader('assets/coach/intents.json');
    } else {
      throw StateError('Either jsonString or assetLoader must be provided');
    }

    final Map<String, dynamic> rawMap = jsonDecode(content) as Map<String, dynamic>;

    // 1. Collect all phrases and document frequencies
    final Map<String, int> docFreq = {};
    int totalDocs = 0;

    final List<({CoachIntent intent, String text})> flatList = [];

    rawMap.forEach((intentKey, phrasesDynamic) {
      final intent = CoachIntent.fromKey(intentKey);
      final phrases = (phrasesDynamic as List<dynamic>).cast<String>();

      for (final phrase in phrases) {
        final norm = TextNormalizer.normalize(phrase);
        if (norm.isEmpty) continue;
        flatList.add((intent: intent, text: norm));
        totalDocs++;

        final words = norm.split(' ').toSet();
        for (final w in words) {
          docFreq[w] = (docFreq[w] ?? 0) + 1;
        }
      }
    });

    // 2. Compute IDF: log(1 + N / df)
    _idfMap.clear();
    for (final entry in docFreq.entries) {
      _idfMap[entry.key] = math.log(1.0 + (totalDocs / entry.value));
    }

    // 3. Index each example
    _examples.clear();
    for (final item in flatList) {
      final words = item.text.split(' ');
      final wordSet = words.toSet();

      final Map<String, double> tfIdf = {};
      double sumSquares = 0.0;

      for (final w in wordSet) {
        final tf = words.where((t) => t == w).length / words.length;
        final idf = _idfMap[w] ?? 1.0;
        final weight = tf * idf;
        tfIdf[w] = weight;
        sumSquares += weight * weight;
      }

      final norm = math.sqrt(sumSquares);

      _examples.add(
        _IndexedExample(
          intent: item.intent,
          normalizedText: item.text,
          words: wordSet,
          wordTfIdf: tfIdf,
          wordVectorNorm: norm > 0 ? norm : 1.0,
          char3grams: _extract3Grams(item.text),
        ),
      );
    }

    _initialized = true;
  }

  @override
  Future<IntentClassificationResult> classify(
    String rawMessage, {
    CoachIntent? previousIntent,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final normalized = TextNormalizer.normalize(rawMessage);
    final slots = SlotExtractor.extract(normalized);

    if (normalized.isEmpty) {
      return IntentClassificationResult(
        intent: CoachIntent.unknown,
        confidence: 0.0,
        slots: slots,
        rawMessage: rawMessage,
        normalizedMessage: normalized,
      );
    }

    // --- Check Follow-Up Context ---
    // If user asks "what about subtraction?", "and cubes?", "how about division?"
    // or provides just a topic after a previous topic-relevant query
    if (previousIntent != null && slots.topic != null) {
      final isFollowUpQuery = _isFollowUpPhrase(normalized);
      if (isFollowUpQuery) {
        // Reuse previous intent with new topic
        return IntentClassificationResult(
          intent: previousIntent,
          confidence: 0.92,
          slots: slots,
          rawMessage: rawMessage,
          normalizedMessage: normalized,
        );
      }
    }

    // --- Fast Keyword Boost for Explicit Start Practice ---
    final isExplicitStart = (normalized.startsWith('practice ') ||
            normalized.startsWith('drill ') ||
            normalized.contains('start practice') ||
            normalized.contains('start a session') ||
            (slots.topic != null && (slots.questionCount != null || slots.minutes != null))) &&
        !normalized.contains('how') &&
        !normalized.contains('where') &&
        !normalized.contains('what');

    if (isExplicitStart) {
      return IntentClassificationResult(
        intent: CoachIntent.startPractice,
        confidence: 0.95,
        slots: slots,
        rawMessage: rawMessage,
        normalizedMessage: normalized,
      );
    }

    // --- Compute Query Vector & 3-Grams ---
    final queryWords = normalized.split(' ');
    final queryWordSet = queryWords.toSet();
    final Map<String, double> queryTfIdf = {};
    double querySumSquares = 0.0;

    for (final w in queryWordSet) {
      final tf = queryWords.where((t) => t == w).length / queryWords.length;
      final idf = _idfMap[w] ?? 1.5; // fallback for unseen words
      final weight = tf * idf;
      queryTfIdf[w] = weight;
      querySumSquares += weight * weight;
    }

    final queryNorm = math.sqrt(querySumSquares);
    final query3Grams = _extract3Grams(normalized);

    // --- Search Highest Scoring Example ---
    CoachIntent bestIntent = CoachIntent.unknown;
    double bestScore = 0.0;

    for (final ex in _examples) {
      // 1. Exact string match
      if (ex.normalizedText == normalized) {
        return IntentClassificationResult(
          intent: ex.intent,
          confidence: 1.0,
          slots: slots,
          rawMessage: rawMessage,
          normalizedMessage: normalized,
        );
      }

      // 2. Word TF-IDF Cosine Similarity
      double dotProduct = 0.0;
      for (final entry in queryTfIdf.entries) {
        final exWeight = ex.wordTfIdf[entry.key];
        if (exWeight != null) {
          dotProduct += entry.value * exWeight;
        }
      }
      final wordCos = queryNorm > 0 ? (dotProduct / (queryNorm * ex.wordVectorNorm)) : 0.0;

      // 3. Character 3-Gram Dice Coefficient
      double charSim = 0.0;
      if (query3Grams.isNotEmpty && ex.char3grams.isNotEmpty) {
        int common3Grams = 0;
        for (final g in query3Grams) {
          if (ex.char3grams.contains(g)) common3Grams++;
        }
        charSim = (2.0 * common3Grams) / (query3Grams.length + ex.char3grams.length);
      }

      // 4. Combined weighted score
      final combined = (0.55 * wordCos) + (0.45 * charSim);

      if (combined > bestScore) {
        bestScore = combined;
        bestIntent = ex.intent;
      }
    }

    // If query has topic and matched general status words (e.g. "how is my division"), map to topicStatus
    if (slots.topic != null &&
        (bestIntent == CoachIntent.accuracy ||
            bestIntent == CoachIntent.speed ||
            bestIntent == CoachIntent.weakAreas ||
            bestIntent == CoachIntent.topicStatus ||
            normalized.contains('how is') ||
            normalized.contains('status') ||
            normalized.contains('tell me about'))) {
      bestIntent = CoachIntent.topicStatus;
      bestScore = math.max(bestScore, 0.75);
    }

    // Threshold gate
    if (bestScore < CoachConstants.confidenceThreshold) {
      return IntentClassificationResult(
        intent: CoachIntent.unknown,
        confidence: bestScore,
        slots: slots,
        rawMessage: rawMessage,
        normalizedMessage: normalized,
      );
    }

    return IntentClassificationResult(
      intent: bestIntent,
      confidence: bestScore,
      slots: slots,
      rawMessage: rawMessage,
      normalizedMessage: normalized,
    );
  }

  static Set<String> _extract3Grams(String text) {
    if (text.length < 3) return {text};
    final padded = '  $text  ';
    final result = <String>{};
    for (int i = 0; i <= padded.length - 3; i++) {
      result.add(padded.substring(i, i + 3));
    }
    return result;
  }

  static bool _isFollowUpPhrase(String text) {
    if (text.startsWith('what about') ||
        text.startsWith('how about') ||
        text.startsWith('and ') ||
        text.startsWith('tell me about') ||
        text.startsWith('what of')) {
      return true;
    }
    // Also if query is just the topic itself e.g. "cubes", "subtraction"
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.length <= 2) return true;
    return false;
  }
}
