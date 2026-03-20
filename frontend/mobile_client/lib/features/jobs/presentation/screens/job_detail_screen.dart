import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/jobs_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/date_utils.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const surface       = Color(0xFFFFFFFF);
  static const surfaceAlt    = Color(0xFFF8FAFC);
  static const border        = Color(0xFFE2E8F0);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted     = Color(0xFF94A3B8);
  static const accent        = Color(0xFF1565C0);
  static const accentLight   = Color(0xFFE3F2FD);
  static const error         = Color(0xFFEF4444);
  static const errorLight    = Color(0xFFFEE2E2);
  static const violet        = Color(0xFF7C3AED);
  static const violetLight   = Color(0xFFEDE9FE);
}

// ─── Job Type Theming ─────────────────────────────────────────────────────────
Color _typeColor(String type) => switch (type.toUpperCase()) {
      'FULL_TIME'  || 'FULL-TIME'  => const Color(0xFF1565C0),
      'PART_TIME'  || 'PART-TIME'  => const Color(0xFF0277BD),
      'INTERNSHIP'                 => const Color(0xFF00838F),
      'CONTRACT'                   => const Color(0xFF6A1B9A),
      'REMOTE'                     => const Color(0xFF2E7D32),
      _                            => const Color(0xFF1565C0),
    };

Color _typeLight(String type) => switch (type.toUpperCase()) {
      'FULL_TIME'  || 'FULL-TIME'  => const Color(0xFFE3F2FD),
      'PART_TIME'  || 'PART-TIME'  => const Color(0xFFE1F5FE),
      'INTERNSHIP'                 => const Color(0xFFE0F7FA),
      'CONTRACT'                   => const Color(0xFFF3E5F5),
      'REMOTE'                     => const Color(0xFFE8F5E9),
      _                            => const Color(0xFFE3F2FD),
    };

IconData _typeIcon(String type) => switch (type.toUpperCase()) {
      'FULL_TIME'  || 'FULL-TIME'  => Icons.work_rounded,
      'PART_TIME'  || 'PART-TIME'  => Icons.work_outline_rounded,
      'INTERNSHIP'                 => Icons.school_rounded,
      'CONTRACT'                   => Icons.handshake_rounded,
      'REMOTE'                     => Icons.home_work_rounded,
      _                            => Icons.work_rounded,
    };

String _typeLabel(String type) =>
    type.replaceAll('_', ' ').replaceAll('-', ' ').split(' ')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

