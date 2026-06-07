import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'share_launcher.dart';
import 'theme.dart';

class ShareMomentSheet extends ConsumerStatefulWidget {
  const ShareMomentSheet({
    required this.pin,
    super.key,
  });

  final PinDto pin;

  @override
  ConsumerState<ShareMomentSheet> createState() => _ShareMomentSheetState();
}

class _ShareMomentSheetState extends ConsumerState<ShareMomentSheet> {
  ShareLinkDto? _link;
  bool _isLoading = true;
  bool _isRevoking = false;
  bool _copied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createLink();
  }

  Future<void> _createLink() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _copied = false;
    });

    try {
      final ShareLinkDto link =
          await ref.read(shareRepositoryProvider).createShareLink(widget.pin.id);
      if (!mounted) return;
      setState(() {
        _link = link;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageForApiError(error);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tạo liên kết chia sẻ.';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyLink() async {
    final ShareLinkDto? link = _link;
    if (link == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: link.url));
    if (!mounted) return;
    setState(() {
      _copied = true;
    });
  }

  Future<void> _shareLink() async {
    final ShareLinkDto? link = _link;
    if (link == null) {
      return;
    }

    await ref.read(shareLauncherProvider).shareText(
          link.url,
          subject: widget.pin.title,
        );
  }

  Future<void> _revokeLink() async {
    final ShareLinkDto? link = _link;
    if (link == null || _isRevoking) {
      return;
    }

    setState(() {
      _isRevoking = true;
      _errorMessage = null;
    });

    try {
      await ref.read(shareRepositoryProvider).revokeShareLink(link.id);
      if (!mounted) return;
      setState(() {
        _link = ShareLinkDto(
          id: link.id,
          pinId: link.pinId,
          token: link.token,
          url: link.url,
          revoked: true,
          createdAt: link.createdAt,
          expiresAt: link.expiresAt,
        );
        _isRevoking = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageForApiError(error);
        _isRevoking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể thu hồi liên kết.';
        _isRevoking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShareLinkDto? link = _link;
    final bool revoked = link?.revoked ?? false;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chia sẻ một khoảnh khắc',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Icon(
              revoked ? Icons.block : Icons.send_outlined,
              size: 48,
              color: revoked ? MemoTheme.danger : MemoTheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chỉ kỷ niệm này, gồm ghi chú, media và vị trí, sẽ được chia sẻ qua liên kết.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                key: Key('share_moment_loading'),
                child: CircularProgressIndicator(),
              )
            else if (_errorMessage != null)
              _ErrorState(
                message: _errorMessage!,
                onRetry: _createLink,
              )
            else if (revoked)
              const _RevokedState()
            else if (link != null)
              _ActiveShareLink(
                link: link,
                copied: _copied,
                isRevoking: _isRevoking,
                onCopy: _copyLink,
                onShare: _shareLink,
                onRevoke: _revokeLink,
              ),
          ],
        ),
      ),
    );
  }

  String _messageForApiError(ApiException error) {
    return switch (error.apiError.error) {
      'forbidden' => 'Bạn không có quyền chia sẻ kỷ niệm này.',
      'link_revoked' => 'Liên kết đã thu hồi.',
      'network_error' => 'Không thể kết nối. Vui lòng thử lại.',
      _ => error.apiError.message,
    };
  }
}

class _ActiveShareLink extends StatelessWidget {
  const _ActiveShareLink({
    required this.link,
    required this.copied,
    required this.isRevoking,
    required this.onCopy,
    required this.onShare,
    required this.onRevoke,
  });

  final ShareLinkDto link;
  final bool copied;
  final bool isRevoking;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('share_moment_link'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.link, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  link.url,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                key: const Key('share_moment_copy'),
                onPressed: onCopy,
                child: Text(copied ? 'Đã sao chép' : 'Sao chép'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('share_moment_copy_button'),
                onPressed: onCopy,
                icon: const Icon(Icons.copy),
                label: const Text('Sao chép liên kết'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('share_moment_share'),
                onPressed: onShare,
                icon: const Icon(Icons.ios_share),
                label: const Text('Chia sẻ'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.public, color: MemoTheme.primary),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đang chia sẻ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Bất kỳ ai có liên kết đều có thể xem.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Switch(
              value: true,
              onChanged: isRevoking ? null : (_) => onRevoke(),
              activeThumbColor: MemoTheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          key: const Key('share_moment_revoke'),
          onPressed: isRevoking ? null : onRevoke,
          icon: const Icon(Icons.block, color: MemoTheme.danger),
          label: Text(
            isRevoking ? 'Đang thu hồi...' : 'Thu hồi liên kết',
            style: const TextStyle(color: MemoTheme.danger),
          ),
        ),
      ],
    );
  }
}

class _RevokedState extends StatelessWidget {
  const _RevokedState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: Key('share_moment_revoked'),
      children: [
        Text(
          'Liên kết đã thu hồi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Kỷ niệm này không còn khả dụng qua liên kết công khai.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('share_moment_error'),
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: MemoTheme.danger),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Thử lại'),
        ),
      ],
    );
  }
}
