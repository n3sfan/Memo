import 'dart:async';

import 'package:just_audio/just_audio.dart' as just_audio;

import 'audio_playback_port.dart';

/// Creates the concrete [AudioPlaybackPort] adapter used by the app.
///
/// This is the single seam where a vendor playback engine is wired in. Feature
/// code (the `AudioPlayer` widget) never calls this directly; it depends on
/// [audioPlaybackPortProvider] instead (OCP/DIP).
AudioPlaybackPort createAudioPlaybackAdapter() => JustAudioPlaybackAdapter();

/// `just_audio` implementation kept entirely behind [AudioPlaybackPort].
class JustAudioPlaybackAdapter implements AudioPlaybackPort {
  JustAudioPlaybackAdapter({just_audio.AudioPlayer? player})
      : _player = player ?? just_audio.AudioPlayer() {
    _playerStateSubscription = _player.playerStateStream.listen(
      _onPlayerState,
    );
    _errorSubscription = _player.errorStream.listen((_) {
      _emit(
        AudioPlaybackState(
          status: AudioPlaybackStatus.failed,
          url: _state.url,
        ),
      );
    });
  }

  final just_audio.AudioPlayer _player;
  final StreamController<AudioPlaybackState> _controller =
      StreamController<AudioPlaybackState>.broadcast();

  late final StreamSubscription<just_audio.PlayerState>
      _playerStateSubscription;
  late final StreamSubscription<just_audio.PlayerException> _errorSubscription;
  AudioPlaybackState _state = AudioPlaybackState.idle;
  bool _disposed = false;

  @override
  AudioPlaybackState get state => _state;

  @override
  Stream<AudioPlaybackState> get stateChanges => _controller.stream;

  void _emit(AudioPlaybackState next) {
    if (_disposed || next == _state) {
      return;
    }
    _state = next;
    _controller.add(next);
  }

  void _onPlayerState(just_audio.PlayerState playerState) {
    if (_disposed || _state.hasFailed) {
      return;
    }

    final AudioPlaybackStatus status = switch (playerState.processingState) {
      just_audio.ProcessingState.loading ||
      just_audio.ProcessingState.buffering =>
        AudioPlaybackStatus.loading,
      just_audio.ProcessingState.ready => playerState.playing
          ? AudioPlaybackStatus.playing
          : AudioPlaybackStatus.paused,
      just_audio.ProcessingState.completed => AudioPlaybackStatus.paused,
      just_audio.ProcessingState.idle => _state.url == null
          ? AudioPlaybackStatus.idle
          : AudioPlaybackStatus.paused,
    };

    _emit(_state.copyWith(status: status));
  }

  @override
  Future<void> play(String url) async {
    if (_disposed) {
      return;
    }

    if (url.isEmpty) {
      _emit(const AudioPlaybackState(status: AudioPlaybackStatus.failed));
      return;
    }

    if (_state.url == url && _state.status == AudioPlaybackStatus.paused) {
      try {
        if (_player.processingState == just_audio.ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      } catch (_) {
        _emit(
          AudioPlaybackState(
            status: AudioPlaybackStatus.failed,
            url: url,
          ),
        );
      }
      return;
    }

    _emit(AudioPlaybackState(status: AudioPlaybackStatus.loading, url: url));

    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      _emit(AudioPlaybackState(status: AudioPlaybackStatus.failed, url: url));
    }
  }

  @override
  Future<void> pause() async {
    if (_disposed) {
      return;
    }
    try {
      await _player.pause();
    } catch (_) {
      _emit(
        AudioPlaybackState(
          status: AudioPlaybackStatus.failed,
          url: _state.url,
        ),
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _state = AudioPlaybackState.idle;
    await _playerStateSubscription.cancel();
    await _errorSubscription.cancel();
    await _player.dispose();
    await _controller.close();
  }
}
