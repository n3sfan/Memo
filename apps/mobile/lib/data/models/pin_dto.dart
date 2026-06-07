import 'json.dart';
import 'media_dto.dart';

class PinCoreDto {
  const PinCoreDto({
    required this.id,
    required this.title,
    required this.note,
    required this.memoryDate,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? note;
  final DateTime? memoryDate;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final DateTime updatedAt;

  JsonMap coreJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'note': note,
      'memoryDate': memoryDate == null ? null : writeDateTime(memoryDate!),
      'lat': lat,
      'lng': lng,
      'createdAt': writeDateTime(createdAt),
      'updatedAt': writeDateTime(updatedAt),
    };
  }
}

class PinDto extends PinCoreDto {
  const PinDto({
    required super.id,
    required this.mapId,
    required super.title,
    required super.note,
    required super.memoryDate,
    required super.lat,
    required super.lng,
    required this.media,
    required super.createdAt,
    required super.updatedAt,
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

  final String mapId;
  final List<PinMediaDto> media;
  final String? clientId;

  JsonMap toJson() {
    return <String, Object?>{
      ...coreJson(),
      'mapId': mapId,
      'media': media.map((PinMediaDto item) => item.toJson()).toList(),
      'clientId': clientId,
    };
  }
}

class PublicPinDto extends PinCoreDto {
  const PublicPinDto({
    required super.id,
    required super.title,
    required super.note,
    required super.memoryDate,
    required super.lat,
    required super.lng,
    required this.media,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PublicPinDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'public pin');

    return PublicPinDto(
      id: readString(json, 'id'),
      title: readString(json, 'title'),
      note: readOptionalString(json, 'note'),
      memoryDate: readOptionalDateTime(json, 'memoryDate'),
      lat: readDouble(json, 'lat'),
      lng: readDouble(json, 'lng'),
      media: asJsonMapList(json['media'], name: 'media')
          .map(PublicPinMediaDto.fromJson)
          .toList(growable: false),
      createdAt: readDateTime(json, 'createdAt'),
      updatedAt: readDateTime(json, 'updatedAt'),
    );
  }

  final List<PublicPinMediaDto> media;

  JsonMap toJson() {
    return <String, Object?>{
      ...coreJson(),
      'media': media.map((PublicPinMediaDto item) => item.toJson()).toList(),
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
