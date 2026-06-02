import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../data/models/models.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authControllerProvider);
    final bool isLoading = authState.status == AuthStatus.authenticating;

    return Scaffold(
      appBar: AppBar(title: const Text('Memory Map')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign in to Memo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Keep your private memory map available across devices.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('login_google_button'),
                    onPressed: isLoading
                        ? null
                        : () => ref
                            .read<AuthController>(
                              authControllerProvider.notifier,
                            )
                            .startOAuth(OAuthProviderType.google),
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('login_apple_button'),
                    onPressed: isLoading
                        ? null
                        : () => ref
                            .read<AuthController>(
                              authControllerProvider.notifier,
                            )
                            .startOAuth(OAuthProviderType.apple),
                    icon: const Icon(Icons.apple),
                    label: const Text('Continue with Apple'),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (authState.errorMessage case final String error) ...[
                    const SizedBox(height: 24),
                    Text(
                      error,
                      key: const Key('auth_error_message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
