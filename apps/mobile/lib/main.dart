import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'auth/auth_controller.dart';

void main() {
  runApp(const ProviderScope(child: MemoryMapApp()));
}

class MemoryMapApp extends ConsumerWidget {
  const MemoryMapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Uri>>(oauthRedirectStreamProvider, (previous, next) {
      next.whenData((Uri uri) {
        ref
            .read<AuthController>(authControllerProvider.notifier)
            .handleOAuthRedirect(uri);
      });
    });

    final AuthState authState = ref.watch(authControllerProvider);

    return MaterialApp.router(
      key: ValueKey<AuthStatus>(authState.status),
      title: 'Memory Map',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
