import '../../auth/session.dart';
import '../../auth/token_storage.dart';
import '../models/models.dart';
import '../repositories/auth_repository.dart';
import 'mock_data.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.tokenStorage);

  final TokenStorage tokenStorage;

  @override
  Future<AuthSession?> getSavedSession() {
    return tokenStorage.getSession();
  }

  @override
  Future<OAuthStartResponseDto> startOAuth({
    required OAuthProviderType provider,
    required String redirectUri,
  }) async {
    return OAuthStartResponseDto(
      authorizationUrl:
          '$redirectUri?code=mock_${provider.pathSegment}_code&state=mock_state',
      state: 'mock_state',
    );
  }

  @override
  Future<SessionDto> completeOAuth({
    required OAuthProviderType provider,
    required String code,
    required String state,
    required String redirectUri,
  }) async {
    await saveSession(mockSession);

    return mockSession;
  }

  @override
  Future<SessionDto> refreshSession() async {
    await saveSession(mockSession);

    return mockSession;
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
  Future<void> logout() {
    return clearSession();
  }
}
