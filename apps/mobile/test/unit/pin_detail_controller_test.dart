import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/pin_detail_controller.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/repositories.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

void main() {
  PinDto pin(String id) => PinDto(
        id: id,
        mapId: 'map_test',
        title: 'Pin $id',
        note: null,
        memoryDate: DateTime.utc(2026, 3, 10),
        lat: 10.5,
        lng: 106.5,
        media: const <PinMediaDto>[],
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  /// Builds a container with the pin repository overridden, and keeps the
  /// autoDispose family member alive so its future resolves while the test
  /// reads it.
  ProviderContainer buildContainer({
    required PinRepository pinRepository,
    required String pinId,
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        pinRepositoryProvider.overrideWithValue(pinRepository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      pinDetailControllerProvider(pinId),
      (_, __) {},
      fireImmediately: true,
    );
    return container;
  }

  test('successful load exposes the matching pin for the requested pinId',
      () async {
    const String pinId = 'pin_42';
    final _RecordingPinRepository repository =
        _RecordingPinRepository(result: pin(pinId));

    final ProviderContainer container = buildContainer(
      pinRepository: repository,
      pinId: pinId,
    );

    final PinDto loaded =
        await container.read(pinDetailControllerProvider(pinId).future);

    // The controller requested the pin we asked for and exposed it as data.
    expect(repository.getPinCalls, <String>[pinId]);
    expect(loaded.id, pinId);

    final AsyncValue<PinDto> state =
        container.read(pinDetailControllerProvider(pinId));
    expect(state.hasValue, isTrue);
    expect(state.value?.id, pinId);
  });

  test('repository failure surfaces an AsyncValue error state', () async {
    const String pinId = 'pin_missing';

    final ProviderContainer container = buildContainer(
      pinRepository: _ThrowingPinRepository(),
      pinId: pinId,
    );

    await expectLater(
      container.read(pinDetailControllerProvider(pinId).future),
      throwsA(isA<StateError>()),
    );

    final AsyncValue<PinDto> state =
        container.read(pinDetailControllerProvider(pinId));
    expect(state.hasError, isTrue);
    expect(state.error, isA<StateError>());
  });
}

class _RecordingPinRepository implements PinRepository {
  _RecordingPinRepository({required this.result});

  final PinDto result;
  final List<String> getPinCalls = <String>[];

  @override
  Future<PinDto> getPin(String pinId) async {
    getPinCalls.add(pinId);
    return result;
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

class _ThrowingPinRepository implements PinRepository {
  @override
  Future<PinDto> getPin(String pinId) async {
    throw StateError('pin request failed');
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
