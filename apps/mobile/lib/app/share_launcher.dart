import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

abstract interface class ShareLauncher {
  Future<void> shareText(String text, {String? subject});
}

class PlatformShareLauncher implements ShareLauncher {
  const PlatformShareLauncher();

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }
}

final shareLauncherProvider = Provider<ShareLauncher>((ref) {
  return const PlatformShareLauncher();
});
