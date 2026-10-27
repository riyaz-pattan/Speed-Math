import 'dart:convert';
import 'dart:math' as math;
import '../../core/enums/enums.dart';
import '../../features/learn/engine/lesson_registry.dart';
import '../../features/practice_session/models/practice_models.dart';
import '../questions/session_random.dart';
import 'coach_constants.dart';
import 'coach_context.dart';
import 'coach_intent.dart';
import 'coach_reply.dart';
import 'coach_slots.dart';

/// Pure Dart response composer that transforms user intent, slots, and real practice
/// data into friendly, encouraging, and mathematically accurate coach replies.
class CoachComposer {
  final math.Random _random = math.Random();
  final Map<String, int> _lastUsedVariantIndices = {};

  Map<String, dynamic> _phrases = {};
  Map<String, dynamic> _tips = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize({
    String? phrasesJson,
    String? tipsJson,
    Future<String> Function(String path)? assetLoader,
  }) async {
    if (_initialized &&
        phrasesJson == null &&
        tipsJson == null &&
        assetLoader == null) {
      return;
    }

    final String pContent;
    if (phrasesJson != null) {
      pContent = phrasesJson;
    } else if (assetLoader != null) {
      pContent = await assetLoader('assets/coach/coach_phrases.json');
    } else {
      throw StateError('Either phrasesJson or assetLoader must be provided');
    }

    final String tContent;
    if (tipsJson != null) {
      tContent = tipsJson;
    } else if (assetLoader != null) {
      tContent = await assetLoader('assets/coach/tips.json');
    } else {
      throw StateError('Either tipsJson or assetLoader must be provided');
    }

    _phrases = jsonDecode(pContent) as Map<String, dynamic>;
    _tips = jsonDecode(tContent) as Map<String, dynamic>;
    _initialized = true;
  }

  /// Composes a grounded [CoachReply] based on classified [intent], [slots], and [context].
  CoachReply compose({
    required CoachIntent intent,
    required CoachSlots slots,
    required CoachContext context,
    String? rawQuery,
  }) {
    assert(_initialized, 'CoachComposer must be initialized before compose()');

    // 1. Intents that can always be answered regardless of total answered questions:
    switch (intent) {
      case CoachIntent.greeting:
        return _composeGreeting(slots);
      case CoachIntent.help:
        return _composeHelp(slots);
      case CoachIntent.thanks:
        return _composeThanks(slots);
      case CoachIntent.goodbye:
        return _composeGoodbye(slots);
      case CoachIntent.smalltalk:
        return _composeSmalltalk(slots);
      case CoachIntent.tips:
        return _composeTips(slots, context);
      case CoachIntent.startPractice:
        return _composeStartPractice(slots);
      case CoachIntent.outOfScope:
        return _composeOutOfScope(slots);
      case CoachIntent.unknown:
        return _composeUnknown(slots);
      case CoachIntent.learn:
        return _composeLearn(slots, rawQuery: rawQuery);
      case CoachIntent.habits:
        return _composeHabits(context, slots);
      default:
        break;
    }

    // 2. If user has fewer than 10 answered questions, return polite early state notice
    // for data-dependent queries (report, weak spots, strong spots, speed, accuracy, etc.)
    if (!context.hasEnoughData) {
      return _composeNotEnoughData(intent, slots, context);
    }

    // 3. Data-dependent query handlers using real data only
    switch (intent) {
      case CoachIntent.reportSummary:
        return _composeReportSummary(slots, context);
      case CoachIntent.weakAreas:
        return _composeWeakAreas(slots, context);
      case CoachIntent.strongAreas:
        return _composeStrongAreas(slots, context);
      case CoachIntent.focus:
        return _composeFocus(slots, context);
      case CoachIntent.dailyPlan:
        return _composeDailyPlan(slots, context);
      case CoachIntent.progress:
        return _composeProgress(slots, context);
      case CoachIntent.topicStatus:
        return _composeTopicStatus(slots, context);
      case CoachIntent.speed:
        return _composeSpeed(slots, context);
      case CoachIntent.accuracy:
        return _composeAccuracy(slots, context);
      case CoachIntent.mistakes:
        return _composeMistakes(slots, context);
      case CoachIntent.motivation:
        return _composeMotivation(slots, context);
      case CoachIntent.activity:
        return _composeActivity(slots, context);
      default:
        return _composeUnknown(slots);
    }
  }

  // --- Individual Intent Composers ---

  CoachReply _composeGreeting(CoachSlots slots) {
    final text = _getVariant('greeting', {});
    return CoachReply(
      text: text,
      suggestions: CoachConstants.readyMadeQuestions.take(3).toList(),
      intent: CoachIntent.greeting,
      slots: slots,
    );
  }

  CoachReply _composeHelp(CoachSlots slots) {
    final text = _getVariant('help', {});
    return CoachReply(
      text: text,
      suggestions: [
        'Where am I weak?',
        'How is my division?',
        'Make me a plan for today',
      ],
      intent: CoachIntent.help,
      slots: slots,
    );
  }

