import '../../auth/session.dart';
import '../../auth/token_storage.dart';
import '../api_client.dart';
import '../models/models.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> getSavedSession();

  Future<SessionDto> refreshSession();

  Future<void> saveSession(SessionDto session);

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
  Future<AuthSession?> getSavedSession() async {
    final String? accessToken = await tokenStorage.getAccessToken();
    final String? refreshToken = await tokenStorage.getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<SessionDto> refreshSession() async {
    final String? refreshToken = await tokenStorage.getRefreshToken();
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
  Future<void> logout() async {
    await apiClient.post<JsonMap>(
      '/auth/logout',
      decoder: (Object? data) => data == null
          ? const <String, Object?>{}
          : asJsonMap(data, name: 'logout response'),
    );
    await tokenStorage.clearSession();
  }
}
