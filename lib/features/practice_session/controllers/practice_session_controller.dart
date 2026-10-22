import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/enums.dart';
import '../../../core/services/sound_service.dart';
import '../../../data/models/attempt.dart';
import '../../../data/models/session.dart';
import '../../../data/repositories/attempt_repository.dart';
import '../../../data/repositories/mistake_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../data/repositories/skill_repository.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../domain/adaptive/mistake_entry.dart';
import '../../../domain/adaptive/skill_engine.dart';
import '../../../domain/adaptive/skill_rating.dart';
import '../../../domain/adaptive/smart_question_picker.dart';
import '../../../domain/questions/question_generator_registry.dart';
import '../../../domain/questions/question_source.dart';
import '../../../domain/questions/session_random.dart';
import '../../../domain/scoring/badge_evaluator.dart';
import '../../../domain/scoring/score_calculator.dart';
import '../../../domain/scoring/session_summary.dart';
import '../models/practice_models.dart';

/// Provider for creating a PracticeSessionController with given [PracticeConfig].
final practiceSessionControllerProvider = StateNotifierProvider.autoDispose
    .family<PracticeSessionController, PracticeSessionState, PracticeConfig>(
        (ref, config) {
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final attemptRepo = ref.watch(attemptRepositoryProvider);
  final statsRepo = ref.watch(statsRepositoryProvider);
  final skillRepo = ref.watch(skillRepositoryProvider);
  final soundService = ref.watch(soundServiceProvider);
  final mistakeRepo = ref.watch(mistakeRepositoryProvider);

  return PracticeSessionController(
    config: config,
    sessionRepository: sessionRepo,
    attemptRepository: attemptRepo,
    statsRepository: statsRepo,
    skillRepository: skillRepo,
    mistakeRepository: mistakeRepo,
    soundService: soundService,
  );
});

/// Pure controller managing state and actions for a practice session.
class PracticeSessionController extends StateNotifier<PracticeSessionState> {
  final SessionRepository _sessionRepository;
  final AttemptRepository _attemptRepository;
  final StatsRepository _statsRepository;
  final SkillRepository? _skillRepository;
  final MistakeRepository? _mistakeRepository;
  final SoundService? _soundService;
  final ScoreCalculator _scoreCalculator;
  final SessionSummaryCalculator _summaryCalculator;
  final BadgeEvaluator _badgeEvaluator;
  final SkillEngine _skillEngine;

  final Random _random;
  late QuestionSource _questionSource;

  Timer? _tickerTimer;
  DateTime _sessionStartedAt;

  // Idempotency controls to guarantee finishing/saving runs exactly once
  bool _isFinishing = false;
  bool _isFinished = false;
  Future<PracticeResultData>? _finishFuture;
  PracticeResultData? _cachedResultData;

  /// Whether the session is currently concluding or has already concluded.
  bool get isFinishingOrFinished => _isFinishing || _isFinished;

  /// Cached result data once finishSession() or quit() has saved.
  PracticeResultData? get cachedResultData => _cachedResultData;

  // In-memory running skill ratings map: "${topic.name}:${difficulty.name}" -> SkillRating
  final Map<String, SkillRating> _runningSkillRatings = {};

  PracticeSessionController({
    required PracticeConfig config,
    required SessionRepository sessionRepository,
    required AttemptRepository attemptRepository,
    required StatsRepository statsRepository,
    SkillRepository? skillRepository,
    MistakeRepository? mistakeRepository,
    SoundService? soundService,
    QuestionSource? questionSource,
    ScoreCalculator scoreCalculator = const ScoreCalculator(),
    SessionSummaryCalculator summaryCalculator =
        const SessionSummaryCalculator(),
    BadgeEvaluator badgeEvaluator = const BadgeEvaluator(),
    SkillEngine skillEngine = const SkillEngine(),
    DateTime? startTime,
  })  : _sessionRepository = sessionRepository,
        _attemptRepository = attemptRepository,
        _statsRepository = statsRepository,
        _skillRepository = skillRepository,
        _mistakeRepository = mistakeRepository,
        _soundService = soundService,
        _scoreCalculator = scoreCalculator,
        _summaryCalculator = summaryCalculator,
        _badgeEvaluator = badgeEvaluator,
        _skillEngine = skillEngine,
        _random = SessionRandom.forTopic(config.sessionSeed, config.topic),
        _sessionStartedAt = startTime ?? DateTime.now(),
        super(_createInitialState(config, startTime ?? DateTime.now())) {
    _questionSource = questionSource ?? _createDefaultQuestionSource();
    _startNextQuestion(isInitial: true);
    _initSkillRatings();
    _soundService?.setVolume(config.soundVolume);
  }

