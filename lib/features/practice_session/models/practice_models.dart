import '../../../core/enums/enums.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/session.dart';
import '../../../domain/questions/question.dart';
import '../../../domain/scoring/session_summary.dart';

/// Unified configuration model for launching a practice session.
class SessionConfig {
  final List<Topic> selectedTopics;
  final Difficulty? difficulty; // null means Auto
  final bool focusOnWeakAreas;
  final PracticeMode mode; // PracticeMode.timer or PracticeMode.questions
  final int targetValue; // Seconds for timer, question count for questions
  final SessionKind kind;

  const SessionConfig({
    required this.selectedTopics,
    this.difficulty,
    this.focusOnWeakAreas = true,
    required this.mode,
    required this.targetValue,
    SessionKind? kind,
  }) : kind = kind ??
            ((selectedTopics.length == 1 &&
                    difficulty != null &&
                    difficulty != Difficulty.mixed)
                ? SessionKind.drill
                : (mode == PracticeMode.mistakes
                    ? SessionKind.mistakes
                    : SessionKind.mixed));

  Topic get primaryTopic =>
      selectedTopics.length == 1 ? selectedTopics.first : Topic.mixed;

  Difficulty get effectiveDifficulty => difficulty ?? Difficulty.mixed;

  SessionConfig copyWith({
    List<Topic>? selectedTopics,
    Difficulty? difficulty,
    bool clearDifficulty = false,
    bool? focusOnWeakAreas,
    PracticeMode? mode,
    int? targetValue,
    SessionKind? kind,
  }) {
    return SessionConfig(
      selectedTopics: selectedTopics ?? this.selectedTopics,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      focusOnWeakAreas: focusOnWeakAreas ?? this.focusOnWeakAreas,
      mode: mode ?? this.mode,
      targetValue: targetValue ?? this.targetValue,
      kind: kind ?? this.kind,
    );
  }
}

/// Configuration for starting a practice session.
class PracticeConfig {
  final Topic topic;
  final Difficulty difficulty;
  final PracticeMode mode;
  final int modeValue; // Seconds for timer mode, question count for question mode
  final int sessionSeed;
  final bool autoSubmit;
  final bool hapticsEnabled;
  final VibrationStrength vibrationStrength;
  final bool soundEnabled;
  final bool correctSoundEnabled;
  final bool wrongSoundEnabled;
  final double soundVolume;
  final double? correctSoundVolume;
  final double? wrongSoundVolume;
  final KeypadStyle keypadStyle;
  final List<Topic> selectedTopics;
  final List<dynamic>? initialMistakes;
  final SessionKind kind;
  final bool focusOnWeakAreas;
  final bool similarMistakes;

  bool get autoAdvance => autoSubmit;
  double get effectiveCorrectSoundVolume => correctSoundVolume ?? soundVolume;
  double get effectiveWrongSoundVolume => wrongSoundVolume ?? soundVolume;

  const PracticeConfig({
    required this.topic,
    required this.difficulty,
    required this.mode,
    required this.modeValue,
    required this.sessionSeed,
    SessionKind? kind,
    this.focusOnWeakAreas = true,
    this.similarMistakes = false,
    bool? autoSubmit,
    bool? autoAdvance,
    this.hapticsEnabled = true,
    this.vibrationStrength = VibrationStrength.medium,
    bool? soundEnabled,
    bool? correctSoundEnabled,
    bool? wrongSoundEnabled,
    this.soundVolume = 1.0,
    this.correctSoundVolume,
    this.wrongSoundVolume,
    this.keypadStyle = KeypadStyle.phone,
    List<Topic>? selectedTopics,
    this.initialMistakes,
  })  : kind = kind ??
            (topic != Topic.mixed && difficulty != Difficulty.mixed
                ? SessionKind.drill
                : (mode == PracticeMode.mistakes
                    ? SessionKind.mistakes
                    : SessionKind.mixed)),
        autoSubmit = autoSubmit ?? autoAdvance ?? true,
        correctSoundEnabled = correctSoundEnabled ?? soundEnabled ?? false,
        wrongSoundEnabled = wrongSoundEnabled ?? soundEnabled ?? false,
        soundEnabled = soundEnabled ?? (correctSoundEnabled == true || wrongSoundEnabled == true),
        selectedTopics = selectedTopics ?? const [];

