import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/app/app.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';

void main() {
  testWidgets('App smoke test - loads splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const SpeedMathApp(),
      ),
    );

    // Initial splash screen displays the app title
    expect(find.text(AppStrings.appName), findsOneWidget);

    // Advance 2 seconds for splash transition
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));

    // After 2 seconds, navigated to /home and displays Home
    expect(find.text(AppStrings.home), findsWidgets);
  });
}
