import 'dart:convert';
import '../../core/enums/enums.dart';
import '../questions/question.dart';

/// Origin of why a question was added to the mistake bank.
enum MistakeSource {
  wrong,
  skipped,
  slow;

  String get displayName => switch (this) {
    MistakeSource.wrong => 'Wrong',
    MistakeSource.skipped => 'Skipped',
    MistakeSource.slow => 'Too slow',
  };

  static MistakeSource fromString(String value) {
    return MistakeSource.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MistakeSource.wrong,
    );
  }
}

/// Immutable record of a banked mistake in the adaptive learning system.
class MistakeEntry {
  final int? id;
  final Topic topic;
  final Difficulty difficulty;
  final String questionText;
  final List<int> operands;
  final int correctAnswer;
  final int stage; // 0, 1, or 2
  final int correctStreak;
  final int wrongCount;
  final MistakeSource source;
  final DateTime addedAt;
  final int dueCounter;

  const MistakeEntry({
    this.id,
    required this.topic,
    required this.difficulty,
    required this.questionText,
    required this.operands,
    required this.correctAnswer,
    this.stage = 0,
    this.correctStreak = 0,
    this.wrongCount = 1,
    required this.source,
    required this.addedAt,
    this.dueCounter = 0,
  });

  /// The canonical target answer as a display string (e.g. "1/8" or "42").
  String get targetAnswerText {
    if ((topic == Topic.fractionReciprocals ||
            topic == Topic.derivedFractions) &&
        operands.length >= 2) {
      return '${operands[0]}/${operands[1]}';
    }
    return correctAnswer.toString();
  }

  /// Converts this mistake entry to an executable [Question].
  Question toQuestion() {
    final String? strAns = (topic == Topic.fractionReciprocals ||
            topic == Topic.derivedFractions) &&
        operands.length >= 2
        ? '${operands[0]}/${operands[1]}'
        : null;

    return Question(
      topic: topic,
      difficulty: difficulty,
      displayText: questionText,
      operands: operands,
      correctAnswer: correctAnswer,
      stringAnswer: strAns,
    );
  }

  /// Converts to database map.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'topic': topic.name,
      'difficulty': difficulty.name,
      'question_text': questionText,
      'operands': jsonEncode(operands),
      'correct_answer': correctAnswer,
      'stage': stage,
      'correct_streak': correctStreak,
      'wrong_count': wrongCount,
      'source': source.name,
      'added_at': addedAt.millisecondsSinceEpoch,
      'due_counter': dueCounter,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// Creates a [MistakeEntry] from database map.
  factory MistakeEntry.fromMap(Map<String, dynamic> map) {
    List<int> parsedOperands = [];
    final operandsRaw = map['operands'];
    if (operandsRaw is String) {
      try {
        final decoded = jsonDecode(operandsRaw);
        if (decoded is List) {
          parsedOperands = decoded.map((e) => int.parse(e.toString())).toList();
        }
      } catch (_) {
        parsedOperands = [];
      }
    }

    final addedAtVal = map['added_at'];
    final addedAt = addedAtVal is int
        ? DateTime.fromMillisecondsSinceEpoch(addedAtVal)
        : (addedAtVal is String
            ? (int.tryParse(addedAtVal) != null
                ? DateTime.fromMillisecondsSinceEpoch(int.parse(addedAtVal))
                : DateTime.tryParse(addedAtVal) ?? DateTime.now())
            : DateTime.now());

    return MistakeEntry(
      id: (map['id'] as num?)?.toInt(),
      topic: Topic.values.firstWhere(
        (t) => t.name.toLowerCase() == (map['topic'] as String).toLowerCase(),
        orElse: () => Topic.addition,
      ),
      difficulty: Difficulty.values.firstWhere(
        (d) =>
            d.name.toLowerCase() == (map['difficulty'] as String).toLowerCase(),
        orElse: () => Difficulty.easy,
      ),
      questionText: map['question_text'] as String,
      operands: parsedOperands,
      correctAnswer: (map['correct_answer'] as num).toInt(),
      stage: ((map['stage'] as num?)?.toInt() ?? 0).clamp(0, 2),
      correctStreak: (map['correct_streak'] as num?)?.toInt() ?? 0,
      wrongCount: (map['wrong_count'] as num?)?.toInt() ?? 1,
      source: MistakeSource.fromString(map['source'] as String? ?? 'wrong'),
      addedAt: addedAt,
      dueCounter: (map['due_counter'] as num?)?.toInt() ?? 0,
    );
  }

  MistakeEntry copyWith({
    int? id,
    Topic? topic,
    Difficulty? difficulty,
    String? questionText,
    List<int>? operands,
    int? correctAnswer,
    int? stage,
    int? correctStreak,
    int? wrongCount,
    MistakeSource? source,
    DateTime? addedAt,
    int? dueCounter,
  }) {
    return MistakeEntry(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      questionText: questionText ?? this.questionText,
      operands: operands ?? this.operands,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      stage: stage ?? this.stage,
      correctStreak: correctStreak ?? this.correctStreak,
      wrongCount: wrongCount ?? this.wrongCount,
      source: source ?? this.source,
      addedAt: addedAt ?? this.addedAt,
      dueCounter: dueCounter ?? this.dueCounter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MistakeEntry &&
          runtimeType == other.runtimeType &&
          questionText == other.questionText;

  @override
  int get hashCode => questionText.hashCode;
}
