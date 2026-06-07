import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/models.dart';
import '../data/repository_providers.dart';
import 'share_moment_sheet.dart';
import 'theme.dart';

class PinDetailScreen extends ConsumerStatefulWidget {
  const PinDetailScreen({required this.pinId, super.key});

  final String pinId;

  @override
  ConsumerState<PinDetailScreen> createState() => _PinDetailScreenState();
}

class _PinDetailScreenState extends ConsumerState<PinDetailScreen> {
  PinDto? _pin;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    try {
      final pin = await ref.read(pinRepositoryProvider).getPin(widget.pinId);
      if (!mounted) return;
      setState(() {
        _pin = pin;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải kỷ niệm này.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _pin == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Lỗi không xác định')),
      );
    }

    final pin = _pin!;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Xem trên bản đồ'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(Icons.location_on, size: 48, color: MemoTheme.accent),
            ),
            const SizedBox(height: 16),
            Text(
              pin.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MemoTheme.onBackground,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.black54,
                ),
                const SizedBox(width: 4),
                Text(
                  pin.memoryDate != null
                      ? '${pin.memoryDate!.day} thg ${pin.memoryDate!.month}, ${pin.memoryDate!.year}'
                      : 'Không rõ',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.black54),
                    SizedBox(width: 4),
                    Text(
                      'Chỉ mình tôi',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Mock images
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildImageMock('1', true),
                  const SizedBox(width: 8),
                  _buildImageMock('2', false),
                  const SizedBox(width: 8),
                  _buildImageMock('3', false, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (pin.note != null && pin.note!.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.eco, size: 18, color: MemoTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Ghi chú',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(pin.note!, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Tọa độ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${pin.lat.toStringAsFixed(4)}° N, ${pin.lng.toStringAsFixed(4)}° E',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.copy, size: 16, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Mock Audio
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: MemoTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ghi âm kỷ niệm',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '00:28',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Icon(
                          Icons.graphic_eq,
                          color: Colors.black26,
                        ), // Mock waveform
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionItem(
                  icon: Icons.edit_outlined,
                  label: 'Sửa',
                  onTap: () {
                    context.push(
                      '/pins/${Uri.encodeComponent(widget.pinId)}/edit',
                    );
                  },
                ),
                _ActionItem(
                  icon: Icons.share_outlined,
                  label: 'Chia sẻ',
                  onTap: () => _showShareSheet(context),
                ),
                _ActionItem(
                  icon: Icons.delete_outline,
                  label: 'Xóa',
                  color: MemoTheme.danger,
                  onTap: () => _showDeleteSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMock(String id, bool isFirst, {bool isLast = false}) {
    return GestureDetector(
      onTap: () => _showImageViewer(context),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1542314831-c6a4d14d8c85?w=400',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: isLast
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '1/5',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _showImageViewer(BuildContext context) {
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz, color: Colors.white),
              ),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: Image.network(
                  'https://images.unsplash.com/photo-1542314831-c6a4d14d8c85',
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quán nhỏ Đà Lạt',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '12 thg 05, 2024 · 07:32',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pin?.note ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      // Mock thumbnails
                      Row(
                        children: [
                          _buildThumbMock(true),
                          const SizedBox(width: 8),
                          _buildThumbMock(false),
                          const SizedBox(width: 8),
                          _buildThumbMock(false),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbMock(bool selected) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1542314831-c6a4d14d8c85?w=100',
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    final PinDto? pin = _pin;
    if (pin == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ShareMomentSheet(pin: pin);
      },
    );
  }

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: MemoTheme.danger,
              ),
              const SizedBox(height: 16),
              const Text(
                'Xóa kỷ niệm này?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kỷ niệm cùng tất cả ảnh, ghi chú\nvà ghi âm sẽ bị xóa vĩnh viễn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Giữ lại'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline),
                label: const Text('Xóa'),
                style:
                    FilledButton.styleFrom(backgroundColor: MemoTheme.danger),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
