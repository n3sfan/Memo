import 'json.dart';

enum MemoryMapType {
  personal,
  duo;

  static MemoryMapType fromWire(String value) {
    return switch (value) {
      'personal' => MemoryMapType.personal,
      'duo' => MemoryMapType.duo,
      _ => throw FormatException('Unknown map type: $value'),
    };
  }

  String toWire() {
    return switch (this) {
      MemoryMapType.personal => 'personal',
      MemoryMapType.duo => 'duo',
    };
  }
}

class MapDto {
  const MapDto({
    required this.id,
    required this.type,
    required this.ownerId,
    this.name,
  });

  factory MapDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'map');

    return MapDto(
      id: readString(json, 'id'),
      type: MemoryMapType.fromWire(readString(json, 'type')),
      ownerId: readString(json, 'ownerId'),
      name: readOptionalString(json, 'name'),
    );
  }

  final String id;
  final MemoryMapType type;
  final String ownerId;
  final String? name;

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'type': type.toWire(),
      'ownerId': ownerId,
      'name': name,
    };
  }
}
