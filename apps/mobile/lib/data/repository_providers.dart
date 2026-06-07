import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import '../auth/token_storage_prefs.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'db/app_database.dart';
import 'db/daos.dart';
import 'mock/fake_auth_repository.dart';
import 'mock/fake_map_repository.dart';
import 'mock/fake_media_repository.dart';
import 'mock/fake_pin_repository.dart';
import 'mock/fake_share_repository.dart';
import 'mock/fake_timeline_repository.dart';
import 'mock/mock_data.dart';
import 'repositories/repositories.dart';

final useMockRepositoriesProvider = Provider<bool>((ref) {
  return const bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);
});

final useRealAuthProvider = Provider<bool>((ref) {
  return const bool.fromEnvironment('USE_REAL_AUTH', defaultValue: true);
});

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return const ApiConfig();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStoragePrefs();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(apiConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final mockBackendStateProvider = Provider<MockBackendState>((ref) {
  return MockBackendState.seeded();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase database = AppDatabase();
  ref.onDispose(() {
    unawaited(database.close());
  });

  return database;
});

final localPinsDaoProvider = Provider<LocalPinsDao>((ref) {
  return LocalPinsDao(ref.watch(appDatabaseProvider));
});

final uploadQueueDaoProvider = Provider<UploadQueueDao>((ref) {
  return UploadQueueDao(ref.watch(appDatabaseProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(useRealAuthProvider) &&
      ref.watch(useMockRepositoriesProvider)) {
    return FakeAuthRepository(ref.watch(tokenStorageProvider));
  }

  return ApiAuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return FakeMapRepository(ref.watch(mockBackendStateProvider));
  }

  return ApiMapRepository(ref.watch(apiClientProvider));
});

final pinRepositoryProvider = Provider<PinRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return FakePinRepository(ref.watch(mockBackendStateProvider));
  }

  return ApiPinRepository(ref.watch(apiClientProvider));
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return FakeMediaRepository(ref.watch(mockBackendStateProvider));
  }

  return ApiMediaRepository(ref.watch(apiClientProvider));
});

final objectUploadClientProvider = Provider<ObjectUploadClient>((ref) {
  return DioObjectUploadClient();
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return FakeTimelineRepository(ref.watch(mockBackendStateProvider));
  }

  return ApiTimelineRepository(ref.watch(apiClientProvider));
});

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  if (ref.watch(useMockRepositoriesProvider)) {
    return FakeShareRepository(ref.watch(mockBackendStateProvider));
  }

  return ApiShareRepository(ref.watch(apiClientProvider));
});
