import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// Service to fetch package and app metadata dynamically at runtime.
abstract final class AppInfoService {
  static const _channel = MethodChannel('com.speedmathwithai/app_info');
  static String? _cachedVersion;

  /// Retrieves the application version dynamically from the Android package.
  ///
  /// Populated by Gradle directly from `pubspec.yaml` at build time.
  static Future<String> getAppVersion() async {
    if (_cachedVersion != null) return _cachedVersion!;
    try {
      final version = await _channel.invokeMethod<String>('getVersion');
      if (version != null && version.isNotEmpty) {
        _cachedVersion = version;
        return version;
      }
    } catch (_) {}
    return AppConstants.appVersion;
  }
}
