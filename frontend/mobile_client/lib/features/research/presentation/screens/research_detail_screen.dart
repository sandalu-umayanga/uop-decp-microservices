import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/research_remote_datasource.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_utils.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const surface       = Color(0xFFFFFFFF);
  static const surfaceAlt    = Color(0xFFF8FAFC);
  static const border        = Color(0xFFE2E8F0);
  static const borderSoft    = Color(0xFFEEF2F7);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted     = Color(0xFF94A3B8);
  static const error         = Color(0xFFEF4444);
  static const errorLight    = Color(0xFFFEF2F2);
}

// ─── Category Meta ────────────────────────────────────────────────────────────
class _CatMeta {
  final Color color;
  final Color light;
  final IconData icon;
  final String label;
  const _CatMeta({
    required this.color,
    required this.light,
    required this.icon,
    required this.label,
  });
}

const _categoryMeta = <String, _CatMeta>{
  'PAPER':      _CatMeta(color: Color(0xFF1565C0), light: Color(0xFFE3F2FD),
                          icon: Icons.article_rounded,        label: 'Paper'),
  'THESIS':     _CatMeta(color: Color(0xFF6A1B9A), light: Color(0xFFF3E5F5),
                          icon: Icons.school_rounded,         label: 'Thesis'),
  'PROJECT':    _CatMeta(color: Color(0xFF0277BD), light: Color(0xFFE1F5FE),
                          icon: Icons.folder_special_rounded,  label: 'Project'),
  'ARTICLE':    _CatMeta(color: Color(0xFF00838F), light: Color(0xFFE0F7FA),
                          icon: Icons.newspaper_rounded,      label: 'Article'),
  'CONFERENCE': _CatMeta(color: Color(0xFFF57C00), light: Color(0xFFFFF3E0),
                          icon: Icons.groups_rounded,         label: 'Conference'),
  'WORKSHOP':   _CatMeta(color: Color(0xFFAD1457), light: Color(0xFFFCE4EC),
                          icon: Icons.build_rounded,          label: 'Workshop'),
};

_CatMeta _meta(String cat) =>
    _categoryMeta[cat] ??
    const _CatMeta(
      color: Color(0xFF1565C0),
      light: Color(0xFFE3F2FD),
      icon: Icons.science_rounded,
      label: 'Research',
    );

String _tagLabel(String t) =>
    t.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

// ─── Research Detail Screen ───────────────────────────────────────────────────
class ResearchDetailScreen extends ConsumerWidget {
  final int researchId;
  const ResearchDetailScreen({super.key, required this.researchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final researchAsync = ref.watch(singleResearchProvider(researchId));
    final user          = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: researchAsync.whenData((r) {
            final m = _meta(r.category);
            final canDelete = user?.role == 'ADMIN' ||
                (r.createdBy != null && r.createdBy == user?.id);
            return Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.pop(),
                ),
              ],
            );
          }).value ??
              _CircleButton(
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
      body: researchAsync.when(
        loading: () => const AppLoadingWidget(message: 'Loading research…'),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (r) {
          final m = _meta(r.category);
          final canDelete = user?.role == 'ADMIN' ||
              (r.createdBy != null && r.createdBy == user?.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Header ──
                _HeroHeader(r: r, m: m, canDelete: canDelete,
                    onDelete: () => _confirmDelete(context, ref, r.id!)),

                // ── Stats row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _StatsRow(
                    views: r.views,
                    downloads: r.downloads,
                    citations: r.citations,
                    color: m.color,
                  ),
                ),

                // ── Authors ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _SectionCard(
                    title: 'Authors',
                    icon: Icons.people_alt_rounded,
                    color: m.color,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: r.authors.map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: m.light,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: m.color.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: m.color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  a.isNotEmpty
                                      ? a[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: m.color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(a,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: m.color,
                                )),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),

                // ── DOI ──
                if (r.doi != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _SectionCard(
                      title: 'Identifier',
                      icon: Icons.fingerprint_rounded,
                      color: m.color,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'DOI: ${r.doi}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: _AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded,
                                size: 16, color: _AppColors.textMuted),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: r.doi!));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('DOI copied'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Tags ──
                if (r.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _SectionCard(
                      title: 'Tags',
                      icon: Icons.label_rounded,
                      color: m.color,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: r.tags.map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _AppColors.border),
                          ),
                          child: Text(
                            _tagLabel(t),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _AppColors.textSecondary,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),

                // ── Abstract ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _SectionCard(
                    title: 'Abstract',
                    icon: Icons.subject_rounded,
                    color: m.color,
                    child: Text(
                      r.researchAbstract,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: _AppColors.textPrimary,
                        height: 1.65,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                // ── Publication info ──
                if (r.createdByName != null || r.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _SectionCard(
                      title: 'Publication Info',
                      icon: Icons.info_outline_rounded,
                      color: m.color,
                      child: Column(
                        children: [
                          if (r.createdByName != null)
                            _MetaRow(
                              icon: Icons.person_rounded,
                              label: 'Posted by',
                              value: r.createdByName!,
                            ),
                          if (r.createdAt != null) ...[
                            const SizedBox(height: 6),
                            _MetaRow(
                              icon: Icons.schedule_rounded,
                              label: 'Published',
                              value: timeAgo(r.createdAt!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Download button ──
                if (r.documentUrl != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(researchDatasourceProvider)
                              .download(r.id!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content:
                                  Text('Document: ${r.documentUrl}'),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: m.color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          shadowColor: m.color.withOpacity(0.35),
                        ),
                        icon: const Icon(Icons.download_rounded,
                            size: 20),
                        label: const Text('Download Paper',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                  ),

                // ── Delete button ──
                if (canDelete) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmDelete(context, ref, r.id!),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _AppColors.error,
                          side: BorderSide(
                              color: _AppColors.error.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18),
                        label: const Text('Delete Research',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Research',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text(
            'This will permanently remove the research publication. '
            'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref.read(researchProvider.notifier).delete(id);
      if (context.mounted) {
        if (ok) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final dynamic r;
  final _CatMeta m;
  final bool canDelete;
  final VoidCallback onDelete;
  const _HeroHeader({
    required this.r,
    required this.m,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [m.color, Color.lerp(m.color, Colors.black, 0.2)!],
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
          // Category badge + delete badge row
          Row(
            children: [
              // Category badge
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
                    Icon(m.icon, size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      m.label.toUpperCase(),
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
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 12, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'DELETE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            r.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          // Primary author
          if (r.authors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_rounded,
                    size: 13, color: Colors.white60),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    r.authors.length == 1
                        ? r.authors.first
                        : '${r.authors.first} + ${r.authors.length - 1} more',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// ─── Stats Row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int views;
  final int downloads;
  final int citations;
  final Color color;
  const _StatsRow({
    required this.views,
    required this.downloads,
    required this.citations,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatBox(
            icon: Icons.visibility_rounded,
            label: 'Views', value: views, color: color)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(
            icon: Icons.download_rounded,
            label: 'Downloads', value: downloads, color: color)),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(
            icon: Icons.format_quote_rounded,
            label: 'Citations', value: citations, color: color)),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatBox({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text('$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                fontSize: 10,
                color: _AppColors.textMuted,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  const _SectionCard({
    required this.title, required this.icon,
    required this.color, required this.child,
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
                Icon(icon, size: 15, color: color),
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

// ─── Meta Row ─────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow({
    required this.icon, required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13,
                color: _AppColors.textMuted,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: _AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
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