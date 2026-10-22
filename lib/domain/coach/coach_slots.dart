import '../../core/enums/enums.dart';

/// Extracted semantic slots from user input.
class CoachSlots {
  final Topic? topic;
  final Difficulty? difficulty;
  final int? questionCount; // 10, 20, 30, 50
  final int? minutes; // 1, 2, 3, 5, 10
  final String? timeWord; // 'today', 'this_week', 'last_week'

  const CoachSlots({
    this.topic,
    this.difficulty,
    this.questionCount,
    this.minutes,
    this.timeWord,
  });

  bool get isEmpty =>
      topic == null &&
      difficulty == null &&
      questionCount == null &&
      minutes == null &&
      timeWord == null;

  bool get isNotEmpty => !isEmpty;

  CoachSlots copyWith({
    Topic? topic,
    Difficulty? difficulty,
    int? questionCount,
    int? minutes,
    String? timeWord,
    bool clearTopic = false,
  }) {
    return CoachSlots(
      topic: clearTopic ? null : (topic ?? this.topic),
      difficulty: difficulty ?? this.difficulty,
      questionCount: questionCount ?? this.questionCount,
      minutes: minutes ?? this.minutes,
      timeWord: timeWord ?? this.timeWord,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (topic != null) 'topic': topic!.name,
      if (difficulty != null) 'difficulty': difficulty!.name,
      if (questionCount != null) 'question_count': questionCount,
      if (minutes != null) 'minutes': minutes,
      if (timeWord != null) 'time_word': timeWord,
    };
  }

  @override
  String toString() => toMap().toString();
}
