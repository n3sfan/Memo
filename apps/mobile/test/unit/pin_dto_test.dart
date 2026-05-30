import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/models/models.dart';

void main() {
  test('serializes and deserializes PinDto', () {
    final PinDto pin = PinDto(
      id: 'pin_1',
      mapId: 'map_1',
      title: 'Da Lat trip',
      note: 'First day',
      memoryDate: DateTime.utc(2026, 5, 30),
      lat: 11.9404,
      lng: 108.4583,
      media: const <PinMediaDto>[],
      createdAt: DateTime.utc(2026, 5, 30, 10),
      updatedAt: DateTime.utc(2026, 5, 30, 10),
      clientId: 'local_pin_1',
    );

    final PinDto parsed = PinDto.fromJson(pin.toJson());

    expect(parsed.id, pin.id);
    expect(parsed.mapId, pin.mapId);
    expect(parsed.title, pin.title);
    expect(parsed.note, pin.note);
    expect(parsed.memoryDate, pin.memoryDate);
    expect(parsed.lat, pin.lat);
    expect(parsed.lng, pin.lng);
    expect(parsed.clientId, pin.clientId);
  });
}
