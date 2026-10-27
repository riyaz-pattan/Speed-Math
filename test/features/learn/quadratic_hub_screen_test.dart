import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speed_math_with_ai/core/enums/enums.dart';
import 'package:speed_math_with_ai/features/learn/quadratic_hub_screen.dart';
import 'package:speed_math_with_ai/features/practice_session/models/practice_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QuadraticHubScreen renders drills buttons and launches session', (tester) async {
    PracticeConfig? launchedConfig;

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: '/learn/quadratic',
      routes: [
        GoRoute(
          path: '/learn/quadratic',
          builder: (context, state) => const QuadraticHubScreen(),
        ),
        GoRoute(
          path: '/practice/session',
          builder: (context, state) {
            launchedConfig = state.extra as PracticeConfig?;
            return Scaffold(body: Text('Session: ${launchedConfig?.topic.name}'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and tabs
    expect(find.text('Golden Rules'), findsOneWidget);
    expect(find.text('Equation Solver'), findsOneWidget);

    // Scroll down to drill buttons
    final quadraticDrillFinder = find.text('Quadratic Drills');
    await tester.scrollUntilVisible(
      quadraticDrillFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(quadraticDrillFinder, findsOneWidget);
    expect(find.text('Linear Drills'), findsOneWidget);

    // Tap Quadratic Drills
    await tester.tap(quadraticDrillFinder);
    await tester.pumpAndSettle();

    // Verify session launched cleanly without navigator assertions!
    expect(launchedConfig, isNotNull);
    expect(launchedConfig!.topic, Topic.quadraticEquations);
    expect(launchedConfig!.modeValue, 10);
    expect(find.text('Session: quadraticEquations'), findsOneWidget);
  });

  testWidgets('QuadraticHubScreen launches Linear Drills cleanly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    PracticeConfig? launchedConfig;

    final router = GoRouter(
      initialLocation: '/learn/quadratic',
      routes: [
        GoRoute(
          path: '/learn/quadratic',
          builder: (context, state) => const QuadraticHubScreen(),
        ),
        GoRoute(
          path: '/practice/session',
          builder: (context, state) {
            launchedConfig = state.extra as PracticeConfig?;
            return Scaffold(body: Text('Session: ${launchedConfig?.topic.name}'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll to Linear Drills
    final linearDrillFinder = find.text('Linear Drills');
    await tester.scrollUntilVisible(
      linearDrillFinder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -100));
    await tester.pumpAndSettle();

    expect(linearDrillFinder, findsOneWidget);

    // Tap Linear Drills
    await tester.tap(linearDrillFinder);
    await tester.pumpAndSettle();

    // Verify session launched cleanly
    expect(launchedConfig, isNotNull);
    expect(launchedConfig!.topic, Topic.linearEquations);
    expect(launchedConfig!.modeValue, 10);
    expect(find.text('Session: linearEquations'), findsOneWidget);
  });
}
