import 'package:decp_mobile_app/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:decp_mobile_app/features/messaging/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_utils.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const accent       = Color(0xFF1565C0);
  static const accentMid    = Color(0xFF1976D2);
  static const accentLight  = Color(0xFFE3F2FD);
  static const accentGlow   = Color(0xFF42A5F5);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFF4F7FB);
  static const surfaceCard  = Color(0xFFF8FAFD);
  static const border       = Color(0xFFE2E8F0);
  static const borderSoft   = Color(0xFFEEF2F7);
  static const textPrimary  = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted    = Color(0xFF94A3B8);
  static const error        = Color(0xFFEF4444);
  static const online       = Color(0xFF22C55E);
}

Color _avatarColor(String name) {
  const palette = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF0277BD),
    Color(0xFF00838F), Color(0xFFF57C00), Color(0xFFAD1457),
  ];
  if (name.isEmpty) return palette[0];
  return palette[name.codeUnitAt(0) % palette.length];
}

String _initial(String name) =>
    name.isNotEmpty ? name[0].toUpperCase() : '?';

// ─── Conversations Screen ─────────────────────────────────────────────────────
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, int> _unreadOverrides = {};
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    Future.microtask(() {
      ref.read(conversationsProvider.notifier).loadConversations();
      _fabCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  Future<void> _showNewConversationSheet() async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewConversationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(conversationsProvider);
    final currentUser = ref.watch(currentUserProvider);

    final totalUnread = state.conversations.fold<int>(0, (sum, c) {
      final n = _unreadOverrides.containsKey(c.id)
          ? _unreadOverrides[c.id]!
          : c.unreadCount;
      return sum + n;
    });

    return Scaffold(
      backgroundColor: _AppColors.surfaceAlt,
      appBar: _ConversationsAppBar(totalUnread: totalUnread),
      floatingActionButton: ScaleTransition(
        scale: _fabAnim,
        child: FloatingActionButton(
          onPressed: _showNewConversationSheet,
          backgroundColor: _AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 4,
          tooltip: 'New Chat',
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.edit_rounded, size: 22),
        ),
      ),
      body: Builder(builder: (_) {
        if (state.isLoading && state.conversations.isEmpty) {
          return const AppLoadingWidget(message: 'Loading conversations…');
        }
        if (state.error != null && state.conversations.isEmpty) {
          return AppErrorWidget(
            message: state.error!,
            onRetry: () =>
                ref.read(conversationsProvider.notifier).loadConversations(),
          );
        }
        if (state.conversations.isEmpty) {
          return _EmptyState(onNewChat: _showNewConversationSheet);
        }

        return RefreshIndicator(
          color: _AppColors.accent,
          backgroundColor: _AppColors.surface,
          displacement: 50,
          onRefresh: () =>
              ref.read(conversationsProvider.notifier).loadConversations(),
          child: CustomScrollView(
            slivers: [
              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        '${state.conversations.length} conversation${state.conversations.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      if (totalUnread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$totalUnread unread',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Conversation list
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final conv = state.conversations[i];
                      final otherNames = currentUser == null
                          ? conv.participantNames
                          : conv.participantNames.where((n) {
                              return n != currentUser.username &&
                                  n != currentUser.fullName;
                            }).toList();

                      final displayName = conv.isGroup &&
                              (conv.groupName?.isNotEmpty ?? false)
                          ? conv.groupName!
                          : otherNames.isNotEmpty
                              ? otherNames.join(', ')
                              : conv.participantNames.isNotEmpty
                                  ? conv.participantNames.first
                                  : 'Chat';

                      final effectiveUnread =
                          _unreadOverrides.containsKey(conv.id)
                              ? _unreadOverrides[conv.id]!
                              : conv.unreadCount;

                      return _ConversationTile(
                        key: ValueKey(conv.id),
                        displayName: displayName,
                        isGroup: conv.isGroup,
                        participantNames: otherNames,
                        lastMessage: conv.lastMessage,
                        lastMessageAt: conv.lastMessageAt,
                        unreadCount: effectiveUnread,
                        index: i,
                        onTap: () async {
                          if (conv.unreadCount > 0) {
                            setState(() => _unreadOverrides[conv.id] = 0);
                          }
                          await context.push('/chat/${conv.id}');
                          if (context.mounted) {
                            await ref
                                .read(conversationsProvider.notifier)
                                .loadConversations();
                            if (mounted) setState(() => _unreadOverrides.clear());
                          }
                        },
                      );
                    },
                    childCount: state.conversations.length,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────
class _ConversationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final int totalUnread;
  const _ConversationsAppBar({required this.totalUnread});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _AppColors.accent,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 0,
      title: const Text('Messages'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, size: 22),
          onPressed: () {},
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Conversation Tile ────────────────────────────────────────────────────────
class _ConversationTile extends StatefulWidget {
  final String displayName;
  final bool isGroup;
  final List<String> participantNames;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;
  final int index;
  final VoidCallback onTap;

  const _ConversationTile({
    super.key,
    required this.displayName,
    required this.isGroup,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * 45).clamp(0, 400);
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 380 + widget.index * 30),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.onTap,
              splashColor: _AppColors.accentLight,
              highlightColor: _AppColors.accentLight.withOpacity(0.5),
              child: Ink(
                decoration: BoxDecoration(
                  color: _AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: hasUnread
                        ? _AppColors.accent.withOpacity(0.3)
                        : _AppColors.borderSoft,
                    width: hasUnread ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasUnread
                          ? _AppColors.accent.withOpacity(0.06)
                          : Colors.black.withOpacity(0.03),
                      blurRadius: hasUnread ? 12 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      // Avatar
                      _ConversationAvatar(
                        isGroup: widget.isGroup,
                        names: widget.participantNames,
                        hasUnread: hasUnread,
                      ),
                      const SizedBox(width: 13),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (widget.isGroup)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: Icon(
                                      Icons.group_rounded,
                                      size: 13,
                                      color: hasUnread
                                          ? _AppColors.accent
                                          : _AppColors.textMuted,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    widget.displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: hasUnread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: _AppColors.textPrimary,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.lastMessage ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: hasUnread
                                    ? _AppColors.textSecondary
                                    : _AppColors.textMuted,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Right meta
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.lastMessageAt != null)
                            Text(
                              timeAgo(widget.lastMessageAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? _AppColors.accent
                                    : _AppColors.textMuted,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          if (hasUnread) ...[
                            const SizedBox(height: 6),
                            Container(
                              constraints:
                                  const BoxConstraints(minWidth: 22),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _AppColors.accent.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.unreadCount > 99
                                    ? '99+'
                                    : '${widget.unreadCount}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Conversation Avatar ──────────────────────────────────────────────────────
class _ConversationAvatar extends StatelessWidget {
  final bool isGroup;
  final List<String> names;
  final bool hasUnread;
  const _ConversationAvatar({
    required this.isGroup,
    required this.names,
    required this.hasUnread,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGroup || names.isEmpty) {
      final name  = names.isNotEmpty ? names.first : '?';
      final color = _avatarColor(name);
      return Stack(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: hasUnread
                    ? color.withOpacity(0.35)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _initial(name),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Group: two overlapping circles
    final first  = names[0];
    final second = names.length > 1 ? names[1] : names[0];
    return SizedBox(
      width: 50, height: 50,
      child: Stack(
        children: [
          Positioned(
            top: 2, left: 0,
            child: _MiniAvatar(name: first, size: 36),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _AppColors.surface, width: 2.5),
              ),
              child: _MiniAvatar(name: second, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _MiniAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(name);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initial(name),
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;
  const _EmptyState({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(
                    color: _AppColors.accentLight,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(
                    color: _AppColors.accentLight,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: _AppColors.accent.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 36,
                    color: _AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a chat to connect\nwith someone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onNewChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  shadowColor: _AppColors.accent.withOpacity(0.35),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text(
                  'Start a Conversation',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── New Conversation Sheet ───────────────────────────────────────────────────
class _NewConversationSheet extends ConsumerStatefulWidget {
  const _NewConversationSheet();

  @override
  ConsumerState<_NewConversationSheet> createState() =>
      _NewConversationSheetState();
}

class _NewConversationSheetState
    extends ConsumerState<_NewConversationSheet> {
  final _searchCtrl    = TextEditingController();
  final _messageCtrl   = TextEditingController();
  final _groupNameCtrl = TextEditingController();

  UserModel? _foundUser;
  bool _searching = false;
  bool _sending   = false;
  String? _searchError;
  final List<UserModel> _members = [];

  bool get _isGroup => _members.length > 1;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _messageCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching   = true;
      _searchError = null;
      _foundUser   = null;
    });
    try {
      final user =
          await ref.read(messagingDatasourceProvider).searchUser(query);
      setState(() {
        _searching = false;
        if (user == null) {
          _searchError = 'No user found for "$query"';
        } else if (_members.any((m) => m.id == user.id)) {
          _searchError = '@${user.username} is already added';
        } else {
          _foundUser = user;
        }
      });
    } catch (_) {
      setState(() {
        _searching   = false;
        _searchError = 'Search failed. Try again.';
      });
    }
  }

  void _addMember() {
    if (_foundUser == null) return;
    setState(() {
      _members.add(_foundUser!);
      _foundUser   = null;
      _searchError = null;
      _searchCtrl.clear();
    });
  }

  void _removeMember(UserModel user) =>
      setState(() => _members.removeWhere((m) => m.id == user.id));

  Future<void> _startConversation() async {
    final me      = ref.read(currentUserProvider);
    final message = _messageCtrl.text.trim();
    if (_members.isEmpty || me == null || message.isEmpty) return;
    setState(() => _sending = true);

    final allIds   = [me.id, ..._members.map((m) => m.id)];
    final allNames = [me.username, ..._members.map((m) => m.username)];
    final groupName = _isGroup ? _groupNameCtrl.text.trim() : null;

    final conv = await ref
        .read(conversationsProvider.notifier)
        .startConversation(
          participantIds: allIds,
          participantNames: allNames,
          groupName: groupName?.isEmpty ?? true ? null : groupName,
          msg: message,
        );

    if (!mounted) return;
    setState(() => _sending = false);
    if (conv != null) {
      Navigator.pop(context);
      context.push('/chat/${conv.id}');
    }
  }

  InputDecoration _fieldDeco({
    required String hint,
    Widget? prefixIcon,
    String? errorText,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: _AppColors.textMuted, fontSize: 14),
        prefixIcon: prefixIcon,
        errorText: errorText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: _AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: _AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: _AppColors.error, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canSend     = _members.isNotEmpty &&
        _messageCtrl.text.trim().isNotEmpty &&
        !_sending;

    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isGroup ? 'New Group Chat' : 'New Conversation',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _members.isEmpty
                            ? 'Search by username to add people'
                            : '${_members.length} ${_members.length == 1 ? 'person' : 'people'} added',
                        style: const TextStyle(
                            fontSize: 13, color: _AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (_members.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: _AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_alt_rounded,
                            size: 13, color: _AppColors.accent),
                        const SizedBox(width: 5),
                        Text(
                          '${_members.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Member chips
            if (_members.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _members
                    .map((m) => _MemberChip(
                          user: m,
                          onRemove: () => _removeMember(m),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Group name (2+ members)
            if (_isGroup) ...[
              TextField(
                controller: _groupNameCtrl,
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                  hint: 'Group name (optional)',
                  prefixIcon: const Icon(Icons.group_rounded,
                      size: 18, color: _AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Search field
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _searchUser(),
                    style: const TextStyle(
                        fontSize: 14, color: _AppColors.textPrimary),
                    decoration: _fieldDeco(
                      hint: _members.isEmpty
                          ? 'Search username…'
                          : 'Add another person…',
                      prefixIcon: const Icon(Icons.person_search_rounded,
                          size: 18, color: _AppColors.textMuted),
                      errorText: _searchError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52, width: 52,
                  child: ElevatedButton(
                    onPressed: _searching ? null : _searchUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _searching
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ],
            ),

            // Found user
            if (_foundUser != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _AppColors.accentLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _AppColors.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: _avatarColor(_foundUser!.fullName)
                            .withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initial(_foundUser!.fullName),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _avatarColor(_foundUser!.fullName),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _foundUser!.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '@${_foundUser!.username}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _addMember,
                      style: FilledButton.styleFrom(
                        backgroundColor: _AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: Size.zero,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            // First message
            if (_members.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _AppColors.border,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageCtrl,
                maxLines: 3,
                minLines: 1,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                    hint: 'Write your first message…'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: canSend ? _startConversation : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _AppColors.accent.withOpacity(0.35),
                    disabledForegroundColor: Colors.white60,
                    elevation: 0,
                    shadowColor: _AppColors.accent.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _isGroup
                              ? Icons.group_add_rounded
                              : Icons.send_rounded,
                          size: 18),
                  label: Text(
                    _sending
                        ? 'Creating…'
                        : _isGroup
                            ? 'Create Group & Send'
                            : 'Send Message',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Member Chip ──────────────────────────────────────────────────────────────
class _MemberChip extends StatelessWidget {
  final UserModel user;
  final VoidCallback onRemove;
  const _MemberChip({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(user.fullName);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 5, 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initial(user.fullName),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            user.username,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }
}