import 'json.dart';

class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserProfileDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'user');

    return UserProfileDto(
      id: readString(json, 'id'),
      email: readString(json, 'email'),
      displayName: readString(json, 'displayName'),
      avatarUrl: readOptionalString(json, 'avatarUrl'),
    );
  }

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
    };
  }
}

class SessionDto {
  const SessionDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory SessionDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'session');

    return SessionDto(
      accessToken: readString(json, 'accessToken'),
      refreshToken: readString(json, 'refreshToken'),
      expiresIn: readInt(json, 'expiresIn'),
      user: UserProfileDto.fromJson(json['user']),
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserProfileDto user;

  JsonMap toJson() {
    return <String, Object?>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'user': user.toJson(),
    };
  }
}
