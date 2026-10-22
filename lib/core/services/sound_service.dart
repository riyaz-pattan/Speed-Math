import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Constants and mathematical curves for application audio playback.
class SoundConstants {
  /// Perceptual power curve exponent for human-hearing volume scaling.
  /// Human hearing perceives amplitude logarithmically (~power of 0.33),
  /// so effective amplitude = sliderValue^3.0 gives a natural perceptual response.
  static const double perceptualVolumeExponent = 3.0;

  /// Converts a slider setting in [0.0, 1.0] to an effective audio playback volume
  /// using the cubic perceptual power curve.
  static double toEffectiveVolume(double sliderValue) {
    final clamped = sliderValue.clamp(0.0, 1.0);
    return pow(clamped, perceptualVolumeExponent).toDouble();
  }
}

/// Abstract interface for application audio feedback.
abstract class SoundService {
  Future<void> playCorrect();
  Future<void> playWrong();
  Future<void> setVolume(double volume);
  double get volume;
  double get effectiveVolume;
  void dispose();
}

/// Riverpod provider for the active [SoundService].
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = AppSoundService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Production implementation of [SoundService] using [audioplayers].
///
/// Features:
/// - Low-latency audio playback
/// - Preloaded sound assets
/// - Uses Android media stream (STREAM_MUSIC) to respect phone media volume
/// - Non-exclusive audio focus (ambient/mixWithOthers) so music in other apps is never interrupted
/// - Perceptual power volume curve (effectiveVolume = sliderValue^3.0)
/// - Silent failure handling (never crashes if audio hardware is unavailable)
class AppSoundService implements SoundService {
  AudioPlayer? _correctPlayer;
  AudioPlayer? _wrongPlayer;
  bool _initialized = false;
  bool _initFailed = false;
  double _sliderVolume = 1.0;

  @override
  double get volume => _sliderVolume;

  @override
  double get effectiveVolume => SoundConstants.toEffectiveVolume(_sliderVolume);

  AppSoundService() {
    _init();
  }

  Future<void> _init() async {
    if (_initialized || _initFailed) return;

    try {
      // Configure global audio context:
      // Media stream + no exclusive focus so background music mixes seamlessly
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );

      _correctPlayer = AudioPlayer();
      _wrongPlayer = AudioPlayer();

      await _correctPlayer!.setPlayerMode(PlayerMode.lowLatency);
      await _wrongPlayer!.setPlayerMode(PlayerMode.lowLatency);

      final eff = effectiveVolume;
      await _correctPlayer!.setVolume(eff);
      await _wrongPlayer!.setVolume(eff);

      // Preload assets for instant response
      await _correctPlayer!.setSource(AssetSource('sounds/correct.mp3'));
      await _wrongPlayer!.setSource(AssetSource('sounds/wrong.mp3'));

      _initialized = true;
    } catch (e) {
      debugPrint('SoundService audio initialization failed: $e');
      _initFailed = true;
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _sliderVolume = volume.clamp(0.0, 1.0);
    final eff = effectiveVolume;
    try {
      await _correctPlayer?.setVolume(eff);
      await _wrongPlayer?.setVolume(eff);
    } catch (_) {}
  }

  @override
  Future<void> playCorrect() async {
    if (_initFailed) return;
    try {
      if (!_initialized) await _init();
      final player = _correctPlayer;
      if (player != null) {
        final eff = effectiveVolume;
        // Fire-and-forget: do not await completion so UI never lags
        unawaited(player.stop().then((_) {
          player.setVolume(eff);
          return player.play(
            AssetSource('sounds/correct.mp3'),
            volume: eff,
          );
        }).catchError((_) {}));
      }
    } catch (_) {
      // Stay silent and never crash
    }
  }

  @override
  Future<void> playWrong() async {
    if (_initFailed) return;
    try {
      if (!_initialized) await _init();
      final player = _wrongPlayer;
      if (player != null) {
        final eff = effectiveVolume;
        // Fire-and-forget
        unawaited(player.stop().then((_) {
          player.setVolume(eff);
          return player.play(
            AssetSource('sounds/wrong.mp3'),
            volume: eff,
          );
        }).catchError((_) {}));
      }
    } catch (_) {
      // Stay silent and never crash
    }
  }

  @override
  void dispose() {
    try {
      _correctPlayer?.dispose();
      _wrongPlayer?.dispose();
    } catch (_) {}
    _correctPlayer = null;
    _wrongPlayer = null;
    _initialized = false;
  }
}
