import 'json.dart';

class Coordinates {
  const Coordinates({
    required this.lat,
    required this.lng,
  });

  factory Coordinates.fromJson(JsonMap json) {
    return Coordinates(
      lat: readDouble(json, 'lat'),
      lng: readDouble(json, 'lng'),
    );
  }

  final double lat;
  final double lng;

  JsonMap toJson() {
    return <String, Object?>{
      'lat': lat,
      'lng': lng,
    };
  }
}

class BboxQuery {
  const BboxQuery({
    required this.minLng,
    required this.minLat,
    required this.maxLng,
    required this.maxLat,
  });

  final double minLng;
  final double minLat;
  final double maxLng;
  final double maxLat;

  String serialize() {
    return '$minLng,$minLat,$maxLng,$maxLat';
  }

  JsonMap toJson() {
    return <String, Object?>{
      'minLng': minLng,
      'minLat': minLat,
      'maxLng': maxLng,
      'maxLat': maxLat,
    };
  }
}
