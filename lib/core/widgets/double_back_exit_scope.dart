import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speed_math_with_ai/core/strings/app_strings.dart';
import 'package:speed_math_with_ai/core/widgets/app_toast.dart';

/// Centralized service handling the double-back-to-exit timing and logic across
/// all screens in the application.
class DoubleBackExitService {
  DoubleBackExitService._();
  static final DoubleBackExitService instance = DoubleBackExitService._();

  DateTime? _lastBackPressTime;
  DateTime Function()? nowProvider;

  /// Resets the double-back press state (e.g. when changing tabs or navigating).
  void reset() {
    _lastBackPressTime = null;
  }

  /// Handles a back press event. Shows toast on first press; exits app on second press within 2s.
  Future<bool> handleBackPress(BuildContext context) async {
    final now = (nowProvider ?? DateTime.now)();

    // 1. If first press, clock shifted backwards, or > 2s elapsed since last press:
    // show confirmation toast and start the 2-second window.
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) < Duration.zero ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      HapticFeedback.lightImpact();
      AppToast.show(
        context,
        message: AppStrings.pressAgainToExit,
        type: AppToastType.info,
        duration: const Duration(seconds: 2),
      );
      return true;
    }

    // 2. Hardware / gesture bounce filter: ignore duplicate events arriving within 50ms
    if (now.difference(_lastBackPressTime!) < const Duration(milliseconds: 50)) {
      return true;
    }

    // 3. Deliberate second back press strictly within the 50ms..2000ms window: exit app
    reset();
    await SystemNavigator.pop();
    return true;
  }
}

/// A scope widget that intercepts the Android back button and predictive back gesture,
/// requiring a second back press within 2 seconds to exit the application.
class DoubleBackExitScope extends StatelessWidget {
  const DoubleBackExitScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        DoubleBackExitService.instance.handleBackPress(context);
      },
      child: child,
    );
  }
}
