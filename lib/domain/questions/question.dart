import '../../core/enums/enums.dart';

/// Immutable model representing a generated math question.
///
/// Pure Dart — no Flutter imports. Used by generators and the practice session.
class Question {
  /// The math topic this question belongs to.
  final Topic topic;

  /// The difficulty level of this question.
  final Difficulty difficulty;

  /// Human-readable display text, e.g. "47 + 38" or "17²".
  final String displayText;

  /// The operands used to generate this question.
  /// For most topics this is [a, b]. For hard addition it is [a, b, c].
  final List<int> operands;

  /// The correct integer answer.
  final int correctAnswer;

  /// The specific pattern / question type (e.g. 'add_e_one_carry').
  final String? pattern;

  /// Optional string answer for fraction-type questions (e.g. '1/8').
  /// When non-null, the answer is compared as a string rather than an integer.
  final String? stringAnswer;

  const Question({
    required this.topic,
    required this.difficulty,
    required this.displayText,
    required this.operands,
    required this.correctAnswer,
    this.pattern,
    this.stringAnswer,
  });

  /// The canonical answer string: fraction string if available, else the integer.
  String get targetAnswer => stringAnswer ?? correctAnswer.toString();

  /// Whether this question expects a fraction string answer (e.g. '1/8').
  bool get isFractionAnswer =>
      stringAnswer != null && stringAnswer!.contains('/');

  /// The first operand (for database storage as operand_a).
  String get operandA => operands.isNotEmpty ? operands[0].toString() : '';

  /// The second operand (for database storage as operand_b).
  /// For hard addition (3 operands), this returns the second number;
  /// the full expression is stored in [displayText] / question_text.
  String get operandB => operands.length > 1 ? operands[1].toString() : '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          displayText == other.displayText &&
          correctAnswer == other.correctAnswer &&
          stringAnswer == other.stringAnswer;

  @override
  int get hashCode =>
      displayText.hashCode ^ correctAnswer.hashCode ^ stringAnswer.hashCode;

  @override
  String toString() =>
      'Question($displayText = $targetAnswer, topic: ${topic.name}, '
      'difficulty: ${difficulty.name})';
}
