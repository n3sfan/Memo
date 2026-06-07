import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memory_map_mobile/app/pin_detail_screen.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/media_repository.dart';
import 'package:memory_map_mobile/data/repositories/pin_repository.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';
import 'package:memory_map_mobile/l10n/app_localizations.dart';
import 'package:memory_map_mobile/l10n/app_localizations_en.dart';
import 'package:memory_map_mobile/media/image_viewer.dart';
import 'package:memory_map_mobile/media/media_placeholder.dart';
import 'package:memory_map_mobile/sync/network_monitor.dart';

void main() {
  // English source-of-truth strings, so assertions never hardcode copy.
  final AppLocalizations l10n = AppLocalizationsEn();

  PinMediaDto imageMedia(String id) => PinMediaDto(
        id: id,
        pinId: 'pin_1',
        mediaType: PinMediaType.image,
        objectKey: 'maps/pin_1/$id.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1024,
        createdAt: DateTime.utc(2026, 1, 1),
      );

  PinDto buildPin({
    String id = 'pin_1',
    String title = 'A sunny afternoon',
    String? note = 'We watched the sunset by the river.',
    DateTime? memoryDate,
    double lat = 10.762622,
    double lng = 106.660172,
    List<PinMediaDto> media = const <PinMediaDto>[],
  }) =>
      PinDto(
        id: id,
        mapId: 'map_test',
        title: title,
        note: note,
        memoryDate: memoryDate,
        lat: lat,
        lng: lng,
        media: media,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  testWidgets(
    'shows MediaPlaceholder when a read URL cannot be retrieved (Req 13.4)',
    (WidgetTester tester) async {
      final PinDto pin = buildPin(
        memoryDate: DateTime.utc(2026, 5, 20),
        media: <PinMediaDto>[imageMedia('media_1')],
      );

      await _pumpPinDetail(
        tester,
        pin: pin,
        // createReadUrl throws -> MediaUrlController resolves to
        // MediaUnavailable -> the thumbnail renders a MediaPlaceholder.
        mediaRepository: _FailingMediaRepository(),
      );

      expect(find.byType(MediaPlaceholder), findsOneWidget);
    },
  );

  testWidgets(
    'renders title, note, and coordinates when media is unavailable '
    '(Req 13.5)',
    (WidgetTester tester) async {
      final PinDto pin = buildPin(
        memoryDate: DateTime.utc(2026, 5, 20),
        media: <PinMediaDto>[imageMedia('media_1')],
      );

      await _pumpPinDetail(
        tester,
        pin: pin,
        mediaRepository: _FailingMediaRepository(),
      );

      // Media degraded to a placeholder...
      expect(find.byType(MediaPlaceholder), findsOneWidget);
      // ...but the pin's text content stays visible (Req 10.1).
      expect(find.text(pin.title), findsOneWidget);
      expect(find.text(pin.note!), findsOneWidget);
      // Location is shown as a useful map-location section, with raw
      // coordinates kept as secondary detail.
      final String coordinateText =
          '${pin.lat.toStringAsFixed(4)}, ${pin.lng.toStringAsFixed(4)}';
      expect(find.text(l10n.savedMapLocation), findsOneWidget);
      expect(find.textContaining(coordinateText), findsOneWidget);
      // Not the "coordinates unavailable" fallback.
      expect(find.text(l10n.coordinatesUnavailable), findsNothing);
    },
  );

  testWidgets(
    'renders the "date unknown" label for a pin with no memory date '
    '(Req 3.3, 5.4)',
    (WidgetTester tester) async {
      final PinDto pin = buildPin(memoryDate: null);

      await _pumpPinDetail(
        tester,
        pin: pin,
        mediaRepository: _FailingMediaRepository(),
      );

      expect(find.text(l10n.dateUnknown), findsOneWidget);
    },
  );

  testWidgets('formats the memory date using the active app locale (Req 5.3)',
      (WidgetTester tester) async {
    final DateTime memoryDate = DateTime(2026, 5, 20);
    final PinDto pin = buildPin(memoryDate: memoryDate);

    await _pumpPinDetail(
      tester,
      pin: pin,
      mediaRepository: _FailingMediaRepository(),
      locale: const Locale('vi'),
    );

    expect(
      find.text(DateFormat.yMMMd('vi').format(memoryDate)),
      findsOneWidget,
    );
  });

  testWidgets(
    'renders the "coordinates unavailable" label for invalid coordinates '
    '(Req 5.6)',
    (WidgetTester tester) async {
      // Out-of-range latitude makes _hasValidCoordinates return false.
      final PinDto pin = buildPin(
        memoryDate: DateTime.utc(2026, 5, 20),
        lat: 999,
        lng: 106.660172,
      );

      await _pumpPinDetail(
        tester,
        pin: pin,
        mediaRepository: _FailingMediaRepository(),
      );

      expect(find.text(l10n.coordinatesUnavailable), findsOneWidget);
    },
  );

  testWidgets('view on map includes the pin coordinates (Req 6.1)',
      (WidgetTester tester) async {
    final PinDto pin = buildPin(memoryDate: DateTime.utc(2026, 5, 20));

    await _pumpPinDetailRouter(
      tester,
      pin: pin,
      mediaRepository: _FailingMediaRepository(),
    );

    await tester.tap(find.text(l10n.viewOnMap));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'map:${pin.lat.toStringAsFixed(6)},${pin.lng.toStringAsFixed(6)}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('edit opens the matching pin editor route (Req 6.2)',
      (WidgetTester tester) async {
    final PinDto pin = buildPin(memoryDate: DateTime.utc(2026, 5, 20));

    await _pumpPinDetailRouter(
      tester,
      pin: pin,
      mediaRepository: _FailingMediaRepository(),
    );

    await tester.tap(find.text(l10n.edit));
    await tester.pumpAndSettle();

    expect(find.text('edit:${pin.id}'), findsOneWidget);
  });

  testWidgets('share sheet exposes copyable memory text',
      (WidgetTester tester) async {
    final PinDto pin = buildPin(memoryDate: DateTime.utc(2026, 5, 20));

    await _pumpPinDetailRouter(
      tester,
      pin: pin,
      mediaRepository: _FailingMediaRepository(),
    );

    await tester.tap(find.text(l10n.share));
    await tester.pumpAndSettle();

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.textContaining(pin.title), findsWidgets);
    expect(find.widgetWithText(FilledButton, l10n.copy), findsOneWidget);
  });

  testWidgets('delete confirms through repository and returns to timeline',
      (WidgetTester tester) async {
    final PinDto pin = buildPin(memoryDate: DateTime.utc(2026, 5, 20));
    final _FakePinRepository pinRepository = _FakePinRepository(pin);

    await _pumpPinDetailRouter(
      tester,
      pin: pin,
      pinRepository: pinRepository,
      mediaRepository: _FailingMediaRepository(),
    );

    await tester.tap(find.text(l10n.delete));
    await tester.pumpAndSettle();
    expect(find.text(l10n.deletePinTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
    await tester.pumpAndSettle();

    expect(pinRepository.deletedPinIds, <String>[pin.id]);
    expect(find.text('timeline'), findsOneWidget);
  });

  testWidgets('image thumbnail opens and dismisses the image viewer',
      (WidgetTester tester) async {
    final PinDto pin = buildPin(
      memoryDate: DateTime.utc(2026, 5, 20),
      media: <PinMediaDto>[imageMedia('media_ready')],
    );

    await _pumpPinDetail(
      tester,
      pin: pin,
      mediaRepository: _SuccessfulMediaRepository(),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('image-thumbnail-media_ready'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ImageViewer), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('image-viewer-close-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ImageViewer), findsNothing);
    expect(find.text(pin.title), findsOneWidget);
  });
}

/// Pumps [PinDetailScreen] inside a localized [MaterialApp] with overridden pin
/// and media repositories. The network monitor is forced online so media
/// unavailability is driven solely by the (failing) media repository.
Future<void> _pumpPinDetail(
  WidgetTester tester, {
  required PinDto pin,
  required MediaRepository mediaRepository,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pinRepositoryProvider.overrideWithValue(_FakePinRepository(pin)),
        mediaRepositoryProvider.overrideWithValue(mediaRepository),
        networkMonitorProvider
            .overrideWithValue(_FakeNetworkMonitor(NetworkStatus.online)),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en'), Locale('vi')],
        home: PinDetailScreen(pinId: pin.id),
      ),
    ),
  );

  // Resolve the pin-detail load and the per-media read-URL resolution.
  await tester.pumpAndSettle();
}

Future<void> _pumpPinDetailRouter(
  WidgetTester tester, {
  required PinDto pin,
  required MediaRepository mediaRepository,
  PinRepository? pinRepository,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final GoRouter router = GoRouter(
    initialLocation: '/pins/${pin.id}',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            body: Text(
              'map:${state.uri.queryParameters['lat']},'
              '${state.uri.queryParameters['lng']}',
            ),
          );
        },
      ),
      GoRoute(
        path: '/timeline',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(body: Text('timeline'));
        },
      ),
      GoRoute(
        path: '/pins/:pinId',
        builder: (BuildContext context, GoRouterState state) {
          return PinDetailScreen(
            pinId: state.pathParameters['pinId'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/pins/:pinId/edit',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            body: Text('edit:${state.pathParameters['pinId']}'),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pinRepositoryProvider.overrideWithValue(
          pinRepository ?? _FakePinRepository(pin),
        ),
        mediaRepositoryProvider.overrideWithValue(mediaRepository),
        networkMonitorProvider
            .overrideWithValue(_FakeNetworkMonitor(NetworkStatus.online)),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const <Locale>[Locale('en'), Locale('vi')],
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A [PinRepository] that returns a fixed [PinDto] for `getPin`. The other
/// operations are never exercised by the Pin Detail view.
class _FakePinRepository implements PinRepository {
  _FakePinRepository(this.pin);

  final PinDto pin;
  final List<String> deletedPinIds = <String>[];

  @override
  Future<PinDto> getPin(String pinId) async => pin;

  @override
  Future<List<PinDto>> listByBbox({
    required String mapId,
    required BboxQuery bbox,
  }) =>
      throw UnimplementedError();

  @override
  Future<PinDto> createPin({
    required String mapId,
    required CreatePinRequestDto request,
  }) =>
      throw UnimplementedError();

  @override
  Future<PinDto> updatePin({
    required String pinId,
    required CreatePinRequestDto request,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deletePin(String pinId) async {
    deletedPinIds.add(pinId);
  }
}

/// A [MediaRepository] whose `createReadUrl` always throws, forcing the
/// media-url controller to resolve to [MediaUnavailable] so the Pin Detail view
/// renders a [MediaPlaceholder] (Req 7.4).
class _FailingMediaRepository implements MediaRepository {
  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) async {
    throw Exception('read url unavailable for $mediaId');
  }

  @override
  Future<PresignResponseDto> createPresignedUpload({
    required String pinId,
    required PresignRequestDto request,
  }) =>
      throw UnimplementedError();

  @override
  Future<PinMediaDto> registerMedia({
    required String pinId,
    required RegisterMediaRequestDto request,
  }) =>
      throw UnimplementedError();
}

class _SuccessfulMediaRepository extends _FailingMediaRepository {
  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) async {
    return MediaReadUrlDto(
      url: 'https://storage.memo.local/read/$mediaId',
      expiresAt: DateTime.utc(2026, 6, 7, 12, 15),
    );
  }
}

/// A [NetworkMonitor] reporting a fixed [NetworkStatus].
class _FakeNetworkMonitor implements NetworkMonitor {
  _FakeNetworkMonitor(this.status);

  final NetworkStatus status;

  @override
  Future<NetworkStatus> currentStatus() async => status;

  @override
  Stream<NetworkStatus> statusChanges() => const Stream<NetworkStatus>.empty();
}
