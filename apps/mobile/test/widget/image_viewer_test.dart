import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/media_repository.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';
import 'package:memory_map_mobile/media/image_viewer.dart';
import 'package:memory_map_mobile/media/media_placeholder.dart';
import 'package:memory_map_mobile/sync/network_monitor.dart';

void main() {
  testWidgets('image viewer retry requests a fresh authorized URL',
      (WidgetTester tester) async {
    final _RecordingFailingMediaRepository repository =
        _RecordingFailingMediaRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkMonitorProvider.overrideWithValue(
            const _OnlineNetworkMonitor(),
          ),
          mediaRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: ImageViewer(
            mediaId: 'image_retry',
            unavailableMessage: 'Image unavailable',
            retryLabel: 'Retry',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MediaPlaceholder), findsOneWidget);
    expect(repository.requestedIds, <String>['image_retry']);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.requestedIds, <String>['image_retry', 'image_retry']);
    expect(find.byType(MediaPlaceholder), findsOneWidget);
  });
}

class _RecordingFailingMediaRepository implements MediaRepository {
  final List<String> requestedIds = <String>[];

  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) async {
    requestedIds.add(mediaId);
    throw StateError('read URL unavailable');
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

class _OnlineNetworkMonitor implements NetworkMonitor {
  const _OnlineNetworkMonitor();

  @override
  Future<NetworkStatus> currentStatus() async => NetworkStatus.online;

  @override
  Stream<NetworkStatus> statusChanges() => const Stream<NetworkStatus>.empty();
}
