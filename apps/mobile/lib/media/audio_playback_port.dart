import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_playback_adapter.dart';

/// The playback phase of a single audio source, exposed by [AudioPlaybackPort]
/// so feature/UI code can render controls without knowing the vendor engine.
enum AudioPlaybackStatus {
  /// No source has been loaded yet, or playback has been stopped/disposed.
  idle,

  /// A source is being prepared/buffered from its Authorized Read URL.
  loading,

  /// A source is loaded and actively playing.
  playing,

  /// A source is loaded but paused.
  paused,

  /// The source failed to load or play. The UI hides controls and shows an
  /// unavailable placeholder for this state (Requirement 9.5).
  failed,
}

/// An immutable snapshot of the current playback state.
class AudioPlaybackState {
  const AudioPlaybackState({
    required this.status,
    this.url,
  });

  /// The initial, source-less idle state.
  static const AudioPlaybackState idle =
      AudioPlaybackState(status: AudioPlaybackStatus.idle);

  /// The current [AudioPlaybackStatus].
  final AudioPlaybackStatus status;

  /// The Authorized Read URL currently loaded, when any.
  final String? url;

  bool get isPlaying => status == AudioPlaybackStatus.playing;

  bool get isPaused => status == AudioPlaybackStatus.paused;

  bool get isLoading => status == AudioPlaybackStatus.loading;

  bool get hasFailed => status == AudioPlaybackStatus.failed;

  AudioPlaybackState copyWith({
    AudioPlaybackStatus? status,
    String? url,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      url: url ?? this.url,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AudioPlaybackState && other.status == status && other.url == url;

  @override
  int get hashCode => Object.hash(status, url);
}

/// Project-owned port for audio playback.
///
/// Feature/UI code (the `AudioPlayer` widget) depends on this interface rather
/// than on a concrete audio package, keeping any vendor dependency behind an
/// adapter (OCP/DIP), mirroring the map provider port/adapter pattern in
/// `apps/mobile/lib/map`.
///
/// Implementations must surface load/playback failures through the [state]
/// stream as [AudioPlaybackStatus.failed] rather than throwing, so the UI can
/// degrade to a `MediaPlaceholder` (Requirement 9.5).
abstract interface class AudioPlaybackPort {
  /// The current playback state snapshot.
  AudioPlaybackState get state;

  /// Emits a new [AudioPlaybackState] whenever playback state changes.
  Stream<AudioPlaybackState> get stateChanges;

  /// Loads (if necessary) and plays the audio at [url] (an Authorized Read
  /// URL). On load/playback failure the implementation transitions to
  /// [AudioPlaybackStatus.failed].
  Future<void> play(String url);

  /// Pauses playback if a source is currently playing.
  Future<void> pause();

  /// Releases any underlying playback resources. The port must not be used
  /// after disposal.
  Future<void> dispose();
}

/// Provides one [AudioPlaybackPort] per media id.
///
/// The provider yields the project-owned port; the concrete vendor adapter is
/// selected here so feature code never references the vendor package directly.
/// Riverpod owns disposal, preventing multiple audio widgets from sharing and
/// disposing the same player instance.
final audioPlaybackPortProvider =
    Provider.autoDispose.family<AudioPlaybackPort, String>((ref, mediaId) {
  final AudioPlaybackPort port = createAudioPlaybackAdapter();
  ref.onDispose(() => unawaited(port.dispose()));
  return port;
});

/// Reactive playback state for one media item.
final audioPlaybackStateProvider =
    StreamProvider.autoDispose.family<AudioPlaybackState, String>(
  (ref, mediaId) async* {
    final AudioPlaybackPort port =
        ref.watch(audioPlaybackPortProvider(mediaId));
    yield port.state;
    yield* port.stateChanges;
  },
);
