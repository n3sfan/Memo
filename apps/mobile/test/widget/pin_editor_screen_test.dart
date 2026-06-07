import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/app/pin_editor_save_flow.dart';
import 'package:memory_map_mobile/app/pin_editor_screen.dart';
import 'package:memory_map_mobile/data/db/app_database.dart';
import 'package:memory_map_mobile/data/db/cache_models.dart';
import 'package:memory_map_mobile/data/db/daos.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/repositories.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

void main() {
  testWidgets(
      'new editor without coordinates blocks save with friendly message',
      (WidgetTester tester) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();

    await _pumpEditor(tester, pinRepository: pinRepository);

    await tester.enterText(
      find.byKey(const ValueKey<String>('pin-editor-title-field')),
      'Kỷ niệm mới',
    );
    await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
    await tester.pump();

    expect(
      find.text('Hãy chọn vị trí trên bản đồ trước khi lưu.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('pin-editor-lat-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('pin-editor-lng-field')),
      findsNothing,
    );
    expect(pinRepository.createCalls, 0);
  });

  testWidgets('new editor saves with route coordinates and no lat/lng inputs',
      (WidgetTester tester) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();
    final _MemoryLocalPinsDao localPinsDao = _MemoryLocalPinsDao();

    await _pumpEditor(
      tester,
      pinRepository: pinRepository,
      localPinsDao: localPinsDao,
      initialCoordinates: _coordinates,
    );

    await _fillValidPinForm(tester);
    await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
    await _pumpAsync(tester);

    expect(
      find.byKey(const ValueKey<String>('pin-editor-lat-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('pin-editor-lng-field')),
      findsNothing,
    );
    expect(pinRepository.createCalls, 1);
    expect(pinRepository.lastCreateRequest?.lat, _coordinates.lat);
    expect(pinRepository.lastCreateRequest?.lng, _coordinates.lng);
    expect(find.text('Kỷ niệm đã lưu.'), findsOneWidget);

    final PinDto? cached = await localPinsDao.getPin('pin_saved_1');
    expect(cached?.lat, _coordinates.lat);
    expect(cached?.lng, _coordinates.lng);
  });

  testWidgets('memory date uses date picker instead of manual typing',
      (WidgetTester tester) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();

    await _pumpEditor(
      tester,
      pinRepository: pinRepository,
      initialCoordinates: _coordinates,
    );

    await tester
        .tap(find.byKey(const ValueKey<String>('pin-editor-date-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('2026-06-15'), findsOneWidget);
  });

  testWidgets('copy separates the memory story from text file attachments',
      (WidgetTester tester) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();

    await _pumpEditor(
      tester,
      pinRepository: pinRepository,
      initialCoordinates: _coordinates,
    );

    expect(find.text('Ghi chú'), findsOneWidget);
    expect(find.text('Nội dung đính kèm'), findsOneWidget);
    expect(find.text('Thêm ghi chú'), findsNothing);
  });

  testWidgets('audio control opens clear audio options, not a vague recorder',
      (WidgetTester tester) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();

    await _pumpEditor(
      tester,
      pinRepository: pinRepository,
      initialCoordinates: _coordinates,
      attachmentActions: const DefaultPinEditorAttachmentActions(),
    );

    await _openAddContentSheet(tester);
    await tester
        .tap(find.byKey(const ValueKey<String>('pin-editor-add-audio')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Âm thanh'),
      ),
      findsOneWidget,
    );
    expect(find.text('Ghi âm mới'), findsOneWidget);
    expect(find.text('Chọn file âm thanh'), findsOneWidget);
    expect(
      find.text('Video cần backend hỗ trợ mediaType video nên chưa bật ở đây.'),
      findsOneWidget,
    );
  });

  testWidgets('attachment controls add real drafts and allow removal',
      (WidgetTester tester) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();

    await _pumpEditor(
      tester,
      pinRepository: pinRepository,
      initialCoordinates: _coordinates,
      attachmentActions: _FakeAttachmentActions(),
    );

    await _addAttachment(tester, 'pin-editor-add-image');
    await _addAttachment(tester, 'pin-editor-add-text');
    await _addAttachment(tester, 'pin-editor-add-audio');

    expect(find.text('photo.jpg'), findsOneWidget);
    expect(find.text('story.txt'), findsOneWidget);
    expect(find.text('voice.m4a'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('pin-editor-remove-image-1')));
    await tester.pump();

    expect(find.text('photo.jpg'), findsNothing);
    expect(find.text('story.txt'), findsOneWidget);
  });

  testWidgets('online save uploads attachments to R2 and registers media',
      (WidgetTester tester) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();
    final _RecordingMediaRepository mediaRepository =
        _RecordingMediaRepository();
    final _RecordingObjectUploadClient uploadClient =
        _RecordingObjectUploadClient();
    final _MemoryLocalPinsDao localPinsDao = _MemoryLocalPinsDao();

    await _pumpEditor(
      tester,
      pinRepository: pinRepository,
      mediaRepository: mediaRepository,
      objectUploadClient: uploadClient,
      localPinsDao: localPinsDao,
      initialCoordinates: _coordinates,
      attachmentActions: _FakeAttachmentActions(),
    );

    await _fillValidPinForm(tester);
    await _addAttachment(tester, 'pin-editor-add-image');
    await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
    await _pumpAsync(tester);

    expect(pinRepository.createCalls, 1);
    expect(mediaRepository.presignCalls, 1);
    expect(uploadClient.uploadCalls, 1);
    expect(mediaRepository.registerCalls, 1);
    expect(mediaRepository.lastRegisterObjectKey, 'pins/pin_saved_1/photo.jpg');
    expect(find.text('Kỷ niệm đã lưu.'), findsOneWidget);

    final PinDto? cached = await localPinsDao.getPin('pin_saved_1');
    expect(cached?.media, hasLength(1));
  });

  testWidgets('media upload failure keeps saved pin and queues attachment',
      (WidgetTester tester) async {
    final _RecordingPinRepository pinRepository = _RecordingPinRepository();
    final _RecordingMediaRepository mediaRepository =
        _RecordingMediaRepository();
    final _FailingObjectUploadClient uploadClient =
        _FailingObjectUploadClient();
    final _MemoryUploadQueueDao uploadQueueDao = _MemoryUploadQueueDao();

    await _pumpEditor(
      tester,
      pinRepository: pinRepository,
      mediaRepository: mediaRepository,
      objectUploadClient: uploadClient,
      uploadQueueDao: uploadQueueDao,
      initialCoordinates: _coordinates,
      attachmentActions: _FakeAttachmentActions(),
    );

    await _fillValidPinForm(tester);
    await _addAttachment(tester, 'pin-editor-add-image');
    await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
    await _pumpAsync(tester);

    expect(pinRepository.createCalls, 1);
    expect(uploadClient.uploadCalls, 1);
    expect(mediaRepository.registerCalls, 0);
    expect(await uploadQueueDao.listPendingMediaUploads(), hasLength(1));
    expect(
      find.text('Kỷ niệm đã lưu, tệp sẽ tải lên lại sau.'),
      findsOneWidget,
    );
  });

  testWidgets('offline pin save still queues pending pin and media',
      (WidgetTester tester) async {
    final _FailingPinRepository pinRepository = _FailingPinRepository();
    final _MemoryUploadQueueDao uploadQueueDao = _MemoryUploadQueueDao();

    await _pumpEditor(
      tester,
      pinRepository: pinRepository,
      uploadQueueDao: uploadQueueDao,
      initialCoordinates: _coordinates,
      attachmentActions: _FakeAttachmentActions(),
    );

    await _fillValidPinForm(tester);
    await _addAttachment(tester, 'pin-editor-add-image');
    await tester.tap(find.byKey(const ValueKey<String>('pin-editor-save')));
    await _pumpAsync(tester);

    expect(await uploadQueueDao.listPendingPinMutations(), hasLength(1));
    expect(await uploadQueueDao.listPendingMediaUploads(), hasLength(1));
    expect(
      find.text('Đã lưu offline. Sẽ đồng bộ khi có mạng.'),
      findsOneWidget,
    );
  });
}