  CoachReply _composeThanks(CoachSlots slots) {
    final text = _getVariant('thanks', {});
    return CoachReply(
      text: text,
      intent: CoachIntent.thanks,
      slots: slots,
    );
  }

  CoachReply _composeGoodbye(CoachSlots slots) {
    final text = _getVariant('goodbye', {});
    return CoachReply(
      text: text,
      intent: CoachIntent.goodbye,
      slots: slots,
    );
  }

  CoachReply _composeSmalltalk(CoachSlots slots) {
    final text = _getVariant('smalltalk', {});
    return CoachReply(
      text: text,
      suggestions: [
        'What can you do?',
        'Where should I focus?',
      ],
      intent: CoachIntent.smalltalk,
      slots: slots,
    );
  }

  CoachReply _composeOutOfScope(CoachSlots slots) {
    final text = _getVariant('out_of_scope', {});
    return CoachReply(
      text: text,
      suggestions: CoachConstants.fallbackSuggestions,
      intent: CoachIntent.outOfScope,
      slots: slots,
    );
  }

  CoachReply _composeUnknown(CoachSlots slots) {
    final text = _getVariant('low_confidence', {});
    return CoachReply(
      text: text,
      suggestions: CoachConstants.fallbackSuggestions,
      intent: CoachIntent.unknown,
      slots: slots,
    );
  }

  CoachReply _composeNotEnoughData(
    CoachIntent intent,
    CoachSlots slots,
    CoachContext context,
  ) {
    final text = _getVariant('not_enough_data', {
      'answered': context.totalAnswered.toString(),
    });

    final defaultDrillConfig = PracticeConfig(
      topic: slots.topic ?? Topic.addition,
      difficulty: slots.difficulty ?? Difficulty.easy,
      mode: PracticeMode.questions,
      kind: SessionKind.drill,
      modeValue: 10,
      sessionSeed: SessionRandom.newSessionSeed(),
    );

    return CoachReply(
      text: text,
      actions: [
        CoachAction(
          label: 'Start 10 questions',
          type: CoachActionType.startPractice,
          payload: defaultDrillConfig,
        ),
      ],
      intent: intent,
      slots: slots,
    );
  }

  CoachReply _composeReportSummary(CoachSlots slots, CoachContext context) {
    final rep = context.reportData;
    final wc = rep.weeklyComparison.currentWindow;
    final scoreStr = rep.overallSpeedScore != null
        ? rep.overallSpeedScore!.toStringAsFixed(0)
        : 'Pending';
    final labelStr = rep.speedScoreLabel?.displayName ?? 'Building';

    final text = _getVariant('report_summary', {
      'score': scoreStr,
      'label': labelStr,
      'sessions': wc.sessionsCount.toString(),
      'questions': wc.questionsAnswered.toString(),
      'minutes': wc.practiceMinutes.toStringAsFixed(1),
      'accuracy': _formatPercent(wc.accuracy),
      'time': _formatTime(wc.avgTimeMsPerCorrect),
    });

    return CoachReply(
      text: text,
      actions: const [
        CoachAction(
          label: 'Open report',
          type: CoachActionType.openReport,
        ),
      ],
      intent: CoachIntent.reportSummary,
      slots: slots,
    );
  }

  CoachReply _composeWeakAreas(CoachSlots slots, CoachContext context) {
    final weakList = context.reportData.weakAreas;
    if (weakList.isEmpty) {
      final text = _getVariant('no_weak_areas', {});
      return CoachReply(
        text: text,
        intent: CoachIntent.weakAreas,
        slots: slots,
      );
    }

    final top = weakList.first;
    final perf = context.getPerformanceForTopic(top.topic);
    final accuracyStr = _formatPercent(perf?.accuracy ?? top.mastery);
    final timeStr = _formatTime(perf?.avgTimeMs ?? 4000);

    var text = _getVariant('weak_areas_found', {
      'top_weak': '${top.topic.displayName} (${top.difficulty.displayName})',
      'accuracy': accuracyStr,
      'time': timeStr,
    });

    if (top.weakestPatternExplanation != null) {
      text += '\n\n${top.weakestPatternExplanation}';
    }

    final drillConfig = PracticeConfig(
      topic: top.topic,
      difficulty: top.difficulty,
      mode: PracticeMode.questions,
      kind: SessionKind.drill,
      modeValue: 10,
      sessionSeed: SessionRandom.newSessionSeed(),
    );

    return CoachReply(
      text: text,
      actions: [
        CoachAction(
          label: 'Practice this',
          type: CoachActionType.startPractice,
          payload: drillConfig,
        ),
      ],
      intent: CoachIntent.weakAreas,
      slots: slots,
    );
  }

