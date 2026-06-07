import '../models/models.dart';
import '../repositories/media_repository.dart';
import 'mock_data.dart';

class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository(this.state);

  final MockBackendState state;

  @override
  Future<PresignResponseDto> createPresignedUpload({
    required String pinId,
    required PresignRequestDto request,
  }) async {
    return PresignResponseDto(
      uploadUrl: 'https://storage.memo.local/upload/$pinId/${request.fileName}',
      objectKey: 'mock/$pinId/${state.nextId('media')}-${request.fileName}',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<PinMediaDto> registerMedia({
    required String pinId,
    required RegisterMediaRequestDto request,
  }) async {
    return PinMediaDto(
      id: state.nextId('media'),
      pinId: pinId,
      mediaType: request.mediaType,
      objectKey: request.objectKey,
      mimeType: request.mimeType,
      sizeBytes: request.sizeBytes,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) async {
    return MediaReadUrlDto(
      url: _readUrlFor(mediaId),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }

  String _readUrlFor(String mediaId) {
    final PinMediaDto? media = _findMedia(mediaId);

    return switch (media?.mediaType) {
      PinMediaType.image => 'https://picsum.photos/seed/memo-$mediaId/1200/900',
      PinMediaType.audio =>
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      PinMediaType.text || null => 'https://storage.memo.local/read/$mediaId',
    };
  }

  PinMediaDto? _findMedia(String mediaId) {
    for (final PinDto pin in state.pins) {
      for (final PinMediaDto media in pin.media) {
        if (media.id == mediaId) {
          return media;
        }
      }
    }
    return null;
  }
}
