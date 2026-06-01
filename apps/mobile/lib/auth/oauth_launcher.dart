import 'package:url_launcher/url_launcher.dart';

abstract interface class OAuthLauncher {
  Future<void> launch(Uri authorizationUri);
}

class UrlLauncherOAuthLauncher implements OAuthLauncher {
  const UrlLauncherOAuthLauncher();

  @override
  Future<void> launch(Uri authorizationUri) async {
    final bool launched = await launchUrl(
      authorizationUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw StateError('Could not launch OAuth URL');
    }
  }
}
