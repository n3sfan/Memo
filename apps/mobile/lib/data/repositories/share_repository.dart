import '../api_client.dart';
import '../models/models.dart';

abstract interface class ShareRepository {
  Future<ShareLinkDto> createShareLink(String pinId);
  Future<void> revokeShareLink(String shareLinkId);
  Future<PublicSharedPinDto> resolvePublicPin(String token);
}

class ApiShareRepository implements ShareRepository {
  ApiShareRepository(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<ShareLinkDto> createShareLink(String pinId) {
    return apiClient.post<ShareLinkDto>(
      '/pins/$pinId/share-links',
      body: const <String, Object?>{},
      decoder: ShareLinkDto.fromJson,
    );
  }

  @override
  Future<void> revokeShareLink(String shareLinkId) async {
    await apiClient.delete<JsonMap>(
      '/share-links/$shareLinkId',
      decoder: (Object? data) => data == null
          ? const <String, Object?>{}
          : asJsonMap(data, name: 'revoke share link response'),
    );
  }

  @override
  Future<PublicSharedPinDto> resolvePublicPin(String token) {
    return apiClient.get<PublicSharedPinDto>(
      '/share/$token',
      decoder: PublicSharedPinDto.fromJson,
    );
  }
}
