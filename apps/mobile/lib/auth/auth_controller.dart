import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repository_providers.dart';
import 'oauth_launcher.dart';
import 'oauth_redirects.dart';
import 'session.dart';

enum AuthStatus {
  bootstrapping,
  unauthenticated,
  authenticating,
  authenticated,
}

class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
  });

  const AuthState.bootstrapping()
      : status = AuthStatus.bootstrapping,
        session = null,
        errorMessage = null;

  const AuthState.unauthenticated({this.errorMessage})
      : status = AuthStatus.unauthenticated,
        session = null;

  const AuthState.authenticating()
      : status = AuthStatus.authenticating,
        session = null,
        errorMessage = null;

  const AuthState.authenticated(this.session)
      : status = AuthStatus.authenticated,
        errorMessage = null;

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  late AuthRepository _authRepository;
  late OAuthLauncher _oauthLauncher;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _oauthLauncher = ref.watch(oauthLauncherProvider);
    if (ref.watch(authAutoBootstrapProvider)) {
      unawaited(bootstrap());
    }

    return const AuthState.bootstrapping();
  }

  Future<void> bootstrap() async {
    state = const AuthState.bootstrapping();

    try {
      final AuthSession? session = await _authRepository.getSavedSession();
      if (session == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      if (!session.isExpired()) {
        state = AuthState.authenticated(session);
        return;
      }

      final SessionDto refreshed = await _authRepository.refreshSession();
      state = AuthState.authenticated(AuthSession.fromDto(refreshed));
    } catch (_) {
      await _authRepository.clearSession();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> startOAuth(OAuthProviderType provider) async {
    state = const AuthState.authenticating();

    try {
      final String redirectUri = redirectUriFor(provider);
      final OAuthStartResponseDto response = await _authRepository.startOAuth(
        provider: provider,
        redirectUri: redirectUri,
      );
      final Uri authorizationUri = Uri.parse(response.authorizationUrl);

      if (_isMemoOAuthRedirect(authorizationUri)) {
        await handleOAuthRedirect(authorizationUri);
        return;
      }

      await _oauthLauncher.launch(authorizationUri);
    } catch (error) {
      state = AuthState.unauthenticated(
        errorMessage: _messageForSignInError(error),
      );
    }
  }

  Future<void> handleOAuthRedirect(Uri uri) async {
    if (!_isMemoOAuthRedirect(uri)) {
      return;
    }

    final OAuthProviderType provider;
    try {
      provider = _providerFromRedirect(uri);
    } on FormatException {
      state = const AuthState.unauthenticated(
        errorMessage: 'Unsupported sign in provider.',
      );
      return;
    }

    final String? oauthError = uri.queryParameters['error'];
    if (oauthError != null && oauthError.isNotEmpty) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Sign in was cancelled or failed.',
      );
      return;
    }

    final String? code = uri.queryParameters['code'];
    final String? oauthState = uri.queryParameters['state'];
    if (code == null ||
        code.isEmpty ||
        oauthState == null ||
        oauthState.isEmpty) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Sign in response was incomplete.',
      );
      return;
    }

    state = const AuthState.authenticating();

    try {
      final SessionDto session = await _authRepository.completeOAuth(
        provider: provider,
        code: code,
        state: oauthState,
        redirectUri: redirectUriFor(provider),
      );
      state = AuthState.authenticated(AuthSession.fromDto(session));
    } catch (error) {
      state = AuthState.unauthenticated(
        errorMessage: _messageForSignInError(error),
      );
    }
  }

  Future<void> logout() async {
    state = const AuthState.bootstrapping();

    try {
      await _authRepository.logout();
    } finally {
      state = const AuthState.unauthenticated();
    }
  }

  String _messageForSignInError(Object error) {
    if (error is ApiException) {
      if (error.apiError.error == 'network_error') {
        return 'Cannot reach Memo API. Check API_BASE_URL and backend status.';
      }

      return error.apiError.message;
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Sign in failed. Please try again.';
  }

  static String redirectUriFor(OAuthProviderType provider) {
    if (kIsWeb) {
      const String callbackBaseUrl = String.fromEnvironment(
        'OAUTH_CALLBACK_BASE_URL',
        defaultValue: 'http://localhost:3000/api/v1',
      );

      return '$callbackBaseUrl/auth/oauth/${provider.pathSegment}/callback';
    }

    return 'memo://oauth/${provider.pathSegment}';
  }

  bool _isMemoOAuthRedirect(Uri uri) {
    return (uri.scheme == 'memo' && uri.host == 'oauth') ||
        (uri.pathSegments.length == 2 && uri.pathSegments.first == 'oauth');
  }

  OAuthProviderType _providerFromRedirect(Uri uri) {
    if (uri.scheme == 'memo' && uri.host == 'oauth') {
      if (uri.pathSegments.isEmpty) {
        throw const FormatException('Missing OAuth provider');
      }

      return OAuthProviderType.fromPathSegment(uri.pathSegments.first);
    }

    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'oauth') {
      return OAuthProviderType.fromPathSegment(uri.pathSegments.last);
    }

    throw const FormatException('Missing OAuth provider');
  }
}

final authAutoBootstrapProvider = Provider<bool>((ref) {
  return true;
});

final oauthLauncherProvider = Provider<OAuthLauncher>((ref) {
  return const UrlLauncherOAuthLauncher();
});

final oauthRedirectSourceProvider = Provider<OAuthRedirectSource>((ref) {
  return AppLinksOAuthRedirectSource();
});

final oauthRedirectStreamProvider = StreamProvider<Uri>((ref) {
  return ref.watch(oauthRedirectSourceProvider).links;
});

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
