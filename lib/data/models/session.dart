import 'package:flutter/foundation.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';

/// Immutable model representing a practice session in Mental Calculation Tricks.
@immutable
class Session {
  final int? id;
  final Topic topic;
  final Difficulty difficulty;
  final PracticeMode mode;
  final int modeValue;
  final SessionKind kind;
  final DateTime startedAt;
  final int durationMs;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double accuracy;
  final double avgTimeMs;
  final double score;
  final bool completed;

  const Session({
    this.id,
    required this.topic,
    required this.difficulty,
    required this.mode,
    required this.modeValue,
    this.kind = SessionKind.drill,
    required this.startedAt,
    this.durationMs = 0,
    this.totalQuestions = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.skippedCount = 0,
    this.accuracy = 0.0,
    this.avgTimeMs = 0.0,
    this.score = 0.0,
    this.completed = false,
  });

  /// Converts this [Session] instance into a database map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'topic': topic.name,
      'difficulty': difficulty.name,
      'mode': mode.name,
      'mode_value': modeValue,
      'kind': kind.name,
      'started_at': startedAt.toIso8601String(),
      'duration_ms': durationMs,
      'total_questions': totalQuestions,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'skipped_count': skippedCount,
      'accuracy': accuracy,
      'avg_time_ms': avgTimeMs,
      'score': score,
      'completed': completed ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates a [Session] instance from a database map.
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: (map['id'] as num?)?.toInt(),
      topic: _parseTopic(map['topic'] as String),
      difficulty: _parseDifficulty(map['difficulty'] as String),
      mode: _parsePracticeMode(map['mode'] as String),
      modeValue: (map['mode_value'] as num).toInt(),
      kind: _parseSessionKind(map['kind'] as String?),
      startedAt: DateTime.parse(map['started_at'] as String),
      durationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['total_questions'] as num?)?.toInt() ?? 0,
      correctCount: (map['correct_count'] as num?)?.toInt() ?? 0,
      wrongCount: (map['wrong_count'] as num?)?.toInt() ?? 0,
      skippedCount: (map['skipped_count'] as num?)?.toInt() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      avgTimeMs: (map['avg_time_ms'] as num?)?.toDouble() ?? 0.0,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      completed: ((map['completed'] as num?)?.toInt() ?? 0) == 1,
    );
  }

  /// Returns a copy of this [Session] with updated fields.
  Session copyWith({
    int? id,
    Topic? topic,
    Difficulty? difficulty,
    PracticeMode? mode,
    int? modeValue,
    SessionKind? kind,
    DateTime? startedAt,
    int? durationMs,
    int? totalQuestions,
    int? correctCount,
    int? wrongCount,
    int? skippedCount,
    double? accuracy,
    double? avgTimeMs,
    double? score,
    bool? completed,
  }) {
    return Session(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      mode: mode ?? this.mode,
      modeValue: modeValue ?? this.modeValue,
      kind: kind ?? this.kind,
      startedAt: startedAt ?? this.startedAt,
      durationMs: durationMs ?? this.durationMs,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      skippedCount: skippedCount ?? this.skippedCount,
      accuracy: accuracy ?? this.accuracy,
      avgTimeMs: avgTimeMs ?? this.avgTimeMs,
      score: score ?? this.score,
      completed: completed ?? this.completed,
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

  static PracticeMode _parsePracticeMode(String value) {
    return PracticeMode.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PracticeMode.timer,
    );
  }

  static SessionKind _parseSessionKind(String? value) {
    if (value == null) return SessionKind.drill;
    return SessionKind.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SessionKind.drill,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          topic == other.topic &&
          difficulty == other.difficulty &&
          mode == other.mode &&
          modeValue == other.modeValue &&
          kind == other.kind &&
          startedAt == other.startedAt &&
          durationMs == other.durationMs &&
          totalQuestions == other.totalQuestions &&
          correctCount == other.correctCount &&
          wrongCount == other.wrongCount &&
          skippedCount == other.skippedCount &&
          accuracy == other.accuracy &&
          avgTimeMs == other.avgTimeMs &&
          score == other.score &&
          completed == other.completed;

  @override
  int get hashCode =>
      id.hashCode ^
      topic.hashCode ^
      difficulty.hashCode ^
      mode.hashCode ^
      modeValue.hashCode ^
      kind.hashCode ^
      startedAt.hashCode ^
      durationMs.hashCode ^
      totalQuestions.hashCode ^
      correctCount.hashCode ^
      wrongCount.hashCode ^
      skippedCount.hashCode ^
      accuracy.hashCode ^
      avgTimeMs.hashCode ^
      score.hashCode ^
      completed.hashCode;

  @override
  String toString() {
    return 'Session('
        'id: $id, '
        'topic: ${topic.name}, '
        'difficulty: ${difficulty.name}, '
        'mode: ${mode.name}, '
        'modeValue: $modeValue, '
        'kind: ${kind.name}, '
        'startedAt: $startedAt, '
        'durationMs: $durationMs, '
        'totalQuestions: $totalQuestions, '
        'correctCount: $correctCount, '
        'wrongCount: $wrongCount, '
        'skippedCount: $skippedCount, '
        'accuracy: $accuracy, '
        'avgTimeMs: $avgTimeMs, '
        'score: $score, '
        'completed: $completed)';
  }
}
