import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';
import 'package:speed_math_with_ai/data/repositories/mistake_repository.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/mistake_entry.dart';
import 'package:speed_math_with_ai/domain/questions/generators/quadratic_equations_generator.dart';
import 'package:speed_math_with_ai/domain/questions/question.dart';
import 'package:speed_math_with_ai/domain/questions/session_random.dart';
import 'package:speed_math_with_ai/features/practice_session/controllers/practice_session_controller.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';
import 'package:speed_math_with_ai/features/practice_session/practice_session_screen.dart';

class _TestMistakeRepo extends MistakeRepository {
  @override
  Future<bool> clearMistakeByQuestionText(String questionText) async => true;
  @override
  Future<bool> recordAttempt({
    required Question question,
    required bool isCorrect,
    required bool isSkipped,
    required int timeMs,
    int? targetTimeMs,
  }) async => true;
  @override
  int getSmartQuestionCounter() => 0;
  @override
  Future<int> incrementSmartQuestionCounter([int delta = 1]) async => 0;
  @override
  Future<List<MistakeEntry>> getDueMistakes({required int currentCounter, List<Topic>? topics, int? limit}) async => [];
  @override
  Future<List<MistakeEntry>> getMistakesForPractice({List<Topic>? topics, int limit = 20}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PracticeSessionScreen pumps cleanly with Topic.linearEquations', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final config = PracticeConfig(
      topic: Topic.linearEquations,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 10,
      sessionSeed: 12345,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mistakeRepositoryProvider.overrideWithValue(_TestMistakeRepo()),
        ],
        child: MaterialApp(
          home: PracticeSessionScreen(config: config),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PracticeSessionScreen), findsOneWidget);

    // Unmount cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('PracticeSessionScreen pumps cleanly with Topic.quadraticEquations Dual Roots', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Find a seed that produces a dual-root question
    int seed = 1;
    for (int s = 1; s < 100; s++) {
      final gen = QuadraticEquationsGenerator();
      final rand = SessionRandom.forTopic(s, Topic.quadraticEquations);
      final q = gen.generate(difficulty: Difficulty.easy, random: rand);
      if (q.isDualRootQuestion) {
        seed = s;
        break;
      }
    }

    final config = PracticeConfig(
      topic: Topic.quadraticEquations,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 10,
      sessionSeed: seed,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mistakeRepositoryProvider.overrideWithValue(_TestMistakeRepo()),
        ],
        child: MaterialApp(
          home: PracticeSessionScreen(config: config),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PracticeSessionScreen), findsOneWidget);

    // Verify dual root boxes
    expect(find.text(AppStrings.root1), findsOneWidget);
    expect(find.text(AppStrings.root2), findsOneWidget);

    // Verify minus button on keypad
    expect(find.text('−'), findsOneWidget);

    // Unmount cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('PracticeSessionScreen pumps cleanly with Topic.quadraticEquations 5-Choice Comparison', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Find a seed that produces a comparison question
    int seed = 1;
    for (int s = 1; s < 100; s++) {
      final gen = QuadraticEquationsGenerator();
      final rand = SessionRandom.forTopic(s, Topic.quadraticEquations);
      final q = gen.generate(difficulty: Difficulty.easy, random: rand);
      if (q.isMultipleChoice) {
        seed = s;
        break;
      }
    }

    final config = PracticeConfig(
      topic: Topic.quadraticEquations,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 10,
      sessionSeed: seed,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mistakeRepositoryProvider.overrideWithValue(_TestMistakeRepo()),
        ],
        child: MaterialApp(
          home: PracticeSessionScreen(config: config),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(PracticeSessionScreen), findsOneWidget);

    // Verify 5 multiple-choice options are rendered
    expect(find.text('x > y'), findsOneWidget);
    expect(find.text('x < y'), findsOneWidget);
    expect(find.text('x ≥ y'), findsOneWidget);
    expect(find.text('x ≤ y'), findsOneWidget);
    expect(find.text('x = y or CND'), findsOneWidget);

    // Tap one of the choices
    await tester.tap(find.text('x > y'));
    await tester.pump(const Duration(milliseconds: 100));

    // Unmount cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('PracticeSessionScreen displays celebration pill at top on correct answer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    int seed = 1;
    for (int s = 1; s < 100; s++) {
      final gen = QuadraticEquationsGenerator();
      final rand = SessionRandom.forTopic(s, Topic.quadraticEquations);
      final q = gen.generate(difficulty: Difficulty.easy, random: rand);
      if (q.isMultipleChoice) {
        seed = s;
        break;
      }
    }

    final config = PracticeConfig(
      topic: Topic.quadraticEquations,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 10,
      sessionSeed: seed,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mistakeRepositoryProvider.overrideWithValue(_TestMistakeRepo()),
        ],
        child: MaterialApp(
          home: PracticeSessionScreen(config: config),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Get current question's correct answer string
    final element = tester.element(find.byType(PracticeSessionScreen));
    final container = ProviderScope.containerOf(element);
    final controller = container.read(practiceSessionControllerProvider(config).notifier);
    final correctOpt = controller.state.currentQuestion.stringAnswer ??
        controller.state.currentQuestion.options![controller.state.currentQuestion.correctAnswer];

    // Tap the correct option
    await tester.tap(find.text(correctOpt));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Top celebration pill should be displayed!
    expect(find.textContaining('Correct!'), findsOneWidget);

    // Unmount cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('PracticeSessionScreen displays try again pill at top on wrong answer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    int seed = 1;
    for (int s = 1; s < 100; s++) {
      final gen = QuadraticEquationsGenerator();
      final rand = SessionRandom.forTopic(s, Topic.quadraticEquations);
      final q = gen.generate(difficulty: Difficulty.easy, random: rand);
      if (q.isMultipleChoice) {
        seed = s;
        break;
      }
    }

    final config = PracticeConfig(
      topic: Topic.quadraticEquations,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 10,
      sessionSeed: seed,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mistakeRepositoryProvider.overrideWithValue(_TestMistakeRepo()),
        ],
        child: MaterialApp(
          home: PracticeSessionScreen(config: config),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Get an incorrect option
    final element = tester.element(find.byType(PracticeSessionScreen));
    final container = ProviderScope.containerOf(element);
    final controller = container.read(practiceSessionControllerProvider(config).notifier);
    final correctOpt = controller.state.currentQuestion.stringAnswer ??
        controller.state.currentQuestion.options![controller.state.currentQuestion.correctAnswer];
    final wrongOpt = controller.state.currentQuestion.options!.firstWhere((o) => o != correctOpt);

    // Tap the incorrect option
    await tester.tap(find.text(wrongOpt));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Top error feedback pill should be displayed!
    expect(find.text('Try again ✕'), findsOneWidget);

    // Unmount cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('PracticeSessionScreen displays skipped pill at top on skip', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final config = PracticeConfig(
      topic: Topic.quadraticEquations,
      difficulty: Difficulty.easy,
      mode: PracticeMode.questions,
      modeValue: 10,
      sessionSeed: 42,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mistakeRepositoryProvider.overrideWithValue(_TestMistakeRepo()),
        ],
        child: MaterialApp(
          home: PracticeSessionScreen(config: config),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Skip button
    await tester.tap(find.text(AppStrings.skip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Top skipped feedback pill should be displayed!
    expect(find.text('Skipped ↷'), findsOneWidget);

    // Unmount cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
