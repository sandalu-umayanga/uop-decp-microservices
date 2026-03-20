import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mentorship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/mentorship_models.dart';
import '../../data/models/feedback_model.dart';
import '../../data/models/relationship_model.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const accent      = Color(0xFF1565C0);
  static const accentLight = Color(0xFFE3F2FD);
  static const accentMid   = Color(0xFF1976D2);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF4F7FB);
  static const border      = Color(0xFFE2E8F0);
  static const borderSoft  = Color(0xFFEEF2F7);
  static const text        = Color(0xFF0F172A);
  static const textSec     = Color(0xFF475569);
  static const textMuted   = Color(0xFF94A3B8);
  static const teal        = Color(0xFF00897B);
  static const tealLight   = Color(0xFFE0F2F1);
  static const green       = Color(0xFF2E7D32);
  static const greenLight  = Color(0xFFE8F5E9);
  static const amber       = Color(0xFFF59E0B);
  static const orange      = Color(0xFFF57C00);
  static const orangeLight = Color(0xFFFFF3E0);
  static const error       = Color(0xFFEF4444);
  static const errorLight  = Color(0xFFFEF2F2);
  static const grey        = Color(0xFF9E9E9E);
}

Color _avatarColor(String name) {
  const p = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF0277BD),
    Color(0xFF00838F), Color(0xFFF57C00), Color(0xFFAD1457),
  ];
  if (name.isEmpty) return p[0];
  return p[name.codeUnitAt(0) % p.length];
}

String _initial(String name) => name.isNotEmpty ? name[0].toUpperCase() : '?';

// Availability
Color _availColor(String a) => switch (a) {
      'HIGHLY_AVAILABLE' => _C.green,
      'AVAILABLE'        => _C.teal,
      'LIMITED'          => _C.orange,
      _                  => _C.error,
    };

Color _availLight(String a) => switch (a) {
      'HIGHLY_AVAILABLE' => _C.greenLight,
      'AVAILABLE'        => _C.tealLight,
      'LIMITED'          => _C.orangeLight,
      _                  => _C.errorLight,
    };

String _availLabel(String a) =>
    a.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');

// Request / relationship status
Color _statusColor(String s) => switch (s) {
      'PENDING'   || 'PAUSED'    => _C.orange,
      'ACCEPTED'  || 'ACTIVE'    => _C.green,
      'COMPLETED'                => _C.accent,
      'REJECTED'  || 'CANCELLED' => _C.error,
      _                          => _C.grey,
    };

Color _statusLight(String s) => switch (s) {
      'PENDING'   || 'PAUSED'    => _C.orangeLight,
      'ACCEPTED'  || 'ACTIVE'    => _C.greenLight,
      'COMPLETED'                => _C.accentLight,
      'REJECTED'  || 'CANCELLED' => _C.errorLight,
      _                          => const Color(0xFFF5F5F5),
    };

// ─── Root Screen ──────────────────────────────────────────────────────────────
class MentorshipScreen extends ConsumerStatefulWidget {
  const MentorshipScreen({super.key});

