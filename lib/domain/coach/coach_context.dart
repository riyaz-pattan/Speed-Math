import '../../core/enums/enums.dart';
import '../adaptive/mistake_entry.dart';
import '../../data/models/session.dart';
import '../adaptive/skill_rating.dart';
import '../report/report_data.dart';
import '../report/todays_plan.dart';

/// Complete in-memory contextual snapshot of user performance, plans, and mistakes
/// used by the AI Coach to formulate grounded, 100% factual responses.
class CoachContext {
  final ReportData reportData;
  final TodayPlan todayPlan;
  final List<Session> recentSessions;
  final int mistakeCount;
  final List<MistakeEntry> mistakes;
  final Map<Topic, Map<Difficulty, SkillRating>> skillRatings;

  const CoachContext({
    required this.reportData,
    required this.todayPlan,
    required this.recentSessions,
    required this.mistakeCount,
    required this.mistakes,
    required this.skillRatings,
  });

  /// Total questions answered across all topics and sessions (excluding skips).
  int get totalAnswered => reportData.totalQuestionsAllTime;

  /// Whether the user has passed the 10-question report unlock threshold.
  bool get hasEnoughData => reportData.hasEnoughData;

  /// The user's primary weak skill bucket, if any.
  SkillBucketSummary? get primaryWeakArea =>
      reportData.weakAreas.isNotEmpty ? reportData.weakAreas.first : null;

  /// The user's primary strong skill bucket, if any.
  SkillBucketSummary? get primaryStrongArea =>
      reportData.strongAreas.isNotEmpty ? reportData.strongAreas.first : null;

  /// The first neglected topic (not practiced in 7+ days).
  Topic? get primaryNeglectedTopic =>
      reportData.neglectedTopics.isNotEmpty ? reportData.neglectedTopics.first : null;

  /// Topics currently marked as improving.
  List<TopicPerformance> get improvingTopics =>
      reportData.topicPerformances.where((t) => t.trend == TopicTrend.improving).toList();

  /// Topics currently marked as slipping.
  List<TopicPerformance> get slippingTopics =>
      reportData.topicPerformances.where((t) => t.trend == TopicTrend.slipping).toList();

  /// Finds performance stats for the given [topic].
  TopicPerformance? getPerformanceForTopic(Topic topic) {
    for (final p in reportData.topicPerformances) {
      if (p.topic == topic) return p;
    }
    return null;
  }

  /// Identifies the topic with the highest attempts or best accuracy to highlight during motivation.
  TopicPerformance? get bestPracticedTopic {
    TopicPerformance? best;
    for (final p in reportData.topicPerformances) {
      if (p.totalAttempts >= 5) {
        if (best == null || p.accuracy > best.accuracy) {
          best = p;
        }
      }
    }
    return best;
  }
}
