import 'json.dart';

class ApiEnvelope<T extends Object?> {
  const ApiEnvelope({
    required this.data,
    required this.requestId,
  });

  factory ApiEnvelope.fromJson(
    JsonMap json,
    T Function(Object? data) decodeData,
  ) {
    return ApiEnvelope<T>(
      data: decodeData(json['data']),
      requestId: readOptionalString(json, 'requestId') ?? '',
    );
  }

  final T data;
  final String requestId;
}

class ApiError {
  const ApiError({
    required this.error,
    required this.message,
    required this.details,
    required this.requestId,
  });

  factory ApiError.fromJson(Object? value) {
    final JsonMap json = asJsonMap(value, name: 'error response');
    final Object? detailsValue = json['details'];

    return ApiError(
      error: readString(json, 'error'),
      message: readString(json, 'message'),
      details: detailsValue == null
          ? const <String, Object?>{}
          : asJsonMap(detailsValue, name: 'details'),
      requestId: readOptionalString(json, 'requestId') ?? '',
    );
  }

  factory ApiError.fallback({
    required String message,
    String error = 'network_error',
    String requestId = '',
  }) {
    return ApiError(
      error: error,
      message: message,
      details: const <String, Object?>{},
      requestId: requestId,
    );
  }

  final String error;
  final String message;
  final JsonMap details;
  final String requestId;

  JsonMap toJson() {
    return <String, Object?>{
      'error': error,
      'message': message,
      'details': details,
      'requestId': requestId,
    };
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.apiError,
    this.statusCode,
  });

  final ApiError apiError;
  final int? statusCode;

  @override
  String toString() {
    final int? code = statusCode;
    if (code == null) {
      return '${apiError.error}: ${apiError.message}';
    }

    return '$code ${apiError.error}: ${apiError.message}';
  }
}