  @override
  ConsumerState<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends ConsumerState<MentorshipScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late final AnimationController _fabCtrl;
  late final Animation<double>   _fabAnim;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    Future.microtask(() {
      ref.read(mentorshipProvider.notifier).loadAll();
      _fabCtrl.forward();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  void _showEditProfile(MentorshipProfileModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentorshipProvider);

    MentorshipData? data;
    state.whenData((d) => data = d);

    return Scaffold(
      backgroundColor: _C.surfaceAlt,
      floatingActionButton: ScaleTransition(
        scale: _fabAnim,
        child: FloatingActionButton(
          onPressed: () => _showEditProfile(data?.profile),
          backgroundColor: _C.accent,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          tooltip: 'Edit my profile',
          child: const Icon(Icons.manage_accounts_rounded, size: 22),
        ),
      ),
      body: Builder(builder: (_) {
        if (state.isLoading) {
          return const AppLoadingWidget(message: 'Loading mentorship…');
        }
        if (state.hasError && data == null) {
          return AppErrorWidget(
            message: state.error.toString(),
            onRetry: () =>
                ref.read(mentorshipProvider.notifier).loadAll(),
          );
        }

        return Column(
          children: [
            // Profile banner
            if (data?.profile != null)
              _ProfileBanner(profile: data!.profile!),

            // Tab bar
            Container(
              color: _C.surface,
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: _C.accent,
                indicatorWeight: 2.5,
                labelColor: _C.accent,
                unselectedLabelColor: _C.textMuted,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                tabs: [
                  Tab(text: 'Discover (${data?.matches.length ?? 0})'),
                  Tab(text: 'Requests (${data?.requests.length ?? 0})'),
                  Tab(text: 'Active (${data?.relationships.length ?? 0})'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _DiscoverTab(
                    matches: data?.matches ?? [],
                    isStudent: ref.watch(currentUserProvider)?.role == 'STUDENT',
                  ),
                  _RequestsTab(requests: data?.requests ?? []),
                  _ActiveTab(relationships: data?.relationships ?? []),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Profile Banner ───────────────────────────────────────────────────────────
class _ProfileBanner extends StatelessWidget {
  final MentorshipProfileModel profile;
  const _ProfileBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isMentor = profile.role == 'MENTOR';
    final color    = isMentor ? _C.accent : _C.teal;
    final light    = isMentor ? _C.accentLight : _C.tealLight;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: light,
                shape: BoxShape.circle,
                border: Border.all(
                    color: color.withOpacity(0.25), width: 1.5)),
            child: Icon(
              isMentor ? Icons.school_rounded : Icons.person_rounded,
              color: color, size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are a ${profile.role}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${profile.department} · ${profile.yearsOfExperience} yr${profile.yearsOfExperience != 1 ? 's' : ''} exp',
                  style: const TextStyle(
                      fontSize: 12, color: _C.textMuted),
                ),
              ],
            ),
          ),
          _AvailChip(availability: profile.availability),
        ],
      ),
    );
  }
}

class _AvailChip extends StatelessWidget {
  final String availability;
  const _AvailChip({required this.availability});

  @override
  Widget build(BuildContext context) {
    final c = _availColor(availability);
    final l = _availLight(availability);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: l,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        _availLabel(availability),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: c,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Discover Tab ─────────────────────────────────────────────────────────────
class _DiscoverTab extends ConsumerStatefulWidget {
  final List<MatchModel> matches;
  final bool isStudent; // true = STUDENT, false = ALUMNI/ADMIN
  const _DiscoverTab({required this.matches, required this.isStudent});

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  final _searchCtrl = TextEditingController();
  String? _filterAvailability;

  static const _availOptions = [
    'HIGHLY_AVAILABLE', 'AVAILABLE', 'LIMITED',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final q = _searchCtrl.text.trim();
    ref.read(mentorshipProvider.notifier).loadMatches(
      expertise: q.isEmpty ? null : q,
      availability: _filterAvailability,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter bar
        Container(
          color: _C.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _C.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _C.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _search(),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                        fontSize: 14, color: _C.text),
                    decoration: InputDecoration(
                      hintText: 'Search by expertise…',
                      hintStyle: const TextStyle(
                          color: _C.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _C.textMuted, size: 19),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 17, color: _C.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                                ref.read(mentorshipProvider.notifier)
                                    .loadMatches(
                                        availability: _filterAvailability);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Availability filter
              _FilterButton(
                active: _filterAvailability != null,
                onTap: () async {
                  final picked =
                      await showModalBottomSheet<String?>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AvailPickerSheet(
                        selected: _filterAvailability,
                        options: _availOptions),
                  );
                  if (picked != null) {
                    setState(() => _filterAvailability =
                        picked == '__clear__' ? null : picked);
                    _search();
                  }
                },
              ),
            ],
          ),
        ),

        // Active filter chip
        if (_filterAvailability != null)
          Container(
            color: _C.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _availLight(_filterAvailability!),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _availColor(_filterAvailability!)
                            .withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _availLabel(_filterAvailability!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _availColor(_filterAvailability!),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() => _filterAvailability = null);
                          _search();
                        },
                        child: Icon(Icons.close_rounded,
                            size: 13,
                            color: _availColor(_filterAvailability!)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Match list
        Expanded(
          child: widget.matches.isEmpty
              ? _EmptyTab(
                  icon: Icons.people_alt_rounded,
                  title: 'No matches yet',
                  subtitle: widget.isStudent
                      ? 'Try adjusting your filters'
                      : 'Matches appear as students enrol',
                )
              : RefreshIndicator(
                  color: _C.accent,
                  backgroundColor: _C.surface,
                  onRefresh: () =>
                      ref.read(mentorshipProvider.notifier).loadAll(),
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: widget.matches.length,
                    itemBuilder: (_, i) => _MatchCard(
                        match: widget.matches[i],
                        index: i,
                        isStudent: widget.isStudent),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: active ? _C.accent : _C.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? _C.accent : _C.border),
        ),
        child: Icon(Icons.filter_list_rounded,
            size: 20,
            color: active ? Colors.white : _C.textMuted),
      ),
    );
  }
}

class _AvailPickerSheet extends StatelessWidget {
  final String? selected;
  final List<String> options;
  const _AvailPickerSheet(
      {required this.selected, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: _C.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Filter by Availability',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.text,
                letterSpacing: -0.3,
              )),
          const SizedBox(height: 14),
          _PickerOption(
            label: 'Any Availability',
            icon: Icons.all_inclusive_rounded,
            color: _C.accent,
            light: _C.accentLight,
            isSelected: selected == null,
            onTap: () => Navigator.pop(context, '__clear__'),
          ),
          const SizedBox(height: 8),
          ...options.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PickerOption(
                  label: _availLabel(o),
                  icon: Icons.circle_rounded,
                  color: _availColor(o),
                  light: _availLight(o),
                  isSelected: selected == o,
                  onTap: () => Navigator.pop(context, o),
                ),
              )),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color light;
  final bool isSelected;
  final VoidCallback onTap;
  const _PickerOption({
    required this.label, required this.icon,
    required this.color, required this.light,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.07)
              : _C.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.4)
                : _C.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: light,
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color:
                        isSelected ? color : _C.text,
                  )),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── Match Card ───────────────────────────────────────────────────────────────