  CoachReply _composeStrongAreas(CoachSlots slots, CoachContext context) {
    final strongList = context.reportData.strongAreas;
    if (strongList.isEmpty) {
      final text = _getVariant('no_strong_areas', {});
      return CoachReply(
        text: text,
        intent: CoachIntent.strongAreas,
        slots: slots,
      );
    }

    final top = strongList.first;
    final perf = context.getPerformanceForTopic(top.topic);
    final accuracyStr = _formatPercent(perf?.accuracy ?? top.mastery);
    final timeStr = _formatTime(perf?.avgTimeMs ?? 2500);

    final text = _getVariant('strong_areas_found', {
      'top_strong': '${top.topic.displayName} (${top.difficulty.displayName})',
      'accuracy': accuracyStr,
      'time': timeStr,
    });

    return CoachReply(
      text: text,
      actions: const [
        CoachAction(
          label: 'Open stats',
          type: CoachActionType.openStats,
        ),
      ],
      intent: CoachIntent.strongAreas,
      slots: slots,
    );
  }

  CoachReply _composeFocus(CoachSlots slots, CoachContext context) {
    // 1. Weakest active bucket
    if (context.primaryWeakArea != null) {
      final weak = context.primaryWeakArea!;
      final perf = context.getPerformanceForTopic(weak.topic);
      var text = _getVariant('focus_weak', {
        'bucket': '${weak.topic.displayName} (${weak.difficulty.displayName})',
        'accuracy': _formatPercent(perf?.accuracy ?? weak.mastery),
        'time': _formatTime(perf?.avgTimeMs ?? 4000),
      });

      if (weak.weakestPatternExplanation != null) {
        text += '\n\n${weak.weakestPatternExplanation}';
      }

      final drillConfig = PracticeConfig(
        topic: weak.topic,
        difficulty: weak.difficulty,
        mode: PracticeMode.questions,
        kind: SessionKind.drill,
        modeValue: 10,
        sessionSeed: SessionRandom.newSessionSeed(),
      );

      return CoachReply(
        text: text,
        actions: [
          CoachAction(
            label: 'Start ${weak.topic.displayName}',
            type: CoachActionType.startPractice,
            payload: drillConfig,
          ),
        ],
        intent: CoachIntent.focus,
        slots: slots,
      );
    }

    // 2. Neglected topic (not practiced in 7+ days)
    if (context.primaryNeglectedTopic != null) {
      final topic = context.primaryNeglectedTopic!;
      final perf = context.getPerformanceForTopic(topic);
      final days = perf?.daysSinceLastPracticed ?? 7;

      final text = _getVariant('focus_neglected', {
        'topic': topic.displayName,
        'days': days.toString(),
      });

      final drillConfig = PracticeConfig(
        topic: topic,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        kind: SessionKind.drill,
        modeValue: 10,
        sessionSeed: SessionRandom.newSessionSeed(),
      );

      return CoachReply(
        text: text,
        actions: [
          CoachAction(
            label: 'Start ${topic.displayName}',
            type: CoachActionType.startPractice,
            payload: drillConfig,
          ),
        ],
        intent: CoachIntent.focus,
        slots: slots,
      );
    }

    // 3. Mistakes waiting
    if (context.mistakeCount > 0) {
      final text = _getVariant('focus_mistakes', {
        'count': context.mistakeCount.toString(),
      });

      return CoachReply(
        text: text,
        actions: const [
          CoachAction(
            label: 'Practice my mistakes',
            type: CoachActionType.practiceMistakes,
          ),
        ],
        intent: CoachIntent.focus,
        slots: slots,
      );
    }

    // 4. General mixed recommendation
    final text = _getVariant('focus_general', {});
    final mixedConfig = PracticeConfig(
      topic: Topic.mixed,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      kind: SessionKind.mixed,
      modeValue: 20,
      sessionSeed: SessionRandom.newSessionSeed(),
    );

    return CoachReply(
      text: text,
      actions: [
        CoachAction(
          label: 'Start Mixed Practice',
          type: CoachActionType.startPractice,
          payload: mixedConfig,
        ),
      ],
      intent: CoachIntent.focus,
      slots: slots,
    );
  }

  CoachReply _composeDailyPlan(CoachSlots slots, CoachContext context) {
    final plan = context.todayPlan;
    final completedCount = plan.completedCount;
    final totalCount = plan.blocks.length;

    final text = _getVariant('daily_plan_overview', {
      'completed': completedCount.toString(),
      'total': totalCount.toString(),
    });

    final actions = <CoachAction>[];
    for (final block in plan.blocks) {
      if (!block.isCompleted) {
        actions.add(
          CoachAction(
            label: 'Start: ${block.title}',
            type: CoachActionType.startPractice,
            payload: block.config,
          ),
        );
      }
    }

    if (actions.isEmpty) {
      actions.add(
        const CoachAction(
          label: 'Open report',
          type: CoachActionType.openReport,
        ),
      );
    }

    return CoachReply(
      text: text,
      actions: actions,
      intent: CoachIntent.dailyPlan,
      slots: slots,
    );
  }

