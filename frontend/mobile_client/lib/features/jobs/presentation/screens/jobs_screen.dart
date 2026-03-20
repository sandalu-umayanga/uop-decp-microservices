import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/jobs_provider.dart';
import '../../data/models/job_model.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/date_utils.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const accent      = Color(0xFF1565C0);
  static const accentLight = Color(0xFFE3F2FD);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFF4F7FB);
  static const border      = Color(0xFFE2E8F0);
  static const borderSoft  = Color(0xFFEEF2F7);
  static const text        = Color(0xFF0F172A);
  static const textSec     = Color(0xFF475569);
  static const textMuted   = Color(0xFF94A3B8);
  static const green       = Color(0xFF2E7D32);
  static const greenLight  = Color(0xFFE8F5E9);
  static const error       = Color(0xFFEF4444);
  static const errorLight  = Color(0xFFFEF2F2);
  static const violet      = Color(0xFF7C3AED);
  static const violetLight = Color(0xFFEDE9FE);
}

// ─── Jobs Screen ──────────────────────────────────────────────────────────────
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabCtrl;
  late final Animation<double>   _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    Future.microtask(() {
      ref.read(jobsProvider.notifier).loadJobs();
      _fabCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _showPostJobSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PostJobSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state           = ref.watch(jobsProvider);
    final user            = ref.watch(currentUserProvider);
    final applicationsAsync = ref.watch(userApplicationsProvider);
    final canCreate = user?.role == 'ALUMNI' || user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: _C.surfaceAlt,
      floatingActionButton: canCreate
          ? ScaleTransition(
              scale: _fabAnim,
              child: FloatingActionButton.extended(
                onPressed: _showPostJobSheet,
                backgroundColor: _C.accent,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Post Job',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2)),
              ),
            )
          : null,
      body: Builder(builder: (_) {
        if (state.isLoading && state.jobs.isEmpty) {
          return const AppLoadingWidget(message: 'Loading jobs…');
        }
        if (state.error != null && state.jobs.isEmpty) {
          return AppErrorWidget(
            message: state.error!,
            onRetry: () => ref.read(jobsProvider.notifier).loadJobs(),
          );
        }

        return RefreshIndicator(
          color: _C.accent,
          backgroundColor: _C.surface,
          onRefresh: () => ref.read(jobsProvider.notifier).loadJobs(),
          child: state.jobs.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: state.jobs.length,
                  itemBuilder: (_, i) {
                    final job = state.jobs[i];
                    return applicationsAsync.when(
                      loading: () => _JobCard(job: job, index: i),
                      error:   (_, __) => _JobCard(job: job, index: i),
                      data: (applications) => _JobCard(
                        job: job,
                        index: i,
                        hasApplied:
                            applications.any((a) => a.jobId == job.id),
                      ),
                    );
                  },
                ),
        );
      }),
    );
  }
}

// ─── Post Job Sheet ───────────────────────────────────────────────────────────
class _PostJobSheet extends ConsumerStatefulWidget {
  const _PostJobSheet();

  @override
  ConsumerState<_PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends ConsumerState<_PostJobSheet> {
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _companyCtrl  = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl     = TextEditingController();
  String _type        = 'FULL_TIME';
  bool   _submitting  = false;
  String? _error;

  static const _types = {
    'FULL_TIME':  'Full-time',
    'PART_TIME':  'Part-time',
    'INTERNSHIP': 'Internship',
    'CONTRACT':   'Contract',
    'REMOTE':     'Remote',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _submitting = true; _error = null; });