  QuestionSource _createDefaultQuestionSource() {
    if (state.config.mode == PracticeMode.mistakes ||
        state.config.kind == SessionKind.mistakes) {
      final mistakes =
          (state.config.initialMistakes?.cast<MistakeEntry>()) ??
              const <MistakeEntry>[];
      return MistakeQuestionSource(mistakes: mistakes);
    } else if (state.config.kind == SessionKind.drill &&
        state.config.topic != Topic.mixed &&
        state.config.difficulty != Difficulty.mixed &&
        state.config.selectedTopics.length <= 1) {
      return GeneratorQuestionSource.forTopic(
        topic: state.config.topic,
        difficulty: state.config.difficulty,
        random: _random,
      );
    } else {
      final fixedDiff = state.config.difficulty == Difficulty.mixed
          ? null
          : state.config.difficulty;
      final picker = SmartQuestionPicker(
        selectedTopics: state.config.selectedTopics,
        ratings: const {},
        dueMistakes: const [],
        random: _random,
        totalSessionQuestions: state.config.modeValue,
        fixedDifficulty: fixedDiff,
        focusOnWeakAreas: state.config.focusOnWeakAreas,
      );
      return SmartQuestionSource(picker: picker);
    }
  }

  Future<void> _initSkillRatings() async {
    if (_skillRepository != null) {
      try {
        final allRatings = await _skillRepository.getAllRatingsMap();
        _runningSkillRatings.addAll(allRatings);
      } catch (_) {}
    }

    // In Mixed / Smart Practice, update picker with loaded ratings and due mistakes
    final isMixed = state.config.kind == SessionKind.mixed ||
        state.config.mode == PracticeMode.smart ||
        state.config.topic == Topic.mixed ||
        state.config.difficulty == Difficulty.mixed ||
        state.config.selectedTopics.length > 1;

    if (isMixed) {
      List<MistakeEntry> dueMistakes = [];
      if (_mistakeRepository != null) {
        try {
          final counter = _mistakeRepository.getSmartQuestionCounter();
          dueMistakes = await _mistakeRepository.getDueMistakes(
            currentCounter: counter,
            topics: state.config.selectedTopics,
          );
        } catch (_) {}
      }

      final fixedDiff = state.config.difficulty == Difficulty.mixed
          ? null
          : state.config.difficulty;
      final picker = SmartQuestionPicker(
        selectedTopics: state.config.selectedTopics,
        ratings: Map.from(_runningSkillRatings),
        dueMistakes: dueMistakes,
        random: _random,
        totalSessionQuestions: state.config.modeValue,
        fixedDifficulty: fixedDiff,
        focusOnWeakAreas: state.config.focusOnWeakAreas,
      );
      _questionSource = SmartQuestionSource(picker: picker);

      // If user hasn't typed yet, refresh first question with real smart question
      if (state.attempts.isEmpty &&
          state.currentInput.isEmpty &&
          !state.currentQuestionHasWrongTry) {
        final firstSmart = _questionSource.next();
        state = state.copyWith(
          currentQuestion: firstSmart.question,
          currentQuestionIsReplay: firstSmart.isReplayedMistake,
          currentMistakeId: firstSmart.mistakeId,
          clearMistakeId: firstSmart.mistakeId == null,
        );
      }
    }
  }

