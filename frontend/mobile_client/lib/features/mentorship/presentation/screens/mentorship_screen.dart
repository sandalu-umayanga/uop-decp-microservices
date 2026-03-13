import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mentorship_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/mentorship_models.dart';

// ─────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────

class MentorshipScreen extends ConsumerStatefulWidget {
  const MentorshipScreen({super.key});

  @override
  ConsumerState<MentorshipScreen> createState() => _MentorshipScreenState();
}

class _MentorshipScreenState extends ConsumerState<MentorshipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(mentorshipProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentorshipProvider);

    MentorshipData? data;
    state.when(
      data: (d) => data = d,
      loading: () {},
      error: (_, __) {},
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditProfileSheet(context, data?.profile),
        tooltip: 'Edit my profile',
        child: const Icon(Icons.manage_accounts_outlined),
      ),
      body: Builder(builder: (_) {
        if (state.isLoading) {
          return const AppLoadingWidget(message: 'Loading mentorship...');
        }
        if (state.hasError && data == null) {
          return AppErrorWidget(
            message: state.error.toString(),
            onRetry: () => ref.read(mentorshipProvider.notifier).loadAll(),
          );
        }

        return Column(
          children: [
            if (data?.profile != null)
              _ProfileBanner(profile: data!.profile!),
            TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(text: 'Discover'),
                Tab(text: 'Requests'),
                Tab(text: 'Active'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _DiscoverTab(matches: data?.matches ?? []),
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

  void _showEditProfileSheet(
      BuildContext context, MentorshipProfileModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(existing: existing),
    );
  }
}

// ─────────────────────────────────────────────
// Profile banner
// ─────────────────────────────────────────────

class _ProfileBanner extends StatelessWidget {
  final MentorshipProfileModel profile;
  const _ProfileBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final color =
        profile.role == 'MENTOR' ? const Color(0xFF1565C0) : const Color(0xFF00897B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.08),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(
              profile.role == 'MENTOR' ? Icons.school : Icons.person,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are a ${profile.role}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  '${profile.department} · ${profile.yearsOfExperience} yrs exp',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _AvailabilityChip(availability: profile.availability),
        ],
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  final String availability;
  const _AvailabilityChip({required this.availability});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'HIGHLY_AVAILABLE': Colors.green,
      'AVAILABLE': Colors.teal,
      'LIMITED': Colors.orange,
      'NOT_AVAILABLE': Colors.red,
    };
    final c = colors[availability] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        availability.replaceAll('_', ' '),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Discover tab
// ─────────────────────────────────────────────

class _DiscoverTab extends ConsumerStatefulWidget {
  final List<MatchModel> matches;
  const _DiscoverTab({required this.matches});

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  String? _filterExpertise;
  String? _filterAvailability;
  final _expertiseCtrl = TextEditingController();

  static const _availabilityOptions = [
    'HIGHLY_AVAILABLE',
    'AVAILABLE',
    'LIMITED',
  ];

  @override
  void dispose() {
    _expertiseCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(mentorshipProvider.notifier).loadMatches(
          expertise: _filterExpertise,
          availability: _filterAvailability,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) {
      return const Center(child: Text('No recommendations yet.'));
    }

    return Column(
      children: [
        // ── Filter bar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expertiseCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Filter by expertise…',
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onSubmitted: (v) {
                    setState(() =>
                        _filterExpertise = v.trim().isEmpty ? null : v.trim());
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _filterAvailability,
                hint: const Text('Any'),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  ..._availabilityOptions.map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(
                        a.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _filterAvailability = v);
                  _applyFilters();
                },
              ),
            ],
          ),
        ),
        // ── Match list ──────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(mentorshipProvider.notifier).loadAll(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: widget.matches.length,
              itemBuilder: (_, i) => _MatchCard(match: widget.matches[i]),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Match card
// ─────────────────────────────────────────────

class _MatchCard extends ConsumerWidget {
  final MatchModel match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRequestDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        const Color(0xFF1565C0).withValues(alpha: 0.15),
                    child: Text(
                      match.userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Color(0xFF1565C0)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.userName,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          match.profile.department,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _CompatibilityRing(score: match.compatibilityScore),
                ],
              ),
              if (match.commonInterests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: match.commonInterests
                      .map((i) => Chip(
                            label: Text(i,
                                style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRequestDialog(BuildContext context, WidgetRef ref) async {
    final messageCtrl =
        TextEditingController(text: 'Hi, I would love to connect!');
    final topicsCtrl = TextEditingController();
    String duration = 'THREE_MONTHS';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Connect with ${match.userName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Topics (comma-separated)',
                    hintText: 'Machine Learning, Career Guidance',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: duration,
                  decoration: const InputDecoration(
                    labelText: 'Proposed Duration',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'ONE_MONTH', child: Text('1 Month')),
                    DropdownMenuItem(
                        value: 'THREE_MONTHS', child: Text('3 Months')),
                    DropdownMenuItem(
                        value: 'SIX_MONTHS', child: Text('6 Months')),
                    DropdownMenuItem(
                        value: 'ONE_YEAR', child: Text('1 Year')),
                  ],
                  onChanged: (v) => setDlg(() => duration = v ?? duration),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Send')),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final topics = topicsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final ok = await ref.read(mentorshipProvider.notifier).requestMentor(
            mentorId: match.userId,
            message: messageCtrl.text.trim(),
            topics: topics,
            proposedDuration: duration,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Request sent!' : 'Failed to send request.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ));
      }
    }
  }
}

class _CompatibilityRing extends StatelessWidget {
  final double score;
  const _CompatibilityRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).toInt();
    final color = score >= 0.75
        ? const Color(0xFF2E7D32)
        : score >= 0.5
            ? const Color(0xFF00897B)
            : Colors.orange;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            strokeWidth: 4,
          ),
          Center(
            child: Text(
              '$pct',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Requests tab
// ─────────────────────────────────────────────

class _RequestsTab extends ConsumerWidget {
  final List<MentorshipRequestModel> requests;
  const _RequestsTab({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return const Center(child: Text('No pending requests.'));
    }

    final currentUser = ref.watch(currentUserProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(mentorshipProvider.notifier).loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final req = requests[i];
          final isReceived = req.menteeName != currentUser?.username;
          return _RequestCard(req: req, isReceived: isReceived);
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final MentorshipRequestModel req;
  final bool isReceived;
  const _RequestCard({required this.req, required this.isReceived});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':   return Colors.orange;
      case 'ACCEPTED':  return Colors.green;
      case 'REJECTED':  return Colors.red;
      case 'CANCELLED': return Colors.grey;
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isReceived
                        ? 'From: ${req.menteeName}'
                        : 'To: ${req.mentorName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(req.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    req.status,
                    style: TextStyle(
                      color: _statusColor(req.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Message ───────────────────────────────────────────────────
            Text(
              '"${req.message}"',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            // ── Topics ────────────────────────────────────────────────────
            if (req.topics.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: req.topics
                    .map((t) => Chip(
                          label: Text(t,
                              style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            // ── Duration + date ───────────────────────────────────────────
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    size: 14, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 4),
                Text(
                  '${req.proposedDuration.replaceAll('_', ' ')} · ${timeAgo(req.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            // ── Rejection reason ──────────────────────────────────────────
            if (req.status == 'REJECTED' &&
                req.rejectionReason != null &&
                req.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${req.rejectionReason}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            // ── Accept / Decline ──────────────────────────────────────────
            if (isReceived && req.status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _reject(context, ref),
                    child: const Text('Decline',
                        style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _accept(context, ref),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(mentorshipProvider.notifier)
        .respondRequest(req.id, 'ACCEPTED');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Request accepted.' : 'Failed to accept.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Request'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Decline')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(mentorshipProvider.notifier)
          .respondRequest(req.id, 'REJECTED',
              rejectionReason: reasonCtrl.text.trim().isEmpty
                  ? null
                  : reasonCtrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Request declined.' : 'Failed to decline.'),
        ));
      }
    }
  }
}

// ─────────────────────────────────────────────
// Active relationships tab
// ─────────────────────────────────────────────

class _ActiveTab extends ConsumerWidget {
  final List<RelationshipModel> relationships;
  const _ActiveTab({required this.relationships});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (relationships.isEmpty) {
      return const Center(child: Text('No active mentorships.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(mentorshipProvider.notifier).loadAll(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: relationships.length,
        itemBuilder: (_, i) => _RelationshipCard(rel: relationships[i]),
      ),
    );
  }
}

class _RelationshipCard extends ConsumerWidget {
  final RelationshipModel rel;
  const _RelationshipCard({required this.rel});

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':    return Colors.green;
      case 'PAUSED':    return Colors.orange;
      case 'COMPLETED': return Colors.grey;
      default:          return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final otherName = rel.menteeName == currentUser?.username
        ? rel.mentorName
        : rel.menteeName;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showUpdateSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.handshake_rounded,
                        color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(otherName,
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        Text(
                          'Started ${timeAgo(rel.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(rel.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rel.status,
                      style: TextStyle(
                        color: _statusColor(rel.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              // ── Goals ────────────────────────────────────────────────────
              if (rel.goals.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        rel.goals,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              // ── Cadence ──────────────────────────────────────────────────
              if (rel.frequency.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.repeat_outlined,
                        size: 14, color: Color(0xFF9E9E9E)),
                    const SizedBox(width: 4),
                    Text(
                      '${rel.frequency.replaceAll('_', ' ')} · ${rel.preferredChannel.replaceAll('_', ' ')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // ── Action row ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.star_rate_rounded,
                        size: 16, color: Colors.amber),
                    label: const Text('Feedback'),
                    onPressed: () => _showFeedbackSheet(context, ref),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    icon: const Icon(Icons.exit_to_app,
                        size: 16, color: Colors.red),
                    label: const Text('End',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => _confirmEnd(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Update relationship sheet ────────────────────────────────────────────

  void _showUpdateSheet(BuildContext context, WidgetRef ref) {
    final goalsCtrl = TextEditingController(text: rel.goals);
    String frequency =
        rel.frequency.isNotEmpty ? rel.frequency : 'BIWEEKLY';
    String channel =
        rel.preferredChannel.isNotEmpty ? rel.preferredChannel : 'VIDEO_CALL';
    String status = rel.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Update Relationship',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: goalsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Goals',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: frequency,
                decoration: const InputDecoration(
                    labelText: 'Frequency', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                  DropdownMenuItem(
                      value: 'BIWEEKLY', child: Text('Biweekly')),
                  DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                ],
                onChanged: (v) =>
                    setSheet(() => frequency = v ?? frequency),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: channel,
                decoration: const InputDecoration(
                    labelText: 'Preferred Channel',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                  DropdownMenuItem(value: 'PHONE', child: Text('Phone')),
                  DropdownMenuItem(
                      value: 'VIDEO_CALL', child: Text('Video Call')),
                  DropdownMenuItem(
                      value: 'IN_PERSON', child: Text('In Person')),
                  DropdownMenuItem(
                      value: 'MESSAGING', child: Text('Messaging')),
                ],
                onChanged: (v) => setSheet(() => channel = v ?? channel),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                    labelText: 'Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'PAUSED', child: Text('Paused')),
                  DropdownMenuItem(
                      value: 'COMPLETED', child: Text('Completed')),
                ],
                onChanged: (v) => setSheet(() => status = v ?? status),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('Save Changes'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await ref
                      .read(mentorshipProvider.notifier)
                      .updateRelationship(rel.id, {
                    'goals': goalsCtrl.text.trim(),
                    'frequency': frequency,
                    'preferredChannel': channel,
                    'status': status,
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          ok ? 'Relationship updated.' : 'Update failed.'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Feedback sheet ───────────────────────────────────────────────────────

  void _showFeedbackSheet(BuildContext context, WidgetRef ref) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Submit Feedback',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setSheet(() => rating = i + 1),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('View Past Feedback'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showFeedbackHistory(context, ref);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                child: const Text('Submit'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await ref
                      .read(mentorshipProvider.notifier)
                      .submitFeedback(
                          rel.id, rating, commentCtrl.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          ok ? 'Feedback submitted!' : 'Failed to submit.'),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Feedback history ─────────────────────────────────────────────────────

  void _showFeedbackHistory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FutureBuilder<List<FeedbackModel>>(
        future: ref.read(mentorshipProvider.notifier).getFeedback(rel.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final feedbacks = snap.data ?? [];
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.5,
            builder: (_, ctrl) => ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(16),
              children: [
                Text('Feedback History',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (feedbacks.isEmpty)
                  const Text('No feedback yet.')
                else
                  ...feedbacks.map((f) => _FeedbackTile(feedback: f)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── End relationship ─────────────────────────────────────────────────────

  Future<void> _confirmEnd(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Relationship'),
        content: const Text(
            'Are you sure you want to end this mentorship? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(mentorshipProvider.notifier)
          .endRelationship(rel.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              ok ? 'Relationship ended.' : 'Failed to end relationship.'),
          backgroundColor: ok ? Colors.red : Colors.grey,
        ));
      }
    }
  }
}

// ─────────────────────────────────────────────
// Feedback tile
// ─────────────────────────────────────────────

class _FeedbackTile extends StatelessWidget {
  final FeedbackModel feedback;
  const _FeedbackTile({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < feedback.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo(feedback.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (feedback.comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(feedback.comment),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Edit profile bottom sheet
// ─────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final MentorshipProfileModel? existing;
  const _EditProfileSheet({this.existing});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _bioCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _expertiseCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  String _role = 'MENTEE';
  String _availability = 'AVAILABLE';

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _bioCtrl.text = p.bio;
      _deptCtrl.text = p.department;
      _expertiseCtrl.text = p.expertise.join(', ');
      _interestsCtrl.text = p.interests.join(', ');
      _expCtrl.text = p.yearsOfExperience.toString();
      _role = p.role;
      _availability = p.availability;
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _deptCtrl.dispose();
    _expertiseCtrl.dispose();
    _interestsCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  List<String> _split(String raw) => raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('My Mentorship Profile',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(
                  labelText: 'Role', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'MENTOR', child: Text('Mentor')),
                DropdownMenuItem(value: 'MENTEE', child: Text('Mentee')),
                DropdownMenuItem(value: 'BOTH', child: Text('Both')),
              ],
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deptCtrl,
              decoration: const InputDecoration(
                  labelText: 'Department', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expertiseCtrl,
              decoration: const InputDecoration(
                  labelText: 'Expertise (comma-separated)',
                  hintText: 'Java, React, ML',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _interestsCtrl,
              decoration: const InputDecoration(
                  labelText: 'Interests (comma-separated)',
                  hintText: 'Machine Learning, Web Development',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Bio', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _availability,
              decoration: const InputDecoration(
                  labelText: 'Availability', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: 'HIGHLY_AVAILABLE',
                    child: Text('Highly Available')),
                DropdownMenuItem(
                    value: 'AVAILABLE', child: Text('Available')),
                DropdownMenuItem(value: 'LIMITED', child: Text('Limited')),
                DropdownMenuItem(
                    value: 'NOT_AVAILABLE', child: Text('Not Available')),
              ],
              onChanged: (v) =>
                  setState(() => _availability = v ?? _availability),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Save Profile'),
              onPressed: () async {
                Navigator.pop(context);
                final ok = await ref
                    .read(mentorshipProvider.notifier)
                    .saveProfile({
                  'role': _role,
                  'department': _deptCtrl.text.trim(),
                  'yearsOfExperience':
                      int.tryParse(_expCtrl.text.trim()) ?? 0,
                  'expertise': _split(_expertiseCtrl.text),
                  'interests': _split(_interestsCtrl.text),
                  'bio': _bioCtrl.text.trim(),
                  'availability': _availability,
                  'timezone': 'Asia/Colombo',
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text(ok ? 'Profile saved!' : 'Save failed.'),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}