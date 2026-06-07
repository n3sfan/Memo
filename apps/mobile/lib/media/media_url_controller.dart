import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import '../sync/network_monitor.dart';

/// Per-media-item load state owned by [MediaUrlController].
///
/// The state is intentionally narrow: the UI only needs to know whether the
/// Authorized Read URL is still being resolved ([MediaLoading]), is ready to
/// load from ([MediaReady]), or cannot be loaded right now ([MediaUnavailable]
/// - offline, pending, or failed).
sealed class MediaLoadState {
  const MediaLoadState();
}

/// The Authorized Read URL is still being resolved.
class MediaLoading extends MediaLoadState {
  const MediaLoading();

  @override
  bool operator ==(Object other) => other is MediaLoading;

  @override
  int get hashCode => (MediaLoading).hashCode;
}

/// An Authorized Read URL was resolved and media can be loaded from [url].
class MediaReady extends MediaLoadState {
  const MediaReady(this.url);

  final String url;

  @override
  bool operator ==(Object other) => other is MediaReady && other.url == url;

  @override
  int get hashCode => Object.hash(MediaReady, url);
}

/// The media cannot be loaded right now (offline, pending, or failed). The UI
/// shows a `MediaPlaceholder` for this state.
class MediaUnavailable extends MediaLoadState {
  const MediaUnavailable();

  @override
  bool operator ==(Object other) => other is MediaUnavailable;

  @override
  int get hashCode => (MediaUnavailable).hashCode;
}

/// Resolves and owns the [MediaLoadState] for a single media item, keyed by
/// `mediaId`.
///
/// Resolution rules (Requirements 7.2-7.4, 10.2):
/// - Offline -> [MediaUnavailable] (no network request is attempted).
/// - Online + repository returns a non-empty read URL -> [MediaReady].
/// - Online + repository fails or returns an empty URL -> [MediaUnavailable].
///
/// The controller depends only on project-owned providers
/// ([mediaRepositoryProvider], [networkStatusProvider]) and never constructs a
/// URL or calls Dio directly (Requirement 7.5).
///
/// Because [build] watches [networkStatusProvider], the controller
/// automatically re-resolves when connectivity is restored, allowing a
/// placeholder to upgrade to loaded media (Requirement 10.5). [retry] forces a
/// fresh resolution for the image retry control (Requirement 8.5).
class MediaUrlController extends AsyncNotifier<MediaLoadState> {
  MediaUrlController(this.mediaId);

  final String mediaId;

  @override
  Future<MediaLoadState> build() async {
    // Watching the network status future re-runs `build` (and therefore
    // re-resolves the read URL) whenever connectivity changes, so a media item
    // shown as unavailable while offline is re-resolved once back online.
    final NetworkStatus status = await ref.watch(networkStatusProvider.future);
    return _resolve(status);
  }

  /// Re-requests the Authorized Read URL and re-attempts resolution.
  Future<void> retry() async {
    state = const AsyncValue<MediaLoadState>.loading();
    try {
      final NetworkStatus status = await ref.read(networkStatusProvider.future);
      state = AsyncValue<MediaLoadState>.data(await _resolve(status));
    } catch (_) {
      state = const AsyncValue<MediaLoadState>.data(MediaUnavailable());
    }
  }

  Future<MediaLoadState> _resolve(NetworkStatus status) async {
    if (status.isOffline) {
      return const MediaUnavailable();
    }

    try {
      final MediaReadUrlDto readUrl =
          await ref.read(mediaRepositoryProvider).createReadUrl(mediaId);

      if (readUrl.url.isEmpty) {
        return const MediaUnavailable();
      }

      return MediaReady(readUrl.url);
    } catch (_) {
      // Any failure (including ApiException) degrades to a placeholder rather
      // than leaking the error to the UI.
      return const MediaUnavailable();
    }
  }
}

/// Family controller keyed by `mediaId`, exposing the [MediaLoadState] for each
/// media item independently so items load, fail, and retry on their own.
final mediaUrlControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MediaUrlController, MediaLoadState, String>(
  MediaUrlController.new,
);
