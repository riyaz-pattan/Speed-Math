import 'coach_composer.dart';
import 'coach_context.dart';
import 'coach_intent.dart';
import 'coach_reply.dart';
import 'intent_classifier.dart';

/// Central coordinator for the AI Coach:
/// - Maintains follow-up conversation context (`previousIntent`).
/// - Executes the intent classifier.
/// - Passes classification and real practice context into the response composer.
class CoachEngine {
  final IntentClassifier _classifier;
  final CoachComposer _composer;

  CoachIntent? _previousIntent;

  CoachEngine({
    IntentClassifier? classifier,
    CoachComposer? composer,
  })  : _classifier = classifier ?? NgramIntentClassifier(),
        _composer = composer ?? CoachComposer();

  CoachIntent? get previousIntent => _previousIntent;

  Future<void> initialize({
    String? intentsJson,
    String? phrasesJson,
    String? tipsJson,
    Future<String> Function(String path)? assetLoader,
  }) async {
    await Future.wait([
      _classifier.initialize(
        jsonString: intentsJson,
        assetLoader: assetLoader,
      ),
      _composer.initialize(
        phrasesJson: phrasesJson,
        tipsJson: tipsJson,
        assetLoader: assetLoader,
      ),
    ]);
  }

  /// Processes user's [rawMessage] against the provided practice [context].
  Future<CoachReply> processMessage(
    String rawMessage,
    CoachContext context,
  ) async {
    final result = await _classifier.classify(
      rawMessage,
      previousIntent: _previousIntent,
    );

    final reply = _composer.compose(
      intent: result.intent,
      slots: result.slots,
      context: context,
    );

    // Update conversation context (remember intent for follow-ups, ignore greetings/smalltalk)
    if (result.intent != CoachIntent.greeting &&
        result.intent != CoachIntent.smalltalk &&
        result.intent != CoachIntent.goodbye &&
        result.intent != CoachIntent.unknown &&
        result.intent != CoachIntent.outOfScope) {
      _previousIntent = result.intent;
    }

    return reply;
  }

  /// Resets the conversation context state (called when chat is cleared).
  void resetContext() {
    _previousIntent = null;
  }
}
