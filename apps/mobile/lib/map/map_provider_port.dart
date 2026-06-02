import 'package:flutter/widgets.dart';

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

class MapViewConfig {
  const MapViewConfig({
    required this.initialCamera,
    required this.markers,
    required this.onViewportChanged,
    required this.onMarkerTap,
    required this.onTap,
    required this.onLongPress,
  });

  final MapCameraPosition initialCamera;
  final List<MapMarkerModel> markers;
  final ValueChanged<BboxQuery> onViewportChanged;
  final ValueChanged<String> onMarkerTap;
  final ValueChanged<Coordinates> onTap;
  final ValueChanged<Coordinates> onLongPress;
}

typedef MapViewWidgetBuilder = Widget Function(
  BuildContext context,
  MapViewConfig config,
);

abstract interface class MapViewportController {
  Stream<BboxQuery> get visibleBounds;

  Future<void> moveTo(MapCameraPosition position);

  Future<void> fitBounds(BboxQuery bounds);
}

abstract interface class MapProviderAdapter {
  MapProviderKind get kind;
}
