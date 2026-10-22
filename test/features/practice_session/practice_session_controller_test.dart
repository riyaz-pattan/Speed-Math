import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/core/services/sound_service.dart';
import 'package:speed_math_with_ai/data/models/attempt.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'package:speed_math_with_ai/data/repositories/attempt_repository.dart';
import 'package:speed_math_with_ai/data/repositories/session_repository.dart';
import 'package:speed_math_with_ai/data/repositories/mistake_repository.dart';
import 'package:speed_math_with_ai/data/repositories/skill_repository.dart';
import 'package:speed_math_with_ai/data/repositories/stats_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_rating.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';
import 'package:speed_math_with_ai/features/practice_session/controllers/practice_session_controller.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';

class FakeSessionRepository extends SessionRepository {
  List<Session> savedSessions = [];

  @override
  Future<int> insertSession(Session session) async {
    savedSessions.add(session);
    return savedSessions.length;
  }
}

class FakeAttemptRepository extends AttemptRepository {
  List<Attempt> savedAttempts = [];

  @override
  Future<List<int>> insertAttempts(List<Attempt> attempts) async {
    savedAttempts.addAll(attempts);
    return List.generate(attempts.length, (i) => i + 1);
  }
}

class FakeStatsRepository extends StatsRepository {
  double? mockBestScore;
  List<Session> mockTopBestTimes = [];

  @override
  Future<double?> getBestScore(
    Topic topic,
    Difficulty difficulty,
    PracticeMode mode,
    int modeValue,
  ) async {
    return mockBestScore;
  }

  @override
  Future<List<Session>> getTopBestTimes(
    Topic topic,
    Difficulty difficulty,
    PracticeMode mode,
    int modeValue, {
    int limit = 3,
  }) async {
    return mockTopBestTimes;
  }
}

class FakeSoundService implements SoundService {
  int correctPlayCount = 0;
  int wrongPlayCount = 0;
  double _volume = 1.0;

  @override
  double get volume => _volume;

  @override
  double get effectiveVolume => SoundConstants.toEffectiveVolume(_volume);

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  @override
  Future<void> playCorrect() async {
    correctPlayCount++;
  }

  @override
  Future<void> playWrong() async {
    wrongPlayCount++;
  }

  @override
  void dispose() {}

  void reset() {
    correctPlayCount = 0;
    wrongPlayCount = 0;
    _volume = 1.0;
  }
}

class FakeSkillRepository extends SkillRepository {
  final Map<String, SkillRating> ratings = {};

  @override
  Future<SkillRating> getOrCreateRating(Topic topic, Difficulty difficulty) async {
    final key = '${topic.name}:${difficulty.name}';
    return ratings[key] ??
        SkillRating(
          topic: topic,
          difficulty: difficulty,
          mastery: 0.5,
          attemptsCount: 0,
        );
  }

  @override
  Future<int> saveRating(SkillRating rating) async {
    final key = '${rating.topic.name}:${rating.difficulty.name}';
    ratings[key] = rating;
    return 1;
  }
}

class FakeMistakeRepository extends MistakeRepository {
  List<Question> recordedMistakes = [];
  int smartCounter = 0;
  List<int> replayedMistakeIds = [];

  @override
  int getSmartQuestionCounter() => smartCounter;

  @override
  Future<int> incrementSmartQuestionCounter([int delta = 1]) async {
    smartCounter += delta;
    return smartCounter;
  }

  @override
  Future<bool> recordAttempt({
    required Question question,
    required bool isCorrect,
    required bool isSkipped,
    required int timeMs,
    int? targetTimeMs,
  }) async {
    recordedMistakes.add(question);
    return true;
  }

  @override
  Future<bool> handleReplayResult({
    required int mistakeId,
    required bool isCorrect,
    required bool isSkipped,
    required int timeMs,
    required int targetTimeMs,
  }) async {
    replayedMistakeIds.add(mistakeId);
    return isCorrect;
  }

  @override
  Future<int> getMistakeCount() async => recordedMistakes.length;
}

