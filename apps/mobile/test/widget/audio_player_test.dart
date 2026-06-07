import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/media_repository.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';
import 'package:memory_map_mobile/media/audio_playback_port.dart';
import 'package:memory_map_mobile/media/audio_player.dart';
import 'package:memory_map_mobile/sync/network_monitor.dart';

void main() {
  testWidgets('audio players keep playback state isolated per media item', (
    WidgetTester tester,
  ) async {
    final Map<String, _FakeAudioPlaybackPort> ports =
        <String, _FakeAudioPlaybackPort>{
      'audio_1': _FakeAudioPlaybackPort(),
      'audio_2': _FakeAudioPlaybackPort(),
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkMonitorProvider.overrideWithValue(
            const _OnlineNetworkMonitor(),
          ),
          mediaRepositoryProvider.overrideWithValue(
            _SuccessfulMediaRepository(),
          ),
          audioPlaybackPortProvider.overrideWith(
            (ref, mediaId) => ports[mediaId]!,
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: const Scaffold(
            body: Column(
              children: [
                AudioPlayer(mediaId: 'audio_1'),
                AudioPlayer(mediaId: 'audio_2'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('audio-play-button-audio_1')),
    );
    await tester.pump();

    expect(ports['audio_1']!.playedUrls, hasLength(1));
    expect(ports['audio_2']!.playedUrls, isEmpty);
    expect(
      find.byKey(const ValueKey<String>('audio-pause-button-audio_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('audio-play-button-audio_2')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('audio-pause-button-audio_1')),
    );
    await tester.pump();

    expect(ports['audio_1']!.pauseCalls, 1);
    expect(
      find.byKey(const ValueKey<String>('audio-play-button-audio_1')),
      findsOneWidget,
    );
  });

  testWidgets('audio hides playback controls when the read URL is unavailable',
      (WidgetTester tester) async {
    int createdPlaybackPorts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkMonitorProvider.overrideWithValue(
            const _OnlineNetworkMonitor(),
          ),
          mediaRepositoryProvider.overrideWithValue(
            _FailingMediaRepository(),
          ),
          audioPlaybackPortProvider.overrideWith(
            (ref, mediaId) {
              createdPlaybackPorts++;
              return _FakeAudioPlaybackPort();
            },
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: const Scaffold(
            body: AudioPlayer(
              mediaId: 'audio_unavailable',
              unavailableMessage: 'Audio unavailable',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audio unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(createdPlaybackPorts, 0);
  });

  testWidgets('audio hides controls when playback fails to load',
      (WidgetTester tester) async {
    final _FakeAudioPlaybackPort port = _FakeAudioPlaybackPort(
      failOnPlay: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          networkMonitorProvider.overrideWithValue(
            const _OnlineNetworkMonitor(),
          ),
          mediaRepositoryProvider.overrideWithValue(
            _SuccessfulMediaRepository(),
          ),
          audioPlaybackPortProvider.overrideWith(
            (ref, mediaId) => port,
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: const Scaffold(
            body: AudioPlayer(
              mediaId: 'audio_fails',
              unavailableMessage: 'Audio unavailable',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('audio-play-button-audio_fails')),
    );
    await tester.pump();

    expect(find.text('Audio unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.pause), findsNothing);
  });
}

class _FakeAudioPlaybackPort implements AudioPlaybackPort {
  _FakeAudioPlaybackPort({this.failOnPlay = false});

  final bool failOnPlay;
  final StreamController<AudioPlaybackState> _states =
      StreamController<AudioPlaybackState>.broadcast();
  final List<String> playedUrls = <String>[];
  int pauseCalls = 0;
  AudioPlaybackState _state = AudioPlaybackState.idle;

  @override
  AudioPlaybackState get state => _state;

  @override
  Stream<AudioPlaybackState> get stateChanges => _states.stream;

  @override
  Future<void> play(String url) async {
    playedUrls.add(url);
    _state = AudioPlaybackState(
      status:
          failOnPlay ? AudioPlaybackStatus.failed : AudioPlaybackStatus.playing,
      url: url,
    );
    _states.add(_state);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _state = _state.copyWith(status: AudioPlaybackStatus.paused);
    _states.add(_state);
  }

  @override
  Future<void> dispose() => _states.close();
}

class _SuccessfulMediaRepository implements MediaRepository {
  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) async {
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

class _FailingMediaRepository extends _SuccessfulMediaRepository {
  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) {
    throw StateError('read URL unavailable');
  }
}

class _OnlineNetworkMonitor implements NetworkMonitor {
  const _OnlineNetworkMonitor();

  @override
  Future<NetworkStatus> currentStatus() async => NetworkStatus.online;

  @override
  Stream<NetworkStatus> statusChanges() => const Stream<NetworkStatus>.empty();
}
