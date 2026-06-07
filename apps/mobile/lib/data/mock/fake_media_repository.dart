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
      url: 'https://storage.memo.local/read/$mediaId',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
  }
}
