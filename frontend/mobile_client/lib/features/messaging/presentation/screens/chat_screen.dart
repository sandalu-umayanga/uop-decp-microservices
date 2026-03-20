import 'package:decp_mobile_app/features/messaging/presentation/providers/chat_provider.dart';
import 'package:decp_mobile_app/features/messaging/presentation/providers/conversations_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/date_utils.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const accent      = Color(0xFF1565C0);
  static const accentMid   = Color(0xFF1976D2);
  static const accentLight = Color(0xFFE3F2FD);
  static const accentGlow  = Color(0xFF42A5F5);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF4F7FB);
  static const surfaceCard = Color(0xFFF8FAFD);
  static const border      = Color(0xFFE2E8F0);
  static const borderSoft  = Color(0xFFEEF2F7);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted   = Color(0xFF94A3B8);
  static const bubbleOut   = Color(0xFF1565C0);
  static const online      = Color(0xFF22C55E);
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

// ─── Chat Screen ──────────────────────────────────────────────────────────────
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl        = TextEditingController();
  final _scrollCtrl  = ScrollController();
  final _focusNode   = FocusNode();
  bool  _typing      = false;
  int   _prevCount   = 0;
  bool  _showScrollBtn = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final nearBottom = _scrollCtrl.hasClients &&
        (_scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset) < 120;
    if (nearBottom != !_showScrollBtn) {
      setState(() => _showScrollBtn = !nearBottom);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (animate) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(chatProvider(widget.conversationId).notifier).sendMessage(text);
    _ctrl.clear();
    _scrollToBottom();
    if (_typing) {
      ref.read(chatProvider(widget.conversationId).notifier).sendTyping(false);
      setState(() => _typing = false);
    }
  }

  void _onTextChanged(String value) {
    final now = value.isNotEmpty;
    if (now != _typing) {
      setState(() => _typing = now);
      ref.read(chatProvider(widget.conversationId).notifier).sendTyping(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(chatProvider(widget.conversationId));
    final currentUser = ref.watch(currentUserProvider);
    final convsState  = ref.watch(conversationsProvider);

    if (state.messages.length != _prevCount) {
      _prevCount = state.messages.length;
      _scrollToBottom(animate: _prevCount > 1);
    }

    final conv = convsState.conversations
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;

    final isGroup    = conv?.isGroup ?? false;
    final allNames   = conv?.participantNames ?? [];
    final otherNames = currentUser == null
        ? allNames
        : allNames
            .where((n) => n != currentUser.username && n != currentUser.fullName)
            .toList();

    final displayName = isGroup && (conv?.groupName?.isNotEmpty ?? false)
        ? conv!.groupName!
        : otherNames.isNotEmpty
            ? otherNames.join(', ')
            : allNames.isNotEmpty
                ? allNames.first
                : 'Chat';

    final subtitle = isGroup
        ? '${allNames.length} members'
        : (state.isConnected ? 'Online' : 'Connecting…');

    return Scaffold(
      backgroundColor: _AppColors.surfaceAlt,
      appBar: _ChatAppBar(
        displayName: displayName,
        subtitle: subtitle,
        isGroup: isGroup,
        otherNames: otherNames,
        isConnected: state.isConnected,
      ),
      body: Column(
        children: [
          // Loading strip
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: state.isLoading ? 2 : 0,
            child: LinearProgressIndicator(
              color: _AppColors.accentGlow,
              backgroundColor: _AppColors.accentLight,
              minHeight: 2,
            ),
          ),

          // Messages
          Expanded(
            child: Stack(
              children: [
                state.messages.isEmpty && !state.isLoading
                    ? const _EmptyChat()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: state.messages.length,
                        itemBuilder: (_, i) {
                          final msg   = state.messages[i];
                          final isMe  = msg.senderId == currentUser?.id;
                          final showDate = i == 0 ||
                              _isDifferentDay(
                                  state.messages[i - 1].createdAt,
                                  msg.createdAt);
                          final isFirst = i == 0 ||
                              state.messages[i - 1].senderId != msg.senderId;
                          final isLast = i == state.messages.length - 1 ||
                              state.messages[i + 1].senderId != msg.senderId;

                          return Column(
                            children: [
                              if (showDate) _DateSeparator(iso: msg.createdAt),
                              _MessageBubble(
                                message: msg,
                                isMe: isMe,
                                isGroup: isGroup,
                                isFirstInGroup: isFirst,
                                isLastInGroup: isLast,
                                index: i,
                              ),
                            ],
                          );
                        },
                      ),

                // Scroll-to-bottom FAB
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  right: 16,
                  bottom: _showScrollBtn ? 12 : -56,
                  child: _ScrollToBottomButton(
                    onTap: () => _scrollToBottom(),
                  ),
                ),
              ],
            ),
          ),

          // Typing indicator
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: state.someoneTyping
                ? _TypingIndicator(name: state.typingUser)
                : const SizedBox.shrink(),
          ),

          // Input
          _InputBar(
            controller: _ctrl,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            onSend: _send,
            isTyping: _typing,
          ),
        ],
      ),
    );
  }

  bool _isDifferentDay(String? a, String? b) {
    if (a == null || b == null) return false;
    try {
      final da = DateTime.parse(a);
      final db = DateTime.parse(b);
      return da.year != db.year || da.month != db.month || da.day != db.day;
    } catch (_) {
      return false;
    }
  }
}

