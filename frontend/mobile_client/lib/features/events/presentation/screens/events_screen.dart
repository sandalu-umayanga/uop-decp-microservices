import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/events_provider.dart';
import '../../data/models/event_model.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/date_utils.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF8FAFC);
  static const border      = Color(0xFFE2E8F0);
  static const borderSoft  = Color(0xFFEEF2F7);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted   = Color(0xFF94A3B8);
  static const accent      = Color(0xFF1565C0);
  static const accentLight = Color(0xFFEEF2FF);
  static const accentMid   = Color(0xFFE3F2FD);
  static const success     = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const error       = Color(0xFFEF4444);
}

// ─── Category Theming ─────────────────────────────────────────────────────────
extension EventCategoryTheme on EventCategory {
  Color get color => switch (this) {
        EventCategory.ACADEMIC    => const Color(0xFF1565C0),
        EventCategory.SOCIAL      => const Color(0xFFF59E0B),
        EventCategory.WORKSHOP    => const Color(0xFF0EA5E9),
        EventCategory.NETWORKING  => const Color(0xFF10B981),
        EventCategory.CAREER      => const Color(0xFF8B5CF6),
        EventCategory.ALUMINI     => const Color(0xFFEC4899),
      };

  Color get lightColor => switch (this) {
        EventCategory.ACADEMIC    => const Color(0xFFEEF2FF),
        EventCategory.SOCIAL      => const Color(0xFFFEF3C7),
        EventCategory.WORKSHOP    => const Color(0xFFE0F2FE),
        EventCategory.NETWORKING  => const Color(0xFFD1FAE5),
        EventCategory.CAREER      => const Color(0xFFEDE9FE),
        EventCategory.ALUMINI     => const Color(0xFFFCE7F3),
      };

  IconData get icon => switch (this) {
        EventCategory.ACADEMIC    => Icons.school_rounded,
        EventCategory.SOCIAL      => Icons.celebration_rounded,
        EventCategory.WORKSHOP    => Icons.build_rounded,
        EventCategory.NETWORKING  => Icons.hub_rounded,
        EventCategory.CAREER      => Icons.work_rounded,
        EventCategory.ALUMINI     => Icons.groups_rounded,
      };

  String get label => switch (this) {
        EventCategory.ACADEMIC    => 'Academic',
        EventCategory.SOCIAL      => 'Social',
        EventCategory.WORKSHOP    => 'Workshop',
        EventCategory.NETWORKING  => 'Networking',
        EventCategory.CAREER      => 'Career',
        EventCategory.ALUMINI     => 'Alumni',
      };
}

