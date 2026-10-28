import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/app/shell.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';
import 'package:speed_math_with_ai/core/widgets/double_back_exit_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DoubleBackExitService.instance.reset();
  });

  group('AppShell Double-Back Exit Tests', () {
    testWidgets('First back press displays "Press again to exit" toast and does not exit', (tester) async {
      int systemPopCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            systemPopCalls++;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Scaffold(body: Center(child: Text('Home Content'))),
            ),
          ),
        ),
      );

      expect(find.text('Home Content'), findsOneWidget);
      expect(find.text(AppStrings.pressAgainToExit), findsNothing);

      // Trigger first back press via PopScope
      final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));
      popScope.onPopInvokedWithResult(false, null);
      await tester.pump();

      // Toast must appear
      expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
      expect(systemPopCalls, 0);
    });

    testWidgets('Second back press within 2 seconds calls SystemNavigator.pop', (tester) async {
      int systemPopCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            systemPopCalls++;
          }
          return null;
        },
      );

      var currentTime = DateTime(2026, 1, 1, 12, 0, 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppShell(
              nowProvider: () => currentTime,
              child: const Scaffold(body: Center(child: Text('Home Content'))),
            ),
          ),
        ),
      );

      final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));

      // First back press
      popScope.onPopInvokedWithResult(false, null);
      await tester.pump();
      expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
      expect(systemPopCalls, 0);

      // Second back press within 2 seconds (500ms later)
      currentTime = currentTime.add(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      popScope.onPopInvokedWithResult(false, null);
      await tester.pump();

      expect(systemPopCalls, 1);
    });

    testWidgets('Rapid duplicate back press within 100ms is ignored as hardware bounce', (tester) async {
      int systemPopCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            systemPopCalls++;
          }
          return null;
        },
      );

      var currentTime = DateTime(2026, 1, 1, 12, 0, 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppShell(
              nowProvider: () => currentTime,
              child: const Scaffold(body: Center(child: Text('Home Content'))),
            ),
          ),
        ),
      );

      final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));

      // First back press
      popScope.onPopInvokedWithResult(false, null);
      await tester.pump();
      expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
      expect(systemPopCalls, 0);

      // Rapid duplicate event (20ms later)
      currentTime = currentTime.add(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      popScope.onPopInvokedWithResult(false, null);
      await tester.pump();

      // Must be debounced, not exiting!
      expect(systemPopCalls, 0);
    });

    testWidgets('Back press after 2.5 seconds shows toast again instead of exiting', (tester) async {
      int systemPopCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'SystemNavigator.pop') {
            systemPopCalls++;
          }
          return null;
        },
      );

      var currentTime = DateTime(2026, 1, 1, 12, 0, 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppShell(
              nowProvider: () => currentTime,
              child: const Scaffold(body: Center(child: Text('Home Content'))),
            ),
          ),
        ),
      );

      final dynamic popScope = tester.widget(find.byWidgetPredicate((w) => w is PopScope));

      // First back press
      popScope.onPopInvokedWithResult(false, null);
      await tester.pump();
      expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
      expect(systemPopCalls, 0);

      // Advance mock time by 2.5 seconds
      currentTime = currentTime.add(const Duration(milliseconds: 2500));
      await tester.pump(const Duration(milliseconds: 2500));

      // Second back press after window expired -> treated as new first back press
      popScope.onPopInvokedWithResult(false, null);
      await tester.pump();

      expect(find.text(AppStrings.pressAgainToExit), findsOneWidget);
      expect(systemPopCalls, 0);
    });
  });
}
