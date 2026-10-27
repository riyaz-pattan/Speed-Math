// lib/core/ads/ad_constants.dart

/// Timing, retry, capping, and preferences constants for AdMob ads.
class AdConstants {
  AdConstants._();

  // =========================================================================
  // INTERSTITIAL POLICIES & THRESHOLDS
  // =========================================================================

  /// Minimum total completed sessions since install before any interstitial can appear.
  static const int minTotalSessionsBeforeInterstitial = 3;

  /// Minimum completed sessions required between two consecutive interstitials.
  static const int minSessionsBetweenInterstitials = 4;

  /// Minimum interval between two interstitials in seconds (5 minutes).
  static const int minSecondsBetweenInterstitials = 300;

  /// Maximum number of interstitials permitted to show in a single calendar day.
  static const int maxInterstitialsPerDay = 3;

  /// Delay before preloading the next interstitial after dismissal (seconds).
  static const int reloadDelaySeconds = 20;

  // =========================================================================
  // BANNER RETRY THRESHOLDS
  // =========================================================================

  /// Maximum retries for loading a banner on a single screen visit.
  static const int maxBannerRetriesPerVisit = 3;

  /// Retry backoff delays for banner ad loading (seconds).
  static const List<int> bannerRetryDelaysSeconds = [30, 60, 120];

  // =========================================================================
  // SHARED PREFERENCES KEYS
  // =========================================================================

  /// Key for total completed sessions count.
  static const String prefTotalCompletedSessions = 'ad_total_completed_sessions';

  /// Key for completed sessions count since the last shown interstitial.
  static const String prefSessionsSinceLastInterstitial = 'ad_sessions_since_last_interstitial';

  /// Key for timestamp (millis since epoch) when the last interstitial was shown.
  static const String prefLastInterstitialShownTime = 'ad_last_interstitial_shown_time';

  /// Key for count of interstitials shown today.
  static const String prefInterstitialsShownTodayCount = 'ad_interstitials_shown_today_count';

  /// Key for the date (YYYY-MM-DD) corresponding to [prefInterstitialsShownTodayCount].
  static const String prefInterstitialsShownDate = 'ad_interstitials_shown_date';
}
