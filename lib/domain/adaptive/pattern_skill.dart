import 'package:flutter/foundation.dart';
import '../../core/enums/enums.dart';

/// Immutable model representing a user's skill level for a specific question pattern.
@immutable
class PatternSkill {
  final int? id;
  final Topic topic;
  final Difficulty difficulty;
  final String pattern;
  final double mastery;
  final int attemptsCount;
  final double accuracyEma;
  final double avgTimeMsEma;
  final DateTime? lastPracticedAt;

  const PatternSkill({
    this.id,
    required this.topic,
    required this.difficulty,
    required this.pattern,
    this.mastery = 0.5,
    this.attemptsCount = 0,
    this.accuracyEma = 0.0,
    this.avgTimeMsEma = 0.0,
    this.lastPracticedAt,
  });

  /// Canonical key format for indexing pattern skills in memory maps.
  static String makeKey(Topic topic, Difficulty difficulty, String pattern) =>
      '${topic.name}:${difficulty.name}:$pattern';

  /// The canonical map key for this instance.
  String get fullKey => makeKey(topic, difficulty, pattern);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'topic': topic.name,
      'difficulty': difficulty.name,
      'pattern': pattern,
      'mastery': mastery,
      'attempts_count': attemptsCount,
      'accuracy_ema': accuracyEma,
      'avg_time_ms_ema': avgTimeMsEma,
      'last_practiced_at': lastPracticedAt?.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory PatternSkill.fromMap(Map<String, dynamic> map) {
    return PatternSkill(
      id: (map['id'] as num?)?.toInt(),
      topic: _parseTopic(map['topic'] as String),
      difficulty: _parseDifficulty(map['difficulty'] as String),
      pattern: map['pattern'] as String? ?? 'default',
      mastery: (map['mastery'] as num?)?.toDouble() ?? 0.5,
      attemptsCount: (map['attempts_count'] as num?)?.toInt() ?? 0,
      accuracyEma: (map['accuracy_ema'] as num?)?.toDouble() ?? 0.0,
      avgTimeMsEma: (map['avg_time_ms_ema'] as num?)?.toDouble() ?? 0.0,
      lastPracticedAt: map['last_practiced_at'] != null
          ? DateTime.tryParse(map['last_practiced_at'] as String)
          : null,
    );
  }

  PatternSkill copyWith({
    int? id,
    Topic? topic,
    Difficulty? difficulty,
    String? pattern,
    double? mastery,
    int? attemptsCount,
    double? accuracyEma,
    double? avgTimeMsEma,
    DateTime? lastPracticedAt,
  }) {
    return PatternSkill(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      pattern: pattern ?? this.pattern,
      mastery: mastery ?? this.mastery,
      attemptsCount: attemptsCount ?? this.attemptsCount,
      accuracyEma: accuracyEma ?? this.accuracyEma,
      avgTimeMsEma: avgTimeMsEma ?? this.avgTimeMsEma,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
    );
  }

  static Topic _parseTopic(String name) {
    return Topic.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Topic.addition,
    );
  }

  static Difficulty _parseDifficulty(String name) {
    return Difficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Difficulty.easy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternSkill &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          difficulty == other.difficulty &&
          pattern == other.pattern &&
          attemptsCount == other.attemptsCount &&
          (mastery - other.mastery).abs() < 1e-6;

  @override
  int get hashCode =>
      topic.hashCode ^
      difficulty.hashCode ^
      pattern.hashCode ^
      attemptsCount.hashCode;

  @override
  String toString() =>
      'PatternSkill(${topic.name}:${difficulty.name}:$pattern, '
      'mastery: ${(mastery * 100).toStringAsFixed(1)}%, attempts: $attemptsCount)';
}
