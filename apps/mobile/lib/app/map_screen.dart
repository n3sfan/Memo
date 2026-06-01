import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../data/models/models.dart';
import '../map/map.dart';
import 'map_view_controller.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({
    this.startPicking = false,
    this.editPinId,
    this.mapViewBuilder = buildOpenStreetMapView,
    super.key,
  });

  final bool startPicking;
  final String? editPinId;
  final MapViewWidgetBuilder mapViewBuilder;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late bool _isPicking = widget.startPicking;

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startPicking != widget.startPicking ||
        oldWidget.editPinId != widget.editPinId) {
      _isPicking = widget.startPicking;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Log out',
            onPressed: () => ref
                .read<AuthController>(authControllerProvider.notifier)
                .logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: widget.mapViewBuilder(
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
                onTap: (Coordinates coordinates) {
                  if (_isPicking) {
                    _openPinEditor(context, coordinates);
                  }
                },
                onLongPress: (Coordinates coordinates) {
                  _openPinEditor(context, coordinates);
                },
              ),
            ),
          ),
          if (_isPicking)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: _PickLocationBanner(
                  onCancel: () {
                    setState(() {
                      _isPicking = false;
                    });
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
        onPressed: () {
          setState(() {
            _isPicking = true;
          });
        },
        tooltip: _isPicking ? 'Đang chọn vị trí' : 'Chọn vị trí',
        child: Icon(
          _isPicking
              ? Icons.touch_app_outlined
              : Icons.add_location_alt_outlined,
        ),
      ),
    );
  }

  void _openPinEditor(BuildContext context, Coordinates coordinates) {
    final Uri uri = Uri(
      path: widget.editPinId == null
          ? '/pins/new'
          : '/pins/${Uri.encodeComponent(widget.editPinId!)}/edit',
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

class _PickLocationBanner extends StatelessWidget {
  const _PickLocationBanner({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 64, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
          const Icon(Icons.touch_app_outlined, size: 20),
          const SizedBox(width: 10),
          const Flexible(child: Text('Chạm vào bản đồ để chọn vị trí.')),
          TextButton(
            onPressed: onCancel,
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }
}
