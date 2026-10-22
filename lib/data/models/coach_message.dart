import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/coach/coach_reply.dart';

/// Database entity and chat UI model for a conversation turn between the user and Coach.
@immutable
class CoachMessage {
  final int? id;
  final String role; // 'user' or 'coach'
  final String text;
  final List<CoachAction> actions;
  final int createdAt; // epoch ms

  const CoachMessage({
    this.id,
    required this.role,
    required this.text,
    this.actions = const [],
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isCoach => role == 'coach';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'role': role,
      'text': text,
      'actions': jsonEncode(actions.map((a) => a.toMap()).toList()),
      'created_at': createdAt,
    };
  }

  factory CoachMessage.fromMap(Map<String, dynamic> map) {
    List<CoachAction> parsedActions = [];
    final actionsRaw = map['actions'] as String?;
    if (actionsRaw != null && actionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(actionsRaw) as List<dynamic>;
        parsedActions = decoded
            .map((a) => CoachAction.fromMap(a as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return CoachMessage(
      id: map['id'] as int?,
      role: map['role'] as String? ?? 'coach',
      text: map['text'] as String? ?? '',
      actions: parsedActions,
      createdAt: map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
