import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'app_database.dart';
import 'cache_models.dart';

class LocalPinsDao {
  const LocalPinsDao(this.database);

  final AppDatabase database;

  Future<void> upsertPin(PinDto pin, {DateTime? syncedAt}) async {
    final Database db = await database.database;
    final CachedPin cachedPin = CachedPin(pin: pin, syncedAt: syncedAt);

    await db.insert(
      'cached_pins',
      cachedPin.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PinDto?> getPin(String id) async {
    final Database db = await database.database;
    final List<JsonMap> rows = await db.query(
      'cached_pins',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return CachedPin.fromMap(rows.first).pin;
  }

  Future<List<PinDto>> listPinsForMap(String mapId) async {
    final Database db = await database.database;
    final List<JsonMap> rows = await db.query(
      'cached_pins',
      where: 'map_id = ?',
      whereArgs: <Object?>[mapId],
      orderBy: 'memory_date DESC, created_at DESC',
    );

    return rows
        .map((JsonMap row) => CachedPin.fromMap(row).pin)
        .toList(growable: false);
  }
}

class UploadQueueDao {
  const UploadQueueDao(this.database);

  final AppDatabase database;

  Future<void> enqueuePinMutation(PendingPinMutation mutation) async {
    final Database db = await database.database;

    await db.insert(
      'pending_pin_mutations',
      mutation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PendingPinMutation>> listPendingPinMutations() async {
    final Database db = await database.database;
    final List<JsonMap> rows = await db.query(
      'pending_pin_mutations',
      orderBy: 'created_at ASC',
    );

    return rows
        .map(PendingPinMutation.fromMap)
        .toList(growable: false);
  }

  Future<void> enqueueMediaUpload(PendingMediaUpload upload) async {
    final Database db = await database.database;

    await db.insert(
      'pending_media_uploads',
      upload.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PendingMediaUpload>> listPendingMediaUploads() async {
    final Database db = await database.database;
    final List<JsonMap> rows = await db.query(
      'pending_media_uploads',
      orderBy: 'created_at ASC',
    );

    return rows
        .map(PendingMediaUpload.fromMap)
        .toList(growable: false);
  }
}