const MapDto _map = MapDto(
  id: 'map_test_1',
  type: MemoryMapType.personal,
  ownerId: 'user_test_1',
  name: 'Test Map',
);

const Coordinates _coordinates = Coordinates(lat: 10.762622, lng: 106.660172);

Future<void> _pumpEditor(
  WidgetTester tester, {
  required PinRepository pinRepository,
  LocalPinsDao? localPinsDao,
  UploadQueueDao? uploadQueueDao,
  MediaRepository? mediaRepository,
  ObjectUploadClient? objectUploadClient,
  PinEditorAttachmentActions? attachmentActions,
  Coordinates? initialCoordinates,
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
        localPinsDaoProvider.overrideWithValue(
          localPinsDao ?? _MemoryLocalPinsDao(),
        ),
        uploadQueueDaoProvider.overrideWithValue(
          uploadQueueDao ?? _MemoryUploadQueueDao(),
        ),
        mapRepositoryProvider.overrideWithValue(const _FakeMapRepository(_map)),
        pinRepositoryProvider.overrideWithValue(pinRepository),
        mediaRepositoryProvider.overrideWithValue(
          mediaRepository ?? _RecordingMediaRepository(),
        ),
        objectUploadClientProvider.overrideWithValue(
          objectUploadClient ?? _RecordingObjectUploadClient(),
        ),
      ],
      child: MaterialApp(
        home: PinEditorScreen(
          pinId: pinId,
          initialCoordinates: initialCoordinates,
          attachmentActions: attachmentActions ?? _NoopAttachmentActions(),
          now: () => DateTime.utc(2026, 6, 2),
        ),
      ),
    ),
  );
}

Future<void> _fillValidPinForm(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('pin-editor-title-field')),
    'Cà phê Đà Lạt',
  );
  await tester.enterText(
    find.byKey(const ValueKey<String>('pin-editor-note-field')),
    'Một buổi sáng yên tĩnh.',
  );
}

