import 'package:flutter_test/flutter_test.dart';
import 'package:speed_math_with_ai/core/services/sound_service.dart';

void main() {
  group('SoundConstants Perceptual Volume Curve Tests', () {
    test('named constant perceptualVolumeExponent is 3.0', () {
      expect(SoundConstants.perceptualVolumeExponent, 3.0);
    });

    test('slider 0.0 maps to effective volume 0.0 (silent)', () {
      expect(SoundConstants.toEffectiveVolume(0.0), closeTo(0.0, 1e-6));
    });

    test('slider 0.05 maps to effective volume 0.000125 (0.05^3)', () {
      expect(SoundConstants.toEffectiveVolume(0.05), closeTo(0.000125, 1e-6));
    });

    test('slider 0.10 maps to effective volume 0.001 (whisper)', () {
      expect(SoundConstants.toEffectiveVolume(0.10), closeTo(0.001, 1e-6));
    });

    test('slider 0.50 maps to effective volume 0.125 (comfortably soft)', () {
      expect(SoundConstants.toEffectiveVolume(0.50), closeTo(0.125, 1e-6));
    });

    test('slider 1.00 maps to effective volume 1.0 (full volume)', () {
      expect(SoundConstants.toEffectiveVolume(1.00), closeTo(1.0, 1e-6));
    });

    test('clamps values below 0.0 and above 1.0', () {
      expect(SoundConstants.toEffectiveVolume(-0.2), closeTo(0.0, 1e-6));
      expect(SoundConstants.toEffectiveVolume(1.5), closeTo(1.0, 1e-6));
    });

    test('cubic power curve is strictly monotonically increasing', () {
      double prev = -1.0;
      for (int i = 0; i <= 20; i++) {
        final slider = i / 20.0; // 5% steps
        final eff = SoundConstants.toEffectiveVolume(slider);
        expect(eff, greaterThanOrEqualTo(prev));
        prev = eff;
      }
    });
  });

  group('Mock SoundService Effective Volume Forwarding', () {
    test('fake sound service receives and forwards effective volume', () async {
      final mock = _RecordingSoundService();
      expect(mock.volume, 1.0);
      expect(mock.effectiveVolume, 1.0);

      await mock.setVolume(0.5);
      expect(mock.volume, 0.5);
      expect(mock.effectiveVolume, closeTo(0.125, 1e-6));

      await mock.playCorrect();
      expect(mock.lastPlayedVolume, closeTo(0.125, 1e-6));

      await mock.setVolume(0.05);
      expect(mock.volume, 0.05);
      expect(mock.effectiveVolume, closeTo(0.000125, 1e-6));

      await mock.playWrong();
      expect(mock.lastPlayedVolume, closeTo(0.000125, 1e-6));
    });
  });
}

class _RecordingSoundService implements SoundService {
  double _volume = 1.0;
  double? lastPlayedVolume;

  @override
  double get volume => _volume;

  @override
  double get effectiveVolume => SoundConstants.toEffectiveVolume(_volume);

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> playCorrect() async {
    lastPlayedVolume = effectiveVolume;
  }

  @override
  Future<void> playWrong() async {
    lastPlayedVolume = effectiveVolume;
  }

  @override
  void dispose() {}
}
