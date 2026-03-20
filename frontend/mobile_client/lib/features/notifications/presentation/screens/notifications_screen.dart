import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const accent = Color(0xFF1565C0);
  static const accentLight = Color(0xFFE3F2FD);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
}

// ─── Notification type metadata ───────────────────────────────────────────────
({IconData icon, Color color, Color bg}) _meta(String type) {
  return switch (type) {
    'POST_LIKED' => (
        icon: Icons.favorite_rounded,
        color: const Color(0xFFE53935),
        bg: const Color(0xFFFFEBEE),
      ),
    'POST_COMMENTED' => (
        icon: Icons.comment_rounded,
        color: const Color(0xFF1565C0),
        bg: const Color(0xFFE3F2FD),
      ),
    'NEW_POST' => (
        icon: Icons.feed_rounded,
        color: const Color(0xFF1565C0),
        bg: const Color(0xFFE3F2FD),
      ),
    'JOB_CREATED' => (
        icon: Icons.work_rounded,
        color: const Color(0xFF00695C),
        bg: const Color(0xFFE0F2F1),
      ),
    'JOB_APPLICATION' => (
        icon: Icons.send_rounded,
        color: const Color(0xFF00695C),
        bg: const Color(0xFFE0F2F1),
      ),
    'EVENT_CREATED' => (
        icon: Icons.event_rounded,
        color: const Color(0xFFE65100),
        bg: const Color(0xFFFFF3E0),
      ),
    'EVENT_RSVP' => (
        icon: Icons.how_to_reg_rounded,
        color: const Color(0xFFE65100),
        bg: const Color(0xFFFFF3E0),
      ),
    'USER_REGISTERED' => (
        icon: Icons.person_add_rounded,
        color: const Color(0xFF6A1B9A),
        bg: const Color(0xFFF3E5F5),
      ),
    _ => (
        icon: Icons.notifications_rounded,
        color: const Color(0xFF546E7A),
        bg: const Color(0xFFECEFF1),
      ),
  };
}

// ─── Notifications Screen ─────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationsProvider.notifier).loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final hasUnread = state.notifications.any((n) => !n.read);
    final unreadCount = state.notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: _AppColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: _AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Builder(builder: (_) {
        if (state.isLoading && state.notifications.isEmpty) {
          return const AppLoadingWidget(message: 'Loading notifications...');
        }
        if (state.error != null && state.notifications.isEmpty) {
          return AppErrorWidget(
            message: state.error!,
            onRetry: () =>
                ref.read(notificationsProvider.notifier).loadNotifications(),
          );
        }
        if (state.notifications.isEmpty) {
          return _EmptyState();
        }

        return RefreshIndicator(
          color: _AppColors.accent,
          backgroundColor: _AppColors.surface,
          onRefresh: () =>
              ref.read(notificationsProvider.notifier).loadNotifications(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: state.notifications.length,
            itemBuilder: (_, i) {
              final n = state.notifications[i];
              return _NotificationCard(
                key: ValueKey(n.id),
                notification: n,
                index: i,
                onTap: () {
                  if (!n.read) {
                    ref
                        .read(notificationsProvider.notifier)
                        .markRead(n.id);
                  }
                },
                onDismiss: () => ref
                    .read(notificationsProvider.notifier)
                    .deleteNotification(n.id),
              );
            },
          ),
        );
      }),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────
class _NotificationCard extends StatefulWidget {
  final dynamic notification;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.index,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 350 + (widget.index * 40).clamp(0, 300)),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 40), () {
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
    final n = widget.notification;
    final m = _meta(n.type as String);
    final isUnread = !(n.read as bool);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_rounded,
                  color: Colors.white, size: 22),
            ),
            onDismissed: (_) => widget.onDismiss(),
            child: Material(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: widget.onTap,
                splashColor: _AppColors.accentLight,
                highlightColor:
                    _AppColors.accentLight.withValues(alpha: 0.4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUnread
                          ? _AppColors.accent.withValues(alpha: 0.3)
                          : _AppColors.border,
                    ),
                    // Subtle blue tint on unread
                    color: isUnread
                        ? _AppColors.accentLight.withValues(alpha: 0.4)
                        : _AppColors.surface,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Icon container ──
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: m.bg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(m.icon, color: m.color, size: 22),
                      ),
                      const SizedBox(width: 12),

                      // ── Text ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: _AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeAgo(n.createdAt as String),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              n.message as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: isUnread
                                    ? _AppColors.textSecondary
                                    : _AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Unread dot ──
                      if (isUnread) ...[
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
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

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _AppColors.accentLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 36, color: _AppColors.accent),
          ),
          const SizedBox(height: 20),
          const Text(
            "You're all caught up",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No new notifications',
            style: TextStyle(fontSize: 14, color: _AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}