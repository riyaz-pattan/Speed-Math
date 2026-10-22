import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/enums/enums.dart';
import '../../features/practice_session/models/practice_models.dart';

/// Type of practice block in Today's Plan.
enum PlanBlockType {
  weakness,
  mistakes,
  keepSharp;

  String get displayName => switch (this) {
        PlanBlockType.weakness => 'Targeted Drill',
        PlanBlockType.mistakes => 'Mistake Practice',
        PlanBlockType.keepSharp => 'Mixed Practice',
      };
}

/// A single practice block inside Today's Plan (~5 minutes).
@immutable
class PlanBlock {
  final int id;
  final PlanBlockType type;
  final String title;
  final String reason;
  final PracticeConfig config;
  final bool isCompleted;

  const PlanBlock({
    required this.id,
    required this.type,
    required this.title,
    required this.reason,
    required this.config,
    this.isCompleted = false,
  });

  PlanBlock copyWith({
    int? id,
    PlanBlockType? type,
    String? title,
    String? reason,
    PracticeConfig? config,
    bool? isCompleted,
  }) {
    return PlanBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      config: config ?? this.config,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'reason': reason,
      'topic': config.topic.name,
      'difficulty': config.difficulty.name,
      'mode': config.mode.name,
      'mode_value': config.modeValue,
    };
  }

  factory PlanBlock.fromMap(Map<String, dynamic> map, {bool isCompleted = false}) {
    final typeName = map['type'] as String? ?? 'weakness';
    final type = PlanBlockType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => PlanBlockType.weakness,
    );

    final topicStr = map['topic'] as String? ?? 'addition';
    final topic = Topic.values.firstWhere(
      (t) => t.name == topicStr,
      orElse: () => Topic.addition,
    );

    final diffStr = map['difficulty'] as String? ?? 'easy';
    final difficulty = Difficulty.values.firstWhere(
      (d) => d.name == diffStr,
      orElse: () => Difficulty.easy,
    );

    final modeStr = map['mode'] as String? ?? 'timer';
    final mode = PracticeMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => PracticeMode.timer,
    );

    final modeValue = (map['mode_value'] as num?)?.toInt() ?? 300;

    return PlanBlock(
      id: (map['id'] as num?)?.toInt() ?? 1,
      type: type,
      title: map['title'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      config: PracticeConfig(
        topic: topic,
        difficulty: difficulty,
        mode: mode,
        modeValue: modeValue,
        sessionSeed: (map['session_seed'] as num?)?.toInt() ?? 0,
      ),
      isCompleted: isCompleted,
    );
  }

  String toJson() => jsonEncode(toMap());
}

/// The daily structured practice plan (~15 minutes total).
@immutable
class TodayPlan {
  final DateTime date;
  final List<PlanBlock> blocks;

  const TodayPlan({
    required this.date,
    required this.blocks,
  });

  int get completedCount => blocks.where((b) => b.isCompleted).length;
  int get totalCount => blocks.length;
  bool get isAllCompleted => totalCount > 0 && completedCount == totalCount;

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
