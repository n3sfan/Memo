import 'json.dart';
import 'pin_dto.dart';

class ShareLinkDto {
  const ShareLinkDto({
    required this.id,
    required this.pinId,
    required this.token,
    required this.url,
    required this.revoked,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ShareLinkDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'share link');

    return ShareLinkDto(
      id: readString(json, 'id'),
      pinId: readString(json, 'pinId'),
      token: readString(json, 'token'),
      url: readString(json, 'url'),
      revoked: readBool(json, 'revoked'),
      createdAt: readDateTime(json, 'createdAt'),
      expiresAt: readOptionalDateTime(json, 'expiresAt'),
    );
  }

  final String id;
  final String pinId;
  final String token;
  final String url;
  final bool revoked;
  final DateTime createdAt;
  final DateTime? expiresAt;

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'pinId': pinId,
      'token': token,
      'url': url,
      'revoked': revoked,
      'createdAt': writeDateTime(createdAt),
      'expiresAt': expiresAt == null ? null : writeDateTime(expiresAt!),
    };
  }
}

class PublicSharedPinDto {
  const PublicSharedPinDto({
    required this.shareLinkId,
    required this.pin,
  });

  factory PublicSharedPinDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'public shared pin');

    return PublicSharedPinDto(
      shareLinkId: readString(json, 'shareLinkId'),
      pin: PublicPinDto.fromJson(json['pin']),
    );
  }

  final String shareLinkId;
  final PublicPinDto pin;

  JsonMap toJson() {
    return <String, Object?>{
      'shareLinkId': shareLinkId,
      'pin': pin.toJson(),
    };
  }
}