  factory PracticeConfig.fromSessionConfig({
    required SessionConfig sessionConfig,
    int? sessionSeed,
    bool autoSubmit = true,
    bool hapticsEnabled = true,
    VibrationStrength vibrationStrength = VibrationStrength.medium,
    bool soundEnabled = false,
    bool correctSoundEnabled = false,
    bool wrongSoundEnabled = false,
    double soundVolume = 1.0,
    double? correctSoundVolume,
    double? wrongSoundVolume,
    KeypadStyle keypadStyle = KeypadStyle.phone,
    List<dynamic>? initialMistakes,
  }) {
    return PracticeConfig(
      topic: sessionConfig.primaryTopic,
      difficulty: sessionConfig.effectiveDifficulty,
      mode: sessionConfig.mode,
      modeValue: sessionConfig.targetValue,
      kind: sessionConfig.kind,
      focusOnWeakAreas: sessionConfig.focusOnWeakAreas,
      selectedTopics: sessionConfig.selectedTopics,
      sessionSeed: sessionSeed ?? DateTime.now().millisecondsSinceEpoch,
      autoSubmit: autoSubmit,
      hapticsEnabled: hapticsEnabled,
      vibrationStrength: vibrationStrength,
      soundEnabled: soundEnabled,
      correctSoundEnabled: correctSoundEnabled,
      wrongSoundEnabled: wrongSoundEnabled,
      soundVolume: soundVolume,
      correctSoundVolume: correctSoundVolume,
      wrongSoundVolume: wrongSoundVolume,
      keypadStyle: keypadStyle,
      initialMistakes: initialMistakes,
    );
  }

  SessionConfig get sessionConfig => SessionConfig(
        selectedTopics: selectedTopics.isNotEmpty
            ? selectedTopics
            : (topic != Topic.mixed ? [topic] : Topic.standardTopics),
        difficulty: difficulty == Difficulty.mixed ? null : difficulty,
        focusOnWeakAreas: focusOnWeakAreas,
        mode: mode,
        targetValue: modeValue,
        kind: kind,
      );

  PracticeConfig copyWith({
    Topic? topic,
    Difficulty? difficulty,
    PracticeMode? mode,
    int? modeValue,
    int? sessionSeed,
    SessionKind? kind,
    bool? focusOnWeakAreas,
    bool? similarMistakes,
    bool? autoSubmit,
    bool? autoAdvance,
    bool? hapticsEnabled,
    VibrationStrength? vibrationStrength,
    bool? soundEnabled,
    bool? correctSoundEnabled,
    bool? wrongSoundEnabled,
    double? soundVolume,
    double? correctSoundVolume,
    double? wrongSoundVolume,
    KeypadStyle? keypadStyle,
    List<Topic>? selectedTopics,
    List<dynamic>? initialMistakes,
  }) {
    final newCorrectSound = correctSoundEnabled ?? this.correctSoundEnabled;
    final newWrongSound = wrongSoundEnabled ?? this.wrongSoundEnabled;

    return PracticeConfig(
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      mode: mode ?? this.mode,
      modeValue: modeValue ?? this.modeValue,
      sessionSeed: sessionSeed ?? this.sessionSeed,
      kind: kind ?? this.kind,
      focusOnWeakAreas: focusOnWeakAreas ?? this.focusOnWeakAreas,
      similarMistakes: similarMistakes ?? this.similarMistakes,
      autoSubmit: autoSubmit ?? autoAdvance ?? this.autoSubmit,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      vibrationStrength: vibrationStrength ?? this.vibrationStrength,
      correctSoundEnabled: newCorrectSound,
      wrongSoundEnabled: newWrongSound,
      soundEnabled: soundEnabled ?? (newCorrectSound || newWrongSound),
      soundVolume: soundVolume ?? this.soundVolume,
      correctSoundVolume: correctSoundVolume ?? this.correctSoundVolume,
      wrongSoundVolume: wrongSoundVolume ?? this.wrongSoundVolume,
      keypadStyle: keypadStyle ?? this.keypadStyle,
      selectedTopics: selectedTopics ?? this.selectedTopics,
      initialMistakes: initialMistakes ?? this.initialMistakes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topic': topic.name,
      'difficulty': difficulty.name,
      'mode': mode.name,
      'modeValue': modeValue,
      'sessionSeed': sessionSeed,
      'autoSubmit': autoSubmit,
      'hapticsEnabled': hapticsEnabled,
      'vibrationStrength': vibrationStrength.name,
      'soundEnabled': soundEnabled,
      'correctSoundEnabled': correctSoundEnabled,
      'wrongSoundEnabled': wrongSoundEnabled,
      'soundVolume': soundVolume,
      'keypadStyle': keypadStyle.name,
      'selectedTopics': selectedTopics.map((t) => t.name).toList(),
      'kind': kind.name,
      'focusOnWeakAreas': focusOnWeakAreas,
    };
  }

