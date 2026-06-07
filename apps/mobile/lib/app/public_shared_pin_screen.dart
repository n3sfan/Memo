import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'theme.dart';

class PublicSharedPinScreen extends ConsumerStatefulWidget {
  const PublicSharedPinScreen({
    required this.token,
    super.key,
  });

  final String token;

  @override
  ConsumerState<PublicSharedPinScreen> createState() =>
      _PublicSharedPinScreenState();
}

class _PublicSharedPinScreenState extends ConsumerState<PublicSharedPinScreen> {
  PublicSharedPinDto? _shared;
  bool _isLoading = true;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    _loadSharedPin();
  }

  Future<void> _loadSharedPin() async {
    setState(() {
      _isLoading = true;
      _errorCode = null;
    });

    try {
      final PublicSharedPinDto shared =
          await ref.read(shareRepositoryProvider).resolvePublicPin(widget.token);
      if (!mounted) return;
      setState(() {
        _shared = shared;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorCode = error.apiError.error;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorCode = 'network_error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          key: Key('public_share_loading'),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final String? errorCode = _errorCode;
    if (errorCode != null || _shared == null) {
      return _PublicShareErrorScreen(
        revoked: errorCode == 'link_revoked',
      );
    }

    final PublicPinDto pin = _shared!.pin;

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
            const SizedBox(height: 8),
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
                color: const Color(0xFFEAF1EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: MemoTheme.accent,
                ),
              ),
            ),
            if (pin.media.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(pin.media.first.url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pin.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _dateLabel(pin.memoryDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  if (pin.note != null && pin.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(pin.note!, style: const TextStyle(height: 1.5)),
                  ],
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
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${pin.lat.toStringAsFixed(4)}° N, '
                            '${pin.lng.toStringAsFixed(4)}° E',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.map),
                    label: const Text('Mở bằng Memo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime? date) {
    if (date == null) {
      return 'Không rõ';
    }

    return '${date.day} tháng ${date.month}, ${date.year}';
  }
}

class _PublicShareErrorScreen extends StatelessWidget {
  const _PublicShareErrorScreen({
    required this.revoked,
  });

  final bool revoked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Khoảnh khắc được chia sẻ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              revoked ? Icons.cancel : Icons.link_off,
              size: 56,
              color: revoked ? MemoTheme.danger : Colors.black38,
            ),
            const SizedBox(height: 24),
            Text(
              revoked ? 'Liên kết đã thu hồi' : 'Không tìm thấy liên kết',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              revoked
                  ? 'Kỷ niệm này không còn khả dụng qua liên kết công khai.'
                  : 'Liên kết này không tồn tại hoặc không còn khả dụng.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
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
}
