import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/pin_editor_screen.dart';
import 'package:memory_map_mobile/data/db/app_database.dart';
import 'package:memory_map_mobile/data/db/cache_models.dart';
import 'package:memory_map_mobile/data/db/daos.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/repositories.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

void main() {
  testWidgets('invalid coordinates show inline validation and do not submit', (
    WidgetTester tester,
  ) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();
    final _MemoryLocalPinsDao localPinsDao = _MemoryLocalPinsDao();
    final _MemoryUploadQueueDao uploadQueueDao = _MemoryUploadQueueDao();

    await _pumpEditor(
      tester,
      localPinsDao: localPinsDao,
      uploadQueueDao: uploadQueueDao,
      pinRepository: pinRepository,
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('pin-editor-title-field')),
      'Invalid place',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('pin-editor-lat-field')),
      '91',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('pin-editor-lng-field')),
      '106.7009',
    );

    await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
    await tester.pump();

    expect(
      find.text('Latitude must be between -90 and 90.'),
      findsOneWidget,
    );
    expect(pinRepository.createCalls, 0);
  });

  testWidgets('saving online calls the API repository and updates local cache',
      (
    WidgetTester tester,
  ) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();
    final _MemoryLocalPinsDao localPinsDao = _MemoryLocalPinsDao();
    final _MemoryUploadQueueDao uploadQueueDao = _MemoryUploadQueueDao();

    await _pumpEditor(
      tester,
      localPinsDao: localPinsDao,
      uploadQueueDao: uploadQueueDao,
      pinRepository: pinRepository,
    );

    await _fillValidPinForm(tester);
    await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
    await _pumpAsync(tester);

    expect(pinRepository.createCalls, 1);
    expect(pinRepository.lastMapId, _map.id);
    expect(pinRepository.lastCreateRequest?.title, 'Da Lat cafe');
    expect(pinRepository.lastCreateRequest?.lat, 11.9404);
    expect(pinRepository.lastCreateRequest?.lng, 108.4583);

    final PinDto? cached = await localPinsDao.getPin('pin_saved_1');

    expect(cached, isNotNull);
    expect(cached?.title, 'Da Lat cafe');
    expect(localPinsDao.syncedAtById['pin_saved_1'], isNotNull);
    expect(find.text('Memory saved.'), findsOneWidget);
  });

  testWidgets(
    'saving after network failure stores pending pin and media placeholders',
    (WidgetTester tester) async {
      final _FailingPinRepository pinRepository = _FailingPinRepository();
      final _MemoryLocalPinsDao localPinsDao = _MemoryLocalPinsDao();
      final _MemoryUploadQueueDao uploadQueueDao = _MemoryUploadQueueDao();

      await _pumpEditor(
        tester,
        localPinsDao: localPinsDao,
        uploadQueueDao: uploadQueueDao,
        pinRepository: pinRepository,
      );

      await _fillValidPinForm(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('pin-editor-add-image')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pin-editor-add-text')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pin-editor-add-audio')),
      );
      await tester.pump();

      expect(find.text('Image placeholder queued'), findsOneWidget);
      expect(find.text('Text placeholder queued'), findsOneWidget);
      expect(find.text('Audio placeholder queued'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
      await _pumpAsync(tester);

      final List<PendingPinMutation> mutations =
          await uploadQueueDao.listPendingPinMutations();
      final List<PendingMediaUpload> uploads =
          await uploadQueueDao.listPendingMediaUploads();
      final List<PinDto> cachedPins = await localPinsDao.listPinsForMap(
        _map.id,
      );

      expect(pinRepository.createCalls, 1);
      expect(mutations, hasLength(1));
      expect(mutations.single.operation, 'create');
      expect(cachedPins, hasLength(1));
      expect(cachedPins.single.clientId, mutations.single.clientId);
      expect(
        uploads.map((PendingMediaUpload item) => item.mediaType),
        <PinMediaType>[
          PinMediaType.image,
          PinMediaType.text,
          PinMediaType.audio,
        ],
      );
      expect(
        find.text('Saved offline. Will sync when you are back online.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('editing an existing pin loads values and calls update', (
    WidgetTester tester,
  ) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();
    final _MemoryLocalPinsDao localPinsDao = _MemoryLocalPinsDao();
    final _MemoryUploadQueueDao uploadQueueDao = _MemoryUploadQueueDao();

    await _pumpEditor(
      tester,
      localPinsDao: localPinsDao,
      uploadQueueDao: uploadQueueDao,
      pinRepository: pinRepository,
      pinId: 'pin_existing_1',
    );
    await _pumpAsync(tester);

    final TextFormField titleField = tester.widget<TextFormField>(
      find.byKey(const ValueKey<String>('pin-editor-title-field')),
    );
    final TextFormField latField = tester.widget<TextFormField>(
      find.byKey(const ValueKey<String>('pin-editor-lat-field')),
    );

    expect(titleField.controller?.text, 'Old memory');
    expect(latField.controller?.text, '10.776900');

    await tester.enterText(
      find.byKey(const ValueKey<String>('pin-editor-title-field')),
      'Updated memory',
    );
    await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
    await _pumpAsync(tester);

    expect(pinRepository.updateCalls, 1);
    expect(pinRepository.lastUpdatePinId, 'pin_existing_1');
    expect(pinRepository.lastUpdateRequest?.title, 'Updated memory');

    final PinDto? cached = await localPinsDao.getPin('pin_existing_1');
    expect(cached?.title, 'Updated memory');
  });
}

const MapDto _map = MapDto(
  id: 'map_test_1',
  type: MemoryMapType.personal,
  ownerId: 'user_test_1',
  name: 'Test Map',
);