// ─── Chat App Bar ─────────────────────────────────────────────────────────────
class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String displayName;
  final String subtitle;
  final bool isGroup;
  final List<String> otherNames;
  final bool isConnected;

  const _ChatAppBar({
    required this.displayName,
    required this.subtitle,
    required this.isGroup,
    required this.otherNames,
    required this.isConnected,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          isGroup
              ? _GroupAvatarSmall(names: otherNames)
              : _DmAvatar(
                  name: otherNames.isNotEmpty ? otherNames.first : '?',
                  isConnected: isConnected,
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isEmpty ? 'Chat' : displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                Row(
                  children: [
                    if (!isGroup && isConnected) ...[
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                          color: _AppColors.online,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: (!isGroup && isConnected)
                            ? const Color(0xFFA5D6A7)
                            : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Video / call placeholder
        IconButton(
          icon: const Icon(Icons.videocam_rounded, size: 22),
          onPressed: () {},
          color: Colors.white70,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onPressed: () {},
          color: Colors.white70,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DmAvatar extends StatelessWidget {
  final String name;
  final bool isConnected;
  const _DmAvatar({required this.name, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
          ),
          child: Center(
            child: Text(
              _initial(name),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: 11, height: 11,
            decoration: BoxDecoration(
              color: isConnected ? _AppColors.online : Colors.white38,
              shape: BoxShape.circle,
              border: Border.all(color: _AppColors.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupAvatarSmall extends StatelessWidget {
  final List<String> names;
  const _GroupAvatarSmall({required this.names});

  @override
  Widget build(BuildContext context) {
    final first  = names.isNotEmpty ? names[0] : '?';
    final second = names.length > 1 ? names[1] : first;
    return SizedBox(
      width: 36, height: 36,
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0,
            child: _TinyAvatar(name: first, size: 24, onBlue: true),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _AppColors.accent, width: 1.5),
              ),
              child: _TinyAvatar(name: second, size: 20, onBlue: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool onBlue;
  const _TinyAvatar({required this.name, required this.size, this.onBlue = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(onBlue ? 0.22 : 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initial(name),
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Scroll-to-bottom Button ──────────────────────────────────────────────────
class _ScrollToBottomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollToBottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: _AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: _AppColors.accent,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Date Separator ───────────────────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final String? iso;
  const _DateSeparator({this.iso});

  String _label() {
    if (iso == null) return '';
    try {
      final d       = DateTime.parse(iso!);
      final now     = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      if (d.year == now.year && d.month == now.month && d.day == now.day)
        return 'Today';
      if (d.year == yesterday.year &&
          d.month == yesterday.month &&
          d.day == yesterday.day) return 'Yesterday';
      return formatDate(iso!);
    } catch (_) {
      return iso ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, _AppColors.border],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              _label(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _AppColors.textMuted,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_AppColors.border, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;
  final bool isGroup;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final int index;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGroup,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Tail radius: sharp corner on the "origin" side for first bubble
    final topLeft    = Radius.circular(isMe || !isFirstInGroup ? 20 : 6);
    final topRight   = Radius.circular(!isMe || !isFirstInGroup ? 20 : 6);
    final bottomLeft = Radius.circular(isMe ? 20 : (isLastInGroup ? 6 : 20));
    final bottomRight = Radius.circular(!isMe ? 20 : (isLastInGroup ? 6 : 20));

    return Padding(
      padding: EdgeInsets.only(bottom: isLastInGroup ? 12 : 2),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name for received messages
          if (!isMe && isFirstInGroup)
            Padding(
              padding: const EdgeInsets.only(left: 46, bottom: 4),
              child: Text(
                message.senderName ?? '',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _avatarColor(message.senderName ?? ''),
                  letterSpacing: 0.1,
                ),
              ),
            ),

          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Received avatar
              if (!isMe)
                isLastInGroup
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 2),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: _avatarColor(message.senderName ?? '')
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _initial(message.senderName ?? '?'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _avatarColor(message.senderName ?? ''),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: 38),

              // Bubble
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? _AppColors.bubbleOut : _AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: topLeft,
                      topRight: topRight,
                      bottomLeft: bottomLeft,
                      bottomRight: bottomRight,
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: _AppColors.borderSoft),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? _AppColors.accent.withOpacity(0.18)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: isMe ? 10 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : _AppColors.textPrimary,
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeAgo(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white.withOpacity(0.55)
                                  : _AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  final String? name;
  const _TypingIndicator({this.name});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Row(
                children: List.generate(3, (i) {
                  final phase = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                  final scale = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: _AppColors.accent.withOpacity(0.5 + scale * 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.name ?? 'Someone'} is typing',
            style: const TextStyle(
              fontSize: 12,
              color: _AppColors.textMuted,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final bool isTyping;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSend,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12, 10, 12,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            10,
      ),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        border: Border(
          top: BorderSide(color: _AppColors.border.withOpacity(0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          _BarIconButton(
            icon: Icons.add_circle_outline_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 6),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isTyping
                      ? _AppColors.accent.withOpacity(0.4)
                      : _AppColors.border,
                  width: isTyping ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmitted: (_) => onSend(),
                      textInputAction: TextInputAction.send,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      minLines: 1,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: _AppColors.textPrimary,
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        hintStyle: TextStyle(
                          color: _AppColors.textMuted,
                          fontSize: 14.5,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // Emoji button
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: _BarIconButton(
                      icon: Icons.sentiment_satisfied_alt_rounded,
                      onTap: () {},
                      color: _AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isTyping ? _AppColors.accent : _AppColors.accentLight,
              shape: BoxShape.circle,
              boxShadow: isTyping
                  ? [
                      BoxShadow(
                        color: _AppColors.accent.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: GestureDetector(
              onTap: onSend,
              child: Icon(
                Icons.send_rounded,
                color: isTyping ? Colors.white : _AppColors.accent,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _BarIconButton({
    required this.icon,
    required this.onTap,
    this.color = _AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 36, height: 36,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ─── Empty Chat ───────────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: _AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: _AppColors.accentLight,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _AppColors.accent.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  size: 32,
                  color: _AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Say hello below 👋',
            style: TextStyle(
              fontSize: 14,
              color: _AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}