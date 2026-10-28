import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/app/router.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';
import 'package:speed_math_with_ai/core/widgets/double_back_exit_scope.dart';
import 'package:speed_math_with_ai/data/repositories/mistake_repository.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';
import 'package:speed_math_with_ai/domain/adaptive/mistake_entry.dart';
import 'package:speed_math_with_ai/features/history/history_screen.dart';
import 'package:speed_math_with_ai/features/practice_setup/practice_setup_screen.dart';

class _FakeMistakeRepo implements MistakeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<MistakeEntry>> getAllMistakes() async => [];

  @override
  Future<int> getMistakeCount() async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Navigation and back button test across tabs and routes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var mockNow = DateTime(2026, 1, 1, 12, 0, 0);
    DoubleBackExitService.instance.reset();
    DoubleBackExitService.instance.nowProvider = () => mockNow;
    addTearDown(() {
      DoubleBackExitService.instance.reset();
    });

    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
    });
    final prefs = await SharedPreferences.getInstance();

    int popCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'SystemNavigator.pop') {
          popCalls++;
        }
        return null;
      },
    );

    late GoRouter testRouter;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mistakeRepositoryProvider.overrideWithValue(_FakeMistakeRepo()),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            testRouter = ref.watch(routerProvider);
            return MaterialApp.router(
              routerConfig: testRouter,
            );
          },
        ),
      ),
    );

    // Let splash finish and navigate to /home
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // Switch to Practice tab
    final practiceTab = find.text('Practice');
    expect(practiceTab, findsOneWidget);
    await tester.tap(practiceTab);
    await tester.pump(const Duration(milliseconds: 500));

    // Now on Practice tab. Send first system back event!
    final dynamic widgetsBinding = WidgetsBinding.instance;
    final didHandle = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));

    expect(didHandle, isTrue);
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(popCalls, 0);

    // Send second back event within 2s -> must trigger SystemNavigator.pop
    mockNow = mockNow.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    final didHandleSecond = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));

    expect(didHandleSecond, isTrue);
    expect(popCalls, 1);

    // Now navigate to /history via router
    testRouter.push('/history');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HistoryScreen), findsOneWidget);

    // Send system back event on /history -> pops back to PracticeSetupScreen, does NOT exit
    final didHandleHistory = await widgetsBinding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(didHandleHistory, isTrue);
    expect(find.byType(HistoryScreen), findsNothing);
    expect(find.byType(PracticeSetupScreen), findsOneWidget);
    // popCalls must still be 1 (did not exit from sub-screen)
    expect(popCalls, 1);

    // Now navigate to /mistakes via router
    testRouter.push('/mistakes');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(AppStrings.myMistakes), findsOneWidget);

    // Send system back event on /mistakes -> pops back, does NOT exit
    final didHandleMistakes = await widgetsBinding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(didHandleMistakes, isTrue);
    expect(find.text(AppStrings.myMistakes), findsNothing);
    expect(find.byType(PracticeSetupScreen), findsOneWidget);
    expect(popCalls, 1);

    // Now navigate to /learn via router
    testRouter.push('/learn');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Learn Shortcuts'), findsOneWidget);

    // Send system back event on /learn -> pops back, does NOT exit
    final didHandleLearn = await widgetsBinding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(didHandleLearn, isTrue);
    expect(find.text('Learn Shortcuts'), findsNothing);
    expect(find.byType(PracticeSetupScreen), findsOneWidget);
    expect(popCalls, 1);

    // -------------------------------------------------------------
    // Scenario 2: Switch to Stats tab, back button shows toast, then exit on 2nd press
    // -------------------------------------------------------------
    final statsTab = find.text('Stats');
    expect(statsTab, findsOneWidget);
    await tester.tap(statsTab);
    await tester.pump(const Duration(milliseconds: 500));

    final didHandleStats1 = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(didHandleStats1, isTrue);
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(popCalls, 1);

    mockNow = mockNow.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    final didHandleStats2 = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(didHandleStats2, isTrue);
    expect(popCalls, 2);

    // -------------------------------------------------------------
    // Scenario 3: Switch to Report tab, back button shows toast, then exit on 2nd press
    // -------------------------------------------------------------
    final reportTab = find.text('Report');
    expect(reportTab, findsOneWidget);
    await tester.tap(reportTab);
    await tester.pump(const Duration(milliseconds: 500));

    final didHandleReport1 = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(didHandleReport1, isTrue);
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(popCalls, 2);

    mockNow = mockNow.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    final didHandleReport2 = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(didHandleReport2, isTrue);
    expect(popCalls, 3);

    // -------------------------------------------------------------
    // Scenario 4: Switch to Settings tab, back button shows toast, then exit on 2nd press
    // -------------------------------------------------------------
    final settingsTab = find.text('Settings');
    expect(settingsTab, findsOneWidget);
    await tester.tap(settingsTab);
    await tester.pump(const Duration(milliseconds: 500));

    final didHandleSettings1 = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(didHandleSettings1, isTrue);
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(popCalls, 3);

    mockNow = mockNow.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    final didHandleSettings2 = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(didHandleSettings2, isTrue);
    expect(popCalls, 4);

    // -------------------------------------------------------------
    // Scenario 5: User opens another tab and RETURNS to Home tab:
    // First back press MUST show "Press again to exit", and second must exit!
    // -------------------------------------------------------------
    final homeTab = find.text('Home');
    expect(homeTab, findsOneWidget);
    await tester.tap(homeTab);
    await tester.pump(const Duration(milliseconds: 500));

    final didHandleHomeReturned1 = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(didHandleHomeReturned1, isTrue);
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(popCalls, 4);

    mockNow = mockNow.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    final didHandleHomeReturned2 = await widgetsBinding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(didHandleHomeReturned2, isTrue);
    expect(popCalls, 5);
  });
}
