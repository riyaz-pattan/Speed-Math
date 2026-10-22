import 'package:flutter/foundation.dart';
import '../../core/enums/enums.dart';

/// Immutable model representing a user's skill level for a specific topic + difficulty bucket.
@immutable
class SkillRating {
  final int? id;
  final Topic topic;
  final Difficulty difficulty;
  final double mastery;
  final int attemptsCount;
  final double accuracyEma;
  final double avgTimeMsEma;
  final DateTime? lastPracticedAt;

  const SkillRating({
    this.id,
    required this.topic,
    required this.difficulty,
    this.mastery = 0.5,
    this.attemptsCount = 0,
    this.accuracyEma = 0.0,
    this.avgTimeMsEma = 0.0,
    this.lastPracticedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'topic': topic.name,
      'difficulty': difficulty.name,
      'mastery': mastery,
      'attempts_count': attemptsCount,
      'accuracy_ema': accuracyEma,
      'avg_time_ms_ema': avgTimeMsEma,
      'last_practiced_at': lastPracticedAt?.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory SkillRating.fromMap(Map<String, dynamic> map) {
    return SkillRating(
      id: (map['id'] as num?)?.toInt(),
      topic: _parseTopic(map['topic'] as String),
      difficulty: _parseDifficulty(map['difficulty'] as String),
      mastery: (map['mastery'] as num?)?.toDouble() ?? 0.5,
      attemptsCount: (map['attempts_count'] as num?)?.toInt() ?? 0,
      accuracyEma: (map['accuracy_ema'] as num?)?.toDouble() ?? 0.0,
      avgTimeMsEma: (map['avg_time_ms_ema'] as num?)?.toDouble() ?? 0.0,
      lastPracticedAt: map['last_practiced_at'] != null
          ? DateTime.tryParse(map['last_practiced_at'] as String)
          : null,
    );
  }

  SkillRating copyWith({
    int? id,
    Topic? topic,
    Difficulty? difficulty,
    double? mastery,
    int? attemptsCount,
    double? accuracyEma,
    double? avgTimeMsEma,
    DateTime? lastPracticedAt,
  }) {
    return SkillRating(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      mastery: mastery ?? this.mastery,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      accuracyEma: accuracyEma ?? this.accuracyEma,
      avgTimeMsEma: avgTimeMsEma ?? this.avgTimeMsEma,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
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
      other is SkillRating &&
          topic == other.topic &&
          difficulty == other.difficulty &&
          mastery == other.mastery &&
          attemptsCount == other.attemptsCount;

  @override
  int get hashCode =>
      topic.hashCode ^ difficulty.hashCode ^ mastery.hashCode ^ attemptsCount.hashCode;

  @override
  String toString() =>
      'SkillRating(topic: ${topic.name}, difficulty: ${difficulty.name}, '
      'mastery: ${mastery.toStringAsFixed(3)}, attempts: $attemptsCount)';
}
