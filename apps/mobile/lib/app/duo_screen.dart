import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

enum DuoState { empty, invitationGenerated, acceptInvitation, active }

class DuoScreen extends StatefulWidget {
  const DuoScreen({super.key});

  @override
  State<DuoScreen> createState() => _DuoScreenState();
}

class _DuoScreenState extends State<DuoScreen> {
  DuoState _state = DuoState.empty;
  final int _bottomNavIndex = 2; // Duo index

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        context.go('/');
        return;
      case 1:
        context.go('/timeline');
        return;
      case 2:
        return;
      case 3:
        context.go('/settings');
        return;
    }
  }

  // To help preview designs, tap the appbar title to cycle state
  void _cycleState() {
    setState(() {
      _state = DuoState.values[(_state.index + 1) % DuoState.values.length];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MemoTheme.background,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _cycleState,
          child: Text(
            switch (_state) {
              DuoState.empty => 'Bản đồ Duo',
              DuoState.invitationGenerated => 'Duo của bạn',
              DuoState.acceptInvitation => 'Tham gia Duo Map',
              DuoState.active => 'Duo: Chuyến đi Đà Lạt',
            },
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        actions:
            _state == DuoState.invitationGenerated || _state == DuoState.active
                ? [
                    IconButton(
                      onPressed:
                          _cycleState, // Cycle on action button for convenience too
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ]
                : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: MemoTheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Bản đồ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Dòng thời gian',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Duo'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case DuoState.empty:
        return _buildEmptyState();
      case DuoState.invitationGenerated:
        return _buildInvitationGeneratedState();
      case DuoState.acceptInvitation:
        return _buildAcceptInvitationState();
      case DuoState.active:
        return _buildActiveState();
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Duo Map chỉ dành cho đúng 2 người.\nCùng nhau lưu giữ và khám phá\nnhững kỷ niệm chung.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.5),
          ),
          const Spacer(),
          // Mock graphic
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.map, size: 100, color: Colors.black12),
                ),
                Positioned(
                  left: 40,
                  top: 40,
                  child: Icon(
                    Icons.location_on,
                    size: 48,
                    color: MemoTheme.primary,
                  ),
                ),
                Positioned(
                  right: 40,
                  top: 80,
                  child: Icon(
                    Icons.location_on,
                    size: 48,
                    color: MemoTheme.danger,
                  ),
                ),
                Positioned(
                  left: 100,
                  bottom: 40,
                  child: Icon(Icons.flag, size: 48, color: MemoTheme.accent),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () =>
                setState(() => _state = DuoState.invitationGenerated),
            child: const Text('Tạo Duo Map'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _state = DuoState.acceptInvitation),
            child: const Text('Nhập mã mời'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInvitationGeneratedState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'Quản lý Duo Map',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 32,
                  color: MemoTheme.accent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'INV-7QK2',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.link, size: 16, color: Colors.black54),
                      SizedBox(width: 8),
                      Expanded(child: Text('memo.app/inv/INV-7QK2')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                    SizedBox(width: 8),
                    Text(
                      'Hết hạn vào 23:59, 28/05/2025',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.copy),
                        label: const Text('Sao chép'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Chia sẻ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Thành viên (1/2)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMemberRow('Minh Trí (Bạn)', 'Chủ sở hữu', isOwner: true),
          const Divider(),
          _buildMemberRow(
            'Đang chờ tham gia',
            'Đang chờ',
            subtitle: 'Mời bằng mã hoặc liên kết',
            isPending: true,
          ),
          const SizedBox(height: 32),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline, color: MemoTheme.danger),
              label: const Text(
                'Thu hồi lời mời',
                style: TextStyle(color: MemoTheme.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptInvitationState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'Nhập mã mời để tham gia bản đồ Duo.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Mã mời',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'INV-7QK3',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: const Icon(Icons.close),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD67D6F)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Color(0xFFD67D6F)),
                SizedBox(width: 8),
                Text(
                  'Mã mời không hợp lệ hoặc đã hết hạn.',
                  style: TextStyle(color: Color(0xFFD67D6F), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Thông tin bản đồ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://tile.openstreetmap.org/13/6511/3850.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on, color: MemoTheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chuyến đi Đà Lạt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Được mời bởi Minh Trí',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Hết hạn: 28/05/2025',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {},
            child: const Text('Tham gia'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _state = DuoState.empty),
            child: const Text('Quay lại'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActiveState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECE5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 14, color: MemoTheme.primary),
                  SizedBox(width: 6),
                  Text(
                    'Chỉ 2 người',
                    style: TextStyle(
                      fontSize: 12,
                      color: MemoTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Thành viên (2/2)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMemberRow('Minh Trí (Bạn)', 'Chủ sở hữu', isOwner: true),
          const Divider(),
          _buildMemberRow(
            'Khánh Linh',
            'Đã tham gia',
            subtitle: 'Đã tham gia',
            showMenu: true,
          ),
          const SizedBox(height: 32),
          const Text(
            'Quyền của chủ sở hữu',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn có toàn quyền quản lý Duo Map này.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_remove, color: MemoTheme.danger),
            label: const Text(
              'Gỡ thành viên',
              style: TextStyle(color: MemoTheme.danger),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: MemoTheme.danger),
            ),
          ),
          const SizedBox(height: 32),
          _buildWarningTile(
            icon: Icons.warning_amber_rounded,
            title: 'Đã có lời mời đang chờ',
            color: const Color(0xFFD67D6F),
            bgColor: const Color(0xFFFDECEA),
          ),
          const SizedBox(height: 12),
          _buildWarningTile(
            icon: Icons.access_time,
            title: 'Duo đã đủ 2 người',
            color: const Color(0xFFB5935A),
            bgColor: const Color(0xFFFBF9F6),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(
    String name,
    String badge, {
    String? subtitle,
    bool isOwner = false,
    bool isPending = false,
    bool showMenu = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPending ? Colors.transparent : Colors.grey[300],
            child: isPending
                ? const Icon(Icons.person_outline, color: Colors.black54)
                : const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
              ],
            ),
          ),
          if (badge.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFFDECEA)
                    : const Color(0xFFE8ECE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isPending ? const Color(0xFFD67D6F) : MemoTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (showMenu)
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildWarningTile({
    required IconData icon,
    required String title,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Icon(Icons.keyboard_arrow_down, color: color),
        ],
      ),
    );
  }
}
