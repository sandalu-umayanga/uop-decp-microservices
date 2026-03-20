import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/events_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/models/rsvp_model.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/date_utils.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const accent = Color(0xFF1565C0);
  static const accentLight = Color(0xFFEEF2FF);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
}

// ─── Category Theming (mirrors events_screen.dart) ────────────────────────────
extension EventCategoryTheme on EventCategory {
  Color get color => switch (this) {
        EventCategory.ACADEMIC => const Color(0xFF1565C0),
        EventCategory.SOCIAL => const Color(0xFFF59E0B),
        EventCategory.WORKSHOP => const Color(0xFF0EA5E9),
        EventCategory.NETWORKING => const Color(0xFF10B981),
        EventCategory.CAREER => const Color(0xFF8B5CF6),
        EventCategory.ALUMINI => const Color(0xFFEC4899),
      };

  Color get lightColor => switch (this) {
        EventCategory.ACADEMIC => const Color(0xFFEEF2FF),
        EventCategory.SOCIAL => const Color(0xFFFEF3C7),
        EventCategory.WORKSHOP => const Color(0xFFE0F2FE),
        EventCategory.NETWORKING => const Color(0xFFD1FAE5),
        EventCategory.CAREER => const Color(0xFFEDE9FE),
        EventCategory.ALUMINI => const Color(0xFFFCE7F3),
      };

  IconData get icon => switch (this) {
        EventCategory.ACADEMIC => Icons.school_rounded,
        EventCategory.SOCIAL => Icons.celebration_rounded,
        EventCategory.WORKSHOP => Icons.build_rounded,
        EventCategory.NETWORKING => Icons.hub_rounded,
        EventCategory.CAREER => Icons.work_rounded,
        EventCategory.ALUMINI => Icons.groups_rounded,
      };

  String get label => switch (this) {
        EventCategory.ACADEMIC => 'Academic',
        EventCategory.SOCIAL => 'Social',
        EventCategory.WORKSHOP => 'Workshop',
        EventCategory.NETWORKING => 'Networking',
        EventCategory.CAREER => 'Career',
        EventCategory.ALUMINI => 'Alumni',
      };
}

// ─── RSVP Status Theming ─────────────────────────────────────────────────────
extension RsvpStatusTheme on RsvpStatus {
  Color get color => switch (this) {
        RsvpStatus.GOING => const Color(0xFF10B981),
        RsvpStatus.MAYBE => const Color(0xFFF59E0B),
        RsvpStatus.NOT_GOING => const Color(0xFFEF4444),
      };

  Color get lightColor => switch (this) {
        RsvpStatus.GOING => const Color(0xFFD1FAE5),
        RsvpStatus.MAYBE => const Color(0xFFFEF3C7),
        RsvpStatus.NOT_GOING => const Color(0xFFFEE2E2),
      };

  IconData get icon => switch (this) {
        RsvpStatus.GOING => Icons.check_circle_rounded,
        RsvpStatus.MAYBE => Icons.help_rounded,
        RsvpStatus.NOT_GOING => Icons.cancel_rounded,
      };

  String get label => switch (this) {
        RsvpStatus.GOING => 'Going',
        RsvpStatus.MAYBE => 'Maybe',
        RsvpStatus.NOT_GOING => "Can't Go",
      };
}