// ─── Job Detail Screen ────────────────────────────────────────────────────────
class JobDetailScreen extends ConsumerStatefulWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  Future<void> _deleteJob(dynamic job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Job Listing',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text(
            'Are you sure you want to delete "${job.title}"? '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await ref.read(jobsProvider.notifier).deleteJob(job.id);
      if (ok && mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync          = ref.watch(singleJobProvider(widget.jobId));
    final user              = ref.watch(currentUserProvider);
    final applicationsAsync = ref.watch(userApplicationsProvider);

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
              onTap: () {},
            ),
          ),
        ],
      ),
      body: jobAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (job) {
          final isOpen    = job.status == 'OPEN';
          final jobColor  = _typeColor(job.type);
          final isStudent = user?.role == 'STUDENT';
          final isPoster  = user?.id == job.postedBy;
          final isAdmin   = user?.role == 'ADMIN';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Header ──
                _HeroHeader(
                    job: job, jobColor: jobColor, isOpen: isOpen),

                // ── Quick Info Grid ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _QuickInfoGrid(
                      job: job, jobColor: jobColor),
                ),

                // ── Applicants ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _SectionCard(
                    title: 'Applications',
                    icon: Icons.people_alt_rounded,
                    catColor: jobColor,
                    child: _ApplicantStat(
                        count: job.applicationCount,
                        color: jobColor),
                  ),
                ),

                // ── Description ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _SectionCard(
                    title: 'About the Role',
                    icon: Icons.description_outlined,
                    catColor: jobColor,
                    child: Text(
                      job.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: _AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                // ── Apply section (students only) ──
                if (isStudent)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _SectionCard(
                      title: 'Your Application',
                      icon: Icons.send_rounded,
                      catColor: jobColor,
                      child: applicationsAsync.when(
                        loading: () => const Center(
                            child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        )),
                        error: (e, _) =>
                            AppErrorWidget(message: e.toString()),
                        data: (applications) {
                          final hasApplied = applications
                              .any((a) => a.jobId == job.id);
                          return _ApplyWidget(
                            jobId: job.id,
                            jobColor: jobColor,
                            isOpen: isOpen,
                            hasApplied: hasApplied,
                          );
                        },
                      ),
                    ),
                  ),

                // ── Poster / Admin actions ──
                if (isPoster || isAdmin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _SectionCard(
                      title: 'Poster Actions',
                      icon: Icons.admin_panel_settings_rounded,
                      catColor: jobColor,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _AppColors.error,
                            side: const BorderSide(
                                color: _AppColors.error),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          onPressed: () => _deleteJob(job),
                          icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18),
                          label: const Text('Delete Job Listing',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final dynamic job;
  final Color jobColor;
  final bool isOpen;
  const _HeroHeader({
    required this.job,
    required this.jobColor,
    required this.isOpen,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [jobColor, jobColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + status badge row
          Row(
            children: [
              // Job type badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon(job.type),
                        size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      _typeLabel(job.type).toUpperCase(),
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
              // Open/Closed status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF69F0AE)
                            : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      job.status,
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
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            job.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 8),

          // Company
          Row(
            children: [
              const Icon(Icons.business_rounded,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 5),
              Text(
                job.company,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (job.posterName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 13, color: Colors.white60),
                const SizedBox(width: 5),
                Text(
                  'Posted by ${job.posterName}',
                  style: const TextStyle(
                    fontSize: 12,
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
  final dynamic job;
  final Color jobColor;
  const _QuickInfoGrid({required this.job, required this.jobColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location full-width (mirrors event location tile)
        _InfoTile(
          icon: Icons.location_on_rounded,
          label: 'Location',
          value: job.location,
          color: jobColor,
          fullWidth: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _InfoTile(
              icon: Icons.work_rounded,
              label: 'Employment Type',
              value: _typeLabel(job.type),
              color: jobColor,
            ),
            const SizedBox(width: 10),
            if (job.createdAt != null)
              _InfoTile(
                icon: Icons.schedule_rounded,
                label: 'Posted',
                value: timeAgo(job.createdAt!),
                color: jobColor,
              ),
          ],
        ),
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
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textMuted,
                      letterSpacing: 0.3,
                    )),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
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

// ─── Applicant Stat ───────────────────────────────────────────────────────────
class _ApplicantStat extends StatelessWidget {
  final int count;
  final Color color;
  const _ApplicantStat({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1,
            )),
        const SizedBox(width: 8),
        const Text('people have applied',
            style: TextStyle(
              fontSize: 14,
              color: _AppColors.textMuted,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}

// ─── Apply Widget ─────────────────────────────────────────────────────────────
class _ApplyWidget extends StatelessWidget {
  final int? jobId;
  final Color jobColor;
  final bool isOpen;
  final bool hasApplied;
  const _ApplyWidget({
    required this.jobId,
    required this.jobColor,
    required this.isOpen,
    required this.hasApplied,
  });

  @override
  Widget build(BuildContext context) {
    if (hasApplied) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _AppColors.violetLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _AppColors.violet.withOpacity(0.25)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 16, color: _AppColors.violet),
            SizedBox(width: 8),
            Text('Application Submitted',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.violet,
                )),
          ],
        ),
      );
    }

    if (!isOpen) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _AppColors.errorLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _AppColors.error.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded,
                size: 16, color: _AppColors.error),
            SizedBox(width: 8),
            Text('Applications are closed',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.error,
                )),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/jobs/$jobId/apply'),
        style: ElevatedButton.styleFrom(
          backgroundColor: jobColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          shadowColor: jobColor.withOpacity(0.35),
        ),
        icon: const Icon(Icons.send_rounded, size: 18),
        label: const Text('Apply Now',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700)),
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
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _AppColors.textPrimary,
                      letterSpacing: -0.1,
                    )),
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

// ─── Circle Button ────────────────────────────────────────────────────────────
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
          width: 40, height: 40,
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