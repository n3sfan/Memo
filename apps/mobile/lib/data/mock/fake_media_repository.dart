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
}
