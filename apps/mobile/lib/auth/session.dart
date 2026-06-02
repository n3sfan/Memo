import '../data/models/auth_dto.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
    this.user,
  });

  factory AuthSession.fromDto(SessionDto dto, {DateTime? issuedAt}) {
    final DateTime now = issuedAt ?? DateTime.now().toUtc();

    return AuthSession(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      expiresAt: now.add(Duration(seconds: dto.expiresIn)),
      user: dto.user,
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;
  final UserProfileDto? user;

  bool isExpired({DateTime? now, Duration skew = const Duration(seconds: 30)}) {
    final DateTime? expiry = expiresAt;
    if (expiry == null) {
      return false;
    }

    return !(now ?? DateTime.now().toUtc()).add(skew).isBefore(expiry);
  }
}