class _MatchCard extends ConsumerStatefulWidget {
  final MatchModel match;
  final int index;
  final bool isStudent;
  const _MatchCard({required this.match, required this.index, required this.isStudent});

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: 360 + (widget.index * 50).clamp(0, 350)));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 50),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m     = widget.match;
    final color = _avatarColor(m.userName);
    final score = m.compatibilityScore;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: _C.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: widget.isStudent
                  ? () => _showRequestSheet(context, ref)
                  : null,
              splashColor: _C.accentLight,
              highlightColor: _C.accentLight.withOpacity(0.5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _C.borderSoft),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _initial(m.userName),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.userName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _C.text,
                                    letterSpacing: -0.2,
                                  )),
                              const SizedBox(height: 2),
                              Text(m.profile.department,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _C.textMuted)),
                              const SizedBox(height: 4),
                              _AvailChip(
                                  availability: m.profile.availability),
                            ],
                          ),
                        ),
                        // Compatibility ring
                        _CompatRing(score: score),
                      ],
                    ),

                    // Common interests
                    if (m.commonInterests.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(
                          height: 1, color: _C.borderSoft),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: m.commonInterests
                            .map((i) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _C.surfaceAlt,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                        color: _C.border),
                                  ),
                                  child: Text(i,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _C.textSec,
                                      )),
                                ))
                            .toList(),
                      ),
                    ],

                    // Expertise chips
                    if (m.profile.expertise.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: m.profile.expertise
                            .take(4)
                            .map((e) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        color.withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                        color: color
                                            .withOpacity(0.2)),
                                  ),
                                  child: Text(e,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      )),
                                ))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 12),
                    // ── Role-aware action ──────────────────────────────────
                    if (widget.isStudent)
                      // STUDENT → send a mentorship request
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showRequestSheet(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          icon: const Icon(
                              Icons.handshake_rounded, size: 16),
                          label: const Text('Connect',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      )
                    else
                      // ALUMNI/ADMIN → requests come TO them; Discover is
                      // read-only. Show a nudge toward the Requests tab.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _C.accentLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _C.accent.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14,
                                color: _C.accent.withOpacity(0.8)),
                            const SizedBox(width: 6),
                            const Text(
                              'Students send requests to you',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _C.accent,
                              ),
                            ),
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

  void _showRequestSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SendRequestSheet(match: widget.match),
    );
  }
}

