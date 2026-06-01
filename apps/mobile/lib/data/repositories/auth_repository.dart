import '../../auth/session.dart';
import '../../auth/token_storage.dart';
import '../api_client.dart';
import '../models/models.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> getSavedSession();

  Future<OAuthStartResponseDto> startOAuth({
    required OAuthProviderType provider,
    required String redirectUri,
  });

  Future<SessionDto> completeOAuth({
    required OAuthProviderType provider,
    required String code,
    required String state,
    required String redirectUri,
  });

  Future<SessionDto> refreshSession();

  Future<void> saveSession(SessionDto session);

  Future<void> clearSession();

  Future<void> logout();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  @override
  Future<AuthSession?> getSavedSession() {
    return tokenStorage.getSession();
  }

  @override
  Future<OAuthStartResponseDto> startOAuth({
    required OAuthProviderType provider,
    required String redirectUri,
  }) {
    return apiClient.post<OAuthStartResponseDto>(
      '/auth/oauth/${provider.pathSegment}/start',
      body: OAuthStartRequestDto(redirectUri: redirectUri).toJson(),
      decoder: OAuthStartResponseDto.fromJson,
    );
  }

  @override
  Future<SessionDto> completeOAuth({
    required OAuthProviderType provider,
    required String code,
    required String state,
    required String redirectUri,
  }) async {
    final SessionDto session = await apiClient.post<SessionDto>(
      '/auth/oauth/${provider.pathSegment}/callback',
      body: OAuthCallbackRequestDto(
        code: code,
        state: state,
        redirectUri: redirectUri,
      ).toJson(),
      decoder: SessionDto.fromJson,
    );
    await saveSession(session);

    return session;
  }

  @override
  Future<SessionDto> refreshSession() async {
    final String? refreshToken = await tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearSession();
      throw const FormatException('Missing refresh token');
    }

    final SessionDto session = await apiClient.post<SessionDto>(
      '/auth/refresh',
      body: <String, Object?>{
        'refreshToken': refreshToken,
      },
      decoder: SessionDto.fromJson,
    );
    await saveSession(session);

    return session;
  }

  @override
  Future<void> saveSession(SessionDto session) {
    return tokenStorage.saveSession(AuthSession.fromDto(session));
  }

  @override
  Future<void> clearSession() {
    return tokenStorage.clearSession();
  }

  @override
  Future<void> logout() async {
    final String? refreshToken = await tokenStorage.getRefreshToken();

    try {
      await apiClient.post<JsonMap>(
        '/auth/logout',
        body: refreshToken == null || refreshToken.isEmpty
            ? null
            : <String, Object?>{'refreshToken': refreshToken},
        decoder: (Object? data) => data == null
            ? const <String, Object?>{}
            : asJsonMap(data, name: 'logout response'),
      );
    } finally {
      await clearSession();
    }
  }
}
