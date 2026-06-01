import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../data/models/models.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'pin_detail_screen.dart';
import 'pin_editor_screen.dart';
import 'timeline_screen.dart';

final _routerRefreshProvider = Provider<Listenable>((ref) {
  final _RouterRefreshNotifier notifier = _RouterRefreshNotifier();
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    notifier.refresh();
  });
  ref.onDispose(notifier.dispose);

  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: ref.watch(_routerRefreshProvider),
    redirect: (context, state) {
      final AuthState authState = ref.read<AuthState>(authControllerProvider);
      final String path = state.uri.path;
      final bool isPublicShare = path.startsWith('/p/');
      final bool isLogin = path == '/login';
      final bool isBootstrap = path == '/bootstrap';
      final bool isOAuthCallback = path.startsWith('/oauth/');

      if (isPublicShare) {
        return null;
      }

      if (isOAuthCallback) {
        if (authState.isAuthenticated) {
          return '/';
        }
        if (authState.status == AuthStatus.unauthenticated &&
            authState.errorMessage != null) {
          return '/login';
        }

        return null;
      }

      if (authState.status == AuthStatus.bootstrapping) {
        return isBootstrap ? null : '/bootstrap';
      }

      if (!authState.isAuthenticated) {
        return isLogin ? null : '/login';
      }

      if (isLogin || isBootstrap) {
        return '/';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/bootstrap',
        builder: (context, state) => const BootstrapScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/oauth/:provider',
        builder: (context, state) => OAuthCallbackScreen(uri: state.uri),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => MapScreen(
          startPicking: state.uri.queryParameters['pick'] == '1',
          editPinId: state.uri.queryParameters['editPinId'],
        ),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: '/pins/new',
        builder: (context, state) {
          return PinEditorScreen(
            initialCoordinates: _coordinatesFromQuery(state.uri),
          );
        },
      ),
      GoRoute(
        path: '/pins/:pinId/edit',
        builder: (context, state) {
          final String pinId = state.pathParameters['pinId'] ?? '';
          return PinEditorScreen(
            pinId: pinId,
            initialCoordinates: _coordinatesFromQuery(state.uri),
          );
        },
      ),
      GoRoute(
        path: '/pins/:pinId',
        builder: (context, state) {
          final String pinId = state.pathParameters['pinId'] ?? '';
          return PinDetailScreen(pinId: pinId);
        },
      ),
      GoRoute(
        path: '/p/:token',
        builder: (context, state) {
          final String token = state.pathParameters['token'] ?? '';
          return PublicSharedPinScreen(token: token);
        },
      ),
    ],
  );
});

class BootstrapScreen extends StatelessWidget {
  const BootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

Coordinates? _coordinatesFromQuery(Uri uri) {
  final double? lat = double.tryParse(uri.queryParameters['lat'] ?? '');
  final double? lng = double.tryParse(uri.queryParameters['lng'] ?? '');
  if (lat == null || lng == null) {
    return null;
  }

  return Coordinates(lat: lat, lng: lng);
}

class PublicSharedPinScreen extends StatelessWidget {
  const PublicSharedPinScreen({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Memory')),
      body: Center(child: Text(token)),
    );
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
