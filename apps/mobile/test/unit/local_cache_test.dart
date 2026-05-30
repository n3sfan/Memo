import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/data/db/app_database.dart';
import 'package:memory_map_mobile/data/db/daos.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('inserts and reads cached pin', () async {
    final AppDatabase database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    final LocalPinsDao dao = LocalPinsDao(database);
    final PinDto pin = PinDto(
      id: 'pin_cache_1',
      mapId: 'map_1',
      title: 'Cached memory',
      note: 'Offline first',
      memoryDate: DateTime.utc(2026, 5, 30),
      lat: 11.9404,
      lng: 108.4583,
      media: const <PinMediaDto>[],
      createdAt: DateTime.utc(2026, 5, 30, 10),
      updatedAt: DateTime.utc(2026, 5, 30, 10),
      clientId: 'local_pin_cache_1',
    );

    await dao.upsertPin(pin, syncedAt: DateTime.utc(2026, 5, 30, 10, 1));

    final PinDto? cached = await dao.getPin(pin.id);

    expect(cached, isNotNull);
    expect(cached?.id, pin.id);
    expect(cached?.title, pin.title);
    expect(cached?.lat, pin.lat);

    await database.close();
  });
}
