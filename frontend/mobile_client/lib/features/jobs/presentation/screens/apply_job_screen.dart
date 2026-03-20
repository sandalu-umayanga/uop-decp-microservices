import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/jobs_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';

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

// ─── Apply Job Screen ─────────────────────────────────────────────────────────
// This screen is navigated to via context.push('/jobs/$jobId/apply').
// It shows a styled full-screen sheet rather than a bare Scaffold form.
class ApplyJobScreen extends ConsumerStatefulWidget {
  final int jobId;
  const ApplyJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<ApplyJobScreen> createState() => _ApplyJobScreenState();
}

class _ApplyJobScreenState extends ConsumerState<ApplyJobScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _whyCtrl          = TextEditingController();
  final _resumeCtrl       = TextEditingController();
  bool  _submitting       = false;
  String? _error;

  @override
  void dispose() {
    _whyCtrl.dispose();
    _resumeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _submitting = true; _error = null; });

    final ok = await ref.read(jobsProvider.notifier).applyToJob(
          widget.jobId,
          _whyCtrl.text.trim(),
          _resumeCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ref.invalidate(userApplicationsProvider);
      ref.invalidate(jobsProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Application submitted!'),
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } else {
      setState(
          () => _error = 'Failed to submit application. Please try again.');
    }
  }

  InputDecoration _deco(String label, String hint, {Widget? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            const TextStyle(fontSize: 13, color: _C.textSec),
        hintStyle:
            const TextStyle(fontSize: 14, color: _C.textMuted),
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
            borderSide:
                const BorderSide(color: _C.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _C.error, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    final jobAsync          = ref.watch(singleJobProvider(widget.jobId));
    final applicationsAsync = ref.watch(userApplicationsProvider);

    return Scaffold(
      backgroundColor: _C.surfaceAlt,
      appBar: AppBar(
        backgroundColor: _C.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Apply for Job',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.0),
              ]),
            ),
          ),
        ),
      ),
      body: jobAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (job) => applicationsAsync.when(
          loading: () => const AppLoadingWidget(),
          error: (e, _) => AppErrorWidget(message: e.toString()),
          data: (applications) {
            final hasApplied =
                applications.any((app) => app.jobId == job.id);

            if (hasApplied) {
              return _AlreadyApplied(jobTitle: job.title);
            }
            if (job.status != 'OPEN') {
              return _PositionClosed(jobTitle: job.title);
            }

            return _ApplicationForm(
              job: job,
              formKey: _formKey,
              whyCtrl: _whyCtrl,
              resumeCtrl: _resumeCtrl,
              submitting: _submitting,
              error: _error,
              onSubmit: _submit,
              fieldDeco: _deco,
            );
          },
        ),
      ),
    );
  }
}

// ─── Application Form ─────────────────────────────────────────────────────────
class _ApplicationForm extends StatelessWidget {
  final dynamic job;
  final GlobalKey<FormState> formKey;
  final TextEditingController whyCtrl;
  final TextEditingController resumeCtrl;
  final bool submitting;
  final String? error;
  final VoidCallback onSubmit;
  final InputDecoration Function(String, String, {Widget? prefix}) fieldDeco;

  const _ApplicationForm({
    required this.job,
    required this.formKey,
    required this.whyCtrl,
    required this.resumeCtrl,
    required this.submitting,
    required this.error,
    required this.onSubmit,
    required this.fieldDeco,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job summary card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.borderSoft),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: _C.accentLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _C.accent.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.business_rounded,
                        color: _C.accent, size: 22),
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
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section header
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: _C.accentLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send_rounded,
                      color: _C.accent, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Application',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.text,
                            letterSpacing: -0.4,
                          )),
                      Text('Stand out with a strong application',
                          style: TextStyle(
                              fontSize: 12, color: _C.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Resume URL
            TextFormField(
              controller: resumeCtrl,
              style: const TextStyle(fontSize: 14, color: _C.text),
              decoration: fieldDeco(
                'Resume URL',
                'https://example.com/your-resume.pdf',
                prefix: const Icon(Icons.link_rounded,
                    size: 18, color: _C.textMuted),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your resume URL';
                }
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.isAbsolute) {
                  return 'Enter a valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Why interested
            TextFormField(
              controller: whyCtrl,
              maxLines: 7,
              minLines: 4,
              style: const TextStyle(
                  fontSize: 14, color: _C.text, height: 1.5),
              decoration: fieldDeco(
                'Why are you interested?',
                'Tell us about yourself and why you\'re a great fit…',
                prefix: const Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.edit_note_rounded,
                      size: 18, color: _C.textMuted),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 20) {
                  return 'Must be at least 20 characters';
                }
                return null;
              },
            ),

            // Error
            if (error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _C.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: _C.error.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: _C.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(error!,
                          style: const TextStyle(
                              fontSize: 13,
                              color: _C.error,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: submitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _C.accent.withOpacity(0.4),
                  disabledForegroundColor: Colors.white60,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  shadowColor: _C.accent.withOpacity(0.35),
                ),
                icon: submitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  submitting ? 'Submitting…' : 'Submit Application',
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

// ─── Already Applied ──────────────────────────────────────────────────────────
class _AlreadyApplied extends StatelessWidget {
  final String jobTitle;
  const _AlreadyApplied({required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: _C.violetLight,
                  borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.check_circle_rounded,
                  size: 40, color: _C.violet),
            ),
            const SizedBox(height: 20),
            const Text('Already Applied',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                  letterSpacing: -0.4,
                )),
            const SizedBox(height: 8),
            Text(
              'You have already submitted an application for $jobTitle.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: _C.textSec,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Position Closed ──────────────────────────────────────────────────────────
class _PositionClosed extends StatelessWidget {
  final String jobTitle;
  const _PositionClosed({required this.jobTitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: _C.errorLight,
                  borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.block_rounded,
                  size: 40, color: _C.error),
            ),
            const SizedBox(height: 20),
            const Text('Position Closed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _C.text,
                  letterSpacing: -0.4,
                )),
            const SizedBox(height: 8),
            Text(
              'Applications for $jobTitle are no longer being accepted.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  color: _C.textSec,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}