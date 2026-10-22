import 'package:flutter/services.dart';

/// Lightweight service to keep the screen awake during active practice sessions.
///
/// Uses platform channel to toggle WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON.
class WakelockService {
  WakelockService._();

  static const _channel = MethodChannel('com.speedmathwithai/wakelock');

  /// Requests the device to keep the screen on.
  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {
      // Ignored on non-supported platforms or test environments
    }
  }

  /// Restores normal screen timeout behavior.
  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {
      // Ignored on non-supported platforms or test environments
    }
  }
}
