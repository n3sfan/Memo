import '../api_client.dart';
import '../models/models.dart';

abstract interface class MediaRepository {
  Future<PresignResponseDto> createPresignedUpload({
    required String pinId,
    required PresignRequestDto request,
  });

  Future<PinMediaDto> registerMedia({
    required String pinId,
    required RegisterMediaRequestDto request,
  });

  Future<MediaReadUrlDto> createReadUrl(String mediaId);
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

  @override
  Future<PinMediaDto> registerMedia({
    required String pinId,
    required RegisterMediaRequestDto request,
  }) {
    return apiClient.post<PinMediaDto>(
      '/pins/$pinId/media',
      body: request.toJson(),
      decoder: PinMediaDto.fromJson,
    );
  }

  @override
  Future<MediaReadUrlDto> createReadUrl(String mediaId) {
    return apiClient.get<MediaReadUrlDto>(
      '/media/$mediaId/presign',
      decoder: MediaReadUrlDto.fromJson,
    );
  }
}
