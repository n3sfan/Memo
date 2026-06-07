import 'json.dart';

class MediaReadUrlDto {
  const MediaReadUrlDto({required this.url, required this.expiresAt});

  factory MediaReadUrlDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'media read url');

    return MediaReadUrlDto(
      url: readString(json, 'url'),
      expiresAt: readDateTime(json, 'expiresAt'),
    );
  }

  final String url;
  final DateTime expiresAt;

  JsonMap toJson() {
    return <String, Object?>{
      'url': url,
      'expiresAt': writeDateTime(expiresAt),
    };
  }
}
