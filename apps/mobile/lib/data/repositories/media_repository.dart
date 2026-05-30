import '../api_client.dart';
import '../models/models.dart';

abstract interface class MediaRepository {
  Future<PresignResponseDto> createPresignedUpload({
    required String pinId,
    required PresignRequestDto request,
  });
}

class ApiMediaRepository implements MediaRepository {
  ApiMediaRepository(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<PresignResponseDto> createPresignedUpload({
    required String pinId,
    required PresignRequestDto request,
  }) {
    return apiClient.post<PresignResponseDto>(
      '/pins/$pinId/media/presign',
      body: request.toJson(),
      decoder: PresignResponseDto.fromJson,
    );
  }
}
