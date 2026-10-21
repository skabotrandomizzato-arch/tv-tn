import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models.dart';

/// Single app-wide radio player. Keeps playing in the background, with
/// controls in the notification / lock screen.
class RadioPlayer {
  RadioPlayer._() {
    _player.playerStateStream.listen((_) => _emit());
    _player.errorStream.listen((_) {
      error.value = true;
    });
  }
  static final instance = RadioPlayer._();

  final _player = AudioPlayer();
  final current = ValueNotifier<RadioStation?>(null);
  final playing = ValueNotifier<bool>(false);
  final loading = ValueNotifier<bool>(false);
  final error = ValueNotifier<bool>(false);

  void _emit() {
    final s = _player.playerState;
    playing.value = s.playing && s.processingState == ProcessingState.ready;
    loading.value = s.playing &&
        (s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering);
  }

  Future<void> play(RadioStation station) async {
    if (current.value?.id == station.id && _player.playing) return;
    current.value = station;
    error.value = false;
    try {
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse(station.url),
        tag: MediaItem(
          id: station.id,
          title: station.name,
          album: 'Radio en direct',
        ),
      ));
      _player.play();
    } catch (_) {
      error.value = true;
    }
  }

  void toggle() {
    if (current.value == null) return;
    if (_player.playing) {
      _player.pause();
    } else {
      error.value = false;
      // Live streams: reload instead of resuming stale buffered audio.
      play(current.value!);
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    current.value = null;
  }
}
