import 'json.dart';

enum OAuthProviderType {
  google('google'),
  apple('apple');

  const OAuthProviderType(this.pathSegment);

  final String pathSegment;

  static OAuthProviderType fromPathSegment(String value) {
    for (final OAuthProviderType provider in OAuthProviderType.values) {
      if (provider.pathSegment == value) {
        return provider;
      }
    }

    throw FormatException('Unsupported OAuth provider: $value');
  }
}

class OAuthStartRequestDto {
  const OAuthStartRequestDto({required this.redirectUri});

  final String redirectUri;

  JsonMap toJson() {
    return <String, Object?>{
      'redirectUri': redirectUri,
    };
  }
}

class OAuthStartResponseDto {
  const OAuthStartResponseDto({
    required this.authorizationUrl,
    required this.state,
  });

  factory OAuthStartResponseDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'oauth start response');

    return OAuthStartResponseDto(
      authorizationUrl: readString(json, 'authorizationUrl'),
      state: readString(json, 'state'),
    );
  }

  final String authorizationUrl;
  final String state;

  JsonMap toJson() {
    return <String, Object?>{
      'authorizationUrl': authorizationUrl,
      'state': state,
    };
  }
}

class OAuthCallbackRequestDto {
  const OAuthCallbackRequestDto({
    required this.code,
    required this.state,
    required this.redirectUri,
  });

  final String code;
  final String state;
  final String redirectUri;

  JsonMap toJson() {
    return <String, Object?>{
      'code': code,
      'state': state,
      'redirectUri': redirectUri,
    };
  }
}

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
