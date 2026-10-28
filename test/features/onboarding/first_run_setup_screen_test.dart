import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';
import 'package:speed_math_with_ai/features/onboarding/first_run_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FirstRunSetupScreen renders all steps cleanly without layout exceptions', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: FirstRunSetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Step 0: Welcome screen visible
    expect(find.text('Mental Calculation Tricks'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started -> moves to Step 1: Goal
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Daily Goal'), findsOneWidget);
    expect(find.text('Set Goal & Continue'), findsOneWidget);

    // Tap Set Goal & Continue -> moves to Step 2: Reminders
    await tester.tap(find.text('Set Goal & Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Reminder'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue -> moves to Step 3: Find My Level
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Find My Starting Level'), findsOneWidget);
    expect(find.text('Start 12-Question Check'), findsOneWidget);
  });

  testWidgets('FirstRunSetupScreen renders cleanly on compact 800x600 screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: FirstRunSetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Step 0: Welcome screen visible on compact screen without overflow
    expect(find.text('Mental Calculation Tricks'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
