import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/models.dart';
import 'session.dart';
import 'token_storage.dart';

class TokenStoragePrefs implements TokenStorage {
  TokenStoragePrefs({
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _preferencesFactory =
            preferencesFactory ?? SharedPreferences.getInstance;

  static const String _accessTokenKey = 'auth.accessToken';
  static const String _refreshTokenKey = 'auth.refreshToken';
  static const String _expiresAtKey = 'auth.expiresAt';
  static const String _userKey = 'auth.user';

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
  Future<AuthSession?> getSession() async {
    final SharedPreferences preferences = await _preferencesFactory();
    final String? accessToken = preferences.getString(_accessTokenKey);
    final String? refreshToken = preferences.getString(_refreshTokenKey);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: _readExpiresAt(preferences),
      user: _readUser(preferences),
    );
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    final SharedPreferences preferences = await _preferencesFactory();

    await preferences.setString(_accessTokenKey, session.accessToken);
    await preferences.setString(_refreshTokenKey, session.refreshToken);

    final DateTime? expiresAt = session.expiresAt;
    if (expiresAt == null) {
      await preferences.remove(_expiresAtKey);
    } else {
      await preferences.setString(_expiresAtKey, expiresAt.toIso8601String());
    }

    final UserProfileDto? user = session.user;
    if (user == null) {
      await preferences.remove(_userKey);
    } else {
      await preferences.setString(_userKey, jsonEncode(user.toJson()));
    }
  }

  @override
  Future<void> clearSession() async {
    final SharedPreferences preferences = await _preferencesFactory();

    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_expiresAtKey);
    await preferences.remove(_userKey);
  }

  DateTime? _readExpiresAt(SharedPreferences preferences) {
    final String? raw = preferences.getString(_expiresAtKey);
    if (raw == null) {
      return null;
    }

    return DateTime.tryParse(raw)?.toUtc();
  }

  UserProfileDto? _readUser(SharedPreferences preferences) {
    final String? raw = preferences.getString(_userKey);
    if (raw == null) {
      return null;
    }

    try {
      return UserProfileDto.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }
}