// ─── Event Detail Screen ──────────────────────────────────────────────────────
class EventDetailScreen extends ConsumerStatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  RsvpStatus? _selectedRsvp;
  bool _isSubmitting = false;

  Future<void> _submitRsvp(EventModel event, RsvpStatus status) async {
    setState(() {
      _isSubmitting = true;
      _selectedRsvp = status;
    });

    final ok = await ref
        .read(eventsProvider.notifier)
        .rsvpEvent(event.id!, status.toString().split('.').last);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(ok ? status.icon : Icons.error_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(ok
                  ? 'RSVP updated: ${status.label}'
                  : 'Failed to update RSVP'),
            ],
          ),
          backgroundColor: ok ? status.color : _AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${event.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok =
          await ref.read(eventsProvider.notifier).deleteEvent(event.id!);
      if (ok && mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(singleEventProvider(widget.eventId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _CircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.pop(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CircleButton(
              icon: Icons.ios_share_rounded,
              onTap: () {/* share */},
            ),
          ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (event) {
          final catColor = event.category.color;
          final isOrganizer = user?.id == event.organizer;
          final isAdmin = user?.role == 'ADMIN';
          final isFull = event.maxAttendees != null &&
              (event.attendeeCount ?? 0) >= event.maxAttendees!;
          final isUpcoming = event.isUpcoming;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero Header ──
                    _HeroHeader(event: event, catColor: catColor),

                    // ── Quick Info Cards ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _QuickInfoGrid(event: event, catColor: catColor),
                    ),

                    // ── Attendee Progress ──
                    if (event.maxAttendees != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _SectionCard(
                          title: 'Attendance',
                          icon: Icons.people_alt_rounded,
                          catColor: catColor,
                          child: _AttendeeProgress(
                            current: event.attendeeCount ?? 0,
                            max: event.maxAttendees!,
                            color: catColor,
                            isFull: isFull,
                          ),
                        ),
                      ),
                    ],

                    // ── Description ──
                    if (event.description != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _SectionCard(
                          title: 'About this Event',
                          icon: Icons.description_outlined,
                          catColor: catColor,
                          child: Text(
                            event.description!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.7,
                              color: _AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // ── RSVP Section ──
                    if (isUpcoming) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _SectionCard(
                          title: 'Your RSVP',
                          icon: Icons.how_to_vote_rounded,
                          catColor: catColor,
                          child: _RsvpSection(
                            event: event,
                            selectedRsvp: _selectedRsvp,
                            isSubmitting: _isSubmitting,
                            isFull: isFull,
                            onRsvp: (status) => _submitRsvp(event, status),
                          ),
                        ),
                      ),
                    ],

                    // ── Organizer / Admin Actions ──
                    if (isOrganizer || isAdmin) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _SectionCard(
                          title: 'Organizer Actions',
                          icon: Icons.admin_panel_settings_rounded,
                          catColor: catColor,
                          child: _OrganizerActions(
                            onDelete: () => _deleteEvent(event),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final EventModel event;
  final Color catColor;
  const _HeroHeader({required this.event, required this.catColor});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    final isUpcoming = event.isUpcoming;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catColor,
            catColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + upcoming badge row
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(event.category.icon,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      event.category.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isUpcoming)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'UPCOMING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),

          if (event.organizerName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 14, color: Colors.white70),
                const SizedBox(width: 5),
                Text(
                  'Organized by ${event.organizerName}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Quick Info Grid ──────────────────────────────────────────────────────────
class _QuickInfoGrid extends StatelessWidget {
  final EventModel event;
  final Color catColor;
  const _QuickInfoGrid({required this.event, required this.catColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _InfoTile(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: formatDate(event.eventDate),
              color: catColor,
            ),
            const SizedBox(width: 10),
            if (event.startTime != null)
              _InfoTile(
                icon: Icons.access_time_rounded,
                label: 'Time',
                value: event.endTime != null
                    ? '${formatTime(event.startTime!)} – ${formatTime(event.endTime!)}'
                    : formatTime(event.startTime!),
                color: catColor,
              ),
          ],
        ),
        if (event.location != null) ...[
          const SizedBox(height: 10),
          _InfoTile(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: event.location!,
            color: catColor,
            fullWidth: true,
          ),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.border),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return fullWidth
        ? SizedBox(width: double.infinity, child: tile)
        : Expanded(child: tile);
  }
}

// ─── Attendee Progress ────────────────────────────────────────────────────────
class _AttendeeProgress extends StatelessWidget {
  final int current;
  final int max;
  final Color color;
  final bool isFull;

  const _AttendeeProgress({
    required this.current,
    required this.max,
    required this.color,
    required this.isFull,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (current / max).clamp(0.0, 1.0);
    final barColor = isFull ? _AppColors.error : color;

    return Column(
      children: [
        Row(
          children: [
            Text(
              '$current',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: barColor,
                letterSpacing: -1,
              ),
            ),
            Text(
              ' / $max',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _AppColors.textMuted,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isFull ? _AppColors.errorLight : barColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isFull ? 'Event Full' : '${max - current} spots left',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isFull ? _AppColors.error : barColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: _AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(ratio * 100).round()}% capacity',
          style: const TextStyle(
            fontSize: 11,
            color: _AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─── RSVP Section ─────────────────────────────────────────────────────────────
class _RsvpSection extends StatelessWidget {
  final EventModel event;
  final RsvpStatus? selectedRsvp;
  final bool isSubmitting;
  final bool isFull;
  final void Function(RsvpStatus) onRsvp;

  const _RsvpSection({
    required this.event,
    required this.selectedRsvp,
    required this.isSubmitting,
    required this.isFull,
    required this.onRsvp,
  });

  @override
  Widget build(BuildContext context) {
    if (isFull && selectedRsvp != RsvpStatus.GOING) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 16, color: _AppColors.error),
            SizedBox(width: 8),
            Text(
              'This event is at full capacity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (selectedRsvp != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: selectedRsvp!.lightColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selectedRsvp!.icon,
                    size: 15, color: selectedRsvp!.color),
                const SizedBox(width: 7),
                Text(
                  'Your response: ${selectedRsvp!.label}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selectedRsvp!.color,
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: RsvpStatus.values.map((status) {
            final isSelected = selectedRsvp == status;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: status != RsvpStatus.NOT_GOING ? 8 : 0,
                ),
                child: _RsvpButton(
                  status: status,
                  isSelected: isSelected,
                  isSubmitting: isSubmitting && isSelected,
                  onTap: () => onRsvp(status),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── RSVP Button ─────────────────────────────────────────────────────────────
class _RsvpButton extends StatelessWidget {
  final RsvpStatus status;
  final bool isSelected;
  final bool isSubmitting;
  final VoidCallback onTap;

  const _RsvpButton({
    required this.status,
    required this.isSelected,
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? status.color : _AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? status.color : _AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: status.color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isSubmitting ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                isSubmitting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isSelected
                              ? Colors.white
                              : status.color,
                        ),
                      )
                    : Icon(
                        status.icon,
                        size: 18,
                        color:
                            isSelected ? Colors.white : status.color,
                      ),
                const SizedBox(height: 4),
                Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : _AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Organizer Actions ────────────────────────────────────────────────────────
class _OrganizerActions extends StatelessWidget {
  final VoidCallback onDelete;
  const _OrganizerActions({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: _AppColors.error,
          side: const BorderSide(color: _AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        label: const Text(
          'Delete Event',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color catColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.catColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 15, color: catColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Circle Button (AppBar action) ────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _AppColors.border),
          ),
          child: Icon(icon, size: 18, color: _AppColors.textPrimary),
        ),
      ),
    );
  }
}