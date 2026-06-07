import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../data/models/models.dart';
import 'duo_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'pin_detail_screen.dart';
import 'pin_editor_screen.dart';
import 'settings_screen.dart';
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
          focusCoordinates: coordinatesFromQuery(state.uri),
        ),
      ),
      GoRoute(
        path: '/timeline',
        builder: (context, state) => const TimelineScreen(),
      ),
      GoRoute(
        path: '/duo',
        builder: (context, state) => const DuoScreen(),
      ),
      GoRoute(
        path: '/inv/:code',
        builder: (context, state) {
          final String code = state.pathParameters['code'] ?? '';

          return DuoScreen(initialInvitationCode: code);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/pins/new',
        builder: (context, state) {
          return PinEditorScreen(
            initialCoordinates: coordinatesFromQuery(state.uri),
          );
        },
      ),
      GoRoute(
        path: '/pins/:pinId/edit',
        builder: (context, state) {
          final String pinId = state.pathParameters['pinId'] ?? '';
          return PinEditorScreen(
            pinId: pinId,
            initialCoordinates: coordinatesFromQuery(state.uri),
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

Coordinates? coordinatesFromQuery(Uri uri) {
  final double? lat = double.tryParse(uri.queryParameters['lat'] ?? '');
  final double? lng = double.tryParse(uri.queryParameters['lng'] ?? '');
  if (lat == null ||
      lng == null ||
      !lat.isFinite ||
      !lng.isFinite ||
      lat < -90 ||
      lat > 90 ||
      lng < -180 ||
      lng > 180) {
    return null;
  }

  return Coordinates(lat: lat, lng: lng);
}

class PublicSharedPinScreen extends StatefulWidget {
  const PublicSharedPinScreen({required this.token, super.key});

  final String token;

  @override
  State<PublicSharedPinScreen> createState() => _PublicSharedPinScreenState();
}

class _PublicSharedPinScreenState extends State<PublicSharedPinScreen> {
  // Mock state for design demonstration
  bool isRevoked = false;

  @override
  Widget build(BuildContext context) {
    if (isRevoked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Khoảnh khắc được chia sẻ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 14),
                      SizedBox(width: 6),
                      Text('Chỉ xem ghim này', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: Colors.black12,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Icon(Icons.cancel, size: 48, color: Color(0xFFD67D6F)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Liên kết đã thu hồi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Kỷ niệm này không còn khả dụng.\nLiên kết chia sẻ có thể đã hết hạn\nhoặc đã bị thu hồi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Về trang đăng nhập'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Khoảnh khắc được chia sẻ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 14),
                    SizedBox(width: 6),
                    Text('Chỉ xem ghim này', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 160,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFEAF1EC),
                    Color(0xFFD9E8DD),
                  ],
                ),
              ),
              child: const Center(
                child:
                    Icon(Icons.location_on, size: 48, color: Color(0xFFB5935A)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFE8E0),
                    Color(0xFFFFCBB8),
                    Color(0xFFFFD27B),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.photo_outlined,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quán nhỏ Đà Lạt',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.black54,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '12 tháng 5, 2025 · 19:15',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Buổi tối se lạnh, ngồi đây nghe nhạc cũ,\nuống ly cacao nóng. Bình yên.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Vị trí đã lưu trên bản đồ'),
                        Spacer(),
                        Icon(Icons.copy, size: 16, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.map),
                    label: const Text('Mở bằng Memo'),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Bạn sẽ được hướng dẫn cài đặt ứng dụng.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
