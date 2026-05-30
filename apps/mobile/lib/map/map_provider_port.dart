import '../data/models/coordinates.dart';

enum MapProviderKind {
  openStreetMap,
  mapbox,
}

class MapCameraPosition {
  const MapCameraPosition({
    required this.center,
    required this.zoom,
    this.bearing = 0,
    this.pitch = 0,
  });

  final Coordinates center;
  final double zoom;
  final double bearing;
  final double pitch;
}

class MapMarkerModel {
  const MapMarkerModel({
    required this.id,
    required this.position,
    this.selected = false,
  });

  final String id;
  final Coordinates position;
  final bool selected;
}

abstract interface class MapViewportController {
  Stream<BboxQuery> get visibleBounds;

  Future<void> moveTo(MapCameraPosition position);

  Future<void> fitBounds(BboxQuery bounds);
}

abstract interface class MapProviderAdapter {
  MapProviderKind get kind;
}
