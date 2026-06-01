import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_map_mobile/auth/auth_controller.dart';
import 'package:memory_map_mobile/auth/oauth_launcher.dart';
import 'package:memory_map_mobile/auth/session.dart';
import 'package:memory_map_mobile/data/models/models.dart';
import 'package:memory_map_mobile/data/repositories/auth_repository.dart';
import 'package:memory_map_mobile/data/repository_providers.dart';

void main() {
  group('AuthController.bootstrap', () {
    test('moves to unauthenticated when no saved session exists', () async {
      final _AuthRepositoryFake repository = _AuthRepositoryFake();
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);
      final AuthController controller = _controller(container);

      await controller.bootstrap();

      expect(
        container.read<AuthState>(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    });

    test('uses valid saved session', () async {
      final _AuthRepositoryFake repository = _AuthRepositoryFake(
        savedSession: _session(
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);
      final AuthController controller = _controller(container);

      await controller.bootstrap();

      expect(
        container.read<AuthState>(authControllerProvider).status,
        AuthStatus.authenticated,
      );
      expect(
        container.read<AuthState>(authControllerProvider).session?.accessToken,
        'access',
      );
    });

    test('refreshes expired session', () async {
      final _AuthRepositoryFake repository = _AuthRepositoryFake(
        savedSession: _session(
          expiresAt:
              DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        ),
      );
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);
      final AuthController controller = _controller(container);

      await controller.bootstrap();

      expect(repository.refreshCount, 1);
      expect(
        container.read<AuthState>(authControllerProvider).status,
        AuthStatus.authenticated,
      );
      expect(
        container.read<AuthState>(authControllerProvider).session?.accessToken,
        'fresh_access',
      );
    });

    test('clears storage when refresh fails', () async {
      final _AuthRepositoryFake repository = _AuthRepositoryFake(
        savedSession: _session(
          expiresAt:
              DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        ),
        refreshFails: true,
      );
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);
      final AuthController controller = _controller(container);

      await controller.bootstrap();

      expect(repository.clearCount, 1);
      expect(
        container.read<AuthState>(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    });
  });

  group('AuthController OAuth', () {
    test('starts OAuth with provider redirect URI', () async {
      final _AuthRepositoryFake repository = _AuthRepositoryFake(
        startResponse: const OAuthStartResponseDto(
          authorizationUrl: 'https://google.example/auth',
          state: 'state_1',
        ),
      );
      final _OAuthLauncherFake launcher = _OAuthLauncherFake();
      final ProviderContainer container = _container(repository, launcher);
      addTearDown(container.dispose);
      final AuthController controller = _controller(container);

      await controller.startOAuth(OAuthProviderType.google);

      expect(repository.startedProvider, OAuthProviderType.google);
      expect(repository.startedRedirectUri, 'memo://oauth/google');
      expect(launcher.launchedUri, Uri.parse('https://google.example/auth'));
      expect(
        container.read<AuthState>(authControllerProvider).status,
        AuthStatus.authenticating,
      );
    });

    test('completes OAuth callback and saves authenticated state', () async {
      final _AuthRepositoryFake repository = _AuthRepositoryFake();
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);
      final AuthController controller = _controller(container);

      await controller.handleOAuthRedirect(
        Uri.parse('memo://oauth/google?code=code_1&state=state_1'),
      );

      expect(repository.completedProvider, OAuthProviderType.google);
      expect(repository.completedCode, 'code_1');
      expect(repository.completedState, 'state_1');
      expect(
        container.read<AuthState>(authControllerProvider).status,
        AuthStatus.authenticated,
      );
    });

    test('completes web OAuth callback route', () async {
      final _AuthRepositoryFake repository = _AuthRepositoryFake();
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);
      final AuthController controller = _controller(container);

      await controller.handleOAuthRedirect(
        Uri.parse(
          'http://localhost:5000/oauth/google?code=code_1&state=state_1',
        ),
      );

      expect(repository.completedProvider, OAuthProviderType.google);
      expect(
        container.read<AuthState>(authControllerProvider).status,
        AuthStatus.authenticated,
      );
    });

    test('shows nonblocking error for cancelled OAuth', () async {
      final _AuthRepositoryFake repository = _AuthRepositoryFake();
      final ProviderContainer container = _container(repository);
      addTearDown(container.dispose);
      final AuthController controller = _controller(container);

      await controller.handleOAuthRedirect(
        Uri.parse('memo://oauth/google?error=access_denied'),
      );

      expect(
        container.read<AuthState>(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
      expect(
        container.read<AuthState>(authControllerProvider).errorMessage,
        contains('cancelled'),
      );
    });
  });

  test('logout calls repository and returns to unauthenticated', () async {
    final _AuthRepositoryFake repository = _AuthRepositoryFake();
    final ProviderContainer container = _container(repository);
    addTearDown(container.dispose);
    final AuthController controller = _controller(container);

    await controller.logout();

    expect(repository.logoutCount, 1);
    expect(
      container.read<AuthState>(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
  });
}

ProviderContainer _container(
  _AuthRepositoryFake repository, [
  _OAuthLauncherFake? launcher,
]) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authAutoBootstrapProvider.overrideWithValue(false),
      oauthLauncherProvider.overrideWithValue(launcher ?? _OAuthLauncherFake()),
    ],
  );
}

AuthController _controller(ProviderContainer container) {
  return container.read<AuthController>(authControllerProvider.notifier);
}

AuthSession _session({DateTime? expiresAt}) {
  return AuthSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: expiresAt,
    user: _user,
  );
}