  CoachReply _composeProgress(CoachSlots slots, CoachContext context) {
    final wc = context.reportData.weeklyComparison;
    final speedDiff = wc.speedImprovementPercent;

    if (speedDiff == null || wc.previousWindow.questionsAnswered == 0) {
      final text = _getVariant('progress_no_data', {});
      return CoachReply(
        text: text,
        intent: CoachIntent.progress,
        slots: slots,
      );
    }

    final timeStr = _formatTime(wc.currentWindow.avgTimeMsPerCorrect);
    final diffAbs = '${speedDiff.abs().toStringAsFixed(0)}%';

    final String text;
    if (speedDiff >= 5.0) {
      text = _getVariant('progress_improving', {
        'speed_diff': diffAbs,
        'time': timeStr,
      });
    } else if (speedDiff <= -5.0) {
      text = _getVariant('progress_slipping', {
        'speed_diff': diffAbs,
        'time': timeStr,
      });
    } else {
      text = _getVariant('progress_steady', {
        'time': timeStr,
        'accuracy': _formatPercent(wc.currentWindow.accuracy),
      });
    }

    return CoachReply(
      text: text,
      actions: const [
        CoachAction(
          label: 'Open report',
          type: CoachActionType.openReport,
        ),
      ],
      intent: CoachIntent.progress,
      slots: slots,
    );
  }

  CoachReply _composeTopicStatus(CoachSlots slots, CoachContext context) {
    // If user asked topic status but did not specify a topic, ask which topic
    if (slots.topic == null) {
      final text = _getVariant('ask_topic', {});
      return CoachReply(
        text: text,
        actions: Topic.standardTopics.map((t) {
          return CoachAction(
            label: t.displayName,
            type: CoachActionType.selectTopic,
            payload: t,
          );
        }).toList(),
        intent: CoachIntent.topicStatus,
        slots: slots,
      );
    }

    final topic = slots.topic!;
    final perf = context.getPerformanceForTopic(topic);

    if (perf == null || perf.totalAttempts == 0) {
      final text = _getVariant('topic_status_no_data', {
        'topic': topic.displayName,
      });

      final drillConfig = PracticeConfig(
        topic: topic,
        difficulty: slots.difficulty ?? Difficulty.easy,
        mode: PracticeMode.questions,
        kind: SessionKind.drill,
        modeValue: 10,
        sessionSeed: SessionRandom.newSessionSeed(),
      );

      return CoachReply(
        text: text,
        actions: [
          CoachAction(
            label: 'Practice ${topic.displayName}',
            type: CoachActionType.startPractice,
            payload: drillConfig,
          ),
        ],
        intent: CoachIntent.topicStatus,
        slots: slots,
      );
    }

    var text = _getVariant('topic_status_with_data', {
      'topic': topic.displayName,
      'level': perf.level.displayName,
      'accuracy': _formatPercent(perf.accuracy),
      'time': _formatTime(perf.avgTimeMs),
      'attempts': perf.totalAttempts.toString(),
      'trend': perf.trend.displayName,
    });

    final patternLine = perf.perDifficulty.values
        .map((b) => b.weakestPatternExplanation)
        .whereType<String>()
        .firstOrNull;

    if (patternLine != null) {
      text += '\n\n$patternLine';
    }

    final drillConfig = PracticeConfig(
      topic: topic,
      difficulty: slots.difficulty ?? perf.bestDifficulty,
      mode: PracticeMode.questions,
      kind: SessionKind.drill,
      modeValue: 10,
      sessionSeed: SessionRandom.newSessionSeed(),
    );

    return CoachReply(
      text: text,
      actions: [
        CoachAction(
          label: 'Practice ${topic.displayName}',
          type: CoachActionType.startPractice,
          payload: drillConfig,
        ),
      ],
      intent: CoachIntent.topicStatus,
      slots: slots,
    );
  }

  CoachReply _composeSpeed(CoachSlots slots, CoachContext context) {
    final cur = context.reportData.weeklyComparison.currentWindow;
    final timeStr = _formatTime(cur.avgTimeMsPerCorrect);

    final text = _getVariant('speed_summary', {
      'time': timeStr,
      'questions': cur.questionsAnswered.toString(),
      'sessions': cur.sessionsCount.toString(),
    });

    return CoachReply(
      text: text,
      actions: const [
        CoachAction(
          label: 'Open stats',
          type: CoachActionType.openStats,
        ),
      ],
      intent: CoachIntent.speed,
      slots: slots,
    );
  }

  CoachReply _composeAccuracy(CoachSlots slots, CoachContext context) {
    final cur = context.reportData.weeklyComparison.currentWindow;
    final accStr = _formatPercent(cur.accuracy);

    final text = _getVariant('accuracy_summary', {
      'accuracy': accStr,
      'correct': cur.correctCount.toString(),
      'total': cur.questionsAnswered.toString(),
      'sessions': cur.sessionsCount.toString(),
    });

    return CoachReply(
      text: text,
      actions: const [
        CoachAction(
          label: 'Open stats',
          type: CoachActionType.openStats,
        ),
      ],
      intent: CoachIntent.accuracy,
      slots: slots,
    );
  }

