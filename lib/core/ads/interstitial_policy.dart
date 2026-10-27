// lib/core/ads/interstitial_policy.dart
import 'ad_constants.dart';

/// Pure policy evaluator for interstitial ads.
class InterstitialPolicy {
  InterstitialPolicy._();

  /// Pure decision function determining whether an interstitial ad should be displayed.
  ///
  /// Evaluates strictly against all 7 mandatory criteria:
  /// 1. Device is online ([isOnline] == true)
  /// 2. An interstitial is already loaded and ready in memory ([isAdLoaded] == true)
  /// 3. At least 3 completed sessions since app install ([totalCompletedSessions] >= 3)
  /// 4. At least 4 completed sessions since the last interstitial ([sessionsSinceLastInterstitial] >= 4)
  /// 5. At least 5 minutes (300 s) elapsed since the last interstitial ([secondsSinceLastInterstitial] >= 300)
  /// 6. Fewer than 3 interstitials displayed today ([shownTodayCount] < 3)
  /// 7. The finished session was completed, not ended early or discarded ([isSessionCompleted] == true)
  static bool shouldShow({
    required bool isOnline,
    required bool isAdLoaded,
    required int totalCompletedSessions,
    required int sessionsSinceLastInterstitial,
    required int secondsSinceLastInterstitial,
    required int shownTodayCount,
    required bool isSessionCompleted,
  }) {
    if (!isOnline) return false;
    if (!isAdLoaded) return false;
    if (!isSessionCompleted) return false;
    if (totalCompletedSessions < AdConstants.minTotalSessionsBeforeInterstitial) {
      return false;
    }
    if (sessionsSinceLastInterstitial < AdConstants.minSessionsBetweenInterstitials) {
      return false;
    }
    if (secondsSinceLastInterstitial < AdConstants.minSecondsBetweenInterstitials) {
      return false;
    }
    if (shownTodayCount >= AdConstants.maxInterstitialsPerDay) {
      return false;
    }

    return true;
  }
}