void main() {
  late FakeSessionRepository fakeSessionRepo;
  late FakeAttemptRepository fakeAttemptRepo;
  late FakeStatsRepository fakeStatsRepo;
  late FakeSoundService fakeSoundService;
  late FakeSkillRepository fakeSkillRepo;
  late FakeMistakeRepository fakeMistakeRepo;

  setUp(() {
    fakeSessionRepo = FakeSessionRepository();
    fakeAttemptRepo = FakeAttemptRepository();
    fakeStatsRepo = FakeStatsRepository();
    fakeSoundService = FakeSoundService();
    fakeSkillRepo = FakeSkillRepository();
    fakeMistakeRepo = FakeMistakeRepository();
  });

  PracticeSessionController createController({
    Topic topic = Topic.addition,
    Difficulty difficulty = Difficulty.easy,
    PracticeMode mode = PracticeMode.questions,
    int modeValue = 5,
    bool autoAdvance = true,
    bool? soundEnabled = true,
    bool? correctSoundEnabled,
    bool? wrongSoundEnabled,
    double soundVolume = 1.0,
    List<Topic>? selectedTopics,
    SkillRepository? skillRepository,
    MistakeRepository? mistakeRepository,
  }) {
    final config = PracticeConfig(
      topic: topic,
      difficulty: difficulty,
      mode: mode,
      modeValue: modeValue,
      sessionSeed: 12345,
      autoAdvance: autoAdvance,
      soundEnabled: soundEnabled,
      correctSoundEnabled: correctSoundEnabled,
      wrongSoundEnabled: wrongSoundEnabled,
      soundVolume: soundVolume,
      selectedTopics: selectedTopics,
    );

    return PracticeSessionController(
      config: config,
      sessionRepository: fakeSessionRepo,
      attemptRepository: fakeAttemptRepo,
      statsRepository: fakeStatsRepo,
      skillRepository: skillRepository ?? fakeSkillRepo,
      mistakeRepository: mistakeRepository ?? fakeMistakeRepo,
      soundService: fakeSoundService,
    );
  }

  group('PracticeSessionController', () {
    test('initial state is ready with first question', () {
      final controller = createController();
      final state = controller.state;

      expect(state.status, PracticeSessionStatus.ready);
      expect(state.currentQuestion, isNotNull);
      expect(state.attempts, isEmpty);
      expect(state.currentInput, isEmpty);
      expect(state.totalElapsedMs, 0);
      expect(state.currentQuestionHasWrongTry, isFalse);
    });

    test('auto-advance ON advances instantly when correct answer is typed on first try', () {
      final controller = createController(autoAdvance: true, soundEnabled: true);
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final answerStr = firstQ.correctAnswer.toString();

      for (var i = 0; i < answerStr.length; i++) {
        controller.inputDigit(answerStr[i]);
      }

      expect(controller.state.attempts.length, 1);
      final attempt = controller.state.attempts.first;
      expect(attempt.isCorrect, isTrue);
      expect(attempt.isSkipped, isFalse);
      expect(attempt.userAnswer, firstQ.correctAnswer);
      expect(attempt.points, greaterThan(0));
      expect(controller.state.currentInput, isEmpty);
      expect(controller.state.currentQuestion, isNot(equals(firstQ)));
      expect(fakeSoundService.correctPlayCount, 1);
      expect(fakeSoundService.wrongPlayCount, 0);
    });

    test('auto-advance OFF requires manual Submit button press for correct answer', () {
      final controller = createController(autoAdvance: false);
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final answerStr = firstQ.correctAnswer.toString();

      for (var i = 0; i < answerStr.length; i++) {
        controller.inputDigit(answerStr[i]);
      }

      // Does not advance yet
      expect(controller.state.attempts, isEmpty);
      expect(controller.state.currentInput, answerStr);

      controller.submit();

      expect(controller.state.attempts.length, 1);
      expect(controller.state.attempts.first.isCorrect, isTrue);
      expect(controller.state.currentInput, isEmpty);
      expect(fakeSoundService.correctPlayCount, 1);
    });

    test('auto-submit ON: wrong answer does NOT advance, keeps typed input, plays wrong sound', () {
      final controller = createController(autoAdvance: true, soundEnabled: true);
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;

      // Construct a wrong number with the same digit count as correct answer
      var wrongStr = '';
      for (var i = 0; i < targetLength; i++) {
        wrongStr += '9';
      }
      if (int.parse(wrongStr) == firstQ.correctAnswer) {
        wrongStr = '';
        for (var i = 0; i < targetLength; i++) {
          wrongStr += '8';
        }
      }

      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }

      // Must NOT advance!
      expect(controller.state.attempts, isEmpty);
      expect(controller.state.currentQuestion, equals(firstQ));
      // Input must be KEPT so user can backspace
      expect(controller.state.currentInput, wrongStr);
      // Internally marked as wrong
      expect(controller.state.currentQuestionHasWrongTry, isTrue);
      expect(controller.state.currentQuestionFirstWrongAnswer, int.parse(wrongStr));
      // Wrong sound played once
      expect(fakeSoundService.wrongPlayCount, 1);
      expect(fakeSoundService.correctPlayCount, 0);
    });

    test('correcting after a wrong try advances, stores first wrong answer, scored as 0 pts', () {
      final controller = createController(autoAdvance: true, soundEnabled: true);
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;

      var wrongStr = '9' * targetLength;
      if (int.parse(wrongStr) == firstQ.correctAnswer) {
        wrongStr = '8' * targetLength;
      }

      // 1. Type wrong answer
      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }
      expect(controller.state.currentQuestionHasWrongTry, isTrue);
      expect(fakeSoundService.wrongPlayCount, 1);

      // 2. Clear/backspace and type correct answer
      controller.clearInput();
      final correctStr = firstQ.correctAnswer.toString();
      for (var i = 0; i < correctStr.length; i++) {
        controller.inputDigit(correctStr[i]);
      }

      // Now it advances!
      expect(controller.state.attempts.length, 1);
      final attempt = controller.state.attempts.first;
      // "First try counts": marked as wrong!
      expect(attempt.isCorrect, isFalse);
      expect(attempt.isSkipped, isFalse);
      expect(attempt.userAnswer, int.parse(wrongStr));
      expect(attempt.points, 0.0);
      expect(controller.state.currentQuestion, isNot(equals(firstQ)));
      // Plays correct sound when solved
      expect(fakeSoundService.correctPlayCount, 1);
    });

    test('first try counts: typing multiple wrong answers only marks wrong once and plays sound once', () {
      final controller = createController(autoAdvance: true, soundEnabled: true);
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;

      var wrongStr1 = '9' * targetLength;
      if (int.parse(wrongStr1) == firstQ.correctAnswer) wrongStr1 = '8' * targetLength;

      // First wrong try
      for (var i = 0; i < wrongStr1.length; i++) {
        controller.inputDigit(wrongStr1[i]);
      }
      expect(fakeSoundService.wrongPlayCount, 1);
      expect(controller.state.currentQuestionFirstWrongAnswer, int.parse(wrongStr1));

      // Second wrong try
      controller.clearInput();
      var wrongStr2 = '7' * targetLength;
      if (int.parse(wrongStr2) == firstQ.correctAnswer) wrongStr2 = '6' * targetLength;
      for (var i = 0; i < wrongStr2.length; i++) {
        controller.inputDigit(wrongStr2[i]);
      }

      // Still only 1 wrong count, sound not repeated, first wrong answer preserved
      expect(fakeSoundService.wrongPlayCount, 1);
      expect(controller.state.currentQuestionFirstWrongAnswer, int.parse(wrongStr1));
    });

    test('auto-submit OFF: submit on wrong answer marks wrong, keeps input, does not advance', () {
      final controller = createController(autoAdvance: false, soundEnabled: true);
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final wrongAnswer = firstQ.correctAnswer + 5;
      final wrongStr = wrongAnswer.toString();

      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }

      // Submit on wrong answer
      controller.submit();

      expect(controller.state.attempts, isEmpty);
      expect(controller.state.currentInput, wrongStr);
      expect(controller.state.currentQuestionHasWrongTry, isTrue);
      expect(controller.state.currentQuestionFirstWrongAnswer, wrongAnswer);
      expect(fakeSoundService.wrongPlayCount, 1);

      // Submit on empty does nothing
      controller.clearInput();
      controller.submit();
      expect(controller.state.attempts, isEmpty);
    });

    test('skip without wrong try is recorded as skipped (is_skipped = 1), plays wrong sound if enabled', () {
      final controller = createController(soundEnabled: true);
      controller.start();

      controller.skip();

      expect(controller.state.attempts.length, 1);
      final attempt = controller.state.attempts.first;
      expect(attempt.isCorrect, isFalse);
      expect(attempt.isSkipped, isTrue);
      expect(attempt.userAnswer, isNull);
      expect(fakeSoundService.correctPlayCount, 0);
      expect(fakeSoundService.wrongPlayCount, 1); // Phase 6B: skip plays wrong sound
    });

    test('skip after a wrong try is recorded as wrong (is_skipped = 0, is_correct = 0)', () {
      final controller = createController(autoAdvance: true, soundEnabled: true);
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;
      var wrongStr = '9' * targetLength;
      if (int.parse(wrongStr) == firstQ.correctAnswer) wrongStr = '8' * targetLength;

      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }

      // Now user decides to skip
      controller.skip();

      expect(controller.state.attempts.length, 1);
      final attempt = controller.state.attempts.first;
      expect(attempt.isCorrect, isFalse);
      expect(attempt.isSkipped, isFalse, reason: 'Skip after wrong try counts as wrong, not skipped');
      expect(attempt.userAnswer, int.parse(wrongStr));
      expect(fakeSoundService.correctPlayCount, 0);
    });

    test('timer mode ends: question with wrong try on screen is flushed and counted as wrong', () async {
      final controller = createController(
        mode: PracticeMode.timer,
        modeValue: 60,
      );
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;
      var wrongStr = '9' * targetLength;
      if (int.parse(wrongStr) == firstQ.correctAnswer) wrongStr = '8' * targetLength;

      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }
      expect(controller.state.attempts, isEmpty);

      // Timer expires
      controller.tick(60000);

      expect(controller.state.status, PracticeSessionStatus.completed);
      // Because it had a wrong try on screen, it must be counted as wrong!
      expect(controller.state.attempts.length, 1);
      final attempt = controller.state.attempts.first;
      expect(attempt.isCorrect, isFalse);
      expect(attempt.userAnswer, int.parse(wrongStr));
    });

    test('quit with a wrong try on screen saves partial session with wrong counted', () async {
      final controller = createController();
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;
      var wrongStr = '9' * targetLength;
      if (int.parse(wrongStr) == firstQ.correctAnswer) wrongStr = '8' * targetLength;

      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }

      final result = await controller.quit();

      expect(result, isNotNull);
      expect(result!.savedAttempts.length, 1);
      expect(result.savedAttempts.first.isCorrect, isFalse);
      expect(result.savedAttempts.first.userAnswer, int.parse(wrongStr));
      expect(fakeSessionRepo.savedSessions.length, 1);
      expect(fakeSessionRepo.savedSessions.first.wrongCount, 1);
    });

    test('sound setting OFF: neither correct nor wrong sounds are played', () {
      final controller = createController(autoAdvance: true, soundEnabled: false);
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;

      var wrongStr = '9' * targetLength;
      if (int.parse(wrongStr) == firstQ.correctAnswer) wrongStr = '8' * targetLength;

      // Type wrong answer
      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }
      expect(fakeSoundService.wrongPlayCount, 0);

      // Correct answer
      controller.clearInput();
      final correctStr = firstQ.correctAnswer.toString();
      for (var i = 0; i < correctStr.length; i++) {
        controller.inputDigit(correctStr[i]);
      }
      expect(fakeSoundService.correctPlayCount, 0);
    });

    test('pause stops time tracking and resume continues without counting paused time', () {
      final controller = createController();
      controller.start();

      controller.tick(1500);
      expect(controller.state.totalElapsedMs, 1500);

      controller.pause();
      expect(controller.state.status, PracticeSessionStatus.paused);

      controller.tick(5000);
      expect(controller.state.totalElapsedMs, 1500);

      controller.resume();
      expect(controller.state.status, PracticeSessionStatus.running);

      controller.tick(1000);
      expect(controller.state.totalElapsedMs, 2500);
    });

    test('correctSound alone plays on correct answer only, not on wrong or skip', () {
      final controller = createController(
        correctSoundEnabled: true,
        wrongSoundEnabled: false,
      );
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;
      var wrongStr = '9' * targetLength;
      if (int.parse(wrongStr) == firstQ.correctAnswer) wrongStr = '8' * targetLength;

      // Type wrong answer -> wrong sound should NOT play
      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }
      expect(fakeSoundService.wrongPlayCount, 0);

      // Now enter correct answer -> correct sound SHOULD play
      controller.clearInput();
      final correctStr = firstQ.correctAnswer.toString();
      for (var i = 0; i < correctStr.length; i++) {
        controller.inputDigit(correctStr[i]);
      }
      expect(fakeSoundService.correctPlayCount, 1);

      // Skip the next question -> wrong sound should NOT play
      controller.skip();
      expect(fakeSoundService.wrongPlayCount, 0);
    });

    test('wrongSound alone plays on wrong try and skip, but not on correct answer', () {
      final controller = createController(
        correctSoundEnabled: false,
        wrongSoundEnabled: true,
      );
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;
      var wrongStr = '9' * targetLength;
      if (int.parse(wrongStr) == firstQ.correctAnswer) wrongStr = '8' * targetLength;

      // Type wrong answer -> wrong sound SHOULD play
      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }
      expect(fakeSoundService.wrongPlayCount, 1);

      // Now enter correct answer -> correct sound should NOT play
      controller.clearInput();
      final correctStr = firstQ.correctAnswer.toString();
      for (var i = 0; i < correctStr.length; i++) {
        controller.inputDigit(correctStr[i]);
      }
      expect(fakeSoundService.correctPlayCount, 0);
    });

    test('skip on a question with NO prior wrong try plays wrong sound when wrongSoundEnabled is true', () {
      final controller = createController(
        correctSoundEnabled: false,
        wrongSoundEnabled: true,
      );
      controller.start();

      controller.skip();
      expect(fakeSoundService.wrongPlayCount, 1);
    });

    test('skip after a wrong try plays NOTHING extra (wrong sound already played once)', () {
      final controller = createController(
        correctSoundEnabled: false,
        wrongSoundEnabled: true,
      );
      controller.start();

      final firstQ = controller.state.currentQuestion;
      final targetLength = firstQ.correctAnswer.abs().toString().length;
      var wrongStr = '9' * targetLength;
      if (int.parse(wrongStr) == firstQ.correctAnswer) wrongStr = '8' * targetLength;

      for (var i = 0; i < wrongStr.length; i++) {
        controller.inputDigit(wrongStr[i]);
      }
      expect(fakeSoundService.wrongPlayCount, 1);

      // Skip after wrong try
      controller.skip();
      // Count must still be 1!
      expect(fakeSoundService.wrongPlayCount, 1);
    });

    test('volume value is passed to SoundService on controller initialization', () {
      createController(soundVolume: 0.65);
      expect(fakeSoundService.volume, 0.65);
    });

    test('Smart Practice saves attempts with their question topics, updates skill ratings, records mistakes, and excludes best scores', () async {
      final controller = createController(
        topic: Topic.mixed,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.smart,
        modeValue: 2,
        selectedTopics: [Topic.addition, Topic.subtraction],
      );
      controller.start();

      // Answer question 1 correctly
      final q1 = controller.state.currentQuestion;
      final a1Str = q1.correctAnswer.toString();
      for (var i = 0; i < a1Str.length; i++) {
        controller.inputDigit(a1Str[i]);
      }

      // Answer question 2 with a wrong try then skip
      controller.inputDigit('9');
      controller.skip();

      // Session ends after 2 questions
      expect(controller.state.status, PracticeSessionStatus.completed);

      // Await async finishSession saving
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verify attempts saved
      expect(fakeAttemptRepo.savedAttempts.length, 2);
      expect(fakeAttemptRepo.savedAttempts.first.topic, isNot(Topic.mixed));

      // Verify session saved with mode smart and topic mixed
      expect(fakeSessionRepo.savedSessions.length, 1);
      final session = fakeSessionRepo.savedSessions.first;
      expect(session.mode, PracticeMode.smart);
      expect(session.topic, Topic.mixed);

      // Verify skill ratings were updated and saved
      expect(fakeSkillRepo.ratings.isNotEmpty, isTrue);

      // Verify global smart question counter was incremented
      expect(fakeMistakeRepo.smartCounter, 2);

      // Verify wrong/skipped question was recorded in mistake repo
      expect(fakeMistakeRepo.recordedMistakes.length, 1);
    });

    test('Mistake Practice does NOT update skill ratings and excludes best scores', () async {
      final controller = createController(
        topic: Topic.mixed,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.mistakes,
        modeValue: 2,
      );
      controller.start();

      // Answer question 1 correctly
      final q1 = controller.state.currentQuestion;
      final a1Str = q1.correctAnswer.toString();
      for (var i = 0; i < a1Str.length; i++) {
        controller.inputDigit(a1Str[i]);
      }

      // Skip question 2
      controller.skip();

      expect(controller.state.status, PracticeSessionStatus.completed);

      // Await async finishSession saving
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Skill ratings MUST NOT be updated in Mistake Practice
      expect(fakeSkillRepo.ratings.isEmpty, isTrue);

      // Session saved as mistakes mode
      expect(fakeSessionRepo.savedSessions.length, 1);
      expect(fakeSessionRepo.savedSessions.first.mode, PracticeMode.mistakes);
    });
  });

  group('Finish Idempotency & Duplicate Prevention Tests (Phase 7A.1)', () {
    test('finishSession() called twice saves exactly one session and one set of attempts', () async {
      final controller = createController(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 1,
      );
      controller.start();

      // Answer 1 question
      final q = controller.state.currentQuestion;
      final ans = q.correctAnswer.toString();
      for (var i = 0; i < ans.length; i++) {
        controller.inputDigit(ans[i]);
      }

      // Controller auto-finishes when modeValue is reached, but call finishSession() twice more
      final future1 = controller.finishSession();
      final future2 = controller.finishSession();

      final res1 = await future1;
      final res2 = await future2;

      // Both futures return identical result object
      expect(identical(res1, res2), isTrue);
      expect(res1.savedSession?.id, res2.savedSession?.id);

      // Verify exactly ONE session and ONE attempt set in repository
      expect(fakeSessionRepo.savedSessions.length, 1);
      expect(fakeAttemptRepo.savedAttempts.length, 1);
    });

    test('dual triggers: question completion + UI listener finishSession() saves exactly once', () async {
      final controller = createController(
        topic: Topic.multiplication,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 2,
      );
      controller.start();

      // Question 1 correct
      final q1 = controller.state.currentQuestion;
      for (final ch in q1.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      // Question 2 skip -> triggers finish internally inside skip()
      controller.skip();
      expect(controller.state.status, PracticeSessionStatus.completed);

      // Simulate UI listener reacting to status == completed by calling finishSession()
      final listenerResult = await controller.finishSession();

      expect(listenerResult.savedSession?.id, isNotNull);
      expect(fakeSessionRepo.savedSessions.length, 1);
      expect(fakeAttemptRepo.savedAttempts.length, 2);
    });

    test('dual triggers: timer expiring at 0ms and submit at exact same tick saves exactly once', () async {
      final controller = createController(
        topic: Topic.subtraction,
        difficulty: Difficulty.easy,
        mode: PracticeMode.timer,
        modeValue: 60,
      );
      controller.start();

      // Answer 1 question normally
      final q = controller.state.currentQuestion;
      for (final ch in q.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      // Fast forward time to expire timer
      controller.tick(60000); // Remaining reaches 0 -> triggers finishSession()
      expect(controller.state.status, PracticeSessionStatus.completed);

      // Concurrently submit or call finishSession again
      controller.inputDigit('5');
      controller.submit();
      controller.skip();
      final res = await controller.finishSession();

      expect(res.savedSession?.id, isNotNull);
      expect(fakeSessionRepo.savedSessions.length, 1);
      expect(fakeAttemptRepo.savedAttempts.length, 1);
    });

    test('quit() called multiple times saves at most one session and one set of attempts', () async {
      final controller = createController(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 10,
      );
      controller.start();

      // Answer 1 question then quit
      final q = controller.state.currentQuestion;
      for (final ch in q.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      final f1 = controller.quit();
      final f2 = controller.quit();

      final res1 = await f1;
      final res2 = await f2;

      expect(identical(res1, res2), isTrue);
      expect(fakeSessionRepo.savedSessions.length, 1);
      expect(fakeSessionRepo.savedSessions.first.completed, isFalse);
      expect(fakeAttemptRepo.savedAttempts.length, 1);
    });

    test('quit() with 0 attempts saves 0 sessions and returns null idempotently', () async {
      final controller = createController(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 10,
      );
      controller.start();

      final res1 = await controller.quit();
      final res2 = await controller.quit();

      expect(res1, isNull);
      expect(res2, isNull);
      expect(fakeSessionRepo.savedSessions.isEmpty, isTrue);
      expect(fakeAttemptRepo.savedAttempts.isEmpty, isTrue);
    });

    test('Smart Practice finishSession() called multiple times increments smart counter exactly once', () async {
      fakeMistakeRepo.smartCounter = 0;
      fakeMistakeRepo.recordedMistakes.clear();

      final controller = createController(
        topic: Topic.mixed,
        difficulty: Difficulty.mixed,
        mode: PracticeMode.smart,
        modeValue: 2,
        selectedTopics: [Topic.addition],
      );
      controller.start();

      // Answer 1 correct
      final q1 = controller.state.currentQuestion;
      for (final ch in q1.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      // Question 2 wrong try + skip
      controller.inputDigit('9');
      controller.skip(); // Triggers finish internally

      // Call finishSession 3 times rapidly
      final results = await Future.wait([
        controller.finishSession(),
        controller.finishSession(),
        controller.finishSession(),
      ]);

      expect(results[0].savedSession?.id, results[1].savedSession?.id);
      expect(results[1].savedSession?.id, results[2].savedSession?.id);

      // Smart counter incremented by 2 (the 2 attempts), NOT 6!
      expect(fakeMistakeRepo.smartCounter, 2);

      // Only 1 mistake recorded in bank, not duplicated
      expect(fakeMistakeRepo.recordedMistakes.length, 1);

      // Exactly 1 session saved
      expect(fakeSessionRepo.savedSessions.length, 1);
    });

    test('controller.discard() stops session and saves 0 sessions/attempts even after answers', () async {
      final controller = createController(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 10,
      );
      controller.start();

      // Answer 1 question
      final q = controller.state.currentQuestion;
      for (final ch in q.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      expect(controller.state.attempts.length, 1);

      // Discard session
      controller.discard();

      expect(controller.state.status, PracticeSessionStatus.abandoned);
      expect(fakeSessionRepo.savedSessions.isEmpty, isTrue);
      expect(fakeAttemptRepo.savedAttempts.isEmpty, isTrue);

      // Calling quit() or finishSession() after discard() does not save
      final quitRes = await controller.quit();
      expect(quitRes, isNull);
      expect(fakeSessionRepo.savedSessions.isEmpty, isTrue);
    });

    test('Quit path "End and see results" saves completed=false and updates skills', () async {
      final controller = createController(
        topic: Topic.addition,
        difficulty: Difficulty.easy,
        mode: PracticeMode.questions,
        modeValue: 10,
      );
      controller.start();

      // Answer 1 question
      final q = controller.state.currentQuestion;
      for (final ch in q.correctAnswer.toString().split('')) {
        controller.inputDigit(ch);
      }

      final result = await controller.quit();

      expect(result, isNotNull);
      expect(result!.savedSession?.completed, isFalse);
      expect(result.savedAttempts.length, 1);
      expect(fakeSessionRepo.savedSessions.length, 1);
      expect(fakeSessionRepo.savedSessions.first.completed, isFalse);
    });
  });
}

