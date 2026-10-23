/// Single source of truth for dynamic question font sizing and line breaking.
abstract final class QuestionFontConstants {
  QuestionFontConstants._();

  // Expression questions (numbers, symbols, operators)
  /// Preferred single-line font size for math expressions.
  static const double expressionPreferredSize = 54.0;

  /// Minimum font size before an expression must break into two lines.
  static const double expressionOneLineMinSize = 30.0;

  /// Maximum font size for two-line balanced expression display.
  static const double expressionTwoLinesMaxSize = 40.0;

  /// Minimum font size for two-line balanced expression display.
  static const double expressionTwoLinesMinSize = 28.0;

  // Sentence questions (word problems)
  /// Maximum font size for word problem questions.
  static const double sentenceMaxSize = 34.0;

  /// Minimum font size for word problem questions.
  static const double sentenceMinSize = 22.0;

  /// Maximum lines allowed for word problem questions.
  static const int sentenceMaxLines = 4;
}
