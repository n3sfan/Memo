import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memory_map_mobile/app/timeline_ordering.dart';
import 'package:memory_map_mobile/app/timeline_screen.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/repositories.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';
import 'package:memory_map_mobile/l10n/app_localizations.dart';
import 'package:memory_map_mobile/l10n/app_localizations_en.dart';

void main() {
  const MapDto map = MapDto(
    id: 'map_test',
    type: MemoryMapType.personal,
    ownerId: 'user_test',
  );

  // English source-of-truth strings, used so assertions never hardcode copy.
  final AppLocalizations l10n = AppLocalizationsEn();

  PinDto datedPin(String id, DateTime memoryDate) => PinDto(
        id: id,
        mapId: map.id,
        title: 'Pin $id',
        note: null,
        memoryDate: memoryDate,
        lat: 10.5,
        lng: 106.5,
        media: const <PinMediaDto>[],
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  PinDto undatedPin(String id) => PinDto(
        id: id,
        mapId: map.id,
        title: 'Pin $id',
        note: null,
        memoryDate: null,
        lat: 10.5,
        lng: 106.5,
        media: const <PinMediaDto>[],
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  // A mix of dated and undated pins, in an arbitrary order.
  final List<PinDto> samplePins = <PinDto>[
    datedPin('b', DateTime.utc(2026, 3, 10)),
    undatedPin('z'),
    datedPin('a', DateTime.utc(2026, 5, 20)),
    datedPin('c', DateTime.utc(2026, 1, 5)),
  ];

  testWidgets(
      'renders an entry for every pin including undated ones (Req 13.1)',
      (WidgetTester tester) async {
    await _pumpTimeline(
      tester,
      timelineRepository: _FakeTimelineRepository(items: samplePins),
    );

    // Each pin title (dated + undated) is rendered.
    for (final PinDto pin in samplePins) {
      expect(find.text(pin.title), findsOneWidget);
    }
    // The undated pin still shows with the localized "date unknown" label.
    expect(find.text(l10n.dateUnknown), findsOneWidget);
  });

  testWidgets('formats memory dates using the active app locale (Req 1.4)',
      (WidgetTester tester) async {
    final DateTime memoryDate = DateTime(2026, 5, 20);
    await _pumpTimeline(
      tester,
      timelineRepository: _FakeTimelineRepository(
        items: <PinDto>[datedPin('localized', memoryDate)],
      ),
      locale: const Locale('vi'),
    );

    expect(
      find.text(DateFormat.yMMMd('vi').format(memoryDate)),
      findsOneWidget,
    );
  });

  testWidgets('sort toggle reorders pins without removing any (Req 13.2)',
      (WidgetTester tester) async {
    await _pumpTimeline(
      tester,
      timelineRepository: _FakeTimelineRepository(items: samplePins),
    );

    List<String> titlesInOrder() => tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Text),
          ),
        )
        .map((Text text) => text.data)
        .whereType<String>()
        .where((String data) => data.startsWith('Pin '))
        .toList();

    final List<String> newestOrder = titlesInOrder();
    expect(
      newestOrder,
      orderPins(samplePins, TimelineSortOrder.newest)
          .map((PinDto pin) => pin.title)
          .toList(),
    );

    // Flip to oldest first.
    await tester.tap(find.text(l10n.sortOldest));
    await tester.pumpAndSettle();

    final List<String> oldestOrder = titlesInOrder();

    // Order changed but the same set of pins is still present (none removed).
    expect(oldestOrder, isNot(equals(newestOrder)));
    expect(oldestOrder.toSet(), newestOrder.toSet());
    expect(oldestOrder.length, samplePins.length);
    expect(
      oldestOrder,
      orderPins(samplePins, TimelineSortOrder.oldest)
          .map((PinDto pin) => pin.title)
          .toList(),
    );
  });

  testWidgets('tapping an entry navigates to that pin id (Req 13.3)',
      (WidgetTester tester) async {
    final List<String> navigatedPinIds = <String>[];

    await _pumpTimeline(
      tester,
      timelineRepository: _FakeTimelineRepository(items: samplePins),
      onPinDetail: navigatedPinIds.add,
    );

    await tester.tap(find.text('Pin a'));
    await tester.pumpAndSettle();

    expect(navigatedPinIds, <String>['a']);
    expect(
      find.byKey(const ValueKey<String>('pin-detail-probe')),
      findsOneWidget,
    );
  });

  testWidgets('back from pin detail returns to the timeline (Req 6.5)',
      (WidgetTester tester) async {
    await _pumpTimeline(
      tester,
      timelineRepository: _FakeTimelineRepository(items: samplePins),
    );

    await tester.tap(find.text('Pin a'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('pin-detail-probe')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(TimelineScreen), findsOneWidget);
    expect(find.text('Pin a'), findsOneWidget);
  });

  testWidgets(
      'renders the localized empty-state when there are no pins '
      '(Req 1.6)', (WidgetTester tester) async {
    await _pumpTimeline(
      tester,
      timelineRepository: _FakeTimelineRepository(items: const <PinDto>[]),
    );

    expect(find.text(l10n.timelineEmpty), findsOneWidget);
  });

  testWidgets('renders error and retry which reloads the timeline (Req 1.7)',
      (WidgetTester tester) async {
    final _FlakyTimelineRepository timelineRepository =
        _FlakyTimelineRepository(items: samplePins);

    await _pumpTimeline(
      tester,
      timelineRepository: timelineRepository,
    );

    // First load failed: error message + retry control are shown.
    expect(find.text(l10n.timelineError), findsOneWidget);
    expect(find.text(l10n.retry), findsOneWidget);
    expect(timelineRepository.calls, 1);

    // Tapping retry attempts a reload; the repository now succeeds.
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();

    expect(timelineRepository.calls, greaterThan(1));
    expect(find.text(l10n.timelineError), findsNothing);
    for (final PinDto pin in samplePins) {
      expect(find.text(pin.title), findsOneWidget);
    }
  });
}

