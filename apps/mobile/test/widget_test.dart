import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_map_mobile/app/map_screen.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/map/map.dart';

void main() {
  testWidgets('renders mock pins and opens a pin from the map', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const MapScreen(mapViewBuilder: _buildFakeMapView);
          },
        ),
        GoRoute(
          path: '/timeline',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Text('timeline-route'));
          },
        ),
        GoRoute(
          path: '/pins/new',
          builder: (BuildContext context, GoRouterState state) {
            return const Scaffold(body: Text('new-pin-route'));
          },
        ),
        GoRoute(
          path: '/pins/:pinId',
          builder: (BuildContext context, GoRouterState state) {
            return Scaffold(
              body: Text('pin-${state.pathParameters['pinId']}'),
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Personal Map'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('fake-marker-pin_da_lat_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('fake-marker-pin_sai_gon_1')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('fake-marker-pin_sai_gon_1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('pin-pin_sai_gon_1'), findsOneWidget);
  });
}

Widget _buildFakeMapView(BuildContext context, MapViewConfig config) {
  return _FakeMapView(config: config);
}

class _FakeMapView extends StatefulWidget {
  const _FakeMapView({required this.config});

  final MapViewConfig config;

  @override
  State<_FakeMapView> createState() => _FakeMapViewState();
}

class _FakeMapViewState extends State<_FakeMapView> {
  bool _emittedViewport = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_emittedViewport) {
      return;
    }

    _emittedViewport = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.config.onViewportChanged(
        const BboxQuery(
          minLng: 100,
          minLat: 8,
          maxLng: 110,
          maxLat: 14,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEAF1EC),
      child: Stack(
        children: widget.config.markers.map((MapMarkerModel marker) {
          return Align(
            alignment: Alignment.center,
            child: TextButton(
              key: ValueKey<String>('fake-marker-${marker.id}'),
              onPressed: () => widget.config.onMarkerTap(marker.id),
              child: Text(marker.id),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
