import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speed_math_with_ai/app/router.dart';
import 'package:speed_math_with_ai/app/theme.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';

class SpeedMathApp extends ConsumerWidget {
  const SpeedMathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