  CoachReply _composeMistakes(CoachSlots slots, CoachContext context) {
    if (context.mistakeCount == 0) {
      final text = _getVariant('no_mistakes', {});
      return CoachReply(
        text: text,
        intent: CoachIntent.mistakes,
        slots: slots,
      );
    }

    final topTopic = context.reportData.mistakeSummary.topMistakeTopics.isNotEmpty
        ? context.reportData.mistakeSummary.topMistakeTopics.first.topic.displayName
        : 'your drills';

    final text = _getVariant('mistakes_found', {
      'count': context.mistakeCount.toString(),
      'top_topic': topTopic,
    });

    return CoachReply(
      text: text,
      actions: const [
        CoachAction(
          label: 'Practice my mistakes',
          type: CoachActionType.practiceMistakes,
        ),
      ],
      intent: CoachIntent.mistakes,
      slots: slots,
    );
  }

  CoachReply _composeTips(CoachSlots slots, CoachContext context) {
    // Pick topic: user specified topic, or user's weakest topic, or random standard topic
    final Topic targetTopic;
    if (slots.topic != null) {
      targetTopic = slots.topic!;
    } else if (context.primaryWeakArea != null) {
      targetTopic = context.primaryWeakArea!.topic;
    } else {
      targetTopic = Topic.standardTopics[_random.nextInt(Topic.standardTopics.length)];
    }

    final topicKey = targetTopic.name;
    final tipsForTopic = (_tips[topicKey] as List<dynamic>?)?.cast<Map<String, dynamic>>();

    if (tipsForTopic != null && tipsForTopic.isNotEmpty) {
      final tip = tipsForTopic[_random.nextInt(tipsForTopic.length)];
      final text = _getVariant('tip_intro', {
        'topic': targetTopic.displayName,
        'title': tip['title'] as String? ?? 'Shortcut',
        'text': tip['text'] as String? ?? '',
        'example': tip['example'] as String? ?? '',
      });

      final drillConfig = PracticeConfig(
        topic: targetTopic,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        kind: SessionKind.drill,
        modeValue: 10,
        sessionSeed: SessionRandom.newSessionSeed(),
      );

      return CoachReply(
        text: text,
        actions: [
          CoachAction(
            label: 'Try ${targetTopic.displayName}',
            type: CoachActionType.startPractice,
            payload: drillConfig,
          ),
        ],
        intent: CoachIntent.tips,
        slots: slots,
      );
    }

    // Grounded recommendation for topics without pre-authored tip entries
    final perf = context.getPerformanceForTopic(targetTopic);
    final String text;
    if (perf != null && perf.totalAttempts > 0) {
      text =
          'For ${targetTopic.displayName}, you have practiced ${perf.totalAttempts} questions with ${_formatPercent(perf.accuracy)} accuracy and an average of ${_formatTime(perf.avgTimeMs)} per question. Consistent daily drills help sharpen both recognition and speed.';
    } else {
      text =
          'Developing confidence and speed in ${targetTopic.displayName} comes from regular practice. Try a quick set to build your rhythm.';
    }

    final drillConfig = PracticeConfig(
      topic: targetTopic,
      difficulty: perf?.bestDifficulty ?? Difficulty.easy,
      mode: PracticeMode.questions,
      kind: SessionKind.drill,
      modeValue: 10,
      sessionSeed: SessionRandom.newSessionSeed(),
    );

    return CoachReply(
      text: text,
      actions: [
        CoachAction(
          label: 'Try ${targetTopic.displayName}',
          type: CoachActionType.startPractice,
          payload: drillConfig,
        ),
      ],
      intent: CoachIntent.tips,
      slots: slots,
    );
  }

  CoachReply _composeMotivation(CoachSlots slots, CoachContext context) {
    final best = context.bestPracticedTopic;

    if (best != null && context.totalAnswered >= 10) {
      final text = _getVariant('motivation_with_data', {
        'total': context.totalAnswered.toString(),
        'accuracy': _formatPercent(best.accuracy),
        'best_topic': best.topic.displayName,
        'time': _formatTime(best.avgTimeMs),
        'minutes': context.reportData.weeklyComparison.currentWindow.practiceMinutes.toStringAsFixed(0),
      });

      return CoachReply(
        text: text,
        suggestions: [
          'Give me a tip',
          'Make me a plan for today',
        ],
        intent: CoachIntent.motivation,
        slots: slots,
      );
    }

    final text = _getVariant('motivation_no_data', {});
    return CoachReply(
      text: text,
      suggestions: [
        'Give me a tip',
        'Where am I weak?',
      ],
      intent: CoachIntent.motivation,
      slots: slots,
    );
  }

