// Feature: timeline-pin-detail-media-viewer, Property 5: Media load resolves to ready only with a non-empty URL
//
// Property 5 (design.md "Correctness Properties"):
//   For any media id, when the network is offline the resolved
//   `MediaLoadState` is `MediaUnavailable`; when online and the repository
//   returns a non-empty read URL the state is `MediaReady` with that URL; and
//   when the repository fails the state is `MediaUnavailable`.
//
// Validates: Requirements 7.3, 7.4, 10.2
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glados/glados.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/media_repository.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';
import 'package:memory_map_mobile/media/media_url_controller.dart';
import 'package:memory_map_mobile/sync/network_monitor.dart';

/// A [NetworkMonitor] that always reports a fixed [NetworkStatus], letting the
/// test drive connectivity deterministically.
class _FakeNetworkMonitor implements NetworkMonitor {
  _FakeNetworkMonitor(this.status);

  final NetworkStatus status;

  @override
  Future<NetworkStatus> currentStatus() async => status;

  // No connectivity changes during the test: the initial `currentStatus`
  // fully determines resolution. Returning an empty (immediately-completing)
  // stream keeps each generated iteration self-contained and deterministic so
  // the provider does not re-resolve while the container is being disposed.
  @override
  Stream<NetworkStatus> statusChanges() => const Stream<NetworkStatus>.empty();
}

/// A [MediaRepository] whose `createReadUrl` either returns a read URL with a
/// generated url, or throws. The upload-oriented methods are never exercised by
/// the controller and throw if called.
class _FakeMediaRepository implements MediaRepository {
  _FakeMediaRepository({required this.shouldFail, required this.url});

