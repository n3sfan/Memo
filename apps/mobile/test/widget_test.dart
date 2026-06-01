import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_map_mobile/app/map_screen.dart';
import 'package:memory_map_mobile/app/router.dart';
import 'package:memory_map_mobile/auth/auth_controller.dart';
import 'package:memory_map_mobile/auth/token_storage.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';
import 'package:memory_map_mobile/main.dart';
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
            final Map<String, String> query = state.uri.queryParameters;
            return Scaffold(
              body: Text(
                'new-pin-route ${query['lat'] ?? 'no-lat'} '
                '${query['lng'] ?? 'no-lng'}',
              ),
            );
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

  testWidgets('pick mode opens the pin editor with map coordinates', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) {
            return const MapScreen(
              startPicking: true,
              mapViewBuilder: _buildFakeMapView,
            );
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
            final Map<String, String> query = state.uri.queryParameters;
            return Scaffold(
              body: Text('new-pin-route ${query['lat']} ${query['lng']}'),
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

    expect(find.text('Chạm vào bản đồ để chọn vị trí.'), findsOneWidget);

    final Rect mapBounds = tester.getRect(
      find.byKey(const ValueKey<String>('fake-map-canvas')),
    );
    await tester.tapAt(mapBounds.topLeft + const Offset(24, 220));
    await tester.pumpAndSettle();

    expect(find.text('new-pin-route 10.123456 106.654321'), findsOneWidget);
  });

  testWidgets('starts at login when no session exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sign in to Memo'), findsWidgets);
    expect(find.byKey(const Key('login_google_button')), findsOneWidget);
  });

  testWidgets('mock Google login opens the Memory Map shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('login_google_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.add_location_alt_outlined), findsOneWidget);
    expect(find.byKey(const Key('logout_button')), findsOneWidget);
  });

  testWidgets('web OAuth callback opens the Memory Map shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _testApp(initialLocation: '/oauth/google?code=mock_code&state=mock_state'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.add_location_alt_outlined), findsOneWidget);
    expect(find.byKey(const Key('logout_button')), findsOneWidget);
    expect(find.text('Sign in to Memo'), findsNothing);
  });

  testWidgets('logout returns to login', (WidgetTester tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('login_google_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sign in to Memo'), findsWidgets);
  });
}

Widget _testApp({String? initialLocation}) {
  return ProviderScope(
    overrides: [
      tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
      oauthRedirectStreamProvider
          .overrideWith((ref) => const Stream<Uri>.empty()),
    ],
    child: _RouteStarterApp(initialLocation: initialLocation),
  );
}

class _RouteStarterApp extends ConsumerStatefulWidget {
  const _RouteStarterApp({this.initialLocation});

  final String? initialLocation;

  @override
  ConsumerState<_RouteStarterApp> createState() => _RouteStarterAppState();
}

class _RouteStarterAppState extends ConsumerState<_RouteStarterApp> {
  bool _didNavigate = false;

  @override
  Widget build(BuildContext context) {
    final String? initialLocation = widget.initialLocation;
    if (!_didNavigate && initialLocation != null) {
      _didNavigate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appRouterProvider).go(initialLocation);
      });
    }

    return const MemoryMapApp();
  }
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
    return GestureDetector(
      key: const ValueKey<String>('fake-map-canvas'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.config.onTap(
          const Coordinates(lat: 10.123456, lng: 106.654321),
        );
      },
      child: ColoredBox(
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
      ),
    );
  }
}
