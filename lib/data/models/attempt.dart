import 'package:flutter/foundation.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';

/// Immutable model representing an individual question attempt in a practice session.
@immutable
class Attempt {
  final int? id;
  final int sessionId;
  final Topic topic;
  final Difficulty difficulty;
  final String questionText;
  final String operandA;
  final String operandB;
  final int correctAnswer;
  final int? userAnswer;
  final bool isCorrect;
  final bool isSkipped;
  final int timeMs;
  final DateTime createdAt;
  final String? pattern;

  const Attempt({
    this.id,
    required this.sessionId,
    required this.topic,
    required this.difficulty,
    required this.questionText,
    required this.operandA,
    required this.operandB,
    required this.correctAnswer,
    this.userAnswer,
    this.isCorrect = false,
    this.isSkipped = false,
    this.timeMs = 0,
    required this.createdAt,
    this.pattern,
  });

  /// Converts this [Attempt] instance into a database map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'session_id': sessionId,
      'topic': topic.name,
      'difficulty': difficulty.name,
      'question_text': questionText,
      'operand_a': operandA,
      'operand_b': operandB,
      'correct_answer': correctAnswer,
      'user_answer': userAnswer,
      'is_correct': isCorrect ? 1 : 0,
      'is_skipped': isSkipped ? 1 : 0,
      'time_ms': timeMs,
      'created_at': createdAt.toIso8601String(),
      'pattern': pattern,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates an [Attempt] instance from a database map.
  factory Attempt.fromMap(Map<String, dynamic> map) {
    return Attempt(
      id: (map['id'] as num?)?.toInt(),
      sessionId: (map['session_id'] as num).toInt(),
      topic: _parseTopic(map['topic'] as String),
      difficulty: _parseDifficulty(map['difficulty'] as String),
      questionText: map['question_text'] as String,
      operandA: (map['operand_a'] ?? '').toString(),
      operandB: (map['operand_b'] ?? '').toString(),
      correctAnswer: (map['correct_answer'] as num).toInt(),
      userAnswer: (map['user_answer'] as num?)?.toInt(),
      isCorrect: ((map['is_correct'] as num?)?.toInt() ?? 0) == 1,
      isSkipped: ((map['is_skipped'] as num?)?.toInt() ?? 0) == 1,
      timeMs: (map['time_ms'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      pattern: map['pattern'] as String?,
    );
  }

  /// Returns a copy of this [Attempt] with updated fields.
  Attempt copyWith({
    int? id,
    int? sessionId,
    Topic? topic,
    Difficulty? difficulty,
    String? questionText,
    String? operandA,
    String? operandB,
    int? correctAnswer,
    int? userAnswer,
    bool? isCorrect,
    bool? isSkipped,
    int? timeMs,
    DateTime? createdAt,
    String? pattern,
  }) {
    return Attempt(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      questionText: questionText ?? this.questionText,
      operandA: operandA ?? this.operandA,
      operandB: operandB ?? this.operandB,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      isSkipped: isSkipped ?? this.isSkipped,
      timeMs: timeMs ?? this.timeMs,
      createdAt: createdAt ?? this.createdAt,
      pattern: pattern ?? this.pattern,
    );
  }

  static Topic _parseTopic(String value) {
    return Topic.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Topic.addition,
    );
  }

  static Difficulty _parseDifficulty(String value) {
    return Difficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Difficulty.easy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attempt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          topic == other.topic &&
          difficulty == other.difficulty &&
          questionText == other.questionText &&
          operandA == other.operandA &&
          operandB == other.operandB &&
          correctAnswer == other.correctAnswer &&
          userAnswer == other.userAnswer &&
          isCorrect == other.isCorrect &&
          isSkipped == other.isSkipped &&
          timeMs == other.timeMs &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      sessionId.hashCode ^
      topic.hashCode ^
      difficulty.hashCode ^
      questionText.hashCode ^
      operandA.hashCode ^
      operandB.hashCode ^
      correctAnswer.hashCode ^
      userAnswer.hashCode ^
      isCorrect.hashCode ^
      isSkipped.hashCode ^
      timeMs.hashCode ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'Attempt('
        'id: $id, '
        'sessionId: $sessionId, '
        'topic: ${topic.name}, '
        'difficulty: ${difficulty.name}, '
        'questionText: $questionText, '
        'operandA: $operandA, '
        'operandB: $operandB, '
        'correctAnswer: $correctAnswer, '
        'userAnswer: $userAnswer, '
        'isCorrect: $isCorrect, '
        'isSkipped: $isSkipped, '
        'timeMs: $timeMs, '
        'createdAt: $createdAt)';
  }
}
