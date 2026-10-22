// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final soundsDir = Directory('assets/sounds');
  if (!soundsDir.existsSync()) {
    soundsDir.createSync(recursive: true);
  }

  // 1. Correct sound: short pleasant rising chime (two overlapping tones with gentle decay)
  final correctBytes = generateTone(
    durationSeconds: 0.22,
    sampleRate: 22050,
    generator: (t, total) {
      final envelope = exp(-8.0 * t / total);
      // Rising frequency from 660 Hz (E5) to 880 Hz (A5) with a harmonic at 1320 Hz
      final freq1 = 660.0 + (880.0 - 660.0) * (t / total);
      final s1 = sin(2 * pi * freq1 * t);
      final s2 = 0.35 * sin(2 * pi * (freq1 * 1.5) * t);
      return (s1 + s2) * envelope * 0.75;
    },
  );
  File('assets/sounds/correct.wav').writeAsBytesSync(correctBytes);
  print('Generated correct.wav: ${correctBytes.length} bytes');

  // 2. Wrong sound: short soft low buzz (gentle, not harsh, 130 Hz with harmonic, quick decay)
  final wrongBytes = generateTone(
    durationSeconds: 0.22,
    sampleRate: 22050,
    generator: (t, total) {
      final envelope = exp(-7.0 * t / total);
      // Soft low tone 140 Hz blended with slight octave overtone
      final s1 = sin(2 * pi * 140.0 * t);
      final s2 = 0.4 * sin(2 * pi * 210.0 * t);
      final s3 = 0.2 * (sin(2 * pi * 70.0 * t));
      return (s1 + s2 + s3) * envelope * 0.7;
    },
  );
  File('assets/sounds/wrong.wav').writeAsBytesSync(wrongBytes);
  print('Generated wrong.wav: ${wrongBytes.length} bytes');
}

Uint8List generateTone({
  required double durationSeconds,
  required int sampleRate,
  required double Function(double t, double totalDuration) generator,
}) {
  final numSamples = (durationSeconds * sampleRate).round();
  final dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
  final fileSize = 36 + dataSize;

  final bytes = ByteData(44 + dataSize);

  // RIFF header
  bytes.setUint8(0, 0x52); // 'R'
  bytes.setUint8(1, 0x49); // 'I'
  bytes.setUint8(2, 0x46); // 'F'
  bytes.setUint8(3, 0x46); // 'F'
  bytes.setUint32(4, fileSize, Endian.little);
  bytes.setUint8(8, 0x57);  // 'W'
  bytes.setUint8(9, 0x41);  // 'A'
  bytes.setUint8(10, 0x56); // 'V'
  bytes.setUint8(11, 0x45); // 'E'

  // fmt subchunk
  bytes.setUint8(12, 0x66); // 'f'
  bytes.setUint8(13, 0x6D); // 'm'
  bytes.setUint8(14, 0x74); // 't'
  bytes.setUint8(15, 0x20); // ' '
  bytes.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  bytes.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
  bytes.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little); // ByteRate = SampleRate * NumChannels * BitsPerSample/8
  bytes.setUint16(32, 2, Endian.little);  // BlockAlign = NumChannels * BitsPerSample/8
  bytes.setUint16(34, 16, Endian.little); // BitsPerSample = 16

  // data subchunk
  bytes.setUint8(36, 0x64); // 'd'
  bytes.setUint8(37, 0x61); // 'a'
  bytes.setUint8(38, 0x74); // 't'
  bytes.setUint8(39, 0x61); // 'a'
  bytes.setUint32(40, dataSize, Endian.little);

  // PCM sample values
  for (var i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final sampleVal = generator(t, durationSeconds).clamp(-1.0, 1.0);
    final intSample = (sampleVal * 32767).round().clamp(-32768, 32767);
    bytes.setInt16(44 + i * 2, intSample, Endian.little);
  }

  return bytes.buffer.asUint8List();
}
