import '../data/client_id.dart';
import '../data/db/cache_models.dart';
import '../data/db/daos.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

typedef ClientIdFactory = String Function({String prefix});
typedef DateTimeFactory = DateTime Function();

class PinEditorAttachmentDraft {
  const PinEditorAttachmentDraft({
    required this.id,
    required this.mediaType,
    required this.label,
    required this.localPath,
    required this.mimeType,
    required this.sizeBytes,
    required this.fileName,
  });

  factory PinEditorAttachmentDraft.placeholder({
    required PinMediaType mediaType,
    required String id,
  }) {
    return switch (mediaType) {
      PinMediaType.image => PinEditorAttachmentDraft(
          id: id,
          mediaType: mediaType,
          label: 'Image placeholder queued',
          localPath: 'memo-image://$id',
          mimeType: 'image/jpeg',
          sizeBytes: 1,
          fileName: 'image-placeholder.jpg',
        ),
      PinMediaType.text => PinEditorAttachmentDraft(
          id: id,
          mediaType: mediaType,
          label: 'Text placeholder queued',
          localPath: 'memo-text://$id',
          mimeType: 'text/plain',
          sizeBytes: 1,
          fileName: 'text-attachment.txt',
        ),
      PinMediaType.audio => PinEditorAttachmentDraft(
          id: id,
          mediaType: mediaType,
          label: 'Audio placeholder queued',
          localPath: 'memo-audio://$id',
          mimeType: 'audio/mp4',
          sizeBytes: 1,
          fileName: 'audio-placeholder.m4a',
        ),
    };
  }

  final String id;
  final PinMediaType mediaType;
  final String label;
  final String localPath;
  final String mimeType;
  final int sizeBytes;
  final String fileName;
}

class PinEditorSaveInput {
  const PinEditorSaveInput({
    required this.mapId,
    required this.title,
    required this.lat,
    required this.lng,
    required this.attachments,
    this.pinId,
    this.existingPin,
    this.note,
    this.memoryDate,
  });

  final String mapId;
  final String? pinId;
  final PinDto? existingPin;
  final String title;
  final String? note;
  final DateTime? memoryDate;
  final double lat;
  final double lng;
  final List<PinEditorAttachmentDraft> attachments;
}

class PinEditorSaveResult {
  const PinEditorSaveResult({
    required this.pin,
    required this.pendingSync,
  });

  final PinDto pin;
  final bool pendingSync;
}

class PinEditorSaveFlow {
  PinEditorSaveFlow({
    required PinRepository pinRepository,
    required LocalPinsDao localPinsDao,
    required UploadQueueDao uploadQueueDao,
    ClientIdFactory createId = createLocalClientId,
    DateTimeFactory now = _utcNow,
  })  : _pinRepository = pinRepository,
        _localPinsDao = localPinsDao,
        _uploadQueueDao = uploadQueueDao,
        _createId = createId,
        _now = now;

  final PinRepository _pinRepository;
  final LocalPinsDao _localPinsDao;
  final UploadQueueDao _uploadQueueDao;
  final ClientIdFactory _createId;
  final DateTimeFactory _now;

  Future<PinEditorSaveResult> save(PinEditorSaveInput input) async {
    final String clientId = input.existingPin?.clientId ??
        _createId(prefix: input.pinId == null ? 'local_pin' : 'local_pin_edit');
    final CreatePinRequestDto request = CreatePinRequestDto(
      title: input.title,
      note: input.note,
      memoryDate: input.memoryDate,
      lat: input.lat,
      lng: input.lng,
      clientId: clientId,
    );

    try {
      final PinDto saved = input.pinId == null
          ? await _pinRepository.createPin(
              mapId: input.mapId,
              request: request,
            )
          : await _pinRepository.updatePin(
              pinId: input.pinId!,
              request: request,
            );

      final DateTime syncedAt = _now();
      await _localPinsDao.upsertPin(saved, syncedAt: syncedAt);
      await _enqueueAttachments(clientId, input.attachments, syncedAt);

      return PinEditorSaveResult(pin: saved, pendingSync: false);
    } on ApiException catch (error) {
      if (error.apiError.error != 'network_error') {
        rethrow;
      }

      return _savePending(input, request, clientId);
    }
  }

  Future<PinEditorSaveResult> _savePending(
    PinEditorSaveInput input,
    CreatePinRequestDto request,
    String clientId,
  ) async {
    final DateTime createdAt = _now();
    final PinDto pendingPin = _pendingPin(input, clientId, createdAt);

    await _localPinsDao.upsertPin(pendingPin);
    await _uploadQueueDao.enqueuePinMutation(
      PendingPinMutation(
        id: _createId(prefix: 'pending_pin'),
        clientId: clientId,
        operation: input.pinId == null ? 'create' : 'update',
        payload: <String, Object?>{
          'mapId': input.mapId,
          if (input.pinId != null) 'pinId': input.pinId,
          ...request.toJson(),
        },
        createdAt: createdAt,
        retryCount: 0,
      ),
    );
    await _enqueueAttachments(clientId, input.attachments, createdAt);

    return PinEditorSaveResult(pin: pendingPin, pendingSync: true);
  }

  PinDto _pendingPin(
    PinEditorSaveInput input,
    String clientId,
    DateTime now,
  ) {
    final PinDto? current = input.existingPin;

    return PinDto(
      id: input.pinId ?? clientId,
      mapId: input.mapId,
      title: input.title,
      note: input.note,
      memoryDate: input.memoryDate,
      lat: input.lat,
      lng: input.lng,
      media: current?.media ?? const <PinMediaDto>[],
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
      clientId: clientId,
    );
  }

  Future<void> _enqueueAttachments(
    String pinClientId,
    List<PinEditorAttachmentDraft> attachments,
    DateTime createdAt,
  ) async {
    for (final PinEditorAttachmentDraft attachment in attachments) {
      await _uploadQueueDao.enqueueMediaUpload(
        PendingMediaUpload(
          id: attachment.id,
          pinClientId: pinClientId,
          localPath: attachment.localPath,
          mediaType: attachment.mediaType,
          mimeType: attachment.mimeType,
          sizeBytes: attachment.sizeBytes,
          fileName: attachment.fileName,
          createdAt: createdAt,
          retryCount: 0,
        ),
      );
    }
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