class _CompatRing extends StatelessWidget {
  final double score;
  const _CompatRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct   = (score * 100).toInt();
    final color = score >= 0.75 ? _C.green : score >= 0.5 ? _C.teal : _C.orange;
    return SizedBox(
      width: 52, height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score,
            backgroundColor: _C.border,
            valueColor: AlwaysStoppedAnimation(color),
            strokeWidth: 4,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$pct',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                Text('%',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Send Request Sheet ───────────────────────────────────────────────────────
class _SendRequestSheet extends ConsumerStatefulWidget {
  final MatchModel match;
  const _SendRequestSheet({required this.match});

  @override
  ConsumerState<_SendRequestSheet> createState() =>
      _SendRequestSheetState();
}

class _SendRequestSheetState extends ConsumerState<_SendRequestSheet> {
  final _msgCtrl    = TextEditingController(
      text: 'Hi, I would love to connect!');
  final _topicsCtrl = TextEditingController();
  String _duration  = 'THREE_MONTHS';
  bool   _sending   = false;

  static const _durations = {
    'ONE_MONTH':    '1 Month',
    'THREE_MONTHS': '3 Months',
    'SIX_MONTHS':   '6 Months',
    'ONE_YEAR':     '1 Year',
  };

  @override
  void dispose() {
    _msgCtrl.dispose();
    _topicsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, String hint, {Widget? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 13, color: _C.textSec),
        hintStyle: const TextStyle(fontSize: 14, color: _C.textMuted),
        prefixIcon: prefix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: _C.surfaceAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.accent, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final color = _avatarColor(m.userName);

    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20,
          MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_initial(m.userName),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect with ${m.userName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _C.text,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(m.profile.department,
                          style: const TextStyle(
                              fontSize: 12, color: _C.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _msgCtrl,
              maxLines: 3, minLines: 2,
              style: const TextStyle(fontSize: 14, color: _C.text),
              decoration: _deco('Message',
                  'Introduce yourself…',
                  prefix: const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(Icons.message_rounded,
                        size: 18, color: _C.textMuted),
                  )),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _topicsCtrl,
              style: const TextStyle(fontSize: 14, color: _C.text),
              decoration: _deco(
                'Topics (comma-separated)',
                'e.g. Machine Learning, Career Guidance',
                prefix: const Icon(Icons.topic_rounded,
                    size: 18, color: _C.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // Duration chips
            const Text('Proposed Duration',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.textSec,
                  letterSpacing: 0.3,
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.entries.map((e) {
                final sel = _duration == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _duration = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _C.accent : _C.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? _C.accent
                              : _C.border),
                    ),
                    child: Text(e.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? Colors.white
                              : _C.textSec,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : () async {
                  setState(() => _sending = true);
                  final topics = _topicsCtrl.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  final ok = await ref
                      .read(mentorshipProvider.notifier)
                      .requestMentor(
                        mentorId: m.userId,
                        message: _msgCtrl.text.trim(),
                        topics: topics,
                        proposedDuration: _duration,
                      );
                  if (!mounted) return;
                  setState(() => _sending = false);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Request sent to ${m.userName}!'
                        : 'Failed to send request.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: ok ? _C.green : _C.error,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _C.accent.withOpacity(0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _sending ? 'Sending…' : 'Send Request',
                  style: const TextStyle(
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

// ─── Requests Tab ─────────────────────────────────────────────────────────────
class _RequestsTab extends ConsumerWidget {
  final List<MentorshipRequestModel> requests;
  const _RequestsTab({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return const _EmptyTab(
        icon: Icons.inbox_rounded,
        title: 'No pending requests',
        subtitle: 'Sent and received requests will appear here',
      );
    }
    final currentUser = ref.watch(currentUserProvider);
    // ALUMNI/ADMIN are mentors — they *receive* requests.
    // STUDENT is a mentee — they *send* requests.
    final isAlumni = currentUser?.role == 'ALUMNI' ||
        currentUser?.role == 'ADMIN';
    return RefreshIndicator(
      color: _C.accent,
      backgroundColor: _C.surface,
      onRefresh: () => ref.read(mentorshipProvider.notifier).loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final req = requests[i];
          // A request is "received" when the current user is the mentor.
          final isReceived = isAlumni &&
              req.mentorId == currentUser?.id;
          return _RequestCard(req: req, isReceived: isReceived, index: i);
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final MentorshipRequestModel req;
  final bool isReceived;
  final int index;
  const _RequestCard({
    required this.req,
    required this.isReceived,
    required this.index,
  });

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: 360 + (widget.index * 50).clamp(0, 350)));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 50),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final req         = widget.req;
    final statusColor = _statusColor(req.status);
    final statusLight = _statusLight(req.status);
    // When received: the other party is the mentee (student who sent it).
    // When sent:     the other party is the mentor (alumni we requested).
    final otherName   = widget.isReceived
        ? req.menteeUserName
        : req.mentorUserName;
    final color       = _avatarColor(otherName);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.isReceived && req.status == 'PENDING'
                    ? _C.accent.withOpacity(0.3)
                    : _C.borderSoft,
                width: widget.isReceived && req.status == 'PENDING'
                    ? 1.5
                    : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(_initial(otherName),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: color,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                        // isReceived = current user is the mentor,
                        // so the other party is the mentee.
                        widget.isReceived
                            ? 'From ${req.menteeUserName}'
                            : 'To ${req.mentorUserName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _C.text,
                              letterSpacing: -0.1,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 11,
                                  color: _C.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                '${req.proposedDuration.replaceAll('_', ' ')} · ${timeAgo(req.createdAt)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _C.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                statusColor.withOpacity(0.25)),
                      ),
                      child: Text(req.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.2,
                          )),
                    ),
                  ],
                ),

                // Message
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: Text(
                    '"${req.message}"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: _C.textSec,
                      height: 1.4,
                    ),
                  ),
                ),

                // Topics
                if (req.topics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: req.topics
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _C.surfaceAlt,
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: _C.border),
                              ),
                              child: Text(t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _C.textSec,
                                  )),
                            ))
                        .toList(),
                  ),
                ],

                // Rejection reason
                if (req.status == 'REJECTED' &&
                    req.rejectionReason != null &&
                    req.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _C.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _C.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: _C.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(req.rejectionReason!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _C.error)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Accept / Decline
                if (widget.isReceived && req.status == 'PENDING') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _reject(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _C.error,
                            side: BorderSide(
                                color: _C.error
                                    .withOpacity(0.4)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: const Text('Decline',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _accept(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: const Text('Accept',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(mentorshipProvider.notifier)
        .respondRequest(widget.req.id, 'ACCEPTED');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Request accepted!' : 'Failed to accept.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? _C.green : _C.error,
      ));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline Request',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: TextField(
          controller: reasonCtrl,
          style: const TextStyle(fontSize: 14, color: _C.text),
          decoration: InputDecoration(
            labelText: 'Reason (optional)',
            filled: true,
            fillColor: _C.surfaceAlt,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _C.border)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(mentorshipProvider.notifier)
          .respondRequest(widget.req.id, 'REJECTED',
              rejectionReason: reasonCtrl.text.trim().isEmpty
                  ? null
                  : reasonCtrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(ok ? 'Request declined.' : 'Failed to decline.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ─── Active Tab ───────────────────────────────────────────────────────────────
class _ActiveTab extends ConsumerWidget {
  final List<RelationshipModel> relationships;
  const _ActiveTab({required this.relationships});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (relationships.isEmpty) {
      return const _EmptyTab(
        icon: Icons.handshake_rounded,
        title: 'No active mentorships',
        subtitle: 'Accept a request to start a mentorship',
      );
    }
    return RefreshIndicator(
      color: _C.accent,
      backgroundColor: _C.surface,
      onRefresh: () =>
          ref.read(mentorshipProvider.notifier).loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: relationships.length,
        itemBuilder: (_, i) =>
            _RelCard(rel: relationships[i], index: i),
      ),
    );
  }
}

class _RelCard extends ConsumerStatefulWidget {
  final RelationshipModel rel;
  final int index;
  const _RelCard({required this.rel, required this.index});

  @override
  ConsumerState<_RelCard> createState() => _RelCardState();
}

class _RelCardState extends ConsumerState<_RelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: 360 + (widget.index * 50).clamp(0, 350)));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 50),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final rel         = widget.rel;
    final currentUser = ref.watch(currentUserProvider);
    final otherName   = rel.menteeUserName == currentUser?.username
        ? rel.mentorUserName
        : rel.menteeUserName;
    final color       = _avatarColor(otherName);
    final sColor      = _statusColor(rel.status);
    final sLight      = _statusLight(rel.status);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6, offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(_initial(otherName),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: color,
                            )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(otherName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _C.text,
                                letterSpacing: -0.2,
                              )),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 11,
                                  color: _C.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                'Started ${timeAgo(rel.createdAt)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _C.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sColor.withOpacity(0.25)),
                      ),
                      child: Text(rel.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: sColor,
                            letterSpacing: 0.2,
                          )),
                    ),
                  ],
                ),

                // Goals
                if (rel.goals.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _C.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.flag_rounded,
                            size: 14, color: _C.textMuted),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(rel.goals,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _C.textSec,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cadence row
                if (rel.frequency.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _CadenceChip(
                        icon: Icons.repeat_rounded,
                        label: rel.frequency
                            .replaceAll('_', ' '),
                      ),
                      const SizedBox(width: 8),
                      _CadenceChip(
                        icon: Icons.videocam_rounded,
                        label: rel.preferredChannel
                            .replaceAll('_', ' '),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showUpdateSheet(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.accent,
                          side: BorderSide(
                              color: _C.accent
                                  .withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        icon: const Icon(
                            Icons.edit_rounded, size: 15),
                        label: const Text('Update',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showFeedbackSheet(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _C.amber,
                          side: BorderSide(
                              color: _C.amber
                                  .withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        icon: const Icon(
                            Icons.star_rounded, size: 15),
                        label: const Text('Feedback',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () =>
                          _confirmEnd(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _C.error,
                        side: BorderSide(
                            color: _C.error.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        minimumSize: const Size(44, 40),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Icon(Icons.exit_to_app_rounded,
                          size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUpdateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpdateRelSheet(rel: widget.rel),
    );
  }

  void _showFeedbackSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedbackSheet(rel: widget.rel),
    );
  }

  Future<void> _confirmEnd(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('End Mentorship',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text(
            'Are you sure you want to end this mentorship? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(mentorshipProvider.notifier)
          .endRelationship(widget.rel.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? 'Mentorship ended.'
              : 'Failed to end relationship.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? _C.textSec : _C.error,
        ));
      }
    }
  }
}

class _CadenceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CadenceChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _C.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.textSec)),
        ],
      ),
    );
  }
}