/// Pumps [TimelineScreen] inside a GoRouter harness with overridden map and
/// timeline repositories, English localization delegates, and a probe widget
/// at `/pins/:pinId` that records navigation.
Future<void> _pumpTimeline(
  WidgetTester tester, {
  required TimelineRepository timelineRepository,
  ValueChanged<String>? onPinDetail,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const TimelineScreen(),
      ),
      GoRoute(
        path: '/pins/:pinId',
        builder: (BuildContext context, GoRouterState state) {
          final String pinId = state.pathParameters['pinId'] ?? '';
          onPinDetail?.call(pinId);
          return _PinDetailProbe(pinId: pinId);
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mapRepositoryProvider.overrideWithValue(const _FakeMapRepository(map)),
        timelineRepositoryProvider.overrideWithValue(timelineRepository),
      ],
      child: MaterialApp.router(
        locale: locale,
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

  // Resolve the controller's async first-load (or failure).
  await tester.pumpAndSettle();
}

const MapDto map = MapDto(
  id: 'map_test',
  type: MemoryMapType.personal,
  ownerId: 'user_test',
);

class _PinDetailProbe extends StatelessWidget {
  const _PinDetailProbe({required this.pinId});

  final String pinId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('pin-detail-probe'),
      appBar: AppBar(),
      body: Center(child: Text('detail:$pinId')),
    );
  }
}

class _FakeMapRepository implements MapRepository {
  const _FakeMapRepository(this.map);

  final MapDto map;

  @override
  Future<MapDto> getDefaultMap() async => map;

  @override
  Future<List<MapDto>> listMaps() async => <MapDto>[map];

  @override
  Future<MapDto> createDuoMap({String? name}) => throw UnimplementedError();

  @override
  Future<InvitationDto> createInvitation({required String mapId}) =>
      throw UnimplementedError();

  @override
  Future<void> revokeInvitation({
    required String mapId,
    required String invitationId,
  }) =>
      throw UnimplementedError();

  @override
  Future<AcceptInvitationResponseDto> acceptInvitation({
    required String code,
  }) =>
      throw UnimplementedError();

  @override
  Future<RemoveMapMemberResponseDto> removeMember({
    required String mapId,
    required String userId,
  }) =>
      throw UnimplementedError();
}

class _FakeTimelineRepository implements TimelineRepository {
  _FakeTimelineRepository({required this.items});

  final List<PinDto> items;
  int calls = 0;

  @override
  Future<TimelinePageDto> listTimeline({
    required String mapId,
    String? cursor,
    int limit = 50,
    String order = 'desc',
  }) async {
    calls++;
    return TimelinePageDto(items: items, nextCursor: null, hasMore: false);
  }
}

/// Fails on the first load, then succeeds on subsequent loads so the
/// error + retry path can be exercised.
class _FlakyTimelineRepository implements TimelineRepository {
  _FlakyTimelineRepository({required this.items});

  final List<PinDto> items;
  int calls = 0;

  @override
  Future<TimelinePageDto> listTimeline({
    required String mapId,
    String? cursor,
    int limit = 50,
    String order = 'desc',
  }) async {
    calls++;
    if (calls == 1) {
      throw StateError('timeline request failed');
    }
    return TimelinePageDto(items: items, nextCursor: null, hasMore: false);
  }
}
