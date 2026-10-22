import '../../core/enums/enums.dart';
import '../../features/practice_session/models/practice_models.dart';
import 'coach_intent.dart';
import 'coach_slots.dart';

/// Type of interactive action button inside a coach reply.
enum CoachActionType {
  startPractice,
  openReport,
  practiceMistakes,
  openStats,
  selectTopic,
  suggestQuestion;

  static CoachActionType fromString(String val) {
    for (final type in CoachActionType.values) {
      if (type.name == val) return type;
    }
    return CoachActionType.suggestQuestion;
  }
}

/// Interactive button displayed below a coach message.
class CoachAction {
  final String label;
  final CoachActionType type;
  final dynamic payload;

  const CoachAction({
    required this.label,
    required this.type,
    this.payload,
  });

  Map<String, dynamic> toMap() {
    dynamic serializedPayload;
    if (payload is PracticeConfig) {
      serializedPayload = (payload as PracticeConfig).toMap();
    } else if (payload is Topic) {
      serializedPayload = (payload as Topic).name;
    } else if (payload is String) {
      serializedPayload = payload;
    } else {
      serializedPayload = payload?.toString();
    }

    return {
      'label': label,
      'type': type.name,
      if (serializedPayload != null) 'payload': serializedPayload,
    };
  }

  factory CoachAction.fromMap(Map<String, dynamic> map) {
    final type = CoachActionType.fromString(map['type'] as String? ?? '');
    final rawPayload = map['payload'];

    dynamic parsedPayload = rawPayload;
    if (type == CoachActionType.startPractice && rawPayload is Map<String, dynamic>) {
      parsedPayload = PracticeConfig.fromMap(rawPayload);
    } else if (type == CoachActionType.selectTopic && rawPayload is String) {
      parsedPayload = Topic.values.firstWhere(
        (t) => t.name == rawPayload,
        orElse: () => Topic.addition,
      );
    }

    return CoachAction(
      label: map['label'] as String? ?? 'Action',
      type: type,
      payload: parsedPayload,
    );
  }
}

/// Complete response output from the Answer Composer.
class CoachReply {
  final String text;
  final List<CoachAction> actions;
  final List<String> suggestions;
  final CoachIntent intent;
  final CoachSlots slots;

  const CoachReply({
    required this.text,
    this.actions = const [],
    this.suggestions = const [],
    required this.intent,
    required this.slots,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'actions': actions.map((a) => a.toMap()).toList(),
      'suggestions': suggestions,
      'intent': intent.name,
      'slots': slots.toMap(),
    };
  }

  factory CoachReply.fromMap(Map<String, dynamic> map) {
    final actionsList = (map['actions'] as List<dynamic>?)
            ?.map((a) => CoachAction.fromMap(a as Map<String, dynamic>))
            .toList() ??
        const [];
    final suggestionsList =
        (map['suggestions'] as List<dynamic>?)?.cast<String>() ?? const [];

    return CoachReply(
      text: map['text'] as String? ?? '',
      actions: actionsList,
      suggestions: suggestionsList,
      intent: CoachIntent.fromKey(map['intent'] as String? ?? ''),
      slots: CoachSlots(),
    );
  }
}
