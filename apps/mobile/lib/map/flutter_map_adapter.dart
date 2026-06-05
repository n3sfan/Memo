import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models/coordinates.dart';
import 'bbox_bounds.dart';
import 'map_provider_port.dart';

Widget buildOpenStreetMapView(BuildContext context, MapViewConfig config) {
  return _OpenStreetMapView(config: config);
}

class _OpenStreetMapView extends StatefulWidget {
  const _OpenStreetMapView({required this.config});

  final MapViewConfig config;

  @override
  State<_OpenStreetMapView> createState() => _OpenStreetMapViewState();
}

class _OpenStreetMapViewState extends State<_OpenStreetMapView> {
  final MapController _controller = MapController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _toLatLng(widget.config.initialCamera.center),
              initialZoom: widget.config.initialCamera.zoom,
              minZoom: 3,
              maxZoom: 18,
              onMapReady: _emitCurrentBounds,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                _emitBounds(camera);
              },
              onTap: (_, LatLng point) {
                widget.config.onTap(
                  Coordinates(lat: point.latitude, lng: point.longitude),
                );
              },
              onLongPress: (_, LatLng point) {
                widget.config.onLongPress(
                  Coordinates(lat: point.latitude, lng: point.longitude),
                );
              },
            ),
            children: <Widget>[
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.memodev.memory_map_mobile',
              ),
              MarkerLayer(
                markers: widget.config.markers.map(_buildMarker).toList(
                      growable: false,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Marker _buildMarker(MapMarkerModel marker) {
    return Marker(
      key: ValueKey<String>('map-marker-${marker.id}'),
      point: _toLatLng(marker.position),
      width: 44,
      height: 44,
      alignment: Alignment.topCenter,
      child: IconButton.filled(
        onPressed: () => widget.config.onMarkerTap(marker.id),
        icon: const Icon(Icons.location_on),
        tooltip: 'Open memory',
        style: IconButton.styleFrom(
          backgroundColor: marker.selected
              ? const Color(0xFF2E7D32)
              : const Color(0xFF5B4B8A),
          foregroundColor: Colors.white,
          shadowColor: Colors.black38,
          elevation: 3,
        ),
      ),
    );
  }

  void _emitCurrentBounds() {
    _emitBounds(_controller.camera);
  }

  void _emitBounds(MapCamera camera) {
    final LatLngBounds bounds = camera.visibleBounds;
    widget.config.onViewportChanged(
      bboxFromEdges(
        west: bounds.west,
        south: bounds.south,
        east: bounds.east,
        north: bounds.north,
      ),
    );
  }

  LatLng _toLatLng(Coordinates coordinates) {
    return LatLng(coordinates.lat, coordinates.lng);
  }
}
