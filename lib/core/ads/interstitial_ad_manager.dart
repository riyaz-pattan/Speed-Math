// lib/core/ads/interstitial_ad_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_config.dart';
import 'ad_constants.dart';
import 'ad_service.dart';
import 'interstitial_policy.dart';

/// Singleton manager for preloading and displaying interstitial pop-up ads.
class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  int _totalCompletedSessions = 0;
  int _sessionsSinceLastInterstitial = 0;
  int _lastInterstitialShownTime = 0;
  int _shownTodayCount = 0;
  String _shownTodayDate = '';

  bool get isLoaded => _interstitialAd != null;
  int get totalCompletedSessions => _totalCompletedSessions;
  int get sessionsSinceLastInterstitial => _sessionsSinceLastInterstitial;
  int get lastInterstitialShownTime => _lastInterstitialShownTime;
  int get shownTodayCount => _getRefreshedShownTodayCount();

  /// Loads cached counters from [SharedPreferences].
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalCompletedSessions =
          prefs.getInt(AdConstants.prefTotalCompletedSessions) ?? 0;
      _sessionsSinceLastInterstitial =
          prefs.getInt(AdConstants.prefSessionsSinceLastInterstitial) ?? 0;
      _lastInterstitialShownTime =
          prefs.getInt(AdConstants.prefLastInterstitialShownTime) ?? 0;
      _shownTodayCount =
          prefs.getInt(AdConstants.prefInterstitialsShownTodayCount) ?? 0;
      _shownTodayDate =
          prefs.getString(AdConstants.prefInterstitialsShownDate) ?? '';

      _checkDateRoll();
    } catch (e) {
      debugPrint('InterstitialAdManager: init exception: $e');
    }
  }

  /// Increments completed session counters when a practice session completes normally.
  Future<void> onSessionCompleted() async {
    _totalCompletedSessions++;
    _sessionsSinceLastInterstitial++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          AdConstants.prefTotalCompletedSessions, _totalCompletedSessions);
      await prefs.setInt(AdConstants.prefSessionsSinceLastInterstitial,
          _sessionsSinceLastInterstitial);
    } catch (e) {
      debugPrint('InterstitialAdManager: onSessionCompleted save error: $e');
    }

    // Try preloading if an ad is not currently cached
    if (_interstitialAd == null && !_isLoading) {
      preload();
    }
  }

  /// Preloads an interstitial ad into memory ahead of time.
  void preload() {
    if (!AdConfig.isEnabled) return;
    if (!AdService.instance.isOnline) return;
    if (_interstitialAd != null || _isLoading) return;

    final unitId = AdConfig.interstitialAdUnitId;
    if (unitId.isEmpty) return;

    _isLoading = true;
    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          AdService.instance.setLastInterstitialResult('loaded');
          debugPrint('InterstitialAdManager: Ad loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoading = false;
          AdService.instance
              .setLastInterstitialResult('load_failed: ${error.message}');
          debugPrint('InterstitialAdManager: Ad failed to load: ${error.message}');
        },
      ),
    );
  }

  /// Evaluates policy and presents the interstitial ad if all conditions are met.
  ///
  /// If the ad cannot be shown (policy rejection, offline, ad not loaded, etc.),
  /// [onContinue] is invoked immediately without waiting or showing spinners.
  void maybeShowInterstitial(
    BuildContext context, {
    required bool isSessionCompleted,
    required VoidCallback onContinue,
  }) {
    if (!AdConfig.isEnabled) {
      onContinue();
      return;
    }

    final isOnline = AdService.instance.isOnline;
    final isAdLoaded = _interstitialAd != null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final secondsSince = _lastInterstitialShownTime == 0
        ? 999999
        : (nowMs - _lastInterstitialShownTime) ~/ 1000;
    final todayCount = _getRefreshedShownTodayCount();

    final shouldShow = InterstitialPolicy.shouldShow(
      isOnline: isOnline,
      isAdLoaded: isAdLoaded,
      totalCompletedSessions: _totalCompletedSessions,
      sessionsSinceLastInterstitial: _sessionsSinceLastInterstitial,
      secondsSinceLastInterstitial: secondsSince,
      shownTodayCount: todayCount,
      isSessionCompleted: isSessionCompleted,
    );

    if (!shouldShow) {
      AdService.instance.setLastInterstitialResult('skipped_by_policy');
      onContinue();
      return;
    }

    // Ad is ready and policy approved -> show it!
    final ad = _interstitialAd!;
    _interstitialAd = null; // Consume ad

    bool continued = false;
    void proceedOnce() {
      if (!continued) {
        continued = true;
        onContinue();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        AdService.instance.setLastInterstitialResult('shown');
      },
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();
        await _recordAdShown();
        AdService.instance.setLastInterstitialResult('shown_dismissed');
        proceedOnce();
        _scheduleReload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        AdService.instance.setLastInterstitialResult('show_failed: ${error.message}');
        debugPrint('InterstitialAdManager: Failed to show ad: ${error.message}');
        proceedOnce();
        _scheduleReload();
      },
    );

    ad.show();
  }

  Future<void> _recordAdShown() async {
    _sessionsSinceLastInterstitial = 0;
    _lastInterstitialShownTime = DateTime.now().millisecondsSinceEpoch;
    _checkDateRoll();
    _shownTodayCount++;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AdConstants.prefSessionsSinceLastInterstitial, 0);
      await prefs.setInt(
          AdConstants.prefLastInterstitialShownTime, _lastInterstitialShownTime);
      await prefs.setInt(
          AdConstants.prefInterstitialsShownTodayCount, _shownTodayCount);
      await prefs.setString(
          AdConstants.prefInterstitialsShownDate, _shownTodayDate);
    } catch (e) {
      debugPrint('InterstitialAdManager: _recordAdShown save error: $e');
    }
  }

  void _scheduleReload() {
    Timer(const Duration(seconds: AdConstants.reloadDelaySeconds), () {
      if (AdService.instance.isOnline) {
        preload();
      }
    });
  }

  int _getRefreshedShownTodayCount() {
    _checkDateRoll();
    return _shownTodayCount;
  }

  void _checkDateRoll() {
    final today = _formatTodayDate();
    if (_shownTodayDate != today) {
      _shownTodayDate = today;
      _shownTodayCount = 0;
    }
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
