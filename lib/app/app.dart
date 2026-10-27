import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speed_math_with_ai/app/router.dart';
import 'package:speed_math_with_ai/app/theme.dart';
import 'package:speed_math_with_ai/core/services/notification_service.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';
import 'package:speed_math_with_ai/data/repositories/settings_repository.dart';

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
      builder: (context, child) => _LifecycleObserver(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Observes app lifecycle and re-syncs reminders whenever the app is resumed.
/// This ensures notifications are always refreshed after coming back from background.
class _LifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;
  const _LifecycleObserver({required this.child});

  @override
  ConsumerState<_LifecycleObserver> createState() => _LifecycleObserverState();
}

class _LifecycleObserverState extends ConsumerState<_LifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync reminders every time the app is brought to foreground.
      // Because we use DateTimeComponents.dayOfWeekAndTime, the OS handles
      // weekly repeats automatically — this sync only resets permissions state
      // and ensures any newly enabled/disabled days are applied.
      final settings = ref.read(settingsRepositoryProvider);
      if (settings.remindersEnabled) {
        ref.read(notificationServiceProvider).syncReminders();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

