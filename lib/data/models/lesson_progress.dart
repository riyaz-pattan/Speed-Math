// lib/data/models/lesson_progress.dart

/// Tracks a user's progress through a single whiteboard lesson.
class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.status,
    required this.stars,
    required this.viewCount,
    required this.practiceCorrect,
    required this.practiceTotal,
    this.lastCompletedAt,
    required this.xpAwarded,
  });

  final String lessonId;
  final LessonStatus status;
  final int stars;           // 0–3
  final int viewCount;
  final int practiceCorrect;
  final int practiceTotal;
  final DateTime? lastCompletedAt;
  final int xpAwarded;      // 30 once, then 0

  static LessonProgress empty(String lessonId) => LessonProgress(
        lessonId: lessonId,
        status: LessonStatus.none,
        stars: 0,
        viewCount: 0,
        practiceCorrect: 0,
        practiceTotal: 0,
        xpAwarded: 0,
      );

  LessonProgress copyWith({
    String? lessonId,
    LessonStatus? status,
    int? stars,
    int? viewCount,
    int? practiceCorrect,
    int? practiceTotal,
    DateTime? lastCompletedAt,
    int? xpAwarded,
  }) {
    return LessonProgress(
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      stars: stars ?? this.stars,
      viewCount: viewCount ?? this.viewCount,
      practiceCorrect: practiceCorrect ?? this.practiceCorrect,
      practiceTotal: practiceTotal ?? this.practiceTotal,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      xpAwarded: xpAwarded ?? this.xpAwarded,
    );
  }

  Map<String, dynamic> toMap() => {
        'lesson_id': lessonId,
        'status': status.name,
        'stars': stars,
        'view_count': viewCount,
        'practice_correct': practiceCorrect,
        'practice_total': practiceTotal,
        'last_completed_at': lastCompletedAt?.toIso8601String(),
        'xp_awarded': xpAwarded,
      };

  factory LessonProgress.fromMap(Map<String, dynamic> map) => LessonProgress(
        lessonId: map['lesson_id'] as String,
        status: LessonStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String? ?? 'none'),
          orElse: () => LessonStatus.none,
        ),
        stars: (map['stars'] as num?)?.toInt() ?? 0,
        viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
        practiceCorrect: (map['practice_correct'] as num?)?.toInt() ?? 0,
        practiceTotal: (map['practice_total'] as num?)?.toInt() ?? 0,
        lastCompletedAt: map['last_completed_at'] != null
            ? DateTime.tryParse(map['last_completed_at'] as String)
            : null,
        xpAwarded: (map['xp_awarded'] as num?)?.toInt() ?? 0,
      );
}

enum LessonStatus { none, started, learned, mastered }
