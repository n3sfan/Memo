import 'session.dart';

abstract interface class TokenStorage {
  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<AuthSession?> getSession();

  Future<void> saveSession(AuthSession session);

  Future<void> clearSession();
}

class InMemoryTokenStorage implements TokenStorage {
  AuthSession? _session;

  @override
  Future<String?> getAccessToken() async {
    return _session?.accessToken;
  }

  @override
  Future<String?> getRefreshToken() async {
    return _session?.refreshToken;
  }

  @override
  Future<AuthSession?> getSession() async {
    return _session;
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }
}
