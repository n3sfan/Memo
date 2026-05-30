import 'dart:convert';

import '../models/models.dart';

class CachedPin {
  const CachedPin({
    required this.pin,
    this.syncedAt,
  });

  factory CachedPin.fromMap(JsonMap map) {
    final String mediaJson = readString(map, 'media_json');
    final List<PinMediaDto> media = asJsonMapList(
      jsonDecode(mediaJson),
      name: 'media_json',
    ).map(PinMediaDto.fromJson).toList(growable: false);

    return CachedPin(
      pin: PinDto(
        id: readString(map, 'id'),
        mapId: readString(map, 'map_id'),
        title: readString(map, 'title'),
        note: readOptionalString(map, 'note'),
        memoryDate: readOptionalDateTime(map, 'memory_date'),
        lat: readDouble(map, 'lat'),
        lng: readDouble(map, 'lng'),
        media: media,
        createdAt: readDateTime(map, 'created_at'),
        updatedAt: readDateTime(map, 'updated_at'),
        clientId: readOptionalString(map, 'client_id'),
      ),
      syncedAt: readOptionalDateTime(map, 'synced_at'),
    );
  }

  final PinDto pin;
  final DateTime? syncedAt;

  JsonMap toMap() {
    return <String, Object?>{
      'id': pin.id,
      'client_id': pin.clientId,
      'map_id': pin.mapId,
      'title': pin.title,
      'note': pin.note,
      'memory_date': pin.memoryDate == null ? null : writeDateTime(pin.memoryDate!),
      'lat': pin.lat,
      'lng': pin.lng,
      'media_json': jsonEncode(
        pin.media.map((PinMediaDto item) => item.toJson()).toList(),
      ),
      'created_at': writeDateTime(pin.createdAt),
      'updated_at': writeDateTime(pin.updatedAt),
      'synced_at': syncedAt == null ? null : writeDateTime(syncedAt!),
    };
  }
}

class PendingPinMutation {
  const PendingPinMutation({
    required this.id,
    required this.clientId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
  });

  factory PendingPinMutation.fromMap(JsonMap map) {
    return PendingPinMutation(
      id: readString(map, 'id'),
      clientId: readString(map, 'client_id'),
      operation: readString(map, 'operation'),
      payload: asJsonMap(
        jsonDecode(readString(map, 'payload_json')),
        name: 'payload_json',
      ),
      createdAt: readDateTime(map, 'created_at'),
      retryCount: readInt(map, 'retry_count'),
    );
  }

  final String id;
  final String clientId;
  final String operation;
  final JsonMap payload;
  final DateTime createdAt;
  final int retryCount;

  JsonMap toMap() {
    return <String, Object?>{
      'id': id,
      'client_id': clientId,
      'operation': operation,
      'payload_json': jsonEncode(payload),
      'created_at': writeDateTime(createdAt),
      'retry_count': retryCount,
    };
  }
}

class PendingMediaUpload {
  const PendingMediaUpload({
    required this.id,
    required this.pinClientId,
    required this.localPath,
    required this.mediaType,
    required this.mimeType,
    required this.sizeBytes,
    required this.fileName,
    required this.createdAt,
    required this.retryCount,
  });

  factory PendingMediaUpload.fromMap(JsonMap map) {
    return PendingMediaUpload(
      id: readString(map, 'id'),
      pinClientId: readString(map, 'pin_client_id'),
      localPath: readString(map, 'local_path'),
      mediaType: PinMediaType.fromWire(readString(map, 'media_type')),
      mimeType: readString(map, 'mime_type'),
      sizeBytes: readInt(map, 'size_bytes'),
      fileName: readString(map, 'file_name'),
      createdAt: readDateTime(map, 'created_at'),
      retryCount: readInt(map, 'retry_count'),
    );
  }

  final String id;
  final String pinClientId;
  final String localPath;
  final PinMediaType mediaType;
  final String mimeType;
  final int sizeBytes;
  final String fileName;
  final DateTime createdAt;
  final int retryCount;

  JsonMap toMap() {
    return <String, Object?>{
      'id': id,
      'pin_client_id': pinClientId,
      'local_path': localPath,
      'media_type': mediaType.toWire(),
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'file_name': fileName,
      'created_at': writeDateTime(createdAt),
      'retry_count': retryCount,
    };
  }
}
