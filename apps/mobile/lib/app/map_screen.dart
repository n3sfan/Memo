import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/models.dart';
import '../map/map.dart';
import 'map_view_controller.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({
    this.mapViewBuilder = buildOpenStreetMapView,
    super.key,
  });

  final MapViewWidgetBuilder mapViewBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MapViewState state = ref.watch(mapViewControllerProvider);
    final MapViewController controller = ref.read(
      mapViewControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(state.map?.name ?? 'Memory Map'),
        actions: <Widget>[
          IconButton(
            onPressed: state.lastBbox == null
                ? null
                : () {
                    controller.refresh();
                  },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: mapViewBuilder(
              context,
              MapViewConfig(
                initialCamera: _initialCamera,
                markers: state.pins
                    .map(
                      (PinDto pin) => MapMarkerModel(
                        id: pin.id,
                        position: Coordinates(lat: pin.lat, lng: pin.lng),
                      ),
                    )
                    .toList(growable: false),
                onViewportChanged: controller.viewportChanged,
                onMarkerTap: (String pinId) => context.push(
                  '/pins/${Uri.encodeComponent(pinId)}',
                ),
                onLongPress: (Coordinates coordinates) {
                  _openNewPin(context, coordinates);
                },
              ),
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _MapModeSwitch(),
            ),
          ),
          if (state.isLoading)
            const Positioned(
              left: 0,
              top: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (state.errorMessage != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _MapStatusBanner(
                  icon: Icons.cloud_off_outlined,
                  label: state.errorMessage!,
                  action: TextButton.icon(
                    onPressed: () {
                      controller.refresh();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
              ),
            )
          else if (state.isEmpty)
            const SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _MapStatusBanner(
                  icon: Icons.location_off_outlined,
                  label: 'No memories here yet.',
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNewPin(context),
        tooltip: 'New memory',
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }

  void _openNewPin(BuildContext context, [Coordinates? coordinates]) {
    if (coordinates == null) {
      context.push('/pins/new');
      return;
    }

    final Uri uri = Uri(
      path: '/pins/new',
      queryParameters: <String, String>{
        'lat': coordinates.lat.toStringAsFixed(6),
        'lng': coordinates.lng.toStringAsFixed(6),
      },
    );
    context.push(uri.toString());
  }
}

const MapCameraPosition _initialCamera = MapCameraPosition(
  center: Coordinates(lat: 11.35, lng: 107.58),
  zoom: 6.2,
);

class _MapModeSwitch extends StatelessWidget {
  const _MapModeSwitch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SegmentedButton<String>(
        segments: const <ButtonSegment<String>>[
          ButtonSegment<String>(
            value: 'map',
            icon: Icon(Icons.map_outlined),
            label: Text('Map'),
          ),
          ButtonSegment<String>(
            value: 'timeline',
            icon: Icon(Icons.view_timeline_outlined),
            label: Text('Timeline'),
          ),
        ],
        selected: const <String>{'map'},
        showSelectedIcon: false,
        onSelectionChanged: (_) {
          context.push('/timeline');
        },
      ),
    );
  }
}

class _MapStatusBanner extends StatelessWidget {
  const _MapStatusBanner({
    required this.icon,
    required this.label,
    this.action,
  });

  final IconData icon;
  final String label;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Flexible(child: Text(label)),
          if (action != null) ...<Widget>[
            const SizedBox(width: 8),
            action!,
          ],
        ],
      ),
    );
  }
}
