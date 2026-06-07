import 'json.dart';

enum PinMediaType {
  image,
  text,
  audio;

  static PinMediaType fromWire(String value) {
    return switch (value) {
      'image' => PinMediaType.image,
      'text' => PinMediaType.text,
      'audio' => PinMediaType.audio,
      _ => throw FormatException('Unknown media type: $value'),
    };
  }

  String toWire() {
    return switch (this) {
      PinMediaType.image => 'image',
      PinMediaType.text => 'text',
      PinMediaType.audio => 'audio',
    };
  }
}

class PinMediaDto {
  const PinMediaDto({
    required this.id,
    required this.pinId,
    required this.mediaType,
    required this.objectKey,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    this.url,
  });

  factory PinMediaDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'pin media');

    return PinMediaDto(
      id: readString(json, 'id'),
      pinId: readString(json, 'pinId'),
      mediaType: PinMediaType.fromWire(readString(json, 'mediaType')),
      objectKey: readString(json, 'objectKey'),
      mimeType: readString(json, 'mimeType'),
      sizeBytes: readInt(json, 'sizeBytes'),
      createdAt: readDateTime(json, 'createdAt'),
      url: readOptionalString(json, 'url'),
    );
  }

  final String id;
  final String pinId;
  final PinMediaType mediaType;
  final String objectKey;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;
  final String? url;

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'pinId': pinId,
      'mediaType': mediaType.toWire(),
      'objectKey': objectKey,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'createdAt': writeDateTime(createdAt),
      'url': url,
    };
  }
}

class PublicPinMediaDto {
  const PublicPinMediaDto({
    required this.id,
    required this.pinId,
    required this.mediaType,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    required this.url,
  });

  factory PublicPinMediaDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'public pin media');

    return PublicPinMediaDto(
      id: readString(json, 'id'),
      pinId: readString(json, 'pinId'),
      mediaType: PinMediaType.fromWire(readString(json, 'mediaType')),
      mimeType: readString(json, 'mimeType'),
      sizeBytes: readInt(json, 'sizeBytes'),
      createdAt: readDateTime(json, 'createdAt'),
      url: readString(json, 'url'),
    );
  }

  final String id;
  final String pinId;
  final PinMediaType mediaType;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;
  final String url;

  JsonMap toJson() {
    return <String, Object?>{
      'id': id,
      'pinId': pinId,
      'mediaType': mediaType.toWire(),
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'createdAt': writeDateTime(createdAt),
      'url': url,
    };
  }
}

class PresignRequestDto {
  const PresignRequestDto({
    required this.mediaType,
    required this.mimeType,
    required this.sizeBytes,
    required this.fileName,
  });

  final PinMediaType mediaType;
  final String mimeType;
  final int sizeBytes;
  final String fileName;

  JsonMap toJson() {
    return <String, Object?>{
      'mediaType': mediaType.toWire(),
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'fileName': fileName,
    };
  }
}

class PresignResponseDto {
  const PresignResponseDto({
    required this.uploadUrl,
    required this.objectKey,
    required this.expiresAt,
  });

  factory PresignResponseDto.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'presign response');

    return PresignResponseDto(
      uploadUrl: readString(json, 'uploadUrl'),
      objectKey: readString(json, 'objectKey'),
      expiresAt: readDateTime(json, 'expiresAt'),
    );
  }

  final String uploadUrl;
  final String objectKey;
  final DateTime expiresAt;

  JsonMap toJson() {
    return <String, Object?>{
      'uploadUrl': uploadUrl,
      'objectKey': objectKey,
      'expiresAt': writeDateTime(expiresAt),
    };
  }
}

class RegisterMediaRequestDto {
  const RegisterMediaRequestDto({
    required this.mediaType,
    required this.objectKey,
    required this.mimeType,
    required this.sizeBytes,
  });

  final PinMediaType mediaType;
  final String objectKey;
  final String mimeType;
  final int sizeBytes;

  JsonMap toJson() {
    return <String, Object?>{
      'mediaType': mediaType.toWire(),
      'objectKey': objectKey,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
    };
  }
}
