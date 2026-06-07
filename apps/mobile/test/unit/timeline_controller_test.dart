import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/timeline_controller.dart';
import 'package:memory_map_mobile/app/timeline_ordering.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/repositories.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

void main() {
  const MapDto map = MapDto(
    id: 'map_test',
    type: MemoryMapType.personal,
    ownerId: 'user_test',
  );

  // A mix of dated and undated pins, supplied in an arbitrary order so the
  // controller/ordering has real work to do.
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

  final List<PinDto> samplePins = <PinDto>[
    datedPin('b', DateTime.utc(2026, 3, 10)),
    undatedPin('z'),
    datedPin('a', DateTime.utc(2026, 5, 20)),
    datedPin('c', DateTime.utc(2026, 1, 5)),
  ];

  Set<String> idsOf(List<PinDto> pins) =>
      pins.map((PinDto pin) => pin.id).toSet();

  /// Builds a container with the map and timeline repositories overridden, and
  /// keeps [timelineControllerProvider] alive so its autoDispose future
  /// resolves while the test reads it.
  ProviderContainer buildContainer({
    required MapRepository mapRepository,
    required TimelineRepository timelineRepository,
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        mapRepositoryProvider.overrideWithValue(mapRepository),
        timelineRepositoryProvider.overrideWithValue(timelineRepository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(
      timelineControllerProvider,
      (_, __) {},
      fireImmediately: true,
    );
    return container;
  }

  test('first load resolves the default map and requests newest (desc) order',
      () async {
    final _RecordingTimelineRepository timelineRepository =
        _RecordingTimelineRepository(items: samplePins);
    final _FakeMapRepository mapRepository = _FakeMapRepository(map);

    final ProviderContainer container = buildContainer(
      mapRepository: mapRepository,
      timelineRepository: timelineRepository,
    );

    final TimelineState state =
        await container.read(timelineControllerProvider.future);

    // First load uses the active map and the newest order.
    expect(mapRepository.getDefaultMapCalls, 1);
    expect(timelineRepository.calls.single.mapId, map.id);
    expect(timelineRepository.calls.single.order, 'desc');
    expect(state.order, TimelineSortOrder.newest);

    // The projection is the newest ordering of the returned items.
    expect(state.orderedPins, orderPins(samplePins, TimelineSortOrder.newest));
    // Newest dated pins first (by memoryDate desc), undated last.
    expect(
      state.orderedPins.map((PinDto pin) => pin.id).toList(),
      <String>['a', 'b', 'c', 'z'],
    );
  });

  test('setOrder reorders the same pin set without a refetch', () async {
    final _RecordingTimelineRepository timelineRepository =
        _RecordingTimelineRepository(items: samplePins);

    final ProviderContainer container = buildContainer(
      mapRepository: _FakeMapRepository(map),
      timelineRepository: timelineRepository,
    );

    final TimelineState initial =
        await container.read(timelineControllerProvider.future);
    final Set<String> initialIds = idsOf(initial.orderedPins);

    container
        .read(timelineControllerProvider.notifier)
        .setOrder(TimelineSortOrder.oldest);

    final TimelineState reordered =
        container.read(timelineControllerProvider).value!;

    // Order flag flipped and projection now follows the oldest direction.
    expect(reordered.order, TimelineSortOrder.oldest);
    expect(
      reordered.orderedPins.map((PinDto pin) => pin.id).toList(),
      <String>['c', 'b', 'a', 'z'],
    );

    // Same pin set: nothing added or removed.
    expect(idsOf(reordered.orderedPins), initialIds);
    expect(reordered.orderedPins.length, initial.orderedPins.length);

    // No refetch happened: the repository was only hit once (the first load).
    expect(timelineRepository.calls.length, 1);
  });

  test('repository failure surfaces an AsyncValue error state', () async {
    final ProviderContainer container = buildContainer(
      mapRepository: _FakeMapRepository(map),
      timelineRepository: _ThrowingTimelineRepository(),
    );

    await expectLater(
      container.read(timelineControllerProvider.future),
      throwsA(isA<StateError>()),
    );

    final AsyncValue<TimelineState> state =
        container.read(timelineControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<StateError>());
  });
}

class _FakeMapRepository implements MapRepository {
  _FakeMapRepository(this.map);

  final MapDto map;
  int getDefaultMapCalls = 0;

  @override
  Future<MapDto> getDefaultMap() async {
    getDefaultMapCalls++;
    return map;
  }

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

class _TimelineCall {
  const _TimelineCall({required this.mapId, required this.order});

  final String mapId;
  final String order;
}

class _RecordingTimelineRepository implements TimelineRepository {
  _RecordingTimelineRepository({required this.items});

  final List<PinDto> items;
  final List<_TimelineCall> calls = <_TimelineCall>[];

  @override
  Future<TimelinePageDto> listTimeline({
    required String mapId,
    String? cursor,
    int limit = 50,
    String order = 'desc',
  }) async {
    calls.add(_TimelineCall(mapId: mapId, order: order));
    return TimelinePageDto(
      items: items,
      nextCursor: null,
      hasMore: false,
    );
  }
}

class _ThrowingTimelineRepository implements TimelineRepository {
  @override
  Future<TimelinePageDto> listTimeline({
    required String mapId,
    String? cursor,
    int limit = 50,
    String order = 'desc',
  }) async {
    throw StateError('timeline request failed');
  }
}
