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
    required this.status,
  });

  final PinDto pin;
  final PinEditorSaveStatus status;
}

enum PinEditorSaveStatus {
  synced,
  pendingPin,
  mediaPending,
}

class PinEditorSaveFlow {
  PinEditorSaveFlow({
    required PinRepository pinRepository,
    required MediaRepository mediaRepository,
    required ObjectUploadClient objectUploadClient,
    required LocalPinsDao localPinsDao,
    required UploadQueueDao uploadQueueDao,
    ClientIdFactory createId = createLocalClientId,
    DateTimeFactory now = _utcNow,
  })  : _pinRepository = pinRepository,
        _mediaRepository = mediaRepository,
        _objectUploadClient = objectUploadClient,
        _localPinsDao = localPinsDao,
        _uploadQueueDao = uploadQueueDao,
        _createId = createId,
        _now = now;

  final PinRepository _pinRepository;
  final MediaRepository _mediaRepository;
  final ObjectUploadClient _objectUploadClient;
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
      final List<PinMediaDto> uploadedMedia = <PinMediaDto>[];
      var mediaPending = false;

      for (final PinEditorAttachmentDraft attachment in input.attachments) {
        try {
          uploadedMedia.add(await _uploadAttachment(saved.id, attachment));
        } catch (_) {
          mediaPending = true;
          await _enqueueAttachment(clientId, attachment, syncedAt);
        }
      }

      final PinDto pinWithMedia = uploadedMedia.isEmpty
          ? saved
          : _copyPinWithMedia(saved, <PinMediaDto>[
              ...saved.media,
              ...uploadedMedia,
            ]);

      await _localPinsDao.upsertPin(pinWithMedia, syncedAt: syncedAt);

      return PinEditorSaveResult(
        pin: pinWithMedia,
        status: mediaPending
            ? PinEditorSaveStatus.mediaPending
            : PinEditorSaveStatus.synced,
      );
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

    return PinEditorSaveResult(
      pin: pendingPin,
      status: PinEditorSaveStatus.pendingPin,
    );
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

  Future<PinMediaDto> _uploadAttachment(
    String pinId,
    PinEditorAttachmentDraft attachment,
  ) async {
    final PresignResponseDto presigned =
        await _mediaRepository.createPresignedUpload(
      pinId: pinId,
      request: PresignRequestDto(
        mediaType: attachment.mediaType,
        mimeType: attachment.mimeType,
        sizeBytes: attachment.sizeBytes,
        fileName: attachment.fileName,
      ),
    );

    await _objectUploadClient.uploadFile(
      uploadUrl: presigned.uploadUrl,
      localPath: attachment.localPath,
      mimeType: attachment.mimeType,
      sizeBytes: attachment.sizeBytes,
    );

    return _mediaRepository.registerMedia(
      pinId: pinId,
      request: RegisterMediaRequestDto(
        mediaType: attachment.mediaType,
        objectKey: presigned.objectKey,
        mimeType: attachment.mimeType,
        sizeBytes: attachment.sizeBytes,
      ),
    );
  }

  Future<void> _enqueueAttachments(
    String pinClientId,
    List<PinEditorAttachmentDraft> attachments,
    DateTime createdAt,
  ) async {
    for (final PinEditorAttachmentDraft attachment in attachments) {
      await _enqueueAttachment(pinClientId, attachment, createdAt);
    }
  }

  Future<void> _enqueueAttachment(
    String pinClientId,
    PinEditorAttachmentDraft attachment,
    DateTime createdAt,
  ) {
    return _uploadQueueDao.enqueueMediaUpload(
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

  PinDto _copyPinWithMedia(PinDto pin, List<PinMediaDto> media) {
    return PinDto(
      id: pin.id,
      mapId: pin.mapId,
      title: pin.title,
      note: pin.note,
      memoryDate: pin.memoryDate,
      lat: pin.lat,
      lng: pin.lng,
      media: media,
      createdAt: pin.createdAt,
      updatedAt: pin.updatedAt,
      clientId: pin.clientId,
    );
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
