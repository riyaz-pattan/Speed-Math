/// Constants for the AI Coach engine and presentation layers.
abstract final class CoachConstants {
  CoachConstants._();

  /// Confidence threshold below which the coach considers the message unknown.
  static const double confidenceThreshold = 0.28;

  /// Maximum allowed characters for a user query to prevent performance lag.
  static const int maxInputLength = 300;

  /// Maximum number of messages preserved in local SQLite storage.
  static const int maxChatHistory = 100;

  /// Ready-made question chips displayed horizontally above the chat input.
  static const List<String> readyMadeQuestions = [
    'Generate my report',
    'Where am I weak?',
    'Where should I focus?',
    'How is my division?',
    'Make me a plan for today',
    'Am I improving?',
    'My mistakes',
    'Give me a tip',
  ];

  /// Suggested questions surfaced when the user query is unrecognized or out of scope.
  static const List<String> fallbackSuggestions = [
    'Where am I weak?',
    'Make me a plan for today',
    'Give me a tip',
  ];
}