// ─── Events Screen ────────────────────────────────────────────────────────────
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future.microtask(() {
      ref.read(eventsProvider.notifier).loadEvents();
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateEventSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(eventsProvider);
    final user     = ref.watch(currentUserProvider);
    final canCreate = user?.role == 'ALUMNI' || user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: _AppColors.surfaceAlt,
      floatingActionButton: canCreate
          ? ScaleTransition(
              scale: CurvedAnimation(
                parent: _fabController,
                curve: Curves.elasticOut,
              ),
              child: FloatingActionButton.extended(
                onPressed: _showCreateModal,
                backgroundColor: _AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'New Event',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, letterSpacing: 0.2),
                ),
              ),
            )
          : null,
      body: Builder(builder: (_) {
        if (state.isLoading && state.events.isEmpty) {
          return const AppLoadingWidget(message: 'Loading events...');
        }
        if (state.error != null && state.events.isEmpty) {
          return AppErrorWidget(
            message: state.error!,
            onRetry: () => ref.read(eventsProvider.notifier).loadEvents(),
          );
        }

        final upcoming = state.events.where((e) => e.isUpcoming).toList();

        return Column(
          children: [
            Container(
              color: _AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: _AppColors.accent,
                indicatorWeight: 2.5,
                labelColor: _AppColors.accent,
                unselectedLabelColor: _AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'All Events (${state.events.length})'),
                  Tab(text: 'Upcoming (${upcoming.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EventList(events: state.events),
                  _EventList(events: upcoming),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Create Event Sheet ───────────────────────────────────────────────────────
class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet();

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _formKey         = GlobalKey<FormState>();
  final _titleCtrl       = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _maxAttendeesCtrl = TextEditingController();

  DateTime?        _selectedDate;
  TimeOfDay?       _startTime;
  TimeOfDay?       _endTime;
  EventCategory    _category = EventCategory.ACADEMIC;
  bool             _submitting = false;
  String?          _submitError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _maxAttendeesCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _displayTime(TimeOfDay t) {
    final h  = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m  = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ap';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _AppColors.accent,
            onPrimary: Colors.white,
            surface: _AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime   ?? const TimeOfDay(hour: 10, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _AppColors.accent,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else         _endTime   = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      setState(() => _submitError = 'Please select a date.');
      return;
    }
    if (_startTime == null) {
      setState(() => _submitError = 'Please select a start time.');
      return;
    }
    if (_endTime == null) {
      setState(() => _submitError = 'Please select an end time.');
      return;
    }

    setState(() { _submitting = true; _submitError = null; });

    final ok = await ref.read(eventsProvider.notifier).createEvent(
      title:        _titleCtrl.text.trim(),
      description:  _descCtrl.text.trim(),
      location:     _locationCtrl.text.trim(),
      eventDate:    _formatDate(_selectedDate!),
      startTime:    _formatTime(_startTime!),
      endTime:      _formatTime(_endTime!),
      category:     _category.name,
      maxAttendees: int.tryParse(_maxAttendeesCtrl.text.trim()) ?? 0,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _submitError = 'Failed to create event. Please try again.');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  InputDecoration _fieldDeco({
    required String label,
    required String hint,
    Widget? prefixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            fontSize: 13, color: _AppColors.textSecondary),
        hintStyle: const TextStyle(
            fontSize: 14, color: _AppColors.textMuted),
        prefixIcon: prefixIcon,
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
          borderSide:
              const BorderSide(color: _AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: _AppColors.error, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
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

              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _AppColors.accentMid,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_rounded,
                        color: _AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Event',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Fill in the details below',
                          style: TextStyle(
                              fontSize: 13, color: _AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Title ──
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                  label: 'Event Title',
                  hint: 'e.g. Annual Alumni Meetup',
                  prefixIcon: const Icon(Icons.title_rounded,
                      size: 18, color: _AppColors.textMuted),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),

              // ── Description ──
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                minLines: 2,
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                  label: 'Description',
                  hint: 'What is this event about?',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded,
                        size: 18, color: _AppColors.textMuted),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // ── Category picker ──
              _SectionLabel(label: 'Category'),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: EventCategory.values.map((cat) {
                    final selected = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? cat.color
                                : cat.lightColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? cat.color
                                  : cat.color.withOpacity(0.25),
                              width: selected ? 0 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 13,
                                color: selected
                                    ? Colors.white
                                    : cat.color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : cat.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Date ──
              _SectionLabel(label: 'Date & Time'),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Date picker
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.calendar_today_rounded,
                      label: _selectedDate == null
                          ? 'Select date'
                          : _formatDate(_selectedDate!),
                      placeholder: _selectedDate == null,
                      onTap: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Start time
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.access_time_rounded,
                      label: _startTime == null
                          ? 'Start time'
                          : _displayTime(_startTime!),
                      placeholder: _startTime == null,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: _AppColors.textMuted),
                  const SizedBox(width: 8),
                  // End time
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.access_time_filled_rounded,
                      label: _endTime == null
                          ? 'End time'
                          : _displayTime(_endTime!),
                      placeholder: _endTime == null,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Location ──
              TextFormField(
                controller: _locationCtrl,
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                  label: 'Location',
                  hint: 'e.g. Main Hall, Building A',
                  prefixIcon: const Icon(Icons.location_on_rounded,
                      size: 18, color: _AppColors.textMuted),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Location is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // ── Max Attendees ──
              TextFormField(
                controller: _maxAttendeesCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                  label: 'Max Attendees',
                  hint: 'e.g. 50',
                  prefixIcon: const Icon(Icons.people_alt_rounded,
                      size: 18, color: _AppColors.textMuted),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) return 'Enter a valid number';
                  return null;
                },
              ),

              // ── Error ──
              if (_submitError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _AppColors.error.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: _AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _AppColors.accent.withOpacity(0.4),
                    disabledForegroundColor: Colors.white60,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _submitting ? 'Creating…' : 'Create Event',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Picker Tile ──────────────────────────────────────────────────────────────
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool placeholder;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: placeholder ? _AppColors.textMuted : _AppColors.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      placeholder ? FontWeight.w400 : FontWeight.w600,
                  color: placeholder
                      ? _AppColors.textMuted
                      : _AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─── Event List ───────────────────────────────────────────────────────────────
class _EventList extends ConsumerWidget {
  final List<EventModel> events;
  const _EventList({required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) return const _EmptyState();
    return RefreshIndicator(
      color: _AppColors.accent,
      backgroundColor: _AppColors.surface,
      onRefresh: () => ref.read(eventsProvider.notifier).loadEvents(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: events.length,
        itemBuilder: (_, i) => _EventCard(event: events[i], index: i),
      ),
    );
  }
}

// ─── Event Card ───────────────────────────────────────────────────────────────
class _EventCard extends StatefulWidget {
  final EventModel event;
  final int index;
  const _EventCard({required this.event, required this.index});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 400 + (widget.index * 60).clamp(0, 400)),
    );
    _fadeAnim  = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(
        Duration(milliseconds: widget.index * 60),
        () { if (mounted) _controller.forward(); });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event       = widget.event;
    final catColor      = event.category.color;
    final catLightColor = event.category.lightColor;
    final isUpcoming   = event.isUpcoming;
    final isFull       = event.maxAttendees != null &&
        (event.attendeeCount ?? 0) >= event.maxAttendees!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/events/${event.id}'),
              splashColor: catLightColor,
              highlightColor: catLightColor.withOpacity(0.5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _AppColors.border),
                ),
                child: Column(
                  children: [
                    // Category bar
                    Container(
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(event.category.icon,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            event.category.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          if (isFull)
                            _StatusPill(label: 'FULL')
                          else if (isUpcoming)
                            _StatusPill(label: 'UPCOMING'),
                        ],
                      ),
                    ),

                    // Card body
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _AppColors.textPrimary,
                              letterSpacing: -0.2,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (event.organizerName != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'by ${event.organizerName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: catColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: _AppColors.border),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _MetaChip(
                                icon: Icons.calendar_today_rounded,
                                label: formatDate(event.eventDate),
                              ),
                              if (event.startTime != null) ...[
                                const SizedBox(width: 6),
                                _MetaChip(
                                  icon: Icons.access_time_rounded,
                                  label: formatTime(event.startTime!),
                                ),
                              ],
                            ],
                          ),
                          if (event.location != null) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: _AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ],
                          if (event.maxAttendees != null) ...[
                            const SizedBox(height: 10),
                            _AttendeeBar(
                              current: event.attendeeCount ?? 0,
                              max: event.maxAttendees!,
                              color: catColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ─── Meta Chip ────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Attendee Progress Bar ────────────────────────────────────────────────────
class _AttendeeBar extends StatelessWidget {
  final int current;
  final int max;
  final Color color;
  const _AttendeeBar(
      {required this.current, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio  = (current / max).clamp(0.0, 1.0);
    final isFull = ratio >= 1.0;

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_rounded,
                size: 12, color: _AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              '$current / $max spots filled',
              style: const TextStyle(
                fontSize: 11,
                color: _AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${(ratio * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isFull ? _AppColors.error : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: _AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              isFull ? _AppColors.error : color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _AppColors.accentLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.event_busy_rounded,
                size: 36, color: _AppColors.accent),
          ),
          const SizedBox(height: 20),
          const Text(
            'No events here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back soon for upcoming events',
            style:
                TextStyle(fontSize: 14, color: _AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}