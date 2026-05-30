import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_map_mobile/auth/session.dart';
import 'package:memory_map_mobile/auth/token_storage.dart';
import 'package:memory_map_mobile/data/api_client.dart';
import 'package:memory_map_mobile/data/models/models.dart';

void main() {
  test('attaches bearer token when token exists', () async {
    final InMemoryTokenStorage tokenStorage = InMemoryTokenStorage();
    await tokenStorage.saveSession(
      const AuthSession(
        accessToken: 'access_test',
        refreshToken: 'refresh_test',
      ),
    );

    final _CapturingAdapter adapter = _CapturingAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://memo.test'));
    dio.httpClientAdapter = adapter;

    final ApiClient client = ApiClient(
      dio: dio,
      tokenStorage: tokenStorage,
    );

    await client.get<JsonMap>(
      '/ping',
      decoder: (Object? data) => asJsonMap(data, name: 'ping'),
    );

    expect(adapter.lastHeaders['Authorization'], 'Bearer access_test');
  });

  test('does not attach bearer token when storage is empty', () async {
    final _CapturingAdapter adapter = _CapturingAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://memo.test'));
    dio.httpClientAdapter = adapter;

    final ApiClient client = ApiClient(
      dio: dio,
      tokenStorage: InMemoryTokenStorage(),
    );

    await client.get<JsonMap>(
      '/ping',
      decoder: (Object? data) => asJsonMap(data, name: 'ping'),
    );

    expect(adapter.lastHeaders.containsKey('Authorization'), isFalse);
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  JsonMap lastHeaders = const <String, Object?>{};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastHeaders = Map<String, Object?>.from(options.headers);

    return ResponseBody.fromString(
      '{"data":{"ok":true},"requestId":"req_test"}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}
