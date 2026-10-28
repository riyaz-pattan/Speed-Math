import 'package:flutter/foundation.dart';
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

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    DoubleBackExitService.instance.reset();
  });

  testWidgets('Android platform channel: frameworkHandlesBack remains true across all tabs', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

    final List<bool> platformBackHandles = [];
    int systemPopCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          platformBackHandles.add(call.arguments as bool);
        } else if (call.method == 'SystemNavigator.pop') {
          systemPopCalls++;
        }
        return null;
      },
    );

    var mockNow = DateTime(2026, 1, 1, 12, 0, 0);
    DoubleBackExitService.instance.reset();
    DoubleBackExitService.instance.nowProvider = () => mockNow;

    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
    });
    final prefs = await SharedPreferences.getInstance();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

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

    // Home: verify Android is told framework handles back
    expect(platformBackHandles.last, isTrue);

    // First back on Home
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(systemPopCalls, 0);

    // 1. Switch to Practice Tab
    testRouter.go('/practice');
    await tester.pump(const Duration(milliseconds: 500));
    expect(platformBackHandles.last, isTrue);

    // First back on Practice
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(systemPopCalls, 0);

    // Second back within 2s on Practice -> exits
    mockNow = mockNow.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(systemPopCalls, 1);

    // 2. Switch to Stats Tab
    testRouter.go('/stats');
    await tester.pump(const Duration(milliseconds: 500));
    expect(platformBackHandles.last, isTrue);

    // First back on Stats
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(systemPopCalls, 1);

    // 3. Switch to Report Tab
    testRouter.go('/report');
    await tester.pump(const Duration(milliseconds: 500));
    expect(platformBackHandles.last, isTrue);

    // First back on Report
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(systemPopCalls, 1);

    // 4. Switch to Settings Tab
    testRouter.go('/settings');
    await tester.pump(const Duration(milliseconds: 500));
    expect(platformBackHandles.last, isTrue);

    // First back on Settings
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(systemPopCalls, 1);

    // 5. Navigate back to Home Tab
    testRouter.go('/home');
    await tester.pump(const Duration(milliseconds: 500));
    expect(platformBackHandles.last, isTrue);

    // First back on Home after returning
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(systemPopCalls, 1);

    // Second back on Home within 2s -> exits
    mockNow = mockNow.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(systemPopCalls, 2);

    // 6. Test timeout: back press after 3s shows toast again instead of exiting
    mockNow = mockNow.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    await testRouter.routerDelegate.popRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
    expect(systemPopCalls, 2); // Did NOT exit!
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
  });
}
