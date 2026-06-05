import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import 'theme.dart';

enum SettingsState { main, export, delete, deleting }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SettingsState _state = SettingsState.main;
  final int _bottomNavIndex = 3;

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        context.go('/');
        return;
      case 1:
        context.go('/timeline');
        return;
      case 2:
        context.go('/duo');
        return;
      case 3:
        return;
    }
  }

  void _cycleState() {
    setState(() {
      _state = SettingsState
          .values[(_state.index + 1) % SettingsState.values.length];
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
              SettingsState.main => 'Cài đặt',
              SettingsState.export => 'Xuất dữ liệu',
              SettingsState.delete => 'Xóa tài khoản?',
              SettingsState.deleting => 'Đang xóa tài khoản',
            },
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: _state != SettingsState.main,
        leading: _state != SettingsState.main
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _state = SettingsState.main),
              )
            : null,
        titleSpacing: _state == SettingsState.main
            ? 24
            : NavigationToolbar.kMiddleSpacing,
      ),
      body: _buildBody(),
      bottomNavigationBar: _state == SettingsState.main
          ? BottomNavigationBar(
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Duo',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Cài đặt',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case SettingsState.main:
        return _buildMainState();
      case SettingsState.export:
        return _buildExportState();
      case SettingsState.delete:
        return _buildDeleteState();
      case SettingsState.deleting:
        return _buildDeletingState();
    }
  }

  Widget _buildMainState() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chuyến đi của tôi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'chuyendi.cuatoi@memo.app',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Quyền riêng tư'),
        _buildListTile(Icons.lock_outline, 'Quyền riêng tư & bảo mật'),
        _buildListTile(Icons.lock_clock_outlined, 'Khóa ứng dụng'),
        _buildListTile(Icons.data_usage, 'Dữ liệu & quyền của bạn'),
        const SizedBox(height: 16),
        _buildSectionTitle('Đồng bộ'),
        _buildListTile(
          Icons.sync,
          'Trạng thái đồng bộ',
          trailingText: 'Đã đồng bộ',
          trailingIcon: Icons.check_circle,
          trailingIconColor: MemoTheme.primary,
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Ngôn ngữ'),
        _buildListTile(Icons.language, 'Ngôn ngữ', trailingText: 'Tiếng Việt'),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text(
            'Không quảng cáo / không tracking',
            style: TextStyle(fontSize: 14),
          ),
          trailing: Switch(
            value: true,
            onChanged: (v) {},
            activeThumbColor: MemoTheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Dữ liệu'),
        _buildListTile(
          Icons.upload_file,
          'Xuất dữ liệu',
          onTap: () => setState(() => _state = SettingsState.export),
        ),
        _buildListTile(
          Icons.delete_outline,
          'Xóa tài khoản',
          textColor: MemoTheme.danger,
          onTap: () => setState(() => _state = SettingsState.delete),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Tài khoản'),
        _buildListTile(
          Icons.logout,
          'Đăng xuất',
          key: const ValueKey<String>('settings-logout'),
          onTap: () => ref.read(authControllerProvider.notifier).logout(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title, {
    Key? key,
    String? trailingText,
    IconData? trailingIcon,
    Color? trailingIconColor,
    Color textColor = Colors.black87,
    VoidCallback? onTap,
    bool showTrailingIcon = true,
  }) {
    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 16, color: trailingIconColor),
          ],
          if (trailingText == null && trailingIcon == null && showTrailingIcon)
            const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildExportState() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF9F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock, color: MemoTheme.primary),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Dữ liệu của bạn thuộc về bạn.\nBản xuất chỉ chứa các ghim, ghi chú,\nliên kết tệp và dữ liệu thiết yếu.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Phạm vi xuất'),
        _buildListTile(
          Icons.push_pin,
          'Ghim (kèm ghi chú)',
          trailingText: '128 >',
          showTrailingIcon: false,
        ),
        _buildListTile(
          Icons.link,
          'Liên kết phương tiện',
          trailingText: '342 >',
          showTrailingIcon: false,
        ),
        _buildListTile(
          Icons.file_copy,
          'Không bao gồm tệp gốc',
          trailingText: '-',
          showTrailingIcon: false,
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Định dạng'),
        _buildListTile(
          Icons.code,
          'JSON (khuyến nghị)',
          trailingText: '>',
          showTrailingIcon: false,
        ),
        _buildListTile(
          Icons.storage,
          'Kích thước ước tính',
          trailingText: '85 MB',
          showTrailingIcon: false,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: () {}, child: const Text('Tạo bản xuất')),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MemoTheme.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang chuẩn bị',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Chúng tôi đang đóng gói dữ liệu của bạn...',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: MemoTheme.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: MemoTheme.primary),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sẵn sàng để tải xuống',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Bản xuất hoàn tất lúc 12:24, 18/05/2025',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.download, color: MemoTheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 12, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                'Bản xuất được mã hóa và chỉ bạn có quyền truy cập.',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteState() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Center(
          child: Icon(Icons.security, size: 64, color: Color(0xFFD67D6F)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Hành động này không thể hoàn tác.\nTất cả dữ liệu và quyền truy cập sẽ bị xóa vĩnh viễn.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 32),
        const Text(
          'Những gì sẽ bị xóa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildCheckItem('Tất cả ghim và ghi chú'),
        _buildCheckItem('Liên kết tệp phương tiện'),
        _buildCheckItem('Tư cách thành viên Duo'),
        _buildCheckItem('Cài đặt và tùy chọn'),
        const SizedBox(height: 32),
        const Text(
          'Để xác nhận, vui lòng nhập XÓA vào ô bên dưới.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Nhập XÓA',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => setState(() => _state = SettingsState.main),
          child: const Text('Hủy'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => setState(() => _state = SettingsState.deleting),
          icon: const Icon(Icons.delete_forever),
          label: const Text('Xóa vĩnh viễn'),
          style: FilledButton.styleFrom(backgroundColor: MemoTheme.danger),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 12, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                'Chúng tôi cam kết bảo vệ quyền riêng tư của bạn.',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(fontSize: 14)),
          const Icon(Icons.check_circle, color: MemoTheme.primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildDeletingState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Đang xóa dữ liệu của bạn khỏi các máy chủ.\nQuá trình này có thể mất vài phút.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          _buildProgressItem(
            Icons.location_on,
            'Xóa ghim và ghi chú',
            'Đã hoàn tất',
            true,
          ),
          _buildProgressItem(
            Icons.image,
            'Xóa liên kết phương tiện',
            'Đã hoàn tất',
            true,
          ),
          _buildProgressItem(
            Icons.people,
            'Xóa tư cách thành viên Duo',
            'Đang xử lý...',
            false,
          ),
          _buildProgressItem(
            Icons.security,
            'Dọn dẹp dữ liệu còn lại',
            'Đang chờ...',
            false,
            isLast: true,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD67D6F)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: Color(0xFFD67D6F)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Không thể dọn dẹp hoàn tất',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD67D6F),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Kết nối hiện tại không ổn định.\nVui lòng thử lại để đảm bảo dữ liệu được xóa triệt để.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD67D6F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại dọn dẹp'),
            style: FilledButton.styleFrom(backgroundColor: MemoTheme.danger),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 12, color: Colors.black54),
                SizedBox(width: 4),
                Text(
                  'Dữ liệu của bạn sẽ được xóa vĩnh viễn khi hoàn tất.',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    IconData icon,
    String title,
    String subtitle,
    bool done, {
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: done ? MemoTheme.primary : Colors.black26),
              if (!isLast)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 2,
                  height: 24,
                  color: done ? MemoTheme.primary : Colors.black12,
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: done ? Colors.black87 : Colors.black54,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (done)
            const Icon(Icons.check_circle, color: MemoTheme.primary, size: 20)
          else
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black26,
              ),
            ),
        ],
      ),
    );
  }
}
