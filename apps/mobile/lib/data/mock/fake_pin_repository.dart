import '../client_id.dart';
import '../models/models.dart';
import '../repositories/pin_repository.dart';
import 'mock_data.dart';

class FakePinRepository implements PinRepository {
  FakePinRepository(this.state);

  final MockBackendState state;

  @override
  Future<PinDto> createPin({
    required String mapId,
    required CreatePinRequestDto request,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final PinDto pin = PinDto(
      id: state.nextId('pin'),
      mapId: mapId,
      title: request.title,
      note: request.note,
      memoryDate: request.memoryDate,
      lat: request.lat,
      lng: request.lng,
      media: const <PinMediaDto>[],
      createdAt: now,
      updatedAt: now,
      clientId: request.clientId ?? createLocalClientId(prefix: 'local_pin'),
    );
    state.pins.add(pin);

    return pin;
  }

  @override
  Future<void> deletePin(String pinId) async {
    state.pins.removeWhere((PinDto pin) => pin.id == pinId);
  }

  @override
  Future<PinDto> getPin(String pinId) async {
    return state.pins.firstWhere((PinDto pin) => pin.id == pinId);
  }

  @override
  Future<List<PinDto>> listByBbox({
    required String mapId,
    required BboxQuery bbox,
  }) async {
    return state.pins
        .where(
          (PinDto pin) =>
              pin.mapId == mapId &&
              pin.lng >= bbox.minLng &&
              pin.lng <= bbox.maxLng &&
              pin.lat >= bbox.minLat &&
              pin.lat <= bbox.maxLat,
        )
        .toList(growable: false);
  }

  @override
  Future<PinDto> updatePin({
    required String pinId,
    required CreatePinRequestDto request,
  }) async {
    final int index = state.pins.indexWhere((PinDto pin) => pin.id == pinId);
    final PinDto current = state.pins[index];
    final PinDto updated = PinDto(
      id: current.id,
      mapId: current.mapId,
      title: request.title,
      note: request.note,
      memoryDate: request.memoryDate,
      lat: request.lat,
      lng: request.lng,
      media: current.media,
      createdAt: current.createdAt,
      updatedAt: DateTime.now().toUtc(),
      clientId: current.clientId,
    );
    state.pins[index] = updated;

    return updated;
  }
}