Future<void> _pumpEditor(
  WidgetTester tester, {
  required LocalPinsDao localPinsDao,
  required UploadQueueDao uploadQueueDao,
  required PinRepository pinRepository,
  String? pinId,
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
        localPinsDaoProvider.overrideWithValue(localPinsDao),
        uploadQueueDaoProvider.overrideWithValue(uploadQueueDao),
        mapRepositoryProvider.overrideWithValue(const _FakeMapRepository(_map)),
        pinRepositoryProvider.overrideWithValue(pinRepository),
      ],
      child: MaterialApp(
        home: PinEditorScreen(pinId: pinId),
      ),
    ),
  );
}

Future<void> _fillValidPinForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('pin-editor-title-field')),
    'Da Lat cafe',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('pin-editor-note-field')),
    'Coffee near the lake.',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('pin-editor-memory-date-field')),
    '2026-05-30',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('pin-editor-lat-field')),
    '11.9404',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('pin-editor-lng-field')),
    '108.4583',
  );
}

Future<void> _pumpAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

class _FakeMapRepository implements MapRepository {
  const _FakeMapRepository(this.map);

  final MapDto map;

  @override
  Future<MapDto> getDefaultMap() async {
    return map;
  }

  @override
  Future<List<MapDto>> listMaps() async {
    return <MapDto>[map];
  }
}

class _MemoryLocalPinsDao extends LocalPinsDao {
  _MemoryLocalPinsDao() : super(AppDatabase());

  final Map<String, PinDto> pinsById = <String, PinDto>{};
  final Map<String, DateTime?> syncedAtById = <String, DateTime?>{};

  @override
  Future<void> upsertPin(PinDto pin, {DateTime? syncedAt}) async {
    pinsById[pin.id] = pin;
    syncedAtById[pin.id] = syncedAt;
  }

  @override
  Future<PinDto?> getPin(String id) async {
    return pinsById[id];
  }

  @override
  Future<List<PinDto>> listPinsForMap(String mapId) async {
    return pinsById.values
        .where((PinDto pin) => pin.mapId == mapId)
        .toList(growable: false);
  }
}

class _MemoryUploadQueueDao extends UploadQueueDao {
  _MemoryUploadQueueDao() : super(AppDatabase());

  final List<PendingPinMutation> pinMutations = <PendingPinMutation>[];
  final List<PendingMediaUpload> mediaUploads = <PendingMediaUpload>[];

  @override
  Future<void> enqueuePinMutation(PendingPinMutation mutation) async {
    pinMutations.add(mutation);
  }

  @override
  Future<List<PendingPinMutation>> listPendingPinMutations() async {
    return List<PendingPinMutation>.unmodifiable(pinMutations);
  }

  @override
  Future<void> enqueueMediaUpload(PendingMediaUpload upload) async {
    mediaUploads.add(upload);
  }

  @override
  Future<List<PendingMediaUpload>> listPendingMediaUploads() async {
    return List<PendingMediaUpload>.unmodifiable(mediaUploads);
  }
}

class _RecordingPinRepository implements PinRepository {
  int createCalls = 0;
  int updateCalls = 0;
  String? lastMapId;
  String? lastUpdatePinId;
  CreatePinRequestDto? lastCreateRequest;
  CreatePinRequestDto? lastUpdateRequest;

  @override
  Future<PinDto> createPin({
    required String mapId,
    required CreatePinRequestDto request,
  }) async {
    createCalls += 1;
    lastMapId = mapId;
    lastCreateRequest = request;

    final DateTime now = DateTime.utc(2026, 5, 30, 10);

    return PinDto(
      id: 'pin_saved_1',
      mapId: mapId,
      title: request.title,
      note: request.note,
      memoryDate: request.memoryDate,
      lat: request.lat,
      lng: request.lng,
      media: const <PinMediaDto>[],
      createdAt: now,
      updatedAt: now,
      clientId: request.clientId,
    );
  }

  @override
  Future<void> deletePin(String pinId) {
    throw UnimplementedError();
  }

  @override
  Future<PinDto> getPin(String pinId) async {
    return PinDto(
      id: pinId,
      mapId: _map.id,
      title: 'Old memory',
      note: 'Before edit.',
      memoryDate: DateTime.utc(2026, 5, 24),
      lat: 10.7769,
      lng: 106.7009,
      media: const <PinMediaDto>[],
      createdAt: DateTime.utc(2026, 5, 24, 18),
      updatedAt: DateTime.utc(2026, 5, 24, 18),
      clientId: 'local_pin_existing_1',
    );
  }

  @override
  Future<List<PinDto>> listByBbox({
    required String mapId,
    required BboxQuery bbox,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PinDto> updatePin({
    required String pinId,
    required CreatePinRequestDto request,
  }) async {
    updateCalls += 1;
    lastUpdatePinId = pinId;
    lastUpdateRequest = request;

    final DateTime now = DateTime.utc(2026, 5, 31, 10);

    return PinDto(
      id: pinId,
      mapId: _map.id,
      title: request.title,
      note: request.note,
      memoryDate: request.memoryDate,
      lat: request.lat,
      lng: request.lng,
      media: const <PinMediaDto>[],
      createdAt: DateTime.utc(2026, 5, 24, 18),
      updatedAt: now,
      clientId: 'local_pin_existing_1',
    );
  }
}

class _FailingPinRepository extends _RecordingPinRepository {
  @override
  Future<PinDto> createPin({
    required String mapId,
    required CreatePinRequestDto request,
  }) async {
    createCalls += 1;
    lastMapId = mapId;
    lastCreateRequest = request;
    throw const ApiException(
      apiError: ApiError(
        error: 'network_error',
        message: 'offline',
        details: <String, Object?>{},
        requestId: '',
      ),
    );
  }
}
