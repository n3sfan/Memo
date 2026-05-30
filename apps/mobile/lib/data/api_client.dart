import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import 'models/api_envelope.dart';
import 'models/json.dart';

class ApiClient {
  ApiClient({
    Dio? dio,
    TokenStorage? tokenStorage,
    ApiConfig config = const ApiConfig(),
  })  : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.baseUrl,
                connectTimeout: config.connectTimeout,
                receiveTimeout: config.receiveTimeout,
                responseType: ResponseType.json,
              ),
            ),
        _config = config {
    final TokenStorage? storage = tokenStorage;
    if (storage != null) {
      this.dio.interceptors.add(AuthInterceptor(storage));
    }
    this.dio.interceptors.add(ApiErrorInterceptor());
  }

  final Dio dio;
  final ApiConfig _config;

  Future<T> get<T extends Object?>(
    String path, {
    Map<String, Object?>? queryParameters,
    required T Function(Object? data) decoder,
  }) {
    return _request<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      decoder: decoder,
    );
  }

  Future<T> post<T extends Object?>(
    String path, {
    Object? body,
    Map<String, Object?>? queryParameters,
    required T Function(Object? data) decoder,
  }) {
    return _request<T>(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
      decoder: decoder,
    );
  }

  Future<T> patch<T extends Object?>(
    String path, {
    Object? body,
    Map<String, Object?>? queryParameters,
    required T Function(Object? data) decoder,
  }) {
    return _request<T>(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
      decoder: decoder,
    );
  }

  Future<T> delete<T extends Object?>(
    String path, {
    Object? body,
    Map<String, Object?>? queryParameters,
    required T Function(Object? data) decoder,
  }) {
    return _request<T>(
      'DELETE',
      path,
      body: body,
      queryParameters: queryParameters,
      decoder: decoder,
    );
  }

  Future<T> _request<T extends Object?>(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? queryParameters,
    required T Function(Object? data) decoder,
  }) async {
    var attempt = 0;

    while (true) {
      try {
        final Response<Object?> response = await dio.request<Object?>(
          path,
          data: body,
          queryParameters: queryParameters,
          options: Options(method: method),
        );

        return _decodeEnvelope<T>(response.data, decoder);
      } on DioException catch (error) {
        if (_shouldRetry(method, attempt, error)) {
          attempt += 1;
          continue;
        }

        throw _toApiException(error);
      }
    }
  }

  T _decodeEnvelope<T extends Object?>(
    Object? payload,
    T Function(Object? data) decoder,
  ) {
    final JsonMap json = asJsonMap(payload, name: 'api response');
    final ApiEnvelope<T> envelope = ApiEnvelope<T>.fromJson(json, decoder);

    return envelope.data;
  }

  bool _shouldRetry(String method, int attempt, DioException error) {
    if (method != 'GET' || attempt >= _config.getRetryCount) {
      return false;
    }

    final int? statusCode = error.response?.statusCode;
    return statusCode == null || statusCode >= 500;
  }

  ApiException _toApiException(DioException error) {
    final Object? apiError = error.requestOptions.extra['apiError'];
    if (apiError is ApiError) {
      return ApiException(
        apiError: apiError,
        statusCode: error.response?.statusCode,
      );
    }

    final Object? payload = error.response?.data;
    if (payload != null) {
      try {
        return ApiException(
          apiError: ApiError.fromJson(payload),
          statusCode: error.response?.statusCode,
        );
      } on FormatException {
        // Fall through to the generic network/API error below.
      }
    }

    return ApiException(
      apiError: ApiError.fallback(
        error: error.response == null ? 'network_error' : 'unexpected_error',
        message: error.message ?? 'Request failed',
      ),
      statusCode: error.response?.statusCode,
    );
  }
}
