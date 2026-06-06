import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_map_mobile/data/repositories/auth_repository.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

void main() {
  test('uses API auth by default', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read<AuthRepository>(authRepositoryProvider),
      isA<ApiAuthRepository>(),
    );
  });

  test('uses fake auth while mock repositories are explicitly enabled', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        useMockRepositoriesProvider.overrideWithValue(true),
        useRealAuthProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read<AuthRepository>(authRepositoryProvider),
      isNot(isA<ApiAuthRepository>()),
    );
  });

  test('uses API auth when real auth is enabled', () {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        useRealAuthProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read<AuthRepository>(authRepositoryProvider),
      isA<ApiAuthRepository>(),
    );
  });
}