const UserProfileDto _user = UserProfileDto(
  id: 'user_1',
  email: 'user@example.com',
  displayName: 'User One',
);

const SessionDto _freshSession = SessionDto(
  accessToken: 'fresh_access',
  refreshToken: 'fresh_refresh',
  expiresIn: 3600,
  user: _user,
);

class _AuthRepositoryFake implements AuthRepository {
  _AuthRepositoryFake({
    this.savedSession,
    this.refreshFails = false,
    this.startResponse = const OAuthStartResponseDto(
      authorizationUrl: 'memo://oauth/google?code=mock_code&state=mock_state',
      state: 'mock_state',
    ),
  });

  AuthSession? savedSession;
  bool refreshFails;
  OAuthStartResponseDto startResponse;
  int refreshCount = 0;
  int clearCount = 0;
  int logoutCount = 0;
  OAuthProviderType? startedProvider;
  String? startedRedirectUri;
  OAuthProviderType? completedProvider;
  String? completedCode;
  String? completedState;

  @override
  Future<AuthSession?> getSavedSession() async => savedSession;

  @override
  Future<OAuthStartResponseDto> startOAuth({
    required OAuthProviderType provider,
    required String redirectUri,
  }) async {
    startedProvider = provider;
    startedRedirectUri = redirectUri;
    return startResponse;
  }

  @override
  Future<SessionDto> completeOAuth({
    required OAuthProviderType provider,
    required String code,
    required String state,
    required String redirectUri,
  }) async {
    completedProvider = provider;
    completedCode = code;
    completedState = state;
    return _freshSession;
  }

  @override
  Future<SessionDto> refreshSession() async {
    refreshCount += 1;
    if (refreshFails) {
      throw StateError('refresh failed');
    }
    return _freshSession;
  }

  @override
  Future<void> saveSession(SessionDto session) async {}

  @override
  Future<void> clearSession() async {
    clearCount += 1;
    savedSession = null;
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
    savedSession = null;
  }
}

class _OAuthLauncherFake implements OAuthLauncher {
  Uri? launchedUri;

  @override
  Future<void> launch(Uri authorizationUri) async {
    launchedUri = authorizationUri;
  }
}
