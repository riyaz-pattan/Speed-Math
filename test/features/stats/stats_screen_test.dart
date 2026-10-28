import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/data/db/database_helper.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';
import 'package:speed_math_with_ai/data/repositories/skill_repository.dart';
import 'package:speed_math_with_ai/data/repositories/stats_repository.dart';
import 'package:speed_math_with_ai/features/stats/stats_screen.dart';
import 'package:sqflite/sqflite.dart';

class _FakeDb implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper dbHelper;
  late SettingsRepository settingsRepo;
  late StatsRepository statsRepo;
  late SkillRepository skillRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeDb = _FakeDb();
    dbHelper = DatabaseHelper.withDatabase(fakeDb);
    settingsRepo = SettingsRepository(prefs);
    statsRepo = StatsRepository(dbHelper: dbHelper);
    skillRepo = SkillRepository(dbHelper: dbHelper);
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        statsRepositoryProvider.overrideWithValue(statsRepo),
        skillRepositoryProvider.overrideWithValue(skillRepo),
      ],
      child: const MaterialApp(
        home: StatsScreen(),
      ),
    );
  }

  testWidgets('StatsScreen shows Mixed Topics and all 6 difficulty levels in dropdown', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // 1. Verify "Mixed Topics" is present in topic chips
    expect(find.text('Mixed Topics'), findsOneWidget);

    // 2. Open the difficulty dropdown
    // Initial difficulty displayed is Easy or whatever default
    final dropdownFinder = find.byType(DropdownButton<Difficulty>);
    expect(dropdownFinder, findsOneWidget);

    // Tap on the difficulty dropdown
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // 3. Verify that all 6 difficulty options appear in dropdown menu items:
    // Auto, Easy, Medium, Hard, Expert, Genius
    expect(find.text('Auto'), findsWidgets);
    expect(find.text('Easy'), findsWidgets);
    expect(find.text('Medium'), findsWidgets);
    expect(find.text('Hard'), findsWidgets);
    expect(find.text('Expert'), findsWidgets);
    expect(find.text('Genius'), findsWidgets);

    // Tap 'Auto'
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    // Verify 'Auto' is now the selected difficulty in dropdown
    final dropdownWidget = tester.widget<DropdownButton<Difficulty>>(dropdownFinder);
    expect(dropdownWidget.value, Difficulty.mixed);

    // 4. Tap 'Mixed Topics' chip
    await tester.tap(find.text('Mixed Topics'));
    await tester.pumpAndSettle();

    // Verify EmptyStateView reflects Mixed Topics (Auto)
    expect(find.textContaining('Practice with Mixed Topics (Auto)'), findsOneWidget);

    // 5. Select Expert difficulty
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expert').last);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<Difficulty>>(dropdownFinder).value, Difficulty.expert);
    expect(find.textContaining('Practice with Mixed Topics (Expert)'), findsOneWidget);

    // 6. Select Genius difficulty
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Genius').last);
    await tester.pumpAndSettle();
    expect(tester.widget<DropdownButton<Difficulty>>(dropdownFinder).value, Difficulty.genius);
    expect(find.textContaining('Practice with Mixed Topics (Genius)'), findsOneWidget);
  });
}