  final bool shouldFail;
  final String url;

  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) async {
    if (shouldFail) {
      throw Exception('read url failed for $mediaId');
    }
    return MediaReadUrlDto(
      url: url,
      expiresAt: DateTime.utc(2026, 1, 1).add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<PresignResponseDto> createPresignedUpload({
    required String pinId,
    required PresignRequestDto request,
  }) =>
      throw UnimplementedError();

  @override
  Future<PinMediaDto> registerMedia({
    required String pinId,
    required RegisterMediaRequestDto request,
  }) =>
      throw UnimplementedError();
}

/// A generated outcome for the fake repository's `createReadUrl`: either a
/// failure, or a success carrying a non-empty read URL.
class _RepoOutcome {
  const _RepoOutcome({required this.shouldFail, required this.url});

  final bool shouldFail;
  final String url;
}

extension MediaResolutionAny on Any {
  Generator<NetworkStatus> get networkStatus => any.choose(
        const <NetworkStatus>[NetworkStatus.online, NetworkStatus.offline],
      );

  /// A repository outcome: half the time a failure, half the time a success
  /// with a non-empty url. The "presign" path always yields a non-empty value,
  /// so a non-empty alphabet keeps the generator inside the valid input space.
  // ignore: library_private_types_in_public_api
  Generator<_RepoOutcome> get repoOutcome => combine2(
        any.bool,
        any.nonEmptyLetterOrDigits,
        (bool shouldFail, String slug) => _RepoOutcome(
          shouldFail: shouldFail,
          url: 'https://storage.memo.local/read/$slug',
        ),
      );
}

void main() {
  // Glados runs 100 generated cases by default.
  Glados3<String, NetworkStatus, _RepoOutcome>(
    any.nonEmptyLetterOrDigits,
    any.networkStatus,
    any.repoOutcome,
  ).test(
    'media load resolves to MediaReady only when online with a non-empty url',
    (String mediaId, NetworkStatus status, _RepoOutcome outcome) async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          networkMonitorProvider.overrideWithValue(
            _FakeNetworkMonitor(status),
          ),
          mediaRepositoryProvider.overrideWithValue(
            _FakeMediaRepository(
              shouldFail: outcome.shouldFail,
              url: outcome.url,
            ),
          ),
        ],
      );

      try {
        // Keep the autoDispose family member alive while we await it so it is
        // not disposed mid-build (which would leave the future uncompleted).
        container.listen(
          mediaUrlControllerProvider(mediaId),
          (_, __) {},
        );

        final MediaLoadState resolved =
            await container.read(mediaUrlControllerProvider(mediaId).future);

        if (status.isOffline) {
          // Offline never attempts a request and degrades to a placeholder.
          expect(resolved, const MediaUnavailable());
        } else if (outcome.shouldFail) {
          // Online but the repository failed -> placeholder.
          expect(resolved, const MediaUnavailable());
        } else {
          // Online + a non-empty read URL -> ready with that exact url.
          expect(resolved, isA<MediaReady>());
          expect((resolved as MediaReady).url, outcome.url);
        }
      } finally {
        container.dispose();
      }
    },
  );

  test(
    'media automatically resolves when connectivity returns',
    () async {
      final StreamController<NetworkStatus> changes =
          StreamController<NetworkStatus>.broadcast();
      final _ChangingNetworkMonitor monitor = _ChangingNetworkMonitor(
        current: NetworkStatus.offline,
        changes: changes.stream,
      );
      final _RecordingMediaRepository repository = _RecordingMediaRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          networkMonitorProvider.overrideWithValue(monitor),
          mediaRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final Completer<MediaLoadState> recovered = Completer<MediaLoadState>();
      final subscription = container.listen(
        mediaUrlControllerProvider('media_recovery'),
        (_, AsyncValue<MediaLoadState> next) {
          final MediaLoadState? value = next.value;
          if (value is MediaReady && !recovered.isCompleted) {
            recovered.complete(value);
          }
        },
        fireImmediately: true,
      );

      try {
        final MediaLoadState offline = await container.read(
          mediaUrlControllerProvider('media_recovery').future,
        );
        expect(offline, const MediaUnavailable());
        expect(repository.requestedIds, isEmpty);

        changes.add(NetworkStatus.online);

        final MediaLoadState online = await recovered.future.timeout(
          const Duration(seconds: 1),
        );
        expect(online, isA<MediaReady>());
        expect(repository.requestedIds, <String>['media_recovery']);
      } finally {
        subscription.close();
        container.dispose();
        await changes.close();
      }
    },
  );

  test('retry settles on unavailable when network status lookup fails',
      () async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        networkMonitorProvider.overrideWithValue(
          const _ThrowingNetworkMonitor(),
        ),
        mediaRepositoryProvider.overrideWithValue(
          _RecordingMediaRepository(),
        ),
      ],
    );
    final subscription = container.listen(
      mediaUrlControllerProvider('media_network_error'),
      (_, __) {},
    );

    try {
      await expectLater(
        container.read(
          mediaUrlControllerProvider('media_network_error').future,
        ),
        throwsStateError,
      );

      await container
          .read(
            mediaUrlControllerProvider('media_network_error').notifier,
          )
          .retry();

      expect(
        container.read(mediaUrlControllerProvider('media_network_error')).value,
        const MediaUnavailable(),
      );
    } finally {
      subscription.close();
      container.dispose();
    }
  });
}

class _ChangingNetworkMonitor implements NetworkMonitor {
  _ChangingNetworkMonitor({required this.current, required this.changes});

  final NetworkStatus current;
  final Stream<NetworkStatus> changes;

  @override
  Future<NetworkStatus> currentStatus() async => current;

  @override
  Stream<NetworkStatus> statusChanges() => changes;
}

class _ThrowingNetworkMonitor implements NetworkMonitor {
  const _ThrowingNetworkMonitor();

  @override
  Future<NetworkStatus> currentStatus() {
    throw StateError('network status unavailable');
  }

  @override
  Stream<NetworkStatus> statusChanges() => const Stream<NetworkStatus>.empty();
}

class _RecordingMediaRepository implements MediaRepository {
  final List<String> requestedIds = <String>[];

  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) async {
    requestedIds.add(mediaId);
    return MediaReadUrlDto(
      url: 'https://storage.memo.local/read/$mediaId',
      expiresAt: DateTime.utc(2026, 6, 7, 12, 15),
    );
  }

  @override
  Future<PresignResponseDto> createPresignedUpload({
    required String pinId,
    required PresignRequestDto request,
  }) =>
      throw UnimplementedError();

  @override
  Future<PinMediaDto> registerMedia({
    required String pinId,
    required RegisterMediaRequestDto request,
  }) =>
      throw UnimplementedError();
}