Future<void> _openAddContentSheet(WidgetTester tester) async {
  final Finder addContent =
      find.byKey(const ValueKey<String>('pin-editor-add-content'));
  await tester.ensureVisible(addContent);
  await tester.tap(addContent);
  await tester.pumpAndSettle();
}

Future<void> _addAttachment(WidgetTester tester, String actionKey) async {
  await _openAddContentSheet(tester);
  await tester.tap(find.byKey(ValueKey<String>(actionKey)));
  await tester.pumpAndSettle();
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

  @override
  Future<MapDto> createDuoMap({String? name}) {
    throw UnimplementedError();
  }

  @override
  Future<InvitationDto> createInvitation({required String mapId}) {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeInvitation({
    required String mapId,
    required String invitationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AcceptInvitationResponseDto> acceptInvitation({
    required String code,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RemoveMapMemberResponseDto> removeMember({
    required String mapId,
    required String userId,
  }) {
    throw UnimplementedError();
  }
}

class _NoopAttachmentActions implements PinEditorAttachmentActions {
  @override
  Future<PinEditorAttachmentDraft?> pickAudio(BuildContext context) async {
    return null;
  }

  @override
  Future<PinEditorAttachmentDraft?> pickImage(BuildContext context) async {
    return null;
  }

  @override
  Future<PinEditorAttachmentDraft?> pickText(BuildContext context) async {
    return null;
  }
}

class _FakeAttachmentActions implements PinEditorAttachmentActions {
  @override
  Future<PinEditorAttachmentDraft?> pickImage(BuildContext context) async {
    return const PinEditorAttachmentDraft(
      id: 'image-1',
      mediaType: PinMediaType.image,
      label: 'photo.jpg',
      localPath: '/tmp/photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1234,
      fileName: 'photo.jpg',
    );
  }

  @override
  Future<PinEditorAttachmentDraft?> pickText(BuildContext context) async {
    return const PinEditorAttachmentDraft(
      id: 'text-1',
      mediaType: PinMediaType.text,
      label: 'story.txt',
      localPath: '/tmp/story.txt',
      mimeType: 'text/plain',
      sizeBytes: 64,
      fileName: 'story.txt',
    );
  }

  @override
  Future<PinEditorAttachmentDraft?> pickAudio(BuildContext context) async {
    return const PinEditorAttachmentDraft(
      id: 'audio-1',
      mediaType: PinMediaType.audio,
      label: 'voice.m4a',
      localPath: '/tmp/voice.m4a',
      mimeType: 'audio/mp4',
      sizeBytes: 2048,
      fileName: 'voice.m4a',
    );
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

    final DateTime now = DateTime.utc(2026, 6, 2, 10);

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
      title: 'Kỷ niệm cũ',
      note: 'Trước khi sửa.',
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
      updatedAt: DateTime.utc(2026, 6, 2, 10),
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

class _RecordingMediaRepository implements MediaRepository {
  int presignCalls = 0;
  int registerCalls = 0;
  String? lastRegisterObjectKey;

  @override
  Future<PresignResponseDto> createPresignedUpload({
    required String pinId,
    required PresignRequestDto request,
  }) async {
    presignCalls += 1;

    return PresignResponseDto(
      uploadUrl: 'https://r2.example.test/$pinId/${request.fileName}',
      objectKey: 'pins/$pinId/${request.fileName}',
      expiresAt: DateTime.utc(2026, 6, 2, 10, 15),
    );
  }

  @override
  Future<PinMediaDto> registerMedia({
    required String pinId,
    required RegisterMediaRequestDto request,
  }) async {
    registerCalls += 1;
    lastRegisterObjectKey = request.objectKey;

    return PinMediaDto(
      id: 'media_$registerCalls',
      pinId: pinId,
      mediaType: request.mediaType,
      objectKey: request.objectKey,
      mimeType: request.mimeType,
      sizeBytes: request.sizeBytes,
      createdAt: DateTime.utc(2026, 6, 2, 10, 16),
    );
  }

  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) async {
    return MediaReadUrlDto(
      url: 'https://r2.example.test/read/$mediaId',
      expiresAt: DateTime.utc(2026, 6, 2, 10, 15),
    );
  }
}

class _RecordingObjectUploadClient implements ObjectUploadClient {
  int uploadCalls = 0;

  @override
  Future<void> uploadFile({
    required String uploadUrl,
    required String localPath,
    required String mimeType,
    required int sizeBytes,
  }) async {
    uploadCalls += 1;
  }
}

class _FailingObjectUploadClient extends _RecordingObjectUploadClient {
  @override
  Future<void> uploadFile({
    required String uploadUrl,
    required String localPath,
    required String mimeType,
    required int sizeBytes,
  }) async {
    uploadCalls += 1;
    throw const ApiException(
      apiError: ApiError(
        error: 'network_error',
        message: 'upload failed',
        details: <String, Object?>{},
        requestId: '',
      ),
    );
  }
}
