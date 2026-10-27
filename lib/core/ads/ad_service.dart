// lib/core/ads/ad_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'interstitial_ad_manager.dart';

/// Provider for the global [AdService].
final adServiceProvider = ChangeNotifierProvider<AdService>((ref) {
  return AdService.instance;
});

/// Central coordinator for AdMob initialization, UMP consent, and online connectivity.
class AdService extends ChangeNotifier {
  AdService._();

  static final AdService instance = AdService._();

  bool _isInitialized = false;
  bool _isOnline = false;
  String _consentStatus = 'unknown';
  bool _isPrivacyOptionsRequired = false;
  String _lastBannerResult = 'none';
  String _lastInterstitialResult = 'none';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline;
  String get consentStatus => _consentStatus;
  bool get isPrivacyOptionsRequired => _isPrivacyOptionsRequired;
  String get lastBannerResult => _lastBannerResult;
  String get lastInterstitialResult => _lastInterstitialResult;

  /// Initializes connectivity listener and Google Mobile Ads SDK with UMP consent.
  ///
  /// MUST be called post-frame/after splash. Wrapped inside try/catch so failure
  /// never blocks the app.
  Future<void> initialize() async {
    try {
      // 1. Initial connectivity check & listener
      final initialResults = await Connectivity().checkConnectivity();
      _isOnline = initialResults.any((r) => r != ConnectivityResult.none);
      notifyListeners();

      _connectivitySub?.cancel();
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final onlineNow = results.any((r) => r != ConnectivityResult.none);
        if (_isOnline != onlineNow) {
          _isOnline = onlineNow;
          notifyListeners();
          if (_isOnline && _isInitialized) {
            InterstitialAdManager.instance.preload();
          }
        }
      });

      // 2. Safety check: if ads are disabled (e.g. release mode with REPLACE_WITH_REAL_ID), stop here.
      if (!AdConfig.isEnabled) {
        debugPrint('AdService: Ads disabled by AdConfig.');
        _consentStatus = 'disabled_by_config';
        notifyListeners();
        return;
      }

      // 3. Request Configuration: Not child-directed, Max rating PG
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
          maxAdContentRating: MaxAdContentRating.pg,
        ),
      );

      // 4. Request UMP Consent Information
      final params = ConsentRequestParameters(
        tagForUnderAgeOfConsent: false,
      );

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          try {
            ConsentForm.loadAndShowConsentFormIfRequired((FormError? formError) async {
              if (formError != null) {
                debugPrint('AdService: Consent form error: ${formError.message}');
              }
              await _evaluateConsentAndInit();
            });
          } catch (e) {
            debugPrint('AdService: loadAndShowConsentForm error: $e');
            await _evaluateConsentAndInit();
          }
        },
        (FormError formError) async {
          debugPrint('AdService: requestConsentInfoUpdate failed: ${formError.message}');
          await _evaluateConsentAndInit();
        },
      );
    } catch (e, st) {
      debugPrint('AdService: initialization exception (safe fallback): $e\n$st');
    }
  }

  Future<void> _evaluateConsentAndInit() async {
    try {
      final canRequest = await ConsentInformation.instance.canRequestAds();
      final privacyStatus =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();

      _isPrivacyOptionsRequired =
          privacyStatus == PrivacyOptionsRequirementStatus.required;
      _consentStatus = canRequest ? 'obtained' : 'not_obtained';
      notifyListeners();

      if (canRequest && !_isInitialized) {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        notifyListeners();

        // Preload first interstitial ad once initialized and online
        if (_isOnline) {
          InterstitialAdManager.instance.preload();
        }
      }
    } catch (e) {
      debugPrint('AdService: _evaluateConsentAndInit error: $e');
    }
  }

  /// Displays the UMP Privacy Options form so users can change their consent preferences.
  void showPrivacyOptionsForm(BuildContext context) {
    try {
      ConsentForm.showPrivacyOptionsForm((FormError? formError) async {
        if (formError != null) {
          debugPrint('AdService: showPrivacyOptionsForm error: ${formError.message}');
        }
        await _evaluateConsentAndInit();
      });
    } catch (e) {
      debugPrint('AdService: showPrivacyOptionsForm exception: $e');
    }
  }

  /// Records the latest banner ad outcome for diagnostic tracking.
  void setLastBannerResult(String result) {
    _lastBannerResult = result;
    notifyListeners();
  }

  /// Records the latest interstitial ad outcome for diagnostic tracking.
  void setLastInterstitialResult(String result) {
    _lastInterstitialResult = result;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
