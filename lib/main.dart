import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_math_with_ai/app/app.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Kalam font OFL license so it appears on Flutter's licence page.
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/licenses/Kalam-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Kalam'], license);
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF8FAFC),
      child: const Text(
        'Unable to display content',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  };

  final sharedPreferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SpeedMathApp(),
    ),
  );
}
