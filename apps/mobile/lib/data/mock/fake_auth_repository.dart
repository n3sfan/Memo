import '../../auth/session.dart';
import '../../auth/token_storage.dart';
import '../models/models.dart';
import '../repositories/auth_repository.dart';
import 'mock_data.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.tokenStorage);

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
      user: mockUser,
    );
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
  Future<void> logout() {
    return tokenStorage.clearSession();
  }
}
