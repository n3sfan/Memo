import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../data/models/models.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToLogin() {
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildSplash(),
          _buildOnboarding(),
          _buildPermissions(),
          _buildSignIn(ref),
        ],
      ),
    );
  }

  Widget _buildSplash() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 2),
          const Icon(Icons.location_on, size: 48, color: Color(0xFFB5935A)),
          const SizedBox(height: 16),
          Text(
            'Memo',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B5B43),
                ),
          ),
          const SizedBox(height: 8),
          const Text('Private memory map', style: TextStyle(fontSize: 18)),
          const Spacer(flex: 3),
          // Illustration placeholder
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.photo, size: 64, color: Colors.grey),
            ),
          ),
          const Spacer(flex: 2),
          const Icon(Icons.lock_outline, color: Color(0xFFB5935A)),
          const SizedBox(height: 8),
          const Text('No ads. No tracking.'),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton(
              key: const Key('login_start_button'),
              onPressed: _nextPage,
              child: const Text('Bắt đầu'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOnboarding() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Ghim nơi\nkỷ niệm bắt đầu',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B5B43),
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Memo giúp bạn lưu những khoảnh\nkhắc đáng nhớ lên bản đồ riêng tư\ncủa bạn.',
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            // Image placeholder
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(Icons.landscape, size: 64, color: Colors.grey),
              ),
            ),
            const Spacer(),
            FilledButton(
              key: const Key('login_onboarding_next_button'),
              onPressed: _nextPage,
              child: const Text('Tiếp tục'),
            ),
            TextButton(
              key: const Key('login_skip_button'),
              onPressed: _skipToLogin,
              child:
                  const Text('Bỏ qua', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Center(
              child: Icon(Icons.explore, size: 64, color: Color(0xFFB5935A)),
            ),
            const SizedBox(height: 24),
            Text(
              'Chuẩn bị\nlưu kỷ niệm',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B5B43),
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cấp quyền để Memo hoạt động tốt hơn\nvà bảo mật tuyệt đối.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 48),
            ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFF3B5B43)),
              title: const Text(
                'Vị trí',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Ghim kỷ niệm lên bản đồ của bạn'),
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeThumbColor: const Color(0xFF3B5B43),
              ),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mic, color: Color(0xFF3B5B43)),
              title: const Text(
                'Microphone',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Ghi âm kỷ niệm của bạn'),
              trailing: Switch(value: false, onChanged: (v) {}),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: Color(0xFFB5935A),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Quyền riêng tư là ưu tiên hàng đầu.\nMemo không chia sẻ dữ liệu của bạn.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('login_permissions_allow_button'),
              onPressed: _nextPage,
              child: const Text('Cho phép'),
            ),
            TextButton(
              key: const Key('login_permissions_later_button'),
              onPressed: _nextPage,
              child:
                  const Text('Để sau', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignIn(WidgetRef ref) {
    final AuthState authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.status == AuthStatus.authenticating;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 48),
            const Center(
              child:
                  Icon(Icons.location_on, size: 64, color: Color(0xFFB5935A)),
            ),
            const SizedBox(height: 24),
            Text(
              'Vào bản đồ\ncủa bạn',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B5B43),
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đăng nhập để tiếp tục hành trình\nlưu giữ kỷ niệm.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            if (authState.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD67D6F)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFD67D6F)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(color: Color(0xFFD67D6F)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('login_apple_button'),
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read<AuthController>(authControllerProvider.notifier)
                      .startOAuth(OAuthProviderType.apple),
              icon: const Icon(Icons.apple),
              label: const Text('Tiếp tục với Apple'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                side: BorderSide.none,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('login_google_button'),
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read<AuthController>(authControllerProvider.notifier)
                      .startOAuth(OAuthProviderType.google),
              icon: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                height: 24,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.g_mobiledata),
              ),
              label: const Text('Tiếp tục với Google'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black12),
              ),
            ),
            if (isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 16, color: Color(0xFFB5935A)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Memo đặt quyền riêng tư lên hàng đầu.\nKhông bán. Không theo dõi. Mã hóa đầu cuối.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class OAuthCallbackScreen extends ConsumerStatefulWidget {
  const OAuthCallbackScreen({required this.uri, super.key});

  final Uri uri;

  @override
  ConsumerState<OAuthCallbackScreen> createState() =>
      _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read<AuthController>(authControllerProvider.notifier)
          .handleOAuthRedirect(widget.uri);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
