import 'package:dio/dio.dart';

import 'models/api_envelope.dart';

class ApiErrorInterceptor extends Interceptor {
  ApiErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final Object? payload = err.response?.data;
    if (payload != null) {
      try {
        err.requestOptions.extra['apiError'] = ApiError.fromJson(payload);
      } on FormatException {
        err.requestOptions.extra['apiError'] = ApiError.fallback(
          error: 'unexpected_error',
          message: err.response?.statusMessage ?? 'Unexpected API error',
        );
      }
    }

    handler.next(err);
  }
}