// ─── Update Relationship Sheet ────────────────────────────────────────────────
class _UpdateRelSheet extends ConsumerStatefulWidget {
  final RelationshipModel rel;
  const _UpdateRelSheet({required this.rel});

  @override
  ConsumerState<_UpdateRelSheet> createState() =>
      _UpdateRelSheetState();
}

class _UpdateRelSheetState extends ConsumerState<_UpdateRelSheet> {
  late final TextEditingController _goalsCtrl;
  late String _frequency;
  late String _channel;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _goalsCtrl = TextEditingController(text: widget.rel.goals);
    _frequency = widget.rel.frequency.isNotEmpty
        ? widget.rel.frequency
        : 'BIWEEKLY';
    _channel   = widget.rel.preferredChannel.isNotEmpty
        ? widget.rel.preferredChannel
        : 'VIDEO_CALL';
    _status    = widget.rel.status;
  }

  @override
  void dispose() {
    _goalsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {Widget? prefix}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _C.textSec),
        prefixIcon: prefix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: _C.surfaceAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.accent, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20,
          MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _C.accentLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_rounded,
                      color: _C.accent, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update Relationship',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.text,
                            letterSpacing: -0.4,
                          )),
                      Text('Adjust goals and preferences',
                          style: TextStyle(
                              fontSize: 13, color: _C.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _goalsCtrl,
              maxLines: 3, minLines: 2,
              style: const TextStyle(fontSize: 14, color: _C.text),
              decoration: _deco('Goals',
                  prefix: const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(Icons.flag_rounded,
                        size: 18, color: _C.textMuted),
                  )),
            ),
            const SizedBox(height: 12),

            _SheetDropdown<String>(
              value: _frequency,
              label: 'Frequency',
              icon: Icons.repeat_rounded,
              items: const {
                'WEEKLY':   'Weekly',
                'BIWEEKLY': 'Biweekly',
                'MONTHLY':  'Monthly',
              },
              onChanged: (v) => setState(() => _frequency = v),
            ),
            const SizedBox(height: 12),

            _SheetDropdown<String>(
              value: _channel,
              label: 'Preferred Channel',
              icon: Icons.videocam_rounded,
              items: const {
                'EMAIL':      'Email',
                'PHONE':      'Phone',
                'VIDEO_CALL': 'Video Call',
                'IN_PERSON':  'In Person',
                'MESSAGING':  'Messaging',
              },
              onChanged: (v) => setState(() => _channel = v),
            ),
            const SizedBox(height: 12),

            _SheetDropdown<String>(
              value: _status,
              label: 'Status',
              icon: Icons.info_rounded,
              items: const {
                'ACTIVE':    'Active',
                'PAUSED':    'Paused',
                'COMPLETED': 'Completed',
              },
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  Navigator.pop(context);
                  final ok = await ref
                      .read(mentorshipProvider.notifier)
                      .updateRelationship(widget.rel.id, {
                    'goals':            _goalsCtrl.text.trim(),
                    'frequency':        _frequency,
                    'preferredChannel': _channel,
                    'status':           _status,
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          ok ? 'Relationship updated!' : 'Update failed.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: ok ? _C.green : _C.error,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Save Changes',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feedback Sheet ───────────────────────────────────────────────────────────
class _FeedbackSheet extends ConsumerStatefulWidget {
  final RelationshipModel rel;
  const _FeedbackSheet({required this.rel});

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  int    _rating      = 5;
  final  _commentCtrl = TextEditingController();
  bool   _submitting  = false;
  bool   _showHistory = false;
  List<FeedbackModel>? _history;
  bool   _loadingHistory = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final list = await ref
        .read(mentorshipProvider.notifier)
        .getFeedback(widget.rel.id);
    setState(() {
      _history       = list;
      _loadingHistory = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20,
          MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _C.orangeLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.star_rounded,
                      color: _C.amber, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Feedback',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.text,
                            letterSpacing: -0.4,
                          )),
                      Text('Rate your experience',
                          style: TextStyle(
                              fontSize: 13, color: _C.textMuted)),
                    ],
                  ),
                ),
                // History toggle
                TextButton(
                  onPressed: () {
                    if (!_showHistory && _history == null) {
                      _loadHistory();
                    }
                    setState(() => _showHistory = !_showHistory);
                  },
                  child: Text(
                    _showHistory ? 'Write' : 'History',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_showHistory) ...[
              if (_loadingHistory)
                const Center(
                    child: CircularProgressIndicator(
                        color: _C.accent))
              else if (_history == null || _history!.isEmpty)
                const Center(
                    child: Text('No feedback yet.',
                        style: TextStyle(color: _C.textMuted)))
              else
                ..._history!.map((f) => _FeedbackTile(f: f)),
            ] else ...[
              // Star row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _C.amber,
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
              Center(
                child: Text(
                  [
                    '',
                    'Poor',
                    'Fair',
                    'Good',
                    'Great',
                    'Excellent'
                  ][_rating],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.amber,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _commentCtrl,
                maxLines: 3, minLines: 2,
                style: const TextStyle(fontSize: 14, color: _C.text),
                decoration: InputDecoration(
                  labelText: 'Comment',
                  hintText: 'Share your experience…',
                  labelStyle:
                      const TextStyle(fontSize: 13, color: _C.textSec),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(Icons.comment_rounded,
                        size: 18, color: _C.textMuted),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: _C.surfaceAlt,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _C.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _C.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: _C.accent, width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : () async {
                    setState(() => _submitting = true);
                    final ok = await ref
                        .read(mentorshipProvider.notifier)
                        .submitFeedback(widget.rel.id, _rating,
                            _commentCtrl.text.trim());
                    if (!mounted) return;
                    setState(() => _submitting = false);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? 'Feedback submitted!'
                          : 'Failed to submit.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: ok ? _C.green : _C.error,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.amber,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _C.amber.withOpacity(0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Submit Feedback',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final FeedbackModel f;
  const _FeedbackTile({required this.f});

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(f.givenByUserName);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle),
                child: Center(
                  child: Text(_initial(f.givenByUserName),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.givenByUserName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.text,
                        )),
                    Text(f.givenByRole,
                        style: const TextStyle(
                            fontSize: 10, color: _C.textMuted)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < f.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _C.amber,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(timeAgo(f.createdAt),
                  style: const TextStyle(
                      fontSize: 10, color: _C.textMuted)),
            ],
          ),
          if (f.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(f.comment,
                style: const TextStyle(
                  fontSize: 13,
                  color: _C.textSec,
                  height: 1.4,
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Shared Dropdown ──────────────────────────────────────────────────────────
class _SheetDropdown<T> extends StatelessWidget {
  final T value;
  final String label;
  final IconData icon;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  const _SheetDropdown({
    required this.value, required this.label,
    required this.icon, required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      style: const TextStyle(fontSize: 14, color: _C.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _C.textSec),
        prefixIcon: Icon(icon, size: 18, color: _C.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: _C.surfaceAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.accent, width: 1.5)),
      ),
      items: items.entries
          .map((e) => DropdownMenuItem<T>(
                value: e.key,
                child: Text(e.value),
              ))
          .toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final MentorshipProfileModel? existing;
  const _EditProfileSheet({this.existing});

  @override
  ConsumerState<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _bioCtrl       = TextEditingController();
  final _deptCtrl      = TextEditingController();
  final _expCtrl       = TextEditingController();
  // Expertise and interests as chip lists
  final _expertiseCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();
  final List<String> _expertiseList = [];
  final List<String> _interestList  = [];
  String _role         = 'MENTEE';
  String _availability = 'AVAILABLE';
  bool   _saving       = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _bioCtrl.text  = p.bio;
      _deptCtrl.text = p.department;
      _expCtrl.text  = p.yearsOfExperience.toString();
      _role          = p.role;
      _availability  = p.availability;
      _expertiseList.addAll(p.expertise);
      _interestList.addAll(p.interests);
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _deptCtrl.dispose();
    _expCtrl.dispose();
    _expertiseCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {Widget? prefix}) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _C.textSec),
        prefixIcon: prefix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: _C.surfaceAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.accent, width: 1.5)),
      );

  Widget _chipRow({
    required List<String> items,
    required TextEditingController ctrl,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) ...[
          Wrap(
            spacing: 8, runSpacing: 8,
            children: items.map((s) => Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => onRemove(s),
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded,
                          size: 10, color: color),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                onSubmitted: (_) => onAdd(),
                style: const TextStyle(fontSize: 14, color: _C.text),
                decoration: InputDecoration(
                  hintText: 'Add item…',
                  hintStyle: const TextStyle(
                      color: _C.textMuted, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: _C.surfaceAlt,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _C.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: _C.accent, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46, height: 46,
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add_rounded, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20,
          MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _C.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _C.accentLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.manage_accounts_rounded,
                      color: _C.accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Mentorship Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.text,
                            letterSpacing: -0.4,
                          )),
                      Text('Tell others about yourself',
                          style: TextStyle(
                              fontSize: 13, color: _C.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Role
            _SheetDropdown<String>(
              value: _role,
              label: 'Role',
              icon: Icons.badge_rounded,
              items: const {
                'MENTOR': 'Mentor',
                'MENTEE': 'Mentee',
                'BOTH':   'Both',
              },
              onChanged: (v) => setState(() => _role = v),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _deptCtrl,
              style: const TextStyle(fontSize: 14, color: _C.text),
              decoration: _deco('Department',
                  prefix: const Icon(Icons.business_rounded,
                      size: 18, color: _C.textMuted)),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _expCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: _C.text),
              decoration: _deco('Years of Experience',
                  prefix: const Icon(Icons.work_history_rounded,
                      size: 18, color: _C.textMuted)),
            ),
            const SizedBox(height: 16),

            // Expertise
            const Text('Expertise',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.textSec,
                  letterSpacing: 0.3,
                )),
            const SizedBox(height: 8),
            _chipRow(
              items: _expertiseList,
              ctrl: _expertiseCtrl,
              color: _C.accent,
              onAdd: () {
                final v = _expertiseCtrl.text.trim();
                if (v.isNotEmpty && !_expertiseList.contains(v)) {
                  setState(() {
                    _expertiseList.add(v);
                    _expertiseCtrl.clear();
                  });
                }
              },
              onRemove: (s) =>
                  setState(() => _expertiseList.remove(s)),
            ),
            const SizedBox(height: 16),

            // Interests
            const Text('Interests',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _C.textSec,
                  letterSpacing: 0.3,
                )),
            const SizedBox(height: 8),
            _chipRow(
              items: _interestList,
              ctrl: _interestsCtrl,
              color: _C.teal,
              onAdd: () {
                final v = _interestsCtrl.text.trim();
                if (v.isNotEmpty && !_interestList.contains(v)) {
                  setState(() {
                    _interestList.add(v);
                    _interestsCtrl.clear();
                  });
                }
              },
              onRemove: (s) =>
                  setState(() => _interestList.remove(s)),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bioCtrl,
              maxLines: 3, minLines: 2,
              style: const TextStyle(fontSize: 14, color: _C.text),
              decoration: _deco('Bio',
                  prefix: const Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(Icons.notes_rounded,
                        size: 18, color: _C.textMuted),
                  )),
            ),
            const SizedBox(height: 12),

            // Availability
            _SheetDropdown<String>(
              value: _availability,
              label: 'Availability',
              icon: Icons.event_available_rounded,
              items: const {
                'HIGHLY_AVAILABLE': 'Highly Available',
                'AVAILABLE':        'Available',
                'LIMITED':          'Limited',
                'NOT_AVAILABLE':    'Not Available',
              },
              onChanged: (v) => setState(() => _availability = v),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  Navigator.pop(context);
                  final ok = await ref
                      .read(mentorshipProvider.notifier)
                      .saveProfile({
                    'role':              _role,
                    'department':        _deptCtrl.text.trim(),
                    'yearsOfExperience': int.tryParse(_expCtrl.text.trim()) ?? 0,
                    'expertise':         _expertiseList,
                    'interests':         _interestList,
                    'bio':               _bioCtrl.text.trim(),
                    'availability':      _availability,
                    'timezone':          'Asia/Colombo',
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          ok ? 'Profile saved!' : 'Save failed.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: ok ? _C.green : _C.error,
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _C.accent.withOpacity(0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Save Profile',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Tab ────────────────────────────────────────────────────────────────
class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
                color: _C.accentLight,
                borderRadius: BorderRadius.circular(24)),
            child: Icon(icon, size: 36, color: _C.accent),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _C.text,
                letterSpacing: -0.3,
              )),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 13, color: _C.textMuted)),
        ],
      ),
    );
  }
}