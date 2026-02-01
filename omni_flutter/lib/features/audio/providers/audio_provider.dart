import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audio_provider.g.dart';

/// Audio states based on amplitude
enum AudioState {
  fire,   // High energy (> -10 dB)
  water,  // Silence/Spirit (< -45 dB)
  earth;  // Neutral (between)

  String get message {
    switch (this) {
      case AudioState.fire:
        return _fireMessages[DateTime.now().millisecond % _fireMessages.length];
      case AudioState.water:
        return _waterMessages[DateTime.now().millisecond % _waterMessages.length];
      case AudioState.earth:
        return 'NEUTRAL ENERGY DETECTED';
    }
  }

  static const _fireMessages = [
    'CHANNELING RAGE...',
    'THE ANCIENTS ARE LISTENING',
    'WARNING: ZOOMIES IMMINENT',
    'PEAK CHAOS DETECTED',
  ];

  static const _waterMessages = [
    'Scanning Ghost Frequencies...',
    'Calibrating Chakra...',
    'Spirit Realm Connection Active',
    'The Void Whispers...',
  ];
}

/// Simulated audio amplitude provider
/// Note: Actual audio recording won't work on web, so this provides mock data
@riverpod
class AmplitudeStream extends _$AmplitudeStream {
  @override
  Stream<double> build() {
    // Simulate amplitude changes
    return Stream.periodic(
      const Duration(milliseconds: 100),
      (count) {
        // Create varying amplitude between -50 and 0 dB
        final base = -25.0;
        final variation = 20.0 * (count % 10 - 5) / 5;
        return base + variation;
      },
    );
  }

  AudioState getState(double amplitude) {
    if (amplitude > -10) return AudioState.fire;
    if (amplitude < -45) return AudioState.water;
    return AudioState.earth;
  }
}