    final ok = await ref.read(jobsProvider.notifier).createJob(
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      company:     _companyCtrl.text.trim(),
      location:    _locationCtrl.text.trim(),
      type:        _type,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Job listing posted!'),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      setState(() => _error = 'Failed to post job. Please try again.');
    }
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
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.error, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: _C.accentLight,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.work_rounded,
                        color: _C.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Post a Job',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _C.text,
                              letterSpacing: -0.5,
                            )),
                        Text('Fill in the details below',
                            style: TextStyle(
                                fontSize: 13, color: _C.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Job Title
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 14, color: _C.text),
                decoration: _deco('Job Title', 'e.g. Senior Flutter Developer',
                    prefix: const Icon(Icons.work_outline_rounded,
                        size: 18, color: _C.textMuted)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Company
              TextFormField(
                controller: _companyCtrl,
                style: const TextStyle(fontSize: 14, color: _C.text),
                decoration: _deco('Company', 'e.g. Acme Corp',
                    prefix: const Icon(Icons.business_rounded,
                        size: 18, color: _C.textMuted)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Company is required'
                    : null,
              ),
              const SizedBox(height: 12),

              // Location
              TextFormField(
                controller: _locationCtrl,
                style: const TextStyle(fontSize: 14, color: _C.text),
                decoration: _deco('Location', 'e.g. Colombo, Sri Lanka',
                    prefix: const Icon(Icons.location_on_rounded,
                        size: 18, color: _C.textMuted)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Location is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Job Type chips
              const Text('Job Type',
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
                children: _types.entries.map((e) {
                  final sel = _type == e.key;
                  return GestureDetector(
                    onTap: () => setState(() => _type = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? _C.accent : _C.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? _C.accent : _C.border),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : _C.textSec,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(fontSize: 14, color: _C.text),
                decoration: _deco(
                  'Description',
                  'Describe the role, responsibilities, requirements…',
                  prefix: const Padding(
                    padding: EdgeInsets.only(bottom: 64),
                    child: Icon(Icons.description_rounded,
                        size: 18, color: _C.textMuted),
                  ),
                ),
                validator: (v) => (v == null || v.trim().length < 20)
                    ? 'Description must be at least 20 characters'
                    : null,
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.errorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _C.error.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: _C.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: _C.error,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _C.accent.withOpacity(0.4),
                    disabledForegroundColor: Colors.white60,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.publish_rounded, size: 18),
                  label: Text(
                    _submitting ? 'Posting…' : 'Post Job Listing',
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

// ─── Job Card ─────────────────────────────────────────────────────────────────
class _JobCard extends StatefulWidget {
  final JobModel job;
  final bool hasApplied;
  final int index;
  const _JobCard({
    required this.job,
    this.hasApplied = false,
    required this.index,
  });

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard>
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
            milliseconds: 380 + (widget.index * 55).clamp(0, 400)));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 55),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final job      = widget.job;
    final isOpen   = job.status == 'OPEN';

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
              onTap: () => context.push('/jobs/${job.id}'),
              splashColor: _C.accentLight,
              highlightColor: _C.accentLight.withOpacity(0.5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.hasApplied
                        ? _C.violet.withOpacity(0.3)
                        : _C.borderSoft,
                    width: widget.hasApplied ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.hasApplied
                          ? _C.violet.withOpacity(0.06)
                          : Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company icon
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _C.accentLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _C.accent.withOpacity(0.15)),
                          ),
                          child: const Icon(Icons.business_rounded,
                              color: _C.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _C.text,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(job.company,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _C.accent,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(isOpen: isOpen, status: job.status),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.transparent,
                          _C.border,
                          Colors.transparent,
                        ]),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Meta row
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: _C.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(job.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _C.textSec,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis),
                        ),
                        _TypePill(type: job.type),
                        const SizedBox(width: 8),
                        if (job.createdAt != null)
                          Text(timeAgo(job.createdAt!),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _C.textMuted)),
                      ],
                    ),

                    // Applied badge
                    if (widget.hasApplied) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _C.violetLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _C.violet.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_rounded,
                                size: 12, color: _C.violet),
                            SizedBox(width: 5),
                            Text('You applied',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _C.violet,
                                  letterSpacing: 0.1,
                                )),
                          ],
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
    );
  }
}

// ─── Status Pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final bool isOpen;
  final String status;
  const _StatusPill({required this.isOpen, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? _C.green : _C.error;
    final light = isOpen ? _C.greenLight : _C.errorLight;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: light,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }
}

// ─── Type Pill ────────────────────────────────────────────────────────────────
class _TypePill extends StatelessWidget {
  final String type;
  const _TypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _C.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      child: Text(type,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _C.textSec,
          )),
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
                color: _C.accentLight,
                borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.work_off_rounded,
                size: 36, color: _C.accent),
          ),
          const SizedBox(height: 20),
          const Text('No jobs available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _C.text,
              )),
          const SizedBox(height: 8),
          const Text('Check back later for new opportunities',
              style: TextStyle(fontSize: 14, color: _C.textMuted)),
        ],
      ),
    );
  }
}