  static PracticeSessionState _createInitialState(
    PracticeConfig config,
    DateTime startTime,
  ) {
    final initialTopic = config.topic == Topic.mixed
        ? (config.selectedTopics.isNotEmpty
            ? config.selectedTopics.first
            : Topic.addition)
        : config.topic;
    final initialDifficulty = config.difficulty == Difficulty.mixed
        ? Difficulty.easy
        : config.difficulty;

    final gen = QuestionGeneratorRegistry.getGenerator(initialTopic);
    final rand = SessionRandom.forTopic(config.sessionSeed, initialTopic);
    final firstQ = gen.generate(
      difficulty: initialDifficulty,
      random: rand,
    );

    return PracticeSessionState(
      config: config,
      status: PracticeSessionStatus.ready,
      currentQuestion: firstQ,
      questionIndex: 0,
      currentInput: '',
      attempts: const [],
      timeRemainingMs: config.mode == PracticeMode.timer
          ? config.modeValue * 1000
          : 0,
      totalElapsedMs: 0,
      currentQuestionElapsedMs: 0,
    );
  }

  /// Starts the practice session and begins the ticker timer.
  void start() {
    if (state.status == PracticeSessionStatus.running) return;
    _sessionStartedAt = DateTime.now();
    state = state.copyWith(status: PracticeSessionStatus.running);
    _startTicker();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      tick(50);
    });
  }

  void _stopTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  /// Advances session time by [deltaMs]. Called by timer or directly in tests.
  void tick(int deltaMs) {
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;

    final newElapsed = state.totalElapsedMs + deltaMs;
    final newQuestionElapsed = state.currentQuestionElapsedMs + deltaMs;

    if (state.config.mode == PracticeMode.timer) {
      final newRemaining = state.timeRemainingMs - deltaMs;
      if (newRemaining <= 0) {
        state = state.copyWith(
          timeRemainingMs: 0,
          totalElapsedMs: state.config.modeValue * 1000,
          currentQuestionElapsedMs: newQuestionElapsed,
        );
        finishSession();
        return;
      }

      state = state.copyWith(
        timeRemainingMs: newRemaining,
        totalElapsedMs: newElapsed,
        currentQuestionElapsedMs: newQuestionElapsed,
      );
    } else {
      state = state.copyWith(
        totalElapsedMs: newElapsed,
        currentQuestionElapsedMs: newQuestionElapsed,
      );
    }
  }

  /// Appends a digit to the current input, checking for auto-advance or wrong tries.
  void inputDigit(String digit) {
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;
    if (state.currentInput.length >= 8) return; // Prevent overflow

    final newInput = state.currentInput + digit;
    state = state.copyWith(currentInput: newInput);

    // AUTO-SUBMIT check
    if (state.config.autoSubmit) {
      final parsed = int.tryParse(newInput);
      if (parsed != null) {
        final targetLength =
            state.currentQuestion.correctAnswer.abs().toString().length;
        final digitsOnly = newInput.replaceAll('-', '');

        if (parsed == state.currentQuestion.correctAnswer) {
          _recordCorrectAndAdvance(userAnswer: parsed);
        } else if (digitsOnly.length >= targetLength) {
          // Wrong answer reached target length: mark wrong internally, do NOT advance, keep input!
          _markWrongTry(userAnswer: parsed);
        }
      }
    }
  }

  /// Toggles or sets negative sign if applicable.
  void inputMinus() {
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;
    if (state.currentInput.isEmpty) {
      state = state.copyWith(currentInput: '-');
    } else if (state.currentInput == '-') {
      state = state.copyWith(currentInput: '');
    }
  }

  /// Removes the last typed character.
  void deleteDigit() {
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;
    if (state.currentInput.isNotEmpty) {
      state = state.copyWith(
        currentInput:
            state.currentInput.substring(0, state.currentInput.length - 1),
      );
    }
  }

  /// Clears the entire current input.
  void clearInput() {
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;
    state = state.copyWith(currentInput: '');
  }

  /// Submits the current typed answer manually.
  void submit() {
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;
    if (state.currentInput.isEmpty || state.currentInput == '-') return;

    final parsed = int.tryParse(state.currentInput);
    if (parsed == null) return;

    if (parsed == state.currentQuestion.correctAnswer) {
      _recordCorrectAndAdvance(userAnswer: parsed);
    } else {
      _markWrongTry(userAnswer: parsed);
    }
  }

  /// Skips the current question.
  /// If there was a wrong try, it counts as wrong (not skipped).
  /// If there was no wrong try, it counts as skipped.
  void skip() {
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;

    final timeMs = state.currentQuestionElapsedMs;
    final hadWrongTry = state.currentQuestionHasWrongTry;

    if (!hadWrongTry && state.config.wrongSoundEnabled) {
      _soundService?.playWrong();
    }

    final isCorrect = false;
    final isSkipped = !hadWrongTry;
    final storedUserAnswer = hadWrongTry
        ? state.currentQuestionFirstWrongAnswer
        : null;

    final attempt = SessionAttempt(
      question: state.currentQuestion,
      userAnswer: storedUserAnswer,
      isCorrect: isCorrect,
      isSkipped: isSkipped,
      timeMs: timeMs,
      points: 0.0,
      isReplayedMistake: state.currentQuestionIsReplay,
      mistakeId: state.currentMistakeId,
    );

    // Update skill rating with outcome 0.0 (only for non-replays and non-mistake sessions)
    final shouldUpdateSkill = state.config.mode != PracticeMode.mistakes &&
        !state.currentQuestionIsReplay &&
        state.currentQuestion.topic != Topic.mixed;

    if (shouldUpdateSkill) {
      final key =
          '${state.currentQuestion.topic.name}:${state.currentQuestion.difficulty.name}';
      final currentRating = _runningSkillRatings[key] ??
          SkillRating(
            topic: state.currentQuestion.topic,
            difficulty: state.currentQuestion.difficulty,
          );
      _runningSkillRatings[key] = _skillEngine.updateRating(
        currentRating,
        0.0,
        timeMsIfCorrect: null,
      );
    }

    final updatedAttempts = [...state.attempts, attempt];

    state = state.copyWith(
      attempts: updatedAttempts,
      currentInput: '',
      currentQuestionElapsedMs: 0,
      feedback: isSkipped ? AnswerFeedback.skipped : AnswerFeedback.none,
      feedbackTick: state.feedbackTick + 1,
      clearWrongTry: true,
    );

    // Check Question Count Mode finish condition
    final isCountMode = state.config.mode != PracticeMode.timer;
    if (isCountMode && updatedAttempts.length >= state.config.modeValue) {
      finishSession();
      return;
    }

    _startNextQuestion();
  }

  /// Marks the current question wrong internally on the first wrong try.
  /// Does NOT advance, and keeps the typed input intact.
  void _markWrongTry({required int userAnswer}) {
    if (state.currentQuestionHasWrongTry) {
      return;
    }

    if (state.config.wrongSoundEnabled) {
      _soundService?.playWrong();
    }

    state = state.copyWith(
      currentQuestionHasWrongTry: true,
      currentQuestionFirstWrongAnswer: userAnswer,
      feedback: AnswerFeedback.wrong,
      feedbackTick: state.feedbackTick + 1,
    );
  }

  /// Handles correct answer input: records question, updates skill rating, and advances.
  void _recordCorrectAndAdvance({required int userAnswer}) {
    final timeMs = state.currentQuestionElapsedMs;
    final hadWrongTry = state.currentQuestionHasWrongTry;

    final isCorrect = !hadWrongTry;
    final storedUserAnswer = hadWrongTry
        ? (state.currentQuestionFirstWrongAnswer ?? userAnswer)
        : userAnswer;

    final points = hadWrongTry
        ? 0.0
        : _scoreCalculator.calculatePoints(
            isCorrect: true,
            isSkipped: false,
            difficulty: state.currentQuestion.difficulty,
            topic: state.currentQuestion.topic,
            timeMs: timeMs,
          );

    final attempt = SessionAttempt(
      question: state.currentQuestion,
      userAnswer: storedUserAnswer,
      isCorrect: isCorrect,
      isSkipped: false,
      timeMs: timeMs,
      points: points,
      isReplayedMistake: state.currentQuestionIsReplay,
      mistakeId: state.currentMistakeId,
    );

    // Update skill rating if eligible
    final shouldUpdateSkill = state.config.mode != PracticeMode.mistakes &&
        !state.currentQuestionIsReplay &&
        state.currentQuestion.topic != Topic.mixed;

    if (shouldUpdateSkill) {
      final targetTimeMs = AppConstants.getTargetTimeMs(
        state.currentQuestion.topic,
        state.currentQuestion.difficulty,
      );
      final outcome = hadWrongTry
          ? 0.0
          : _skillEngine.calculateOutcomeScore(
              isCorrect: true,
              isSkipped: false,
              timeMs: timeMs,
              targetTimeMs: targetTimeMs,
            );
      final key =
          '${state.currentQuestion.topic.name}:${state.currentQuestion.difficulty.name}';
      final currentRating = _runningSkillRatings[key] ??
          SkillRating(
            topic: state.currentQuestion.topic,
            difficulty: state.currentQuestion.difficulty,
          );
      _runningSkillRatings[key] = _skillEngine.updateRating(
        currentRating,
        outcome,
        timeMsIfCorrect: isCorrect ? timeMs : null,
      );
    }

    if (state.config.correctSoundEnabled) {
      _soundService?.playCorrect();
    }

    final updatedAttempts = [...state.attempts, attempt];

    state = state.copyWith(
      attempts: updatedAttempts,
      currentInput: '',
      currentQuestionElapsedMs: 0,
      feedback: AnswerFeedback.correct,
      feedbackTick: state.feedbackTick + 1,
      clearWrongTry: true,
    );

    // Check Question Count Mode finish condition
    final isCountMode = state.config.mode != PracticeMode.timer;
    if (isCountMode && updatedAttempts.length >= state.config.modeValue) {
      finishSession();
      return;
    }

    _startNextQuestion();
  }

  void _startNextQuestion({bool isInitial = false}) {
    final nextQData = _questionSource.next(
      previousQuestion: isInitial ? null : state.currentQuestion,
      recentAttempts: state.attempts,
    );

    state = state.copyWith(
      currentQuestion: nextQData.question,
      questionIndex: isInitial ? 1 : state.questionIndex + 1,
      currentInput: '',
      currentQuestionElapsedMs: 0,
      clearWrongTry: true,
      currentQuestionIsReplay: nextQData.isReplayedMistake,
      currentMistakeId: nextQData.mistakeId,
      clearMistakeId: nextQData.mistakeId == null,
    );
  }

  /// Pauses the practice session.
  void pause() {
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;
    _stopTicker();
    state = state.copyWith(status: PracticeSessionStatus.paused);
  }

  /// Resumes the practice session from a paused state.
  void resume() {
    if (state.status != PracticeSessionStatus.paused || _isFinishing || _isFinished) return;
    state = state.copyWith(status: PracticeSessionStatus.running);
    _startTicker();
  }

  /// Concludes a completed practice session and persists session + attempts.
  ///
  /// Strictly idempotent: runs exactly once even if called multiple times or
  /// concurrently from different triggers (e.g. timer expiring, question count reaching limit,
  /// and UI state listeners).
  Future<PracticeResultData> finishSession() {
    if (_finishFuture != null) {
      return _finishFuture!;
    }
    if (_cachedResultData != null) {
      return Future.value(_cachedResultData!);
    }
    if (_isFinished) {
      return Future.error(StateError('Session is already finished'));
    }
    _isFinishing = true;
    _stopTicker();

    _flushCurrentQuestionIfWrongTryOnScreen();

    state = state.copyWith(status: PracticeSessionStatus.completed);
    final future = _saveSessionData(completed: true);
    _finishFuture = future;

    return future.then((result) {
      _cachedResultData = result;
      _isFinished = true;
      return result;
    }).catchError((error) {
      _isFinishing = false;
      _finishFuture = null;
      throw error;
    });
  }

  /// User leaves early. Incomplete data is saved if at least 1 attempt occurred.
  ///
  /// Strictly idempotent: runs exactly once even if called multiple times.
  Future<PracticeResultData?> quit() {
    if (_finishFuture != null) {
      return _finishFuture!;
    }
    if (_isFinished) {
      return Future.value(_cachedResultData);
    }
    _isFinishing = true;
    _stopTicker();

    _flushCurrentQuestionIfWrongTryOnScreen();

    state = state.copyWith(status: PracticeSessionStatus.abandoned);

    if (state.attempts.isEmpty) {
      _isFinished = true;
      return Future.value(null);
    }

    final future = _saveSessionData(completed: false);
    _finishFuture = future;

    return future.then((result) {
      _cachedResultData = result;
      _isFinished = true;
      return result;
    }).catchError((error) {
      _isFinishing = false;
      _finishFuture = null;
      throw error;
    });
  }

  /// Discards the session completely: nothing is saved to database,
  /// no attempts, no skill updates, no mistake updates, no counter changes.
  void discard() {
    if (_isFinishing || _isFinished) return;
    _isFinishing = true;
    _stopTicker();
    state = state.copyWith(status: PracticeSessionStatus.abandoned);
    _isFinished = true;
  }

  /// Flushes the current question as a wrong attempt if a wrong try was entered.
  void _flushCurrentQuestionIfWrongTryOnScreen() {
    if (state.currentQuestionHasWrongTry) {
      final attempt = SessionAttempt(
        question: state.currentQuestion,
        userAnswer: state.currentQuestionFirstWrongAnswer,
        isCorrect: false,
        isSkipped: false,
        timeMs: state.currentQuestionElapsedMs,
        points: 0.0,
        isReplayedMistake: state.currentQuestionIsReplay,
        mistakeId: state.currentMistakeId,
      );

      final shouldUpdateSkill = state.config.mode != PracticeMode.mistakes &&
          !state.currentQuestionIsReplay &&
          state.currentQuestion.topic != Topic.mixed;

      if (shouldUpdateSkill) {
        final key =
            '${state.currentQuestion.topic.name}:${state.currentQuestion.difficulty.name}';
        final currentRating = _runningSkillRatings[key] ??
            SkillRating(
              topic: state.currentQuestion.topic,
              difficulty: state.currentQuestion.difficulty,
            );
        _runningSkillRatings[key] = _skillEngine.updateRating(
          currentRating,
          0.0,
          timeMsIfCorrect: null,
        );
      }

      state = state.copyWith(
        attempts: [...state.attempts, attempt],
        clearWrongTry: true,
      );
    }
  }

  Future<PracticeResultData> _saveSessionData({required bool completed}) async {
    final attemptResults = state.attempts
        .map((a) => AttemptResult(
              isCorrect: a.isCorrect,
              isSkipped: a.isSkipped,
              timeMs: a.timeMs,
              points: a.points,
            ))
        .toList();

    final summary = _summaryCalculator.calculate(attemptResults);

    final totalDurationMs = state.config.mode == PracticeMode.timer
        ? state.totalElapsedMs
        : summary.totalTimeMs;

    final sessionRecord = Session(
      topic: state.config.topic,
      difficulty: state.config.difficulty,
      mode: state.config.mode,
      modeValue: state.config.modeValue,
      kind: state.config.kind,
      startedAt: _sessionStartedAt,
      durationMs: totalDurationMs,
      totalQuestions: summary.totalQuestions,
      correctCount: summary.correctCount,
      wrongCount: summary.wrongCount,
      skippedCount: summary.skippedCount,
      accuracy: summary.accuracy,
      avgTimeMs: summary.avgTimeMsPerCorrect,
      score: summary.totalScore,
      completed: completed,
    );

    final isDrill = state.config.kind == SessionKind.drill &&
        state.config.topic != Topic.mixed &&
        state.config.difficulty != Difficulty.mixed &&
        state.config.mode != PracticeMode.mistakes;

    bool isNewBestScore = false;
    bool isNewTop3Time = false;

    if (completed && isDrill) {
      isNewBestScore = await _evaluateBestScore(sessionRecord.score);
      isNewTop3Time = await _evaluateTop3Time(sessionRecord);
    }

    // Save session to database
    final sessionId = await _sessionRepository.insertSession(sessionRecord);
    final savedSession = sessionRecord.copyWith(id: sessionId);

    // Save attempts to database (using question's own topic & difficulty)
    final attemptsToSave = state.attempts.map((a) {
      return Attempt(
        sessionId: sessionId,
        topic: a.question.topic,
        difficulty: a.question.difficulty,
        questionText: a.question.displayText,
        operandA: a.question.operandA,
        operandB: a.question.operandB,
        correctAnswer: a.question.correctAnswer,
        userAnswer: a.userAnswer,
        isCorrect: a.isCorrect,
        isSkipped: a.isSkipped,
        timeMs: a.timeMs,
        createdAt: DateTime.now(),
      );
    }).toList();

    await _attemptRepository.insertAttempts(attemptsToSave);

    // Save updated skill ratings to database (for non-mistake sessions)
    if (_skillRepository != null &&
        state.config.mode != PracticeMode.mistakes &&
        state.config.kind != SessionKind.mistakes &&
        _runningSkillRatings.isNotEmpty) {
      for (final rating in _runningSkillRatings.values) {
        try {
          await _skillRepository.saveRating(rating);
        } catch (_) {}
      }
    }

    // Process Mistake Bank additions and resurfacing replays
    int newMistakesSavedCount = 0;
    int clearedMistakesCount = 0;

    if (_mistakeRepository != null && state.attempts.isNotEmpty) {
      if (state.config.kind == SessionKind.mixed || state.config.mode == PracticeMode.smart) {
        await _mistakeRepository
            .incrementSmartQuestionCounter(state.attempts.length);
      }

      for (final attempt in state.attempts) {
        final targetTimeMs = AppConstants.getTargetTimeMs(
          attempt.question.topic,
          attempt.question.difficulty,
        );

        if (attempt.isReplayedMistake && attempt.mistakeId != null) {
          final cleared = await _mistakeRepository.handleReplayResult(
            mistakeId: attempt.mistakeId!,
            isCorrect: attempt.isCorrect,
            isSkipped: attempt.isSkipped,
            timeMs: attempt.timeMs,
            targetTimeMs: targetTimeMs,
          );
          if (cleared) {
            clearedMistakesCount++;
          }
        } else {
          final isSlow =
              attempt.isCorrect && (attempt.timeMs > 2 * targetTimeMs);
          if (!attempt.isCorrect || attempt.isSkipped || isSlow) {
            final added = await _mistakeRepository.recordAttempt(
              question: attempt.question,
              isCorrect: attempt.isCorrect,
              isSkipped: attempt.isSkipped,
              timeMs: attempt.timeMs,
              targetTimeMs: targetTimeMs,
            );
            if (added) {
              newMistakesSavedCount++;
            }
          }
        }
      }
    }

    final stillToPractice =
        await _mistakeRepository?.getMistakeCount() ?? 0;
    final wrongAttempts =
        state.attempts.where((a) => !a.isCorrect).toList();

    return PracticeResultData(
      savedSession: savedSession,
      savedAttempts: attemptsToSave,
      summary: summary,
      config: state.config,
      isNewBestScore: isNewBestScore,
      isNewTop3Time: isNewTop3Time,
      wrongAttempts: wrongAttempts,
      newMistakesSavedCount: newMistakesSavedCount,
      clearedMistakesCount: clearedMistakesCount,
      stillToPracticeCount: stillToPractice,
    );
  }

  Future<bool> _evaluateBestScore(double score) async {
    final prevBest = await _statsRepository.getBestScore(
      state.config.topic,
      state.config.difficulty,
      state.config.mode,
      state.config.modeValue,
    );
    return _badgeEvaluator.isNewBestScore(
      completed: true,
      newScore: score,
      previousBestScore: prevBest,
    );
  }

  Future<bool> _evaluateTop3Time(Session session) async {
    final currentTopTimes = await _statsRepository.getTopBestTimes(
      state.config.topic,
      state.config.difficulty,
      state.config.mode,
      state.config.modeValue,
    );
    return _badgeEvaluator.isNewTop3Time(
      completed: true,
      accuracy: session.accuracy,
      mode: state.config.mode,
      modeValue: state.config.modeValue,
      durationMs: session.durationMs,
      avgTimeMs: session.avgTimeMs,
      existingTop3Sessions: currentTopTimes,
    );
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
