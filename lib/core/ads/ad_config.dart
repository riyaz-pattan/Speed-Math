// lib/core/ads/ad_config.dart
import 'package:flutter/foundation.dart';

/// Centralized configuration for Google AdMob Ads.
///
/// This is the SINGLE place in the codebase containing AdMob App and Unit IDs.
class AdConfig {
  AdConfig._();

  // =========================================================================
  // REAL PRODUCTION ADMOB IDS (REPLACE WITH REAL PRODUCTION IDS FOR RELEASE)
  // =========================================================================

  /// Your real AdMob Application ID (e.g., 'ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY').
  static const String realAppId = 'ca-app-pub-9917099283589501~2192467260';

  /// Your real AdMob Banner Ad Unit ID (e.g., 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY').
  static const String realBannerUnitId = 'ca-app-pub-9917099283589501/1474281961';

  /// Your real AdMob Interstitial Ad Unit ID (e.g., 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY').
  static const String realInterstitialUnitId = 'ca-app-pub-9917099283589501/3749091511';

  // =========================================================================
  // GOOGLE OFFICIAL TEST IDS (Used automatically in debug and profile modes)
  // Double-checked against Google AdMob official Android sample ad units.
  // =========================================================================

  /// Official Google Android test App ID.
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Official Google Android test Adaptive Banner ID.
  static const String testBannerUnitId = 'ca-app-pub-3940256099942544/6300978111';

  /// Official Google Android test Interstitial ID.
  static const String testInterstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';

  // =========================================================================
  // PRIVACY POLICY URL
  // =========================================================================

  /// Official hosted public URL to the app privacy policy.
  static const String privacyPolicyUrl =
      'https://riyaz-pattan.github.io/speed-math-pro-privacy/';

  // =========================================================================
  // RESOLVED ADMOB IDS & SAFETY GUARDS
  // =========================================================================

  /// Whether ads are enabled.
  ///
  /// - In debug and profile builds: ALWAYS true (uses Google official test IDs).
  /// - In release builds: true ONLY IF real IDs are provided and do NOT contain 'REPLACE'.
  ///   If a release ID still contains 'REPLACE', ads stay completely disabled.
  static bool get isEnabled {
    if (!kReleaseMode) {
      return true;
    }
    // Release safety check:
    final hasRealApp = realAppId.isNotEmpty && !realAppId.contains('REPLACE');
    final hasRealBanner =
        realBannerUnitId.isNotEmpty && !realBannerUnitId.contains('REPLACE');
    final hasRealInterstitial = realInterstitialUnitId.isNotEmpty &&
        !realInterstitialUnitId.contains('REPLACE');
    return hasRealApp && (hasRealBanner || hasRealInterstitial);
  }

  /// Active Banner Ad Unit ID. Returns empty string if disabled.
  static String get bannerAdUnitId {
    if (!kReleaseMode) {
      return testBannerUnitId;
    }
    if (realBannerUnitId.contains('REPLACE')) {
      return '';
    }
    return realBannerUnitId;
  }

  /// Active Interstitial Ad Unit ID. Returns empty string if disabled.
  static String get interstitialAdUnitId {
    if (!kReleaseMode) {
      return testInterstitialUnitId;
    }
    if (realInterstitialUnitId.contains('REPLACE')) {
      return '';
    }
    return realInterstitialUnitId;
  }
}
