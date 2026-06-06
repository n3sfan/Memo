import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/map_view_controller.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/repositories.dart';

void main() {
  const MapDto map = MapDto(
    id: 'map_test',
    type: MemoryMapType.personal,
    ownerId: 'user_test',
  );
  const BboxQuery bbox = BboxQuery(
    minLng: 106,
    minLat: 10,
    maxLng: 109,
    maxLat: 12,
  );
  final PinDto pin = PinDto(
    id: 'pin_test',
    mapId: map.id,
    title: 'Sai Gon walk',
    note: null,
    memoryDate: DateTime.utc(2026, 5, 24),
    lat: 10.7769,
    lng: 106.7009,
    media: const <PinMediaDto>[],
    createdAt: DateTime.utc(2026, 5, 24, 18),
    updatedAt: DateTime.utc(2026, 5, 24, 18),
  );

  test('loads pins from the current viewport through repositories', () async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository(
      pins: <PinDto>[pin],
    );
    final MapViewController controller = MapViewController(
      mapRepository: const _FakeMapRepository(map),
      pinRepository: pinRepository,
      debounceDuration: Duration.zero,
    );

    await controller.loadViewportNow(bbox);

    expect(controller.state.map?.id, map.id);
    expect(controller.state.pins, <PinDto>[pin]);
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.errorMessage, isNull);
    expect(controller.state.lastBbox, bbox);
    expect(pinRepository.lastMapId, map.id);
    expect(pinRepository.lastBbox, bbox);

    controller.dispose();
  });

  test('exposes an error state when pin loading fails', () async {
    final MapViewController controller = MapViewController(
      mapRepository: const _FakeMapRepository(map),
      pinRepository: _ThrowingPinRepository(),
      debounceDuration: Duration.zero,
    );

    await controller.loadViewportNow(bbox);

    expect(controller.state.pins, isEmpty);
    expect(controller.state.isLoading, isFalse);
    expect(controller.state.errorMessage, 'Could not load memories.');
    expect(controller.state.lastBbox, bbox);

    controller.dispose();
  });
}

class _FakeMapRepository implements MapRepository {
  const _FakeMapRepository(this.map);

  final MapDto map;

  @override
  Future<MapDto> getDefaultMap() async {
    return map;
  }

  @override
  Future<List<MapDto>> listMaps() async {
    return <MapDto>[map];
  }

  @override
  Future<MapDto> createDuoMap({String? name}) {
    throw UnimplementedError();
  }

  @override
  Future<InvitationDto> createInvitation({required String mapId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeInvitation({
    required String mapId,
    required String invitationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AcceptInvitationResponseDto> acceptInvitation({
    required String code,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RemoveMapMemberResponseDto> removeMember({
    required String mapId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _RecordingPinRepository implements PinRepository {
  _RecordingPinRepository({required this.pins});

  final List<PinDto> pins;
  String? lastMapId;
  BboxQuery? lastBbox;

  @override
  Future<List<PinDto>> listByBbox({
    required String mapId,
    required BboxQuery bbox,
  }) async {
    lastMapId = mapId;
    lastBbox = bbox;
    return pins;
  }

  @override
  Future<PinDto> createPin({
    required String mapId,
    required CreatePinRequestDto request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePin(String pinId) {
    throw UnimplementedError();
  }

  @override
  Future<PinDto> getPin(String pinId) {
    throw UnimplementedError();
  }

  @override
  Future<PinDto> updatePin({
    required String pinId,
    required CreatePinRequestDto request,
  }) {
    throw UnimplementedError();
  }
}

class _ThrowingPinRepository extends _RecordingPinRepository {
  _ThrowingPinRepository() : super(pins: const <PinDto>[]);

  @override
  Future<List<PinDto>> listByBbox({
    required String mapId,
    required BboxQuery bbox,
  }) async {
    throw StateError('network failed');
  }
}
