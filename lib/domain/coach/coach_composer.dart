import 'dart:convert';
import 'dart:math' as math;
import '../../core/enums/enums.dart';
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
}
