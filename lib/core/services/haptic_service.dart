import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../enums/enums.dart';

/// Abstract service defining app haptic vibration behaviors.
abstract interface class HapticService {
  /// Very short pulse on keypad digit, backspace, or submit.
  void keyPress({VibrationStrength strength = VibrationStrength.medium});

  /// Short crisp pulse on correct answer.
  void correctAnswer({VibrationStrength strength = VibrationStrength.medium});

  /// Stronger, distinct buzz on wrong answer.
  void wrongAnswer({VibrationStrength strength = VibrationStrength.medium});

  /// Double pulse celebration when results screen opens.
  void resultsCelebration({VibrationStrength strength = VibrationStrength.medium});

  /// Sample vibration played in settings so the user feels the intensity.
  void sample({VibrationStrength strength = VibrationStrength.medium});
}

/// Production implementation utilizing the device's vibration motor directly via [Vibration],
/// falling back safely to Flutter's [HapticFeedback] if hardware vibrator is unavailable or errors.
class AppHapticService implements HapticService {
  bool? _hasVibrator;
  bool? _hasAmplitudeControl;

  AppHapticService() {
    _initCapabilities();
  }

  void _initCapabilities() {
    Vibration.hasVibrator().then((val) {
      _hasVibrator = val;
    }).catchError((_) {
      _hasVibrator = false;
    });

    Vibration.hasAmplitudeControl().then((val) {
      _hasAmplitudeControl = val;
    }).catchError((_) {
      _hasAmplitudeControl = false;
    });
  }

  @override
  void keyPress({VibrationStrength strength = VibrationStrength.medium}) {
    final (durationMs, amplitude) = switch (strength) {
      VibrationStrength.light => (8, 64),
      VibrationStrength.medium => (12, 128),
      VibrationStrength.strong => (18, 220),
    };
    _vibrate(
      durationMs: durationMs,
      amplitude: amplitude,
      fallback: HapticFeedback.selectionClick,
    );
  }

  @override
  void correctAnswer({VibrationStrength strength = VibrationStrength.medium}) {
    final (durationMs, amplitude) = switch (strength) {
      VibrationStrength.light => (15, 90),
      VibrationStrength.medium => (22, 180),
      VibrationStrength.strong => (32, 255),
    };
    _vibrate(
      durationMs: durationMs,
      amplitude: amplitude,
      fallback: HapticFeedback.lightImpact,
    );
  }

  @override
  void wrongAnswer({VibrationStrength strength = VibrationStrength.medium}) {
    final (durationMs, amplitude) = switch (strength) {
      VibrationStrength.light => (40, 140),
      VibrationStrength.medium => (60, 220),
      VibrationStrength.strong => (90, 255),
    };
    _vibrate(
      durationMs: durationMs,
      amplitude: amplitude,
      fallback: HapticFeedback.heavyImpact,
    );
  }

  @override
  void resultsCelebration({VibrationStrength strength = VibrationStrength.medium}) {
    final (pattern, intensities) = switch (strength) {
      VibrationStrength.light => ([0, 30, 50, 30], [0, 80, 0, 110]),
      VibrationStrength.medium => ([0, 40, 60, 40], [0, 140, 0, 190]),
      VibrationStrength.strong => ([0, 55, 60, 55], [0, 220, 0, 255]),
    };

    if (_hasVibrator != false) {
      try {
        if (_hasAmplitudeControl == true) {
          Vibration.vibrate(
            pattern: pattern,
            intensities: intensities,
          ).catchError((_) {
            HapticFeedback.mediumImpact();
          });
          return;
        } else {
          Vibration.vibrate(
            pattern: pattern,
          ).catchError((_) {
            HapticFeedback.mediumImpact();
          });
          return;
        }
      } catch (_) {}
    }
    HapticFeedback.mediumImpact();
  }

  void _vibrate({
    required int durationMs,
    required int amplitude,
    required VoidCallback fallback,
  }) {
    if (_hasVibrator != false) {
      try {
        if (_hasAmplitudeControl == true) {
          Vibration.vibrate(
            duration: durationMs,
            amplitude: amplitude,
          ).catchError((_) {
            fallback();
          });
          return;
        } else {
          Vibration.vibrate(
            duration: durationMs,
          ).catchError((_) {
            fallback();
          });
          return;
        }
      } catch (_) {}
    }
    fallback();
  }

  @override
  void sample({VibrationStrength strength = VibrationStrength.medium}) {
    correctAnswer(strength: strength);
  }
}

/// Riverpod provider for the app haptic vibration service.
final hapticServiceProvider = Provider<HapticService>((ref) {
  return AppHapticService();
});
