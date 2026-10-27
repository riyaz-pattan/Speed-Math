// lib/core/ads/widgets/banner_ad_container.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../app/theme.dart';
import '../ad_config.dart';
import '../ad_constants.dart';
import '../ad_service.dart';

/// Container that hosts an adaptive anchored banner ad at the bottom of the content.
///
/// Features:
/// - Created when the hosting screen is shown and disposed when left.
/// - Requests ads ONLY when online; collapses to [SizedBox.shrink] with 0 space when offline or loading.
/// - Guarantees >= 16 dp of clear spacing above the banner to prevent accidental clicks.
/// - Retries at most 3 times per screen visit with growing backoff (30s, 60s, 120s).
class BannerAdContainer extends ConsumerStatefulWidget {
  const BannerAdContainer({super.key});

  @override
  ConsumerState<BannerAdContainer> createState() => _BannerAdContainerState();
}

class _BannerAdContainerState extends ConsumerState<BannerAdContainer> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _retryCount = 0;
  Timer? _retryTimer;
  bool _isDisposed = false;
  bool _initialLoadAttempted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadAttempted) {
      _initialLoadAttempted = true;
      _initAndLoad();
    }
  }

  void _initAndLoad() {
    if (!AdConfig.isEnabled) return;
    final adService = ref.read(adServiceProvider);
    if (adService.isOnline && adService.isInitialized) {
      _loadBanner();
    }
  }

  Future<void> _loadBanner() async {
    if (_isDisposed) return;
    if (!mounted) return;
    if (!AdConfig.isEnabled) return;
    if (_bannerAd != null) return;

    final isOnline = ref.read(adServiceProvider).isOnline;
    if (!isOnline) {
      if (_isLoaded) {
        setState(() => _isLoaded = false);
      }
      return;
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0) return;

    try {
      final AdSize? adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (adaptiveSize == null || _isDisposed || !mounted) return;

      final unitId = AdConfig.bannerAdUnitId;
      if (unitId.isEmpty) return;

      final ad = BannerAd(
        adUnitId: unitId,
        size: adaptiveSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (_isDisposed || !mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
              _retryCount = 0;
            });
            ref.read(adServiceProvider).setLastBannerResult(
                'loaded (${adaptiveSize.width}x${adaptiveSize.height})');
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (_isDisposed || !mounted) return;
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
            ref
                .read(adServiceProvider)
                .setLastBannerResult('load_failed: ${error.message}');
            _scheduleRetry();
          },
        ),
      );

      await ad.load();
    } catch (e) {
      debugPrint('BannerAdContainer: _loadBanner error: $e');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_isDisposed || !mounted) return;
    if (_retryCount >= AdConstants.maxBannerRetriesPerVisit) {
      debugPrint('BannerAdContainer: Max retries reached for this screen visit.');
      return;
    }

    final delaySeconds = AdConstants.bannerRetryDelaysSeconds[_retryCount];
    _retryCount++;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed && mounted && ref.read(adServiceProvider).isOnline) {
        _loadBanner();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to connectivity & ad initialization changes
    ref.listen<AdService>(adServiceProvider, (prev, next) {
      if (next.isOnline && !_isLoaded && _bannerAd == null && _retryCount == 0) {
        _loadBanner();
      } else if (!next.isOnline && _isLoaded) {
        // When connection is lost, collapse ad
        setState(() {
          _isLoaded = false;
          _bannerAd?.dispose();
          _bannerAd = null;
        });
      }
    });

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      // At least 16 dp of clear breathing room above banner
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      alignment: Alignment.center,
      color: AppTheme.canvasBackground,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
