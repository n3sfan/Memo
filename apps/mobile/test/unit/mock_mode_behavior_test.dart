import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/pin_detail_controller.dart';
import 'package:memory_map_mobile/data/mock/fake_media_repository.dart';
import 'package:memory_map_mobile/data/mock/fake_pin_repository.dart';
import 'package:memory_map_mobile/data/mock/fake_timeline_repository.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/repositories.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

/// End-to-end verification that mock-mode wiring (Requirement 11) resolves the
/// feature's repositories to their fakes when `USE_MOCK_DATA` is enabled and
/// that a fake failure surfaces an error state rather than falling back to a
/// real (API) repository.
///
/// `USE_MOCK_DATA` is read in `repository_providers.dart` via
/// `useMockRepositoriesProvider`, a `Provider<bool>` wrapping
/// `const bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false)`. Because
/// the compile-time const is wrapped in an overridable provider, these tests
/// toggle it at runtime with `overrideWithValue(true)`.
void main() {
  /// Builds a container with mock mode enabled, exactly as `USE_MOCK_DATA=true`
  /// would at runtime. An optional [pinRepository] override lets a test inject
  /// a failing fake to prove there is no real-repository fallback.
  ProviderContainer mockModeContainer({PinRepository? pinRepository}) {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        useMockRepositoriesProvider.overrideWithValue(true),
        if (pinRepository != null)
          pinRepositoryProvider.overrideWithValue(pinRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('USE_MOCK_DATA=true resolves the feature repositories to fakes', () {
    test(
        'timelineRepositoryProvider resolves to the fake timeline repository '
        '(Req 11.1)', () {
      final ProviderContainer container = mockModeContainer();

      final TimelineRepository repository =
          container.read(timelineRepositoryProvider);

      expect(repository, isA<FakeTimelineRepository>());
      expect(repository, isNot(isA<ApiTimelineRepository>()));
    });

    test(
        'pinRepositoryProvider resolves to the fake pin repository '
        '(Req 11.2)', () {
      final ProviderContainer container = mockModeContainer();

      final PinRepository repository = container.read(pinRepositoryProvider);

      expect(repository, isA<FakePinRepository>());
      expect(repository, isNot(isA<ApiPinRepository>()));
    });

    test(
        'mediaRepositoryProvider resolves to the fake media repository '
        '(Req 11.3)', () {
      final ProviderContainer container = mockModeContainer();

      final MediaRepository repository =
          container.read(mediaRepositoryProvider);

      expect(repository, isA<FakeMediaRepository>());
      expect(repository, isNot(isA<ApiMediaRepository>()));
    });

    test(
        'the fake media repository returns an Authorized Read URL for a media '
        'id (Req 11.3, 11.4)', () async {
      final ProviderContainer container = mockModeContainer();

      final MediaRepository repository =
          container.read(mediaRepositoryProvider);
      final MediaReadUrlDto readUrl = await repository.createReadUrl('media_1');

      expect(readUrl.url, isNotEmpty);
    });

    test('the default real wiring uses the API repositories (control case)',
        () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(timelineRepositoryProvider),
        isA<ApiTimelineRepository>(),
      );
      expect(container.read(pinRepositoryProvider), isA<ApiPinRepository>());
      expect(
        container.read(mediaRepositoryProvider),
        isA<ApiMediaRepository>(),
      );
    });
  });

  group(
      'a fake repository failure surfaces a localized error without falling '
      'back to real repositories (Req 11.5)', () {
    test(
        'PinDetailController surfaces an AsyncValue error from the fake repo '
        'and never resolves a real repository', () async {
      final _RecordingThrowingPinRepository fakePinRepository =
          _RecordingThrowingPinRepository();

      // Mock mode is on. We override the fake pin repository with one that
      // throws, so the failure originates from the fake; there must be no
      // fallback to ApiPinRepository.
      final ProviderContainer container = mockModeContainer(
        pinRepository: fakePinRepository,
      );

      const String pinId = 'pin_fake_fail';
      container.listen(
        pinDetailControllerProvider(pinId),
        (_, __) {},
        fireImmediately: true,
      );

      await expectLater(
        container.read(pinDetailControllerProvider(pinId).future),
        throwsA(isA<StateError>()),
      );

      // The controller exposes the error state (the screen maps this to a
      // localized message); it did not swallow the error or switch repos.
      final AsyncValue<PinDto> state =
          container.read(pinDetailControllerProvider(pinId));
      expect(state.hasError, isTrue);
      expect(state.error, isA<StateError>());

      // The fake was the only repository consulted: no fallback / no network.
      expect(fakePinRepository.getPinCalls, <String>[pinId]);
      expect(
        container.read(pinRepositoryProvider),
        same(fakePinRepository),
      );
    });

    test(
        'the seeded fake pin repository throws for an unknown pin id rather '
        'than reaching a real repository', () async {
      final ProviderContainer container = mockModeContainer();

      const String missingPinId = 'pin_does_not_exist';
      container.listen(
        pinDetailControllerProvider(missingPinId),
        (_, __) {},
        fireImmediately: true,
      );

      // The fake (seeded, no such pin) throws; the controller surfaces it as
      // an error state with no fallback to ApiPinRepository.
      await expectLater(
        container.read(pinDetailControllerProvider(missingPinId).future),
        throwsA(isA<StateError>()),
      );

      expect(container.read(pinRepositoryProvider), isA<FakePinRepository>());
    });
  });
}

/// A stand-in for the fake pin repository that records calls and always throws,
/// used to prove failures surface without a real-repository fallback.
class _RecordingThrowingPinRepository implements PinRepository {
  final List<String> getPinCalls = <String>[];

  @override
  Future<PinDto> getPin(String pinId) async {
    getPinCalls.add(pinId);
    throw StateError('fake pin request failed');
  }

  @override
  Future<List<PinDto>> listByBbox({
    required String mapId,
    required BboxQuery bbox,
  }) =>
      throw UnimplementedError();

  @override
  Future<PinDto> createPin({
    required String mapId,
    required CreatePinRequestDto request,
  }) =>
      throw UnimplementedError();

  @override
  Future<PinDto> updatePin({
    required String pinId,
    required CreatePinRequestDto request,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deletePin(String pinId) => throw UnimplementedError();
}
