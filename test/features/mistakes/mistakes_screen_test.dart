import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';
import 'package:speed_math_with_ai/data/repositories/mistake_repository.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/mistake_entry.dart';
import 'package:speed_math_with_ai/features/mistakes/mistakes_screen.dart';

class _FakeMistakesRepository implements MistakeRepository {
  List<MistakeEntry> mistakes;

  _FakeMistakesRepository(this.mistakes);

  @override
  Future<List<MistakeEntry>> getAllMistakes() async => List.from(mistakes);

  @override
  Future<int> removeMistake(int id) async {
    mistakes.removeWhere((m) => m.id == id);
    return 1;
  }

  @override
  Future<int> reinsertMistake(MistakeEntry entry) async {
    mistakes.add(entry);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestApp({
  required SharedPreferences prefs,
  required MistakeRepository mistakeRepo,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      mistakeRepositoryProvider.overrideWithValue(mistakeRepo),
    ],
    child: const MaterialApp(
      home: MistakesScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MistakesScreen Widget Tests (Phase 7A.2)', () {
    testWidgets('renders friendly empty state when there are no mistakes', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeRepo = _FakeMistakesRepository([]);

      await tester.pumpWidget(_buildTestApp(prefs: prefs, mistakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noMistakesInBank), findsOneWidget);
      expect(find.text(AppStrings.noMistakesInBankSubtitle), findsOneWidget);
    });

    testWidgets('topic filter chips filter displayed mistakes and practice count', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeRepo = _FakeMistakesRepository([
        MistakeEntry(
          id: 1,
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          questionText: '12 + 15',
          operands: const [12, 15],
          correctAnswer: 27,
          source: MistakeSource.wrong,
          addedAt: DateTime.now(),
        ),
        MistakeEntry(
          id: 2,
          topic: Topic.multiplication,
          difficulty: Difficulty.medium,
          questionText: '14 × 12',
          operands: const [14, 12],
          correctAnswer: 168,
          source: MistakeSource.slow,
          addedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(prefs: prefs, mistakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text(AppStrings.myMistakes), findsOneWidget);

      // Both items shown initially (All)
      expect(find.text('12 + 15'), findsOneWidget);
      expect(find.text('14 × 12'), findsOneWidget);

      // Tap Multiplication filter chip
      await tester.tap(find.text('Multiplication (1)'));
      await tester.pumpAndSettle();

      // Only Multiplication shown now
      expect(find.text('12 + 15'), findsNothing);
      expect(find.text('14 × 12'), findsOneWidget);

      // Label badges displayed
      expect(find.text('Too slow'), findsOneWidget);
    });

    testWidgets('practice count chips allow selecting 10, 20, or All (up to 50)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Create 25 mistakes
      final entries = List.generate(
        25,
        (i) => MistakeEntry(
          id: i + 1,
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          questionText: '$i + $i',
          operands: [i, i],
          correctAnswer: i * 2,
          source: MistakeSource.wrong,
          addedAt: DateTime.now(),
        ),
      );

      final fakeRepo = _FakeMistakesRepository(entries);

      await tester.pumpWidget(_buildTestApp(prefs: prefs, mistakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      // Check practice count options
      expect(find.text('10'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.byKey(const ValueKey('count_chip_50')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('count_chip_50')),
          matching: find.text('All (25)'),
        ),
        findsOneWidget,
      );

      // Tap 20
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      // Button updates to Practice 20 questions
      expect(find.text('Practice 20 questions'), findsOneWidget);

      // Tap All (25)
      await tester.tap(find.byKey(const ValueKey('count_chip_50')));
      await tester.pumpAndSettle();

      expect(find.text('Practice 25 questions'), findsOneWidget);
    });

    testWidgets('swipe to dismiss removes mistake and shows undo snackbar', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final fakeRepo = _FakeMistakesRepository([
        MistakeEntry(
          id: 101,
          topic: Topic.addition,
          difficulty: Difficulty.easy,
          questionText: '99 + 1',
          operands: const [99, 1],
          correctAnswer: 100,
          source: MistakeSource.wrong,
          addedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(_buildTestApp(prefs: prefs, mistakeRepo: fakeRepo));
      await tester.pumpAndSettle();

      expect(find.text('99 + 1'), findsOneWidget);

      // Swipe dismiss the item
      await tester.drag(find.text('99 + 1'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Item should be removed from view
      expect(find.text('99 + 1'), findsNothing);

      // Snackbar with Undo action should appear
      expect(find.text('Removed "99 + 1"'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      // Item should be re-inserted
      expect(fakeRepo.mistakes.any((m) => m.id == 101), isTrue);
    });
  });
}
