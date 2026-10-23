import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  AudioPlayer? _tick;
  bool _loaded = false;

  Future<void> preload() async {
    if (_loaded) {
      return;
    }

    try {
      final AudioPlayer player = AudioPlayer(playerId: 'scanner_beep');
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource('sounds/beep.wav'));
      _tick = player;
    } catch (_) {
      // Sound is optional; scanning must still work if audio fails.
    }
    _loaded = true;
  }

  Future<void> playBeep() async {
    if (!enabled.value) {
      return;
    }

    final AudioPlayer? player = _tick;
    if (player == null) {
      return;
    }

    try {
      await player.stop();
      await player.resume();
    } catch (_) {
      // Ignore playback errors.
    }
  }
}
