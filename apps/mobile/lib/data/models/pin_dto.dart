import 'json.dart';
import 'media_dto.dart';

class PinDto {
  const PinDto({
    required this.id,
    required this.mapId,
    required this.title,
    required this.note,
    required this.memoryDate,
    required this.lat,
    required this.lng,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
    this.clientId,
  });

  factory PinDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'pin');

    return PinDto(
      id: readString(json, 'id'),
      mapId: readString(json, 'mapId'),
      title: readString(json, 'title'),
      note: readOptionalString(json, 'note'),
      memoryDate: readOptionalDateTime(json, 'memoryDate'),
      lat: readDouble(json, 'lat'),
      lng: readDouble(json, 'lng'),
      media: asJsonMapList(json['media'], name: 'media')
          .map(PinMediaDto.fromJson)
          .toList(growable: false),
      createdAt: readDateTime(json, 'createdAt'),
      updatedAt: readDateTime(json, 'updatedAt'),
      clientId: readOptionalString(json, 'clientId'),
    );
  }

  final String id;
  final String mapId;
  final String title;
  final String? note;
  final DateTime? memoryDate;
  final double lat;
  final double lng;
  final List<PinMediaDto> media;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? clientId;

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'mapId': mapId,
      'title': title,
      'note': note,
      'memoryDate': memoryDate == null ? null : writeDateTime(memoryDate!),
      'lat': lat,
      'lng': lng,
      'media': media.map((PinMediaDto item) => item.toJson()).toList(),
      'createdAt': writeDateTime(createdAt),
      'updatedAt': writeDateTime(updatedAt),
      'clientId': clientId,
    };
  }
}

class CreatePinRequestDto {
  const CreatePinRequestDto({
    required this.title,
    required this.lat,
    required this.lng,
    this.note,
    this.memoryDate,
    this.clientId,
  });

  final String title;
  final String? note;
  final DateTime? memoryDate;
  final double lat;
  final double lng;
  final String? clientId;

  JsonMap toJson() {
    return <String, Object?>{
      'title': title,
      'note': note,
      'memoryDate': memoryDate == null ? null : writeDateTime(memoryDate!),
      'lat': lat,
      'lng': lng,
      'clientId': clientId,
    };
  }
}
