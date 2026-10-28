import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';
import 'package:speed_math_with_ai/data/repositories/mistake_repository.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';
import 'package:speed_math_with_ai/data/repositories/skill_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/mistake_entry.dart';
import 'package:speed_math_with_ai/domain/adaptive/skill_rating.dart';
import 'package:speed_math_with_ai/features/practice_setup/practice_setup_screen.dart';

class _FakeSkillRepository implements SkillRepository {
  final List<SkillRating> ratings;

  _FakeSkillRepository(this.ratings);

  @override
  Future<List<SkillRating>> getAllRatings() async => ratings;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMistakeRepository implements MistakeRepository {
  int mistakeCount;

  _FakeMistakeRepository({this.mistakeCount = 0});

  @override
  Future<int> getMistakeCount() async => mistakeCount;

  @override
  Future<List<MistakeEntry>> getMistakesForPractice({
    List<Topic>? topics,
    int limit = 10,
  }) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestApp({
  required SharedPreferences prefs,
  SkillRepository? skillRepo,
  MistakeRepository? mistakeRepo,
  Topic? initialTopic,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      skillRepositoryProvider.overrideWithValue(
        skillRepo ?? _FakeSkillRepository([]),
      ),
      mistakeRepositoryProvider.overrideWithValue(
        mistakeRepo ?? _FakeMistakeRepository(),
      ),
    ],
    child: MaterialApp(
      home: PracticeSetupScreen(initialTopic: initialTopic),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PracticeSetupScreen Widget Tests', () {
    testWidgets('defaults for a new user: All topics, Easy, Questions, 10', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Screen title: "Practice"
      expect(find.text(AppStrings.practice), findsOneWidget);

      // Summary line should reflect defaults: Easy difficulty & 10 questions
      expect(
        find.text('Mixed practice (All topics) • Easy • 10 questions'),
        findsOneWidget,
      );

      // Auto explanation not visible by default since Easy is selected
      expect(find.text(AppStrings.autoDifficultyExplanation), findsNothing);

      // Tapping Auto reveals the explanation
      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.autoDifficultyExplanation), findsOneWidget);

      // Scroll to focus on weak areas switch in the vertical list
      final verticalScrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.scrollUntilVisible(
        find.text(AppStrings.focusWeakAreas),
        200,
        scrollable: verticalScrollable,
      );
      expect(find.text(AppStrings.focusWeakAreas), findsOneWidget);

      // Start Practice button present (sticky at bottom)
      expect(find.text(AppStrings.startPractice), findsOneWidget);
    });

    testWidgets('weak spot chips: tapping sets topic and difficulty and turns off weak area switch', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeSkillRepo = _FakeSkillRepository([
        const SkillRating(
          topic: Topic.division,
          difficulty: Difficulty.hard,
          mastery: 0.42,
          attemptsCount: 12,
        ),
      ]);

      await tester.pumpWidget(
        _buildTestApp(prefs: prefs, skillRepo: fakeSkillRepo),
      );
      await tester.pumpAndSettle();

      // Weak spots row should show "Division - Hard"
      expect(find.text('Division - Hard'), findsOneWidget);

      // Tap the weak spot chip
      await tester.tap(find.text('Division - Hard'));
      await tester.pumpAndSettle();

      // Live summary line updates to single topic drill with 10 questions
      expect(
        find.text('Division • Hard • 10 questions'),
        findsOneWidget,
      );

      // Single topic + explicit difficulty hides the focus on weak areas switch
      expect(find.text(AppStrings.focusWeakAreas), findsNothing);
    });

    testWidgets('topic selection rules: cannot deselect the last topic, tapping All topics selects all', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Initial state: all 25 standard topics selected. Tap Addition to toggle off.
      await tester.tap(find.text('Addition'));
      await tester.pumpAndSettle();

      // Now 24 topics selected
      expect(
        find.text('Mixed practice (24 topics) • Easy • 10 questions'),
        findsOneWidget,
      );

      // Tap "Select all topics" to select all 25 topics again
      await tester.tap(find.text('Select all topics'));
      await tester.pumpAndSettle();

      expect(
        find.text('Mixed practice (All topics) • Easy • 10 questions'),
        findsOneWidget,
      );
    });

    testWidgets('mode and target pills: timer shows minutes, questions shows count', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(_buildTestApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Switch to Timer mode (in sticky top deck)
      await tester.tap(find.text('Timer'));
      await tester.pumpAndSettle();

      // Timer duration pills should appear: 1m, 2m, 3m, 5m, 10m
      expect(find.text('1m'), findsOneWidget);
      expect(find.text('2m'), findsOneWidget);
      expect(find.text('3m'), findsOneWidget);
      expect(find.text('5m'), findsOneWidget);
      expect(find.text('10m'), findsOneWidget);

      // Tap 5m
      await tester.tap(find.text('5m'));
      await tester.pumpAndSettle();

      expect(
        find.text('Mixed practice (All topics) • Easy • 5 min timer'),
        findsOneWidget,
      );

      // Switch back to Questions mode
      await tester.tap(find.text('Questions'));
      await tester.pumpAndSettle();

      // Questions pills: 10 Qs, 20 Qs, 30 Qs, 50 Qs
      expect(find.text('10 Qs'), findsOneWidget);
      expect(find.text('20 Qs'), findsOneWidget);
      expect(find.text('30 Qs'), findsOneWidget);
      expect(find.text('50 Qs'), findsOneWidget);

      // Tap 50 Qs
      await tester.tap(find.text('50 Qs'));
      await tester.pumpAndSettle();

      expect(
        find.text('Mixed practice (All topics) • Easy • 50 questions'),
        findsOneWidget,
      );
    });

    testWidgets('Practice my mistakes card shows count and See all link', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeMistakeRepo = _FakeMistakeRepository(mistakeCount: 7);

      await tester.pumpWidget(
        _buildTestApp(prefs: prefs, mistakeRepo: fakeMistakeRepo),
      );
      await tester.pumpAndSettle();

      // Scroll to card in the vertical ListView
      final verticalScrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.scrollUntilVisible(
        find.text('Revise your mistakes'),
        300,
        scrollable: verticalScrollable,
      );

      // Card title & count
      expect(find.text('Revise your mistakes'), findsOneWidget);
      expect(find.text('7 questions waiting'), findsOneWidget);
      expect(find.text('Practice 7'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
    });

    testWidgets('initialTopic pre-selects that topic on open', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _buildTestApp(prefs: prefs, initialTopic: Topic.squares),
      );
      await tester.pumpAndSettle();

      // Summary should show Squares drill with Easy and 10 questions
      expect(
        find.text('Squares • Easy • 10 questions'),
        findsOneWidget,
      );
    });
  });
}