  CoachReply _composeStartPractice(CoachSlots slots) {
    final topic = slots.topic ?? Topic.addition;
    final difficulty = slots.difficulty ?? Difficulty.easy;
    final isTimer = slots.minutes != null;
    final mode = isTimer ? PracticeMode.timer : PracticeMode.questions;
    final modeValue = isTimer ? (slots.minutes! * 60) : (slots.questionCount ?? 20);

    final targetStr = isTimer ? '${slots.minutes} min' : '$modeValue questions';

    final text = _getVariant('start_practice_confirm', {
      'topic': topic.displayName,
      'difficulty': difficulty.displayName,
      'target': targetStr,
    });

    final config = PracticeConfig(
      topic: topic,
      difficulty: difficulty,
      mode: mode,
      kind: SessionKind.drill,
      modeValue: modeValue,
      sessionSeed: SessionRandom.newSessionSeed(),
    );

    return CoachReply(
      text: text,
      actions: [
        CoachAction(
          label: 'Start ${topic.displayName}',
          type: CoachActionType.startPractice,
          payload: config,
        ),
      ],
      intent: CoachIntent.startPractice,
      slots: slots,
    );
  }

  CoachReply _composeActivity(CoachSlots slots, CoachContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    int questionsToday = 0;
    int sessionsToday = 0;
    int msToday = 0;
    int totalMs = 0;

    for (final s in context.recentSessions) {
      totalMs += s.durationMs;
      if (s.startedAt.isAfter(todayStart) && s.startedAt.isBefore(tomorrowStart)) {
        questionsToday += s.totalQuestions;
        sessionsToday++;
        msToday += s.durationMs;
      }
    }

    final minutesToday = (msToday / 60000).ceil();
    final currentWindow = context.reportData.weeklyComparison.currentWindow;
    final questionsWeek = currentWindow.questionsAnswered;
    final sessionsWeek = currentWindow.sessionsCount;
    final minutesWeek = currentWindow.practiceMinutes.round();

    final questionsTotal = context.reportData.totalQuestionsAllTime;
    final sessionsTotal = context.recentSessions.length;
    final minutesTotal = (totalMs / 60000).ceil().clamp(minutesWeek, 999999);

    final text = _getVariant('activity', {
      'questions_today': questionsToday.toString(),
      'sessions_today': sessionsToday.toString(),
      'minutes_today': minutesToday.toString(),
      'questions_week': questionsWeek.toString(),
      'sessions_week': sessionsWeek.toString(),
      'minutes_week': minutesWeek.toString(),
      'questions_total': questionsTotal.toString(),
      'sessions_total': sessionsTotal.toString(),
      'minutes_total': minutesTotal.toString(),
    });

    return CoachReply(
      text: text,
      actions: const [
        CoachAction(
          label: 'Open stats',
          type: CoachActionType.openStats,
        ),
        CoachAction(
          label: 'Start practice',
          type: CoachActionType.startPractice,
        ),
      ],
      suggestions: const [
        'Where should I focus?',
        'Am I improving?',
        'Give me a tip',
      ],
      intent: CoachIntent.activity,
      slots: slots,
    );
  }

  // --- Helper Methods ---

