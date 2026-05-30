import 'package:shared_preferences/shared_preferences.dart';

import 'session.dart';
import 'token_storage.dart';

class TokenStoragePrefs implements TokenStorage {
  TokenStoragePrefs({
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _preferencesFactory =
            preferencesFactory ?? SharedPreferences.getInstance;

  static const String _accessTokenKey = 'auth.accessToken';
  static const String _refreshTokenKey = 'auth.refreshToken';

  final Future<SharedPreferences> Function() _preferencesFactory;

  @override
  Future<String?> getAccessToken() async {
    final SharedPreferences preferences = await _preferencesFactory();

    return preferences.getString(_accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    final SharedPreferences preferences = await _preferencesFactory();

    return preferences.getString(_refreshTokenKey);
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    final SharedPreferences preferences = await _preferencesFactory();

    await preferences.setString(_accessTokenKey, session.accessToken);
    await preferences.setString(_refreshTokenKey, session.refreshToken);
  }

  @override
  Future<void> clearSession() async {
    final SharedPreferences preferences = await _preferencesFactory();

    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
  }
}
