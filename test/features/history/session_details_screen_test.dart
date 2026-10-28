import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/core/widgets/question_text_widget.dart';
import 'package:speed_math_with_ai/data/models/attempt.dart';
import 'package:speed_math_with_ai/data/models/session.dart';
import 'package:speed_math_with_ai/data/repositories/attempt_repository.dart';
import 'package:speed_math_with_ai/features/history/session_details_screen.dart';

class _FakeAttemptRepository implements AttemptRepository {
  final List<Attempt> attempts;

  _FakeAttemptRepository(this.attempts);

  @override
  Future<List<Attempt>> getAttemptsBySessionId(int sessionId) async => attempts;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSession = Session(
    id: 1,
    topic: Topic.squares,
    difficulty: Difficulty.hard,
    mode: PracticeMode.questions,
    modeValue: 4,
    totalQuestions: 4,
    correctCount: 2,
    score: 80,
    accuracy: 0.5,
    avgTimeMs: 2500,
    durationMs: 10000,
    startedAt: DateTime(2026, 1, 1, 10, 0),
    kind: SessionKind.drill,
  );

  final testAttempts = [
    // 1. Correct and fast (1000ms) -> No "Learn this trick" button
    Attempt(
      id: 101,
      sessionId: 1,
      topic: Topic.squares,
      difficulty: Difficulty.hard,
      questionText: '25²',
      operandA: '25',
      operandB: '',
      correctAnswer: 625,
      userAnswer: 625,
      isCorrect: true,
      isSkipped: false,
      timeMs: 1000,
      createdAt: DateTime(2026, 1, 1, 10, 0, 5),
    ),
    // 2. Wrong (36²) -> MUST show "Learn this trick →"
    Attempt(
      id: 102,
      sessionId: 1,
      topic: Topic.squares,
      difficulty: Difficulty.hard,
      questionText: '36²',
      operandA: '36',
      operandB: '',
      correctAnswer: 1296,
      userAnswer: 1266,
      isCorrect: false,
      isSkipped: false,
      timeMs: 2000,
      createdAt: DateTime(2026, 1, 1, 10, 0, 10),
    ),
    // 3. Skipped (48²) -> MUST show "Learn this trick →"
    Attempt(
      id: 103,
      sessionId: 1,
      topic: Topic.squares,
      difficulty: Difficulty.hard,
      questionText: '48²',
      operandA: '48',
      operandB: '',
      correctAnswer: 2304,
      userAnswer: null,
      isCorrect: false,
      isSkipped: true,
      timeMs: 1500,
      createdAt: DateTime(2026, 1, 1, 10, 0, 15),
    ),
    // 4. Correct but Slowest (5000ms) -> MUST show "Learn this trick →"
    Attempt(
      id: 104,
      sessionId: 1,
      topic: Topic.squares,
      difficulty: Difficulty.hard,
      questionText: '96²',
      operandA: '96',
      operandB: '',
      correctAnswer: 9216,
      userAnswer: 9216,
      isCorrect: true,
      isSkipped: false,
      timeMs: 5000,
      createdAt: DateTime(2026, 1, 1, 10, 0, 20),
    ),
  ];

  testWidgets('SessionDetailsScreen shows "Learn this trick →" only for wrong, skipped, and slowest answers', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepo = _FakeAttemptRepository(testAttempts);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attemptRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: SessionDetailsScreen(session: testSession),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 4 questions are displayed via QuestionTextWidget
    expect(find.byWidgetPredicate((w) => w is QuestionTextWidget && w.text == '25²'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is QuestionTextWidget && w.text == '36²'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is QuestionTextWidget && w.text == '48²'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is QuestionTextWidget && w.text == '96²'), findsOneWidget);

    // "Slowest" badge should be on question 96²
    expect(find.text('Slowest'), findsOneWidget);

    // Exactly 3 "Learn this trick →" buttons (for 36² wrong, 48² skipped, and 96² slowest)
    // 25² (correct and not slowest) must NOT have the button!
    expect(find.text('Learn this trick →'), findsNWidgets(3));
  });
}