  String _getVariant(String key, Map<String, String> values) {
    final list = (_phrases[key] as List<dynamic>?)?.cast<String>();
    if (list == null || list.isEmpty) {
      return 'I am ready to help with your calculations.';
    }

    // Find variants where all placeholders {placeholder} have a matching non-empty value
    final candidateIndices = <int>[];
    for (int i = 0; i < list.length; i++) {
      final variant = list[i];
      final placeholders = _findPlaceholders(variant);
      final hasAll = placeholders.every((p) => values.containsKey(p) && values[p]!.isNotEmpty);
      if (hasAll) {
        candidateIndices.add(i);
      }
    }

    final validIndices = candidateIndices.isNotEmpty
        ? candidateIndices
        : List.generate(list.length, (i) => i);

    // Pick index different from last used index
    final lastIndex = _lastUsedVariantIndices[key];
    int pickedIndex = validIndices.first;

    if (validIndices.length > 1 && lastIndex != null) {
      final available = validIndices.where((idx) => idx != lastIndex).toList();
      pickedIndex = available[_random.nextInt(available.length)];
    } else {
      pickedIndex = validIndices[_random.nextInt(validIndices.length)];
    }

    _lastUsedVariantIndices[key] = pickedIndex;
    var result = list[pickedIndex];

    values.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });

    return result;
  }

  Set<String> _findPlaceholders(String text) {
    final regex = RegExp(r'\{([a-zA-Z0-9_]+)\}');
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)!).toSet();
  }

  String _formatTime(double ms) {
    if (ms <= 0) return '0.0s';
    final totalSeconds = ms / 1000.0;
    if (totalSeconds < 60.0) {
      return '${totalSeconds.toStringAsFixed(1)}s';
    }
    final mins = totalSeconds ~/ 60;
    final secs = (totalSeconds % 60).round();
    return '${mins}m ${secs}s';
  }

  String _formatPercent(double ratio) {
    final pct = ratio <= 1.0 ? (ratio * 100.0) : ratio;
    return '${pct.toStringAsFixed(0)}%';
  }

  CoachReply _composeLearn(CoachSlots slots, {String? rawQuery}) {
    final query = (rawQuery ?? '').toLowerCase();
    final topic = slots.topic;

    // 1. Multiply by 11
    if (query.contains('11') || query.contains('eleven')) {
      return CoachReply(
        text:
            'Shortcut for × 11:\nWrite the outer digits and insert their sum in the middle!\nFor example: 35 × 11 → write 3 _ 5, sum is 3 + 5 = 8 → 385.\nIf the sum is 10 or more (like 67 × 11: 6 + 7 = 13), write 3 in the middle and carry 1 to the tens: 6 + 1 = 7 → 737!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Multiply by 11 Shortcut',
            type: CoachActionType.openLearn,
            payload: 'multiply_by_11',
          ),
        ],
      );
    }

    // 2. Multiply by 99 / 9 / 999
    if (query.contains('99') ||
        query.contains('999') ||
        query.contains('multiply by 9')) {
      return CoachReply(
        text:
            'Shortcut for × 99 / 999:\nThink of 99 as (100 − 1). Multiply by 100 first (append two zeros), then subtract the original number!\nFor example: 47 × 99 = 4,700 − 47 = 4,653. Completed in seconds entirely in your head!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Multiply by 99 Shortcut',
            type: CoachActionType.openLearn,
            payload: 'multiply_by_99',
          ),
        ],
      );
    }

    // 3. Multiply by 5 / 25 / 125
    if (query.contains(' 5') ||
        query.contains('25') ||
        query.contains('125') ||
        query.contains('power of 5')) {
      return CoachReply(
        text:
            'Shortcut for × 5 and × 25:\nHalving is much faster than multiplying!\n• For × 5: halve the number and multiply by 10 (e.g. 48 × 5 = 24 × 10 = 240).\n• For × 25: divide by 4 and multiply by 100 (e.g. 48 × 25 = 12 × 100 = 1,200)!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Multiply by 5 & 25 Shortcut',
            type: CoachActionType.openLearn,
            payload: 'multiply_by_5_25',
          ),
        ],
      );
    }

    // 4. Near 100 Multiplication
    if (query.contains('near 100') ||
        query.contains('close to 100') ||
        query.contains('base 100 mult')) {
      return CoachReply(
        text:
            'Shortcut for Near-100 Multiplication:\nFor numbers close to 100 (like 97 × 94): find the gaps from 100 (3 and 6).\n• Cross-subtract: 97 − 6 = 91 (the left part).\n• Multiply the gaps: 3 × 6 = 18 (the right part).\nCombine: 9,118!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Near-100 Shortcut',
            type: CoachActionType.openLearn,
            payload: 'near_100_mult',
          ),
        ],
      );
    }

    // 5. Squares ending in 5
    if (query.contains('ending in 5') ||
        query.contains('ending with 5') ||
        query.contains('square 5') ||
        query.contains('squares 5')) {
      return CoachReply(
        text:
            'Shortcut for Squares Ending in 5:\nTake the tens prefix (k), multiply by (k + 1), and append 25!\nFor example: 35² → 3 × (3 + 1) = 3 × 4 = 12, append 25 → 1,225.\nFor 75² → 7 × 8 = 56, append 25 → 5,625!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Squares Ending in 5 Shortcut',
            type: CoachActionType.openLearn,
            payload: 'squares_ending_5',
          ),
        ],
      );
    }

    // 6. Base Squaring (Base 25, 50, 100, 150, 200)
    if (query.contains('base 50') ||
        query.contains('base 100') ||
        query.contains('base 25') ||
        query.contains('base 150') ||
        query.contains('base 200') ||
        query.contains('base square')) {
      return CoachReply(
        text:
            'Base Squaring Shortcut:\n• Near 50 (e.g. 54²): Base = 50, deviation d = +4. Add deviation to 25: 25 + 4 = 29. Square deviation: 4² = 16 → 2,916!\n• Near 100 (e.g. 96²): Deviation d = −4. Subtract from number: 96 − 4 = 92. Square deviation: 4² = 16 → 9,216!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Base Squaring Shortcuts',
            type: CoachActionType.openLearn,
            payload: 'squares',
          ),
        ],
      );
    }

    // 7. Criss-Cross Multiplications (2x2, 3x2, 3x3)
    if (query.contains('criss') ||
        query.contains('cross') ||
        query.contains('2x2') ||
        query.contains('3x2') ||
        query.contains('3x3') ||
        (topic == Topic.multiplication && query.contains('trick'))) {
      return CoachReply(
        text:
            'Criss-Cross Vedic Multiplication:\nComputes the product in a single line without scratch work:\n1) Multiply units columns.\n2) Cross-multiply tens and units and add with carry.\n3) Multiply tens columns and add carry.\nExplore all 2×1, 2×2, 3×2, and 3×3 ruled notebooks with live carry arrows in Learn Shortcuts!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Multiplication Shortcuts',
            type: CoachActionType.openLearn,
            payload: 'multiplication',
          ),
        ],
      );
    }

    // 8. Split Percentages
    if (query.contains('split percent') ||
        query.contains('split %') ||
        (topic == Topic.percentages && query.contains('trick'))) {
      return CoachReply(
        text:
            'Split Percentages Shortcut:\nInstead of doing decimal long multiplication, break percentages into easy benchmarks:\n• 50% (half)\n• 25% (quarter)\n• 10% (move decimal 1 place left)\n• 5% (half of 10%)\n• 1% (move decimal 2 places left)\nFor example: 35% of 240 = 3 × (10% of 240) + 5% = 3 × 24 + 12 = 72 + 12 = 84!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Split Percentages Shortcut',
            type: CoachActionType.openLearn,
            payload: 'split_percentages',
          ),
        ],
      );
    }

    // 9. Fraction to Percentages / Reciprocals
    if (query.contains('fraction') ||
        query.contains('reciprocal') ||
        query.contains('percent to fraction')) {
      return CoachReply(
        text:
            'Fraction ↔ Percentage Friends:\nMemorise key fraction reciprocal pairs to skip slow division entirely:\n• 1/2 = 50%   • 1/4 = 25%   • 3/4 = 75%\n• 1/8 = 12.5% • 3/8 = 37.5% • 5/8 = 62.5% • 7/8 = 87.5%\n• 1/3 = 33.33% • 2/3 = 66.67% • 1/6 = 16.67% • 1/7 ≈ 14.28%',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Fraction–% Shortcuts',
            type: CoachActionType.openLearn,
            payload: 'fraction_pct_friends',
          ),
        ],
      );
    }

    // 10. Division Shortcuts
    if (query.contains('division') ||
        query.contains('divide') ||
        query.contains('factor division') ||
        topic == Topic.division) {
      return CoachReply(
        text:
            'Division Shortcuts:\n• Divide by 5: Double the number and divide by 10 (e.g. 140 ÷ 5 = 280 ÷ 10 = 28).\n• Factor Division: For composite divisors (14, 15, 18, 24, 36, 45), break into single digits and divide sequentially: 1,620 ÷ 45 = (1,620 ÷ 9) ÷ 5 = 180 ÷ 5 = 36!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Division Shortcuts',
            type: CoachActionType.openLearn,
            payload: 'division',
          ),
        ],
      );
    }

    // 11. General Squares
    if (topic == Topic.squares) {
      return CoachReply(
        text:
            'Squares & Roots Shortcuts:\nMaster rapid mental squaring with two core techniques:\n1) Numbers ending in 5: multiply tens by (tens + 1) and append 25 (35² = 1,225).\n2) Base Squaring: use deviations from bases 25, 50, 100, 150, and 200 to square any 2 or 3-digit number in under 3 seconds!',
        intent: CoachIntent.learn,
        slots: slots,
        actions: const [
          CoachAction(
            label: 'Open Squares Shortcuts',
            type: CoachActionType.openLearn,
            payload: 'squares',
          ),
        ],
      );
    }

    // 12. General fallback
    final text = _getVariant('learn', {});
    String? lessonPath;
    if (topic != null) {
      if (topic == Topic.multiplication) {
        lessonPath = 'multiplication';
      } else if (topic == Topic.division) {
        lessonPath = 'division';
      } else if (topic == Topic.squares) {
        lessonPath = 'squares';
      } else {
        final lessons = LessonRegistry.forTopic(topic);
        if (lessons.isNotEmpty) {
          lessonPath = lessons.first.id;
        }
      }
    }
    return CoachReply(
      text: text,
      intent: CoachIntent.learn,
      slots: slots,
      actions: [
        CoachAction(
          label: 'Open Learn Shortcuts',
          type: CoachActionType.openLearn,
          payload: lessonPath,
        ),
      ],
    );
  }

  CoachReply _composeHabits(CoachContext context, CoachSlots slots) {
    final habit = context.habitData;
    final streak = habit?.streakDays ?? 0;
    final longest = habit?.longestStreak ?? 0;
    final minsToday = habit?.practiceMinutesToday ?? 0;
    final goal = habit?.dailyGoalMinutes ?? 10;
    final activeMonth = habit?.activeDaysPast30 ?? 0;
    final weekMins = habit?.weekPracticeMinutes ?? 0;

    final vars = {
      'streak': '$streak',
      'longest_streak': '$longest',
      'minutes_today': '$minsToday',
      'goal_minutes': '$goal',
      'active_days_month': '$activeMonth',
      'week_minutes': '$weekMins',
    };

    final text = _getVariant('habits', vars);
    return CoachReply(
      text: text,
      intent: CoachIntent.habits,
      slots: slots,
    );
  }
}
