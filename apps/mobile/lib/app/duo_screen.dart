import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../auth/auth_controller.dart';
import '../data/models/models.dart';
import 'duo_controller.dart';
import 'theme.dart';

class DuoScreen extends ConsumerStatefulWidget {
  const DuoScreen({this.initialInvitationCode, super.key});

  final String? initialInvitationCode;

  @override
  ConsumerState<DuoScreen> createState() => _DuoScreenState();
}

class _DuoScreenState extends ConsumerState<DuoScreen> {
  final TextEditingController _joinCodeController = TextEditingController();
  final int _bottomNavIndex = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final DuoController controller = ref.read(
        duoControllerProvider.notifier,
      );
      unawaited(controller.load());

      final String? initialCode = widget.initialInvitationCode;
      if (initialCode != null && initialCode.trim().isNotEmpty) {
        controller.openJoinForm(initialCode);
      }
    });
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final DuoMapState state = ref.watch(duoControllerProvider);
    final UserProfileDto? currentUser =
        ref.watch(authControllerProvider).session?.user;

    ref.listen<DuoMapState>(duoControllerProvider, (previous, next) {
      if (_joinCodeController.text == next.joinInput) {
        return;
      }

      _joinCodeController.value = TextEditingValue(
        text: next.joinInput,
        selection: TextSelection.collapsed(offset: next.joinInput.length),
      );
    });

    return Scaffold(
      backgroundColor: MemoTheme.background,
      appBar: AppBar(
        title: Text(
          _titleFor(state),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: <Widget>[
          if (state.hasDuoMap)
            IconButton(
              tooltip: 'Làm mới',
              onPressed: state.isMutating
                  ? null
                  : ref.read(duoControllerProvider.notifier).refreshSoon,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _buildBody(state, currentUser),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTapped,
        selectedItemColor: MemoTheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
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

  String _titleFor(DuoMapState state) {
    if (state.showJoinForm) {
      return 'Tham gia Duo Map';
    }

    final MapDto? map = state.duoMap;
    if (map == null) {
      return 'Bản đồ Duo';
    }

    if (state.isFull) {
      return map.name ?? 'Duo Map của bạn';
    }

    return 'Duo của bạn';
  }

  Widget _buildBody(DuoMapState state, UserProfileDto? currentUser) {
    if (state.isLoading && !state.hasDuoMap && !state.showJoinForm) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.showJoinForm) {
      return _buildJoinState(state);
    }

    final MapDto? map = state.duoMap;
    if (map == null) {
      return _buildEmptyState(state);
    }

    if (state.isFull) {
      return _buildActiveState(state, map, currentUser);
    }

    final InvitationDto? invitation = map.pendingInvitation;
    if (invitation != null) {
      return _buildInvitationState(state, map, invitation, currentUser);
    }

    return _buildReadyToInviteState(state, map, currentUser);
  }

  Widget _buildEmptyState(DuoMapState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildStatusMessages(state),
          const SizedBox(height: 16),
          const Text(
            'Duo Map dành cho đúng 2 người.\nCùng nhau lưu giữ và khám phá\nnhững kỷ niệm chung.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.5),
          ),
          const Spacer(),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: <Widget>[
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
            key: const Key('duo_create_button'),
            onPressed: state.isMutating
                ? null
                : ref.read(duoControllerProvider.notifier).createDuoMap,
            child: _buttonChild(state.isMutating, 'Tạo Duo Map'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state.isMutating
                ? null
                : ref.read(duoControllerProvider.notifier).openJoinForm,
            child: const Text('Nhập mã mời'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReadyToInviteState(
    DuoMapState state,
    MapDto map,
    UserProfileDto? currentUser,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildStatusMessages(state),
          const Text(
            'Duo Map đã sẵn sàng.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          _buildMembersSection(map, currentUser),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: state.isMutating
                ? null
                : ref.read(duoControllerProvider.notifier).createInvitation,
            icon: const Icon(Icons.mail_outline),
            label: _buttonChild(state.isMutating, 'Tạo lời mời'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationState(
    DuoMapState state,
    MapDto map,
    InvitationDto invitation,
    UserProfileDto? currentUser,
  ) {
    final String inviteLink = 'memo.app/inv/${invitation.code}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildStatusMessages(state),
          const Center(
            child: Text(
              'Quản lý Duo Map',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.location_on,
                  size: 32,
                  color: MemoTheme.accent,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  invitation.code,
                  key: const Key('duo_invitation_code'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildLinkRow(inviteLink),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hết hạn: ${_formatDateTime(invitation.expiresAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyText(invitation.code),
                        icon: const Icon(Icons.copy),
                        label: const Text('Sao chép'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyText(inviteLink),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Chia sẻ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildMembersSection(map, currentUser, showPending: true),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: state.isMutating
                ? null
                : ref.read(duoControllerProvider.notifier).revokeInvitation,
            icon: const Icon(Icons.delete_outline, color: MemoTheme.danger),
            label: Text(
              state.isMutating ? 'Đang thu hồi...' : 'Thu hồi lời mời',
              style: const TextStyle(color: MemoTheme.danger),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinState(DuoMapState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildStatusMessages(state),
          const Center(
            child: Text(
              'Nhập mã hoặc dán link mời để tham gia bản đồ Duo.',
              textAlign: TextAlign.center,
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
            key: const Key('duo_join_input'),
            controller: _joinCodeController,
            textCapitalization: TextCapitalization.characters,
            onChanged: ref.read(duoControllerProvider.notifier).setJoinInput,
            decoration: InputDecoration(
              hintText: 'INV-DEMO',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                tooltip: 'Xóa',
                onPressed: state.joinInput.isEmpty
                    ? null
                    : () {
                        _joinCodeController.clear();
                        ref
                            .read(duoControllerProvider.notifier)
                            .setJoinInput('');
                      },
                icon: const Icon(Icons.close),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gợi ý demo mock: INV-DEMO',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const Spacer(),
          FilledButton(
            key: const Key('duo_join_button'),
            onPressed: state.isMutating
                ? null
                : ref.read(duoControllerProvider.notifier).acceptInvitation,
            child: _buttonChild(state.isMutating, 'Tham gia'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state.isMutating
                ? null
                : ref.read(duoControllerProvider.notifier).closeJoinForm,
            child: const Text('Quay lại'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildActiveState(
    DuoMapState state,
    MapDto map,
    UserProfileDto? currentUser,
  ) {
    final String? currentUserId = currentUser?.id;
    final bool currentUserIsOwner =
        currentUserId != null && map.ownerId == currentUserId;
    final MapMemberDto? removableMember =
        currentUserIsOwner ? _firstNonOwnerMember(map) : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildStatusMessages(state),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECE5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
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
          _buildMembersSection(map, currentUser),
          if (removableMember != null) ...<Widget>[
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
              onPressed: state.isMutating
                  ? null
                  : () => ref
                      .read(duoControllerProvider.notifier)
                      .removeMember(removableMember.userId),
              icon: const Icon(Icons.person_remove, color: MemoTheme.danger),
              label: Text(
                state.isMutating ? 'Đang gỡ...' : 'Gỡ thành viên',
                style: const TextStyle(color: MemoTheme.danger),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: MemoTheme.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersSection(
    MapDto map,
    UserProfileDto? currentUser, {
    bool showPending = false,
  }) {
    final List<Widget> rows = <Widget>[];
    for (final MapMemberDto member in map.members) {
      if (rows.isNotEmpty) {
        rows.add(const Divider());
      }
      rows.add(_buildMemberRow(map, member, currentUser));
    }

    if (showPending) {
      rows.add(const Divider());
      rows.add(_buildPendingMemberRow());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Thành viên (${map.members.length + (showPending ? 1 : 0)}/2)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...rows,
      ],
    );
  }

  Widget _buildMemberRow(
    MapDto map,
    MapMemberDto member,
    UserProfileDto? currentUser,
  ) {
    final bool isCurrentUser = member.userId == currentUser?.id;
    final bool isOwner = member.role == MapMemberRole.owner;
    final String name = isCurrentUser
        ? '${currentUser?.displayName ?? 'Bạn'} (Bạn)'
        : isOwner
            ? 'Chủ sở hữu'
            : 'Thành viên ${_shortUserId(member.userId)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: isOwner ? MemoTheme.primary : MemoTheme.accent,
            child: Icon(
              isOwner ? Icons.person : Icons.favorite,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isOwner ? 'Chủ sở hữu' : 'Đã tham gia',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          _buildBadge(isOwner ? 'Owner' : 'Member'),
        ],
      ),
    );
  }

  Widget _buildPendingMemberRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Icon(Icons.person_outline, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Đang chờ tham gia',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Mời bằng mã hoặc liên kết',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          _buildBadge('Đang chờ', isWarning: true),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFDECEA) : const Color(0xFFE8ECE5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: isWarning ? const Color(0xFFD67D6F) : MemoTheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLinkRow(String inviteLink) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.link, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(inviteLink)),
        ],
      ),
    );
  }

  Widget _buildStatusMessages(DuoMapState state) {
    final List<Widget> messages = <Widget>[];
    final String? errorCode = state.errorCode;
    if (errorCode != null) {
      messages.add(
        _buildMessageTile(
          icon: Icons.error_outline,
          text: _errorMessage(errorCode),
          color: const Color(0xFFD67D6F),
          backgroundColor: const Color(0xFFFDECEA),
        ),
      );
    }

    final String? notice = state.notice;
    if (notice != null) {
      messages.add(
        _buildMessageTile(
          icon: Icons.check_circle_outline,
          text: notice,
          color: MemoTheme.primary,
          backgroundColor: const Color(0xFFE8ECE5),
        ),
      );
    }

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: messages,
      ),
    );
  }

  Widget _buildMessageTile({
    required IconData icon,
    required String text,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttonChild(bool isBusy, String label) {
    if (!isBusy) {
      return Text(label);
    }

    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Future<void> _copyText(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép lời mời.')),
    );
  }

  String _errorMessage(String code) {
    return switch (code) {
      'invitation_pending_exists' => 'Đã có lời mời đang chờ cho Duo Map này.',
      'map_full' => 'Duo Map đã đủ 2 thành viên.',
      'invalid_invitation' =>
        'Mã mời không hợp lệ, đã hết hạn, bị thu hồi hoặc đã dùng.',
      'forbidden' => 'Bạn không có quyền thực hiện thao tác này.',
      'not_found' => 'Không tìm thấy Duo Map hoặc thành viên.',
      'duo_load_failed' => 'Không tải được Duo Map. Hãy thử lại.',
      _ => 'Không thể hoàn tất thao tác. Hãy thử lại.',
    };
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('HH:mm, dd/MM/yyyy').format(value.toLocal());
  }

  String _shortUserId(String userId) {
    if (userId.length <= 6) {
      return userId;
    }

    return userId.substring(userId.length - 6);
  }

  MapMemberDto? _firstNonOwnerMember(MapDto map) {
    for (final MapMemberDto member in map.members) {
      if (member.role != MapMemberRole.owner) {
        return member;
      }
    }

    return null;
  }
}
