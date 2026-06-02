import 'dart:io';

import 'package:dio/dio.dart';

import '../models/models.dart';

abstract interface class ObjectUploadClient {
  Future<void> uploadFile({
    required String uploadUrl,
    required String localPath,
    required String mimeType,
    required int sizeBytes,
  });
}

class DioObjectUploadClient implements ObjectUploadClient {
  DioObjectUploadClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Future<void> uploadFile({
    required String uploadUrl,
    required String localPath,
    required String mimeType,
    required int sizeBytes,
  }) async {
    try {
      await _dio.put<Object?>(
        uploadUrl,
        data: File(localPath).openRead(),
        options: Options(
          headers: <String, Object?>{
            Headers.contentTypeHeader: mimeType,
            Headers.contentLengthHeader: sizeBytes,
          },
          responseType: ResponseType.plain,
        ),
      );
    } on DioException catch (error) {
      throw ApiException(
        apiError: ApiError.fallback(
          error: error.response == null ? 'network_error' : 'unexpected_error',
          message: error.message ?? 'Upload failed',
        ),
        statusCode: error.response?.statusCode,
      );
    }
  }
}
