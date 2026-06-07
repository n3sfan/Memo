import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import 'audio_playback_port.dart';
import 'media_placeholder.dart';
import 'media_url_controller.dart';

/// Plays a single audio-type media item attached to a pin.
///
/// The widget watches [mediaUrlControllerProvider] for the media's Authorized
/// Read URL and drives playback through the project-owned [AudioPlaybackPort]
/// (never a vendor package directly - OCP/DIP).
///
/// Behavior (Requirements 9.2-9.5):
/// - On [MediaReady], a play control plays from the Authorized Read URL (9.2).
/// - While playing, a pause control is shown (9.3); activating it pauses (9.4).
/// - On [MediaUnavailable] or a playback load failure, the play/pause controls
///   are hidden and a [MediaPlaceholder] indicating the audio is unavailable is
///   shown (9.5).
///
/// Localized strings are supplied by the calling screen; English fallbacks are
/// used until the feature's localization keys are generated (task 11.1).
class AudioPlayer extends ConsumerWidget {
  const AudioPlayer({
    required this.mediaId,
    this.unavailableMessage,
    this.playLabel,
    this.pauseLabel,
    super.key,
  });

  /// Default English label used when [unavailableMessage] is not supplied.
  static const String defaultUnavailableMessage = 'Audio unavailable';

  /// Default English label used when [playLabel] is not supplied.
  static const String defaultPlayLabel = 'Play';

  /// Default English label used when [pauseLabel] is not supplied.
  static const String defaultPauseLabel = 'Pause';

  /// The id of the audio media item to play.
  final String mediaId;

  /// Localized "audio unavailable" message; falls back to English when null.
  final String? unavailableMessage;

  /// Localized play control label; falls back to English when null.
  final String? playLabel;

  /// Localized pause control label; falls back to English when null.
  final String? pauseLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MediaLoadState> urlState =
        ref.watch(mediaUrlControllerProvider(mediaId));

    final String unavailableMessage =
        this.unavailableMessage ?? AudioPlayer.defaultUnavailableMessage;

    return urlState.when(
      loading: _buildLoading,
      error: (_, __) => _buildUnavailable(unavailableMessage),
      data: (MediaLoadState loadState) {
        // Media could not be resolved (offline, pending, or failed) -> hide
        // controls and show the unavailable placeholder (Req 9.5, 10.2).
        if (loadState is! MediaReady) {
          return _buildUnavailable(unavailableMessage);
        }

        final AudioPlaybackState playback =
            ref.watch(audioPlaybackStateProvider(mediaId)).value ??
                AudioPlaybackState.idle;

        // Playback itself failed to load from the read URL -> hide controls and
        // show the unavailable placeholder (Req 9.5).
        if (playback.hasFailed) {
          return _buildUnavailable(unavailableMessage);
        }

        return _buildControls(ref, playback, loadState.url);
      },
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 56,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildUnavailable(String message) {
    return MediaPlaceholder(
      message: message,
      icon: Icons.music_off_outlined,
    );
  }

  Widget _buildControls(
    WidgetRef ref,
    AudioPlaybackState playback,
    String url,
  ) {
    final bool isPlaying = playback.isPlaying;
    final bool isLoading = playback.isLoading;
    final String playLabel = this.playLabel ?? AudioPlayer.defaultPlayLabel;
    final String pauseLabel = this.pauseLabel ?? AudioPlayer.defaultPauseLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 40,
              height: 40,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton.filled(
              key: ValueKey<String>(
                isPlaying
                    ? 'audio-pause-button-$mediaId'
                    : 'audio-play-button-$mediaId',
              ),
              onPressed: () {
                final AudioPlaybackPort port =
                    ref.read(audioPlaybackPortProvider(mediaId));
                if (isPlaying) {
                  port.pause();
                } else {
                  port.play(url);
                }
              },
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              tooltip: isPlaying ? pauseLabel : playLabel,
              style: IconButton.styleFrom(
                backgroundColor: MemoTheme.primary,
                foregroundColor: MemoTheme.onPrimary,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPlaying ? pauseLabel : playLabel,
              style: TextStyle(
                fontSize: 14,
                color: MemoTheme.onBackground.withValues(alpha: 0.8),
              ),
            ),
          ),
          const Icon(
            Icons.audiotrack,
            color: MemoTheme.accent,
          ),
        ],
      ),
    );
  }
}