  factory PracticeConfig.fromMap(Map<String, dynamic> map) {
    Topic parseTopic(String? name) {
      return Topic.values.firstWhere(
        (t) => t.name == name,
        orElse: () => Topic.addition,
      );
    }

    Difficulty parseDifficulty(String? name) {
      return Difficulty.values.firstWhere(
        (d) => d.name == name,
        orElse: () => Difficulty.easy,
      );
    }

    PracticeMode parseMode(String? name) {
      return PracticeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => PracticeMode.questions,
      );
    }

    SessionKind parseKind(String? name) {
      return SessionKind.values.firstWhere(
        (k) => k.name == name,
        orElse: () => SessionKind.drill,
      );
    }

    VibrationStrength parseVibration(String? name) {
      return VibrationStrength.values.firstWhere(
        (v) => v.name == name,
        orElse: () => VibrationStrength.medium,
      );
    }

    KeypadStyle parseKeypad(String? name) {
      return KeypadStyle.values.firstWhere(
        (k) => k.name == name,
        orElse: () => KeypadStyle.phone,
      );
    }

    final rawTopics = map['selectedTopics'] as List?;
    final topics = rawTopics != null
        ? rawTopics.map((e) => parseTopic(e.toString())).toList()
        : <Topic>[];

    return PracticeConfig(
      topic: parseTopic(map['topic'] as String?),
      difficulty: parseDifficulty(map['difficulty'] as String?),
      mode: parseMode(map['mode'] as String?),
      modeValue: (map['modeValue'] as num?)?.toInt() ?? 20,
      sessionSeed: (map['sessionSeed'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      autoSubmit: map['autoSubmit'] as bool? ?? true,
      hapticsEnabled: map['hapticsEnabled'] as bool? ?? true,
      vibrationStrength: parseVibration(map['vibrationStrength'] as String?),
      soundEnabled: map['soundEnabled'] as bool? ?? false,
      correctSoundEnabled: map['correctSoundEnabled'] as bool? ?? false,
      wrongSoundEnabled: map['wrongSoundEnabled'] as bool? ?? false,
      soundVolume: (map['soundVolume'] as num?)?.toDouble() ?? 1.0,
      keypadStyle: parseKeypad(map['keypadStyle'] as String?),
      selectedTopics: topics,
      kind: parseKind(map['kind'] as String?),
      focusOnWeakAreas: map['focusOnWeakAreas'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeConfig &&
          runtimeType == other.runtimeType &&
          topic == other.topic &&
          difficulty == other.difficulty &&
          mode == other.mode &&
          modeValue == other.modeValue &&
          sessionSeed == other.sessionSeed &&
          autoSubmit == other.autoSubmit &&
          hapticsEnabled == other.hapticsEnabled &&
          vibrationStrength == other.vibrationStrength &&
          soundEnabled == other.soundEnabled &&
          correctSoundEnabled == other.correctSoundEnabled &&
          wrongSoundEnabled == other.wrongSoundEnabled &&
          soundVolume == other.soundVolume &&
          correctSoundVolume == other.correctSoundVolume &&
          wrongSoundVolume == other.wrongSoundVolume &&
          keypadStyle == other.keypadStyle &&
          kind == other.kind &&
          focusOnWeakAreas == other.focusOnWeakAreas &&
          similarMistakes == other.similarMistakes;

  @override
  int get hashCode => Object.hash(
        topic,
        difficulty,
        mode,
        modeValue,
        sessionSeed,
        autoSubmit,
        hapticsEnabled,
        vibrationStrength,
        soundEnabled,
        correctSoundEnabled,
        wrongSoundEnabled,
        soundVolume,
        correctSoundVolume,
        wrongSoundVolume,
        keypadStyle,
        kind,
        focusOnWeakAreas,
        similarMistakes,
      );
}

/// Record of an attempt on a single question during a practice session.
class SessionAttempt {
  final Question question;
  final int? userAnswer;
  final bool isCorrect;
  final bool isSkipped;
  final int timeMs;
  final double points;
  final bool isReplayedMistake;
  final int? mistakeId;

  const SessionAttempt({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.isSkipped,
    required this.timeMs,
    required this.points,
    this.isReplayedMistake = false,
    this.mistakeId,
  });
}

/// Lifecycle status of the practice session.
enum PracticeSessionStatus {
  ready,
  running,
  paused,
  completed,
  abandoned,
}

/// Answer feedback type for visual flash and haptics.
enum AnswerFeedback {
  none,
  correct,
  wrong,
  skipped,
}

/// Immutable state of an active practice session.
class PracticeSessionState {
  final PracticeConfig config;
  final PracticeSessionStatus status;
  final Question currentQuestion;
  final int questionIndex; // 0-indexed count of questions presented
  final String currentInput;
  final List<SessionAttempt> attempts;
  final int timeRemainingMs; // For timer mode countdown
  final int totalElapsedMs; // Total active time (paused time excluded)
  final int currentQuestionElapsedMs; // Time spent on current question
  final AnswerFeedback feedback;
  final int feedbackTick; // Incrementing counter to distinguish repeated feedback
  final bool currentQuestionHasWrongTry;
  final int? currentQuestionFirstWrongAnswer;
  final bool currentQuestionIsReplay;
  final int? currentMistakeId;

  const PracticeSessionState({
    required this.config,
    required this.status,
    required this.currentQuestion,
    required this.questionIndex,
    required this.currentInput,
    required this.attempts,
    required this.timeRemainingMs,
    required this.totalElapsedMs,
    required this.currentQuestionElapsedMs,
    this.feedback = AnswerFeedback.none,
    this.feedbackTick = 0,
    this.currentQuestionHasWrongTry = false,
    this.currentQuestionFirstWrongAnswer,
    this.currentQuestionIsReplay = false,
    this.currentMistakeId,
  });

  PracticeSessionState copyWith({
    PracticeConfig? config,
    PracticeSessionStatus? status,
    Question? currentQuestion,
    int? questionIndex,
    String? currentInput,
    List<SessionAttempt>? attempts,
    int? timeRemainingMs,
    int? totalElapsedMs,
    int? currentQuestionElapsedMs,
    AnswerFeedback? feedback,
    int? feedbackTick,
    bool? currentQuestionHasWrongTry,
    int? currentQuestionFirstWrongAnswer,
    bool clearWrongTry = false,
    bool? currentQuestionIsReplay,
    int? currentMistakeId,
    bool clearMistakeId = false,
  }) {
    return PracticeSessionState(
      config: config ?? this.config,
      status: status ?? this.status,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      questionIndex: questionIndex ?? this.questionIndex,
      currentInput: currentInput ?? this.currentInput,
      attempts: attempts ?? this.attempts,
      timeRemainingMs: timeRemainingMs ?? this.timeRemainingMs,
      totalElapsedMs: totalElapsedMs ?? this.totalElapsedMs,
      currentQuestionElapsedMs:
          currentQuestionElapsedMs ?? this.currentQuestionElapsedMs,
      feedback: feedback ?? this.feedback,
      feedbackTick: feedbackTick ?? this.feedbackTick,
      currentQuestionHasWrongTry: clearWrongTry
          ? false
          : (currentQuestionHasWrongTry ?? this.currentQuestionHasWrongTry),
      currentQuestionFirstWrongAnswer: clearWrongTry
          ? null
          : (currentQuestionFirstWrongAnswer ??
              this.currentQuestionFirstWrongAnswer),
      currentQuestionIsReplay: currentQuestionIsReplay ?? this.currentQuestionIsReplay,
      currentMistakeId: clearMistakeId
          ? null
          : (currentMistakeId ?? this.currentMistakeId),
    );
  }
}

/// Complete results payload passed from session to the Results screen.
class PracticeResultData {
  final Session? savedSession; // null if abandoned with 0 answers
  final List<Attempt> savedAttempts;
  final SessionSummary summary;
  final PracticeConfig config;
  final bool isNewBestScore;
  final bool isNewTop3Time;
  final List<SessionAttempt> wrongAttempts;
  final int newMistakesSavedCount;
  final int clearedMistakesCount;
  final int stillToPracticeCount;
  final String? coachInsight;

  const PracticeResultData({
    required this.savedSession,
    required this.savedAttempts,
    required this.summary,
    required this.config,
    required this.isNewBestScore,
    required this.isNewTop3Time,
    required this.wrongAttempts,
    this.newMistakesSavedCount = 0,
    this.clearedMistakesCount = 0,
    this.stillToPracticeCount = 0,
    this.coachInsight,
  });
}
