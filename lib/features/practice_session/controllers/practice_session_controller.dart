import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
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
import '../../../domain/adaptive/pattern_skill.dart';
import '../../../domain/adaptive/skill_engine.dart';
import '../../../domain/adaptive/skill_rating.dart';
import '../../../domain/adaptive/smart_question_picker.dart';
import '../../../domain/questions/question_generator_registry.dart';
import '../../../domain/questions/question_source.dart';
import '../../../domain/questions/session_random.dart';
import '../../../domain/scoring/badge_evaluator.dart';
import '../../../domain/scoring/score_calculator.dart';
import '../../../domain/scoring/session_insight_generator.dart';
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
  Future<PracticeResultData?>? _finishFuture;
  PracticeResultData? _cachedResultData;

  /// Whether the session is currently concluding or has already concluded.
  bool get isFinishingOrFinished => _isFinishing || _isFinished;

  /// Cached result data once finishSession() or quit() has saved.
  PracticeResultData? get cachedResultData => _cachedResultData;

  // In-memory running skill ratings map: "${topic.name}:${difficulty.name}" -> SkillRating
  final Map<String, SkillRating> _runningSkillRatings = {};

  // In-memory running pattern skills map: pattern -> PatternSkill
  final Map<String, PatternSkill> _runningPatternSkills = {};

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
    _soundService?.setCorrectVolume(config.effectiveCorrectSoundVolume);
    _soundService?.setWrongVolume(config.effectiveWrongSoundVolume);
  }

  QuestionSource _createDefaultQuestionSource() {
    if (state.config.mode == PracticeMode.mistakes ||
        state.config.kind == SessionKind.mistakes) {
      final mistakes =
          (state.config.initialMistakes?.cast<MistakeEntry>()) ??
              const <MistakeEntry>[];
      if (state.config.similarMistakes) {
        return SimilarMistakeQuestionSource(
          mistakes: mistakes,
          random: _random,
        );
      } else {
        return MistakeQuestionSource(mistakes: mistakes);
      }
    } else if (state.config.kind == SessionKind.drill &&
        state.config.topic != Topic.mixed &&
        state.config.difficulty != Difficulty.mixed &&
        state.config.selectedTopics.length <= 1) {
      return GeneratorQuestionSource.forTopic(
        topic: state.config.topic,
        difficulty: state.config.difficulty,
        random: _random,
        focusWeakAreas: state.config.focusOnWeakAreas,
        patternSkills: _runningPatternSkills,
      );
    } else {
      final fixedDiff = state.config.difficulty == Difficulty.mixed
          ? null
          : state.config.difficulty;
      final picker = SmartQuestionPicker(
        selectedTopics: state.config.selectedTopics,
        ratings: const {},
        patternSkills: const {},
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
        if (!mounted) return;
        _runningSkillRatings.addAll(allRatings);
        final allPatternSkills =
            await _skillRepository.getAllPatternSkillsMap();
        if (!mounted) return;
        _runningPatternSkills.addAll(allPatternSkills);
      } catch (_) {}
    }

    if (!mounted) return;

    final isMistakes = state.config.kind == SessionKind.mistakes ||
        state.config.mode == PracticeMode.mistakes;

    // In Mixed / Smart Practice, update picker with loaded ratings and due mistakes
    final isMixed = !isMistakes &&
        (state.config.kind == SessionKind.mixed ||
            state.config.mode == PracticeMode.smart ||
            state.config.topic == Topic.mixed ||
            state.config.difficulty == Difficulty.mixed ||
            state.config.selectedTopics.length > 1);

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

      if (!mounted) return;

      final fixedDiff = state.config.difficulty == Difficulty.mixed
          ? null
          : state.config.difficulty;
      final picker = SmartQuestionPicker(
        selectedTopics: state.config.selectedTopics,
        ratings: _runningSkillRatings,
        patternSkills: _runningPatternSkills,
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
    } else if (state.config.kind == SessionKind.drill &&
        state.config.topic != Topic.mixed &&
        state.config.difficulty != Difficulty.mixed &&
        state.config.selectedTopics.length <= 1) {
      _questionSource = GeneratorQuestionSource.forTopic(
        topic: state.config.topic,
        difficulty: state.config.difficulty,
        random: _random,
        focusWeakAreas: state.config.focusOnWeakAreas,
        patternSkills: _runningPatternSkills,
      );

      // If user hasn't typed yet, refresh first question with pattern question
      if (state.attempts.isEmpty &&
          state.currentInput.isEmpty &&
          !state.currentQuestionHasWrongTry) {
        final firstQ = _questionSource.next();
        state = state.copyWith(
          currentQuestion: firstQ.question,
          currentQuestionIsReplay: firstQ.isReplayedMistake,
          currentMistakeId: firstQ.mistakeId,
          clearMistakeId: firstQ.mistakeId == null,
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

  void _ensureRunning() {
    if (state.status == PracticeSessionStatus.ready) {
      start();
    }
  }

  /// Appends a digit to the current input, checking for auto-advance or wrong tries.
  /// Selects active root input box for dual-root questions (0 or 1).
  void selectInputBox(int index) {
    if (state.activeInputBox != index) {
      state = state.copyWith(activeInputBox: index);
    }
  }

  /// Immediately records answer and advances for multiple-choice comparison questions.
  void selectOption(String option) {
    _ensureRunning();
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;
    if (!state.currentQuestion.isMultipleChoice) return;

    final options = state.currentQuestion.options!;
    final selectedIndex = options.indexOf(option);
    if (selectedIndex < 0) return;

    state = state.copyWith(currentInput: option);

    final isCorrect = option == state.currentQuestion.stringAnswer ||
        selectedIndex == state.currentQuestion.correctAnswer;

    if (isCorrect) {
      _recordCorrectAndAdvance(userAnswer: selectedIndex);
    } else {
      _markWrongTry(userAnswer: selectedIndex);
    }
  }

  /// Appends a digit to the current input, checking for auto-advance or wrong tries.
  void inputDigit(String digit) {
    _ensureRunning();
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;

    if (state.currentQuestion.isDualRootQuestion) {
      final isBox0 = state.activeInputBox == 0;
      final currentTarget = isBox0 ? state.currentInput : state.secondaryInput;
      if (currentTarget.length >= 6) return;

      final updatedTarget = currentTarget + digit;
      if (isBox0) {
        state = state.copyWith(currentInput: updatedTarget);
      } else {
        state = state.copyWith(secondaryInput: updatedTarget);
      }

      if (state.config.autoSubmit) {
        _checkDualRootAutoSubmit();
      }
      return;
    }

    if (state.currentInput.length >= 8) return; // Prevent overflow

    final newInput = state.currentInput + digit;
    state = state.copyWith(currentInput: newInput);

    // AUTO-SUBMIT check
    if (state.config.autoSubmit) {
      if (state.currentQuestion.isFractionAnswer) {
        final target = state.currentQuestion.targetAnswer;
        if (newInput == target) {
          _recordCorrectAndAdvance(userAnswer: 0);
        } else if (newInput.contains('/') && newInput.length >= target.length) {
          _markWrongTry(userAnswer: 0);
        }
      } else {
        final parsed = int.tryParse(newInput);
        if (parsed != null) {
          final target = state.currentQuestion.correctAnswer;
          final targetLength = target.abs().toString().length;
          final digitsOnly = newInput.replaceAll('-', '');

          if (parsed == target) {
            _recordCorrectAndAdvance(userAnswer: parsed);
          } else if (digitsOnly.length >= targetLength && (target >= 0 || newInput.startsWith('-'))) {
            // Wrong answer reached target length: mark wrong internally, do NOT advance, keep input!
            _markWrongTry(userAnswer: parsed);
          }
        }
      }
    }
  }

  void _checkDualRootAutoSubmit({bool isManualSubmit = false}) {
    final r1 = int.tryParse(state.currentInput);
    final r2 = int.tryParse(state.secondaryInput);
    if (r1 == null || r2 == null) return;

    final targetRoots = state.currentQuestion.rootAnswers;
    if (targetRoots == null || targetRoots.length < 2) return;

    final isUnorderedMatch = (r1 == targetRoots[0] && r2 == targetRoots[1]) ||
        (r1 == targetRoots[1] && r2 == targetRoots[0]);

    if (isUnorderedMatch) {
      _recordCorrectAndAdvance(userAnswer: r1);
    } else if (isManualSubmit) {
      _markWrongTry(userAnswer: r1);
    }
  }

  /// Inserts the '/' separator for fraction answers.
  void inputSlash() {
    _ensureRunning();
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;
    if (!state.currentQuestion.isFractionAnswer) return;
    if (state.currentInput.isEmpty || state.currentInput.contains('/')) return;
    state = state.copyWith(currentInput: '${state.currentInput}/');
  }

  /// Toggles or sets negative sign if applicable.
  void inputMinus() {
    _ensureRunning();
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;

    if (state.currentQuestion.isDualRootQuestion) {
      final isBox0 = state.activeInputBox == 0;
      final currentTarget = isBox0 ? state.currentInput : state.secondaryInput;
      final String updatedTarget;
      if (currentTarget.isEmpty) {
        updatedTarget = '-';
      } else if (currentTarget == '-') {
        updatedTarget = '';
      } else if (currentTarget.startsWith('-')) {
        updatedTarget = currentTarget.substring(1);
      } else {
        updatedTarget = '-$currentTarget';
      }

      if (isBox0) {
        state = state.copyWith(currentInput: updatedTarget);
      } else {
        state = state.copyWith(secondaryInput: updatedTarget);
      }

      if (state.config.autoSubmit) {
        _checkDualRootAutoSubmit();
      }
      return;
    }

    if (state.currentInput.isEmpty) {
      state = state.copyWith(currentInput: '-');
    } else if (state.currentInput == '-') {
      state = state.copyWith(currentInput: '');
    } else if (state.currentInput.startsWith('-')) {
      state = state.copyWith(currentInput: state.currentInput.substring(1));
    } else {
      state = state.copyWith(currentInput: '-${state.currentInput}');
    }

    if (state.config.autoSubmit) {
      final parsed = int.tryParse(state.currentInput);
      if (parsed != null && parsed == state.currentQuestion.correctAnswer) {
        _recordCorrectAndAdvance(userAnswer: parsed);
      }
    }
  }

  /// Removes the last typed character.
  void deleteDigit() {
    _ensureRunning();
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;

    if (state.currentQuestion.isDualRootQuestion) {
      final isBox0 = state.activeInputBox == 0;
      final currentTarget = isBox0 ? state.currentInput : state.secondaryInput;
      if (currentTarget.isNotEmpty) {
        final updatedTarget = currentTarget.substring(0, currentTarget.length - 1);
        if (isBox0) {
          state = state.copyWith(currentInput: updatedTarget);
        } else {
          state = state.copyWith(secondaryInput: updatedTarget);
        }
      }
      return;
    }

    if (state.currentInput.isNotEmpty) {
      state = state.copyWith(
        currentInput:
            state.currentInput.substring(0, state.currentInput.length - 1),
      );
    }
  }

  /// Clears the entire current input.
  void clearInput() {
    _ensureRunning();
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;

    if (state.currentQuestion.isDualRootQuestion) {
      if (state.activeInputBox == 0) {
        state = state.copyWith(currentInput: '');
      } else {
        state = state.copyWith(secondaryInput: '');
      }
      return;
    }

    state = state.copyWith(currentInput: '');
  }

  /// Submits the current typed answer manually.
  void submit() {
    _ensureRunning();
    if (state.status != PracticeSessionStatus.running || _isFinishing || _isFinished) return;

    if (state.currentQuestion.isDualRootQuestion) {
      if (state.activeInputBox == 0 &&
          state.currentInput.isNotEmpty &&
          state.currentInput != '-' &&
          state.secondaryInput.isEmpty) {
        selectInputBox(1);
        return;
      }
      _checkDualRootAutoSubmit(isManualSubmit: true);
      return;
    }

    if (state.currentInput.isEmpty || state.currentInput == '-') return;

    if (state.currentQuestion.isFractionAnswer) {
      final input = state.currentInput.trim();
      if (!input.contains('/')) return; // Incomplete fraction
      if (input == state.currentQuestion.targetAnswer) {
        _recordCorrectAndAdvance(userAnswer: 0);
      } else {
        _markWrongTry(userAnswer: 0);
      }
      return;
    }

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
    _ensureRunning();
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

    // Update skill rating with outcome 0.0 (only for non-replays and non-mistake sessions, unless similarMistakes)
    final isMistakesSession = state.config.mode == PracticeMode.mistakes ||
        state.config.kind == SessionKind.mistakes;
    final shouldUpdateSkill = (!isMistakesSession || state.config.similarMistakes) &&
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

      final patternName = state.currentQuestion.pattern;
      if (patternName != null) {
        final patternKey = PatternSkill.makeKey(
          state.currentQuestion.topic,
          state.currentQuestion.difficulty,
          patternName,
        );
        final currentPattern = _runningPatternSkills[patternKey] ??
            PatternSkill(
              pattern: patternName,
              topic: state.currentQuestion.topic,
              difficulty: state.currentQuestion.difficulty,
            );
        _runningPatternSkills[patternKey] = _skillEngine.updatePatternSkill(
          currentPattern,
          0.0,
          timeMsIfCorrect: null,
        );
      }
    }

    final updatedAttempts = [...state.attempts, attempt];

    state = state.copyWith(
      attempts: updatedAttempts,
      currentInput: '',
      secondaryInput: '',
      activeInputBox: 0,
      currentQuestionElapsedMs: 0,
      feedback: AnswerFeedback.skipped,
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

    // In mistake replay or practice, immediately clear the mistake entry from database
    final isMistakesSession = state.config.mode == PracticeMode.mistakes ||
        state.config.kind == SessionKind.mistakes;
    if (state.currentQuestionIsReplay && state.currentMistakeId != null) {
      final targetTimeMs = AppConstants.getTargetTimeMs(
        state.currentQuestion.topic,
        state.currentQuestion.difficulty,
      );
      _mistakeRepository?.handleReplayResult(
        mistakeId: state.currentMistakeId!,
        isCorrect: true,
        isSkipped: false,
        timeMs: timeMs,
        targetTimeMs: targetTimeMs,
      );
    } else if (isMistakesSession || isCorrect) {
      _mistakeRepository?.clearMistakeByQuestionText(
        state.currentQuestion.displayText,
      );
    }

    // Update skill rating if eligible
    final shouldUpdateSkill = (!isMistakesSession || state.config.similarMistakes) &&
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

      final patternName = state.currentQuestion.pattern;
      if (patternName != null) {
        final patternKey = PatternSkill.makeKey(
          state.currentQuestion.topic,
          state.currentQuestion.difficulty,
          patternName,
        );
        final currentPattern = _runningPatternSkills[patternKey] ??
            PatternSkill(
              pattern: patternName,
              topic: state.currentQuestion.topic,
              difficulty: state.currentQuestion.difficulty,
            );
        _runningPatternSkills[patternKey] = _skillEngine.updatePatternSkill(
          currentPattern,
          outcome,
          timeMsIfCorrect: isCorrect ? timeMs : null,
        );
      }
    }

    if (state.config.correctSoundEnabled) {
      _soundService?.playCorrect();
    }

    final updatedAttempts = [...state.attempts, attempt];

    state = state.copyWith(
      attempts: updatedAttempts,
      currentInput: '',
      secondaryInput: '',
      activeInputBox: 0,
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
      secondaryInput: '',
      activeInputBox: 0,
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
  Future<PracticeResultData> finishSession() async {
    if (_finishFuture != null) {
      final res = await _finishFuture!;
      return res!;
    }
    if (_cachedResultData != null) {
      return _cachedResultData!;
    }
    if (_isFinished) {
      throw StateError('Session is already finished');
    }
    if (_isFinishing) {
      if (_finishFuture != null) {
        final res = await _finishFuture!;
        return res!;
      }
      if (_cachedResultData != null) return _cachedResultData!;
    }
    _isFinishing = true;
    _stopTicker();

    _flushCurrentQuestionIfWrongTryOnScreen();

    final completer = Completer<PracticeResultData>();
    _finishFuture = completer.future;

    state = state.copyWith(status: PracticeSessionStatus.completed);

    _saveSessionData(completed: true).then((result) {
      _cachedResultData = result;
      _isFinished = true;
      _isFinishing = false;
      completer.complete(result);
    }).catchError((error, stackTrace) {
      _isFinishing = false;
      _finishFuture = null;
      completer.completeError(error, stackTrace);
    });

    return completer.future;
  }

  /// User leaves early. Incomplete data is saved if at least 1 attempt occurred.
  ///
  /// Strictly idempotent: runs exactly once even if called multiple times.
  Future<PracticeResultData?> quit() async {
    if (_finishFuture != null) {
      return await _finishFuture!;
    }
    if (_cachedResultData != null) {
      return _cachedResultData;
    }
    if (_isFinished) {
      return _cachedResultData;
    }
    if (_isFinishing) {
      if (_finishFuture != null) return await _finishFuture!;
      if (_cachedResultData != null) return _cachedResultData;
    }
    _isFinishing = true;
    _stopTicker();

    _flushCurrentQuestionIfWrongTryOnScreen();

    final completer = Completer<PracticeResultData?>();
    _finishFuture = completer.future;

    state = state.copyWith(status: PracticeSessionStatus.abandoned);

    if (state.attempts.isEmpty) {
      _isFinished = true;
      _isFinishing = false;
      completer.complete(null);
      return null;
    }

    _saveSessionData(completed: false).then((result) {
      _cachedResultData = result;
      _isFinished = true;
      _isFinishing = false;
      completer.complete(result);
    }).catchError((error, stackTrace) {
      _isFinishing = false;
      _finishFuture = null;
      completer.completeError(error, stackTrace);
    });

    return completer.future;
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

      final isMistakesSession = state.config.mode == PracticeMode.mistakes ||
          state.config.kind == SessionKind.mistakes;
      final shouldUpdateSkill = (!isMistakesSession || state.config.similarMistakes) &&
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

        final patternName = state.currentQuestion.pattern;
        if (patternName != null) {
          final patternKey = PatternSkill.makeKey(
            state.currentQuestion.topic,
            state.currentQuestion.difficulty,
            patternName,
          );
          final currentPattern = _runningPatternSkills[patternKey] ??
              PatternSkill(
                pattern: patternName,
                topic: state.currentQuestion.topic,
                difficulty: state.currentQuestion.difficulty,
              );
          _runningPatternSkills[patternKey] = _skillEngine.updatePatternSkill(
            currentPattern,
            0.0,
            timeMsIfCorrect: null,
          );
        }
      }

      state = state.copyWith(
        attempts: [...state.attempts, attempt],
        clearWrongTry: true,
      );
    }
  }

  Future<PracticeResultData> _saveSessionData({required bool completed}) async {
    if (completed) {
      unawaited(InterstitialAdManager.instance.onSessionCompleted());
    }
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
        pattern: a.question.pattern,
      );
    }).toList();

    await _attemptRepository.insertAttempts(attemptsToSave);

    // Save updated skill ratings and pattern skills to database (for non-mistake sessions, or similar mistakes)
    final isMistakesSession = state.config.mode == PracticeMode.mistakes ||
        state.config.kind == SessionKind.mistakes;
    final shouldSaveSkills = (!isMistakesSession || state.config.similarMistakes) &&
        (_runningSkillRatings.isNotEmpty || _runningPatternSkills.isNotEmpty);

    if (_skillRepository != null && shouldSaveSkills) {
      try {
        await _skillRepository.saveRatingsAndPatternSkills(
          _runningSkillRatings.values.toList(),
          _runningPatternSkills.values.toList(),
        );
      } catch (_) {}
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

        final isMistakeSession = state.config.mode == PracticeMode.mistakes ||
            state.config.kind == SessionKind.mistakes;
        final isMistakeSuccess = attempt.isCorrect || (!attempt.isSkipped && isMistakeSession);

        if (attempt.isReplayedMistake && attempt.mistakeId != null) {
          final cleared = await _mistakeRepository.handleReplayResult(
            mistakeId: attempt.mistakeId!,
            isCorrect: isMistakeSuccess,
            isSkipped: attempt.isSkipped,
            timeMs: attempt.timeMs,
            targetTimeMs: targetTimeMs,
          );
          if (cleared) {
            clearedMistakesCount++;
          }
        } else if (isMistakeSuccess) {
          final cleared = await _mistakeRepository.clearMistakeByQuestionText(
            attempt.question.displayText,
          );
          if (cleared) {
            clearedMistakesCount++;
          }
        } else {
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

    final stillToPractice =
        await _mistakeRepository?.getMistakeCount() ?? 0;
    final wrongAttempts =
        state.attempts.where((a) => !a.isCorrect).toList();

    int totalSessionsBefore = 0;
    double? historicalAvgTimeMs;
    double? historicalAccuracy;
    double? recentAvgTimeMs;
    double? recentAccuracy;

    try {
      final allSessions = await _sessionRepository.getCompletedSessions();
      final pastSessions =
          allSessions.where((s) => s.id != savedSession.id).toList();
      totalSessionsBefore = pastSessions.length;
      if (pastSessions.isNotEmpty) {
        double totalTime = 0;
        int totalQuestions = 0;
        int totalCorrect = 0;
        for (final s in pastSessions) {
          totalQuestions += s.totalQuestions;
          totalCorrect += s.correctCount;
          if (s.correctCount > 0 && s.avgTimeMs > 0) {
            totalTime += (s.avgTimeMs * s.correctCount);
          }
        }
        if (totalQuestions > 0) {
          historicalAccuracy = totalCorrect / totalQuestions;
        }
        if (totalCorrect > 0) {
          historicalAvgTimeMs = totalTime / totalCorrect;
        }

        final recent = pastSessions.take(5).toList();
        int recentQuestions = 0;
        int recentCorrect = 0;
        double recentTime = 0;
        for (final s in recent) {
          recentQuestions += s.totalQuestions;
          recentCorrect += s.correctCount;
          if (s.correctCount > 0 && s.avgTimeMs > 0) {
            recentTime += (s.avgTimeMs * s.correctCount);
          }
        }
        if (recentQuestions > 0) {
          recentAccuracy = recentCorrect / recentQuestions;
        }
        if (recentCorrect > 0) {
          recentAvgTimeMs = recentTime / recentCorrect;
        }
      }
    } catch (_) {}

    final insightContext = SessionInsightContext(
      totalSessionsBefore: totalSessionsBefore,
      historicalAvgTimeMs: historicalAvgTimeMs,
      historicalAccuracy: historicalAccuracy,
      recentAvgTimeMs: recentAvgTimeMs,
      recentAccuracy: recentAccuracy,
      clearedMistakesCount: clearedMistakesCount,
      stillToPracticeCount: stillToPractice,
      isSimilarMistakes: state.config.similarMistakes,
    );

    String? coachInsight;
    try {
      final insightGen = await SessionInsightGenerator.loadFromBundle();
      coachInsight = insightGen.generateInsight(
        session: savedSession,
        attempts: attemptsToSave,
        summary: summary,
        kind: state.config.kind,
        mode: state.config.mode,
        context: insightContext,
      );
    } catch (_) {
      coachInsight = SessionInsightGenerator().generateInsight(
        session: savedSession,
        attempts: attemptsToSave,
        summary: summary,
        kind: state.config.kind,
        mode: state.config.mode,
        context: insightContext,
      );
    }

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
      coachInsight: coachInsight,
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
