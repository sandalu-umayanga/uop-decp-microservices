import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/research_remote_datasource.dart';
import '../../data/models/research_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_utils.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _AppColors {
  static const accent       = Color(0xFF1565C0);
  static const accentMid    = Color(0xFF1976D2);
  static const accentLight  = Color(0xFFE3F2FD);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceAlt   = Color(0xFFF4F7FB);
  static const border       = Color(0xFFE2E8F0);
  static const borderSoft   = Color(0xFFEEF2F7);
  static const textPrimary  = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted    = Color(0xFF94A3B8);
  static const error        = Color(0xFFEF4444);
  static const purple       = Color(0xFF6A1B9A);
  static const purpleLight  = Color(0xFFF3E5F5);
}

// ─── Category Meta ────────────────────────────────────────────────────────────
class _CatMeta {
  final Color color;
  final Color light;
  final IconData icon;
  final String label;
  const _CatMeta({required this.color, required this.light,
      required this.icon, required this.label});
}

const _categoryMeta = <String, _CatMeta>{
  'PAPER':      _CatMeta(color: Color(0xFF1565C0), light: Color(0xFFE3F2FD),
                          icon: Icons.article_rounded,       label: 'Paper'),
  'THESIS':     _CatMeta(color: Color(0xFF6A1B9A), light: Color(0xFFF3E5F5),
                          icon: Icons.school_rounded,        label: 'Thesis'),
  'PROJECT':    _CatMeta(color: Color(0xFF0277BD), light: Color(0xFFE1F5FE),
                          icon: Icons.folder_special_rounded, label: 'Project'),
  'ARTICLE':    _CatMeta(color: Color(0xFF00838F), light: Color(0xFFE0F7FA),
                          icon: Icons.newspaper_rounded,     label: 'Article'),
  'CONFERENCE': _CatMeta(color: Color(0xFFF57C00), light: Color(0xFFFFF3E0),
                          icon: Icons.groups_rounded,        label: 'Conference'),
  'WORKSHOP':   _CatMeta(color: Color(0xFFAD1457), light: Color(0xFFFCE4EC),
                          icon: Icons.build_rounded,         label: 'Workshop'),
};

_CatMeta _meta(String cat) => _categoryMeta[cat] ??
    const _CatMeta(color: Color(0xFF1565C0), light: Color(0xFFE3F2FD),
                   icon: Icons.science_rounded, label: 'Research');

const _allCategories = ['PAPER', 'THESIS', 'PROJECT', 'ARTICLE', 'CONFERENCE', 'WORKSHOP'];

const _allTags = [
  'MACHINE_LEARNING', 'AI', 'BLOCKCHAIN', 'IOT',
  'CLOUD', 'DATA_SCIENCE', 'QUANTUM',
];

String _tagLabel(String t) =>
    t.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

// ─── Research Screen ──────────────────────────────────────────────────────────
class ResearchScreen extends ConsumerStatefulWidget {
  const ResearchScreen({super.key});

  @override
  ConsumerState<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends ConsumerState<ResearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;
  late final AnimationController _fabCtrl;
  late final Animation<double>   _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    Future.microtask(() {
      ref.read(researchProvider.notifier).loadResearch();
      _fabCtrl.forward();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  void _search() {
    final q = _searchCtrl.text.trim();
    ref.read(researchProvider.notifier).loadResearch(
        category: _selectedCategory,
        search: q.isEmpty ? null : q);
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateResearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(researchProvider);
    final user     = ref.watch(currentUserProvider);
    final canCreate = user?.role == 'ALUMNI' || user?.role == 'ADMIN';

    return Scaffold(
      backgroundColor: _AppColors.surfaceAlt,
      floatingActionButton: canCreate
          ? ScaleTransition(
              scale: _fabAnim,
              child: FloatingActionButton.extended(
                onPressed: _showCreateModal,
                backgroundColor: _AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New Research',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, letterSpacing: 0.2)),
              ),
            )
          : null,
      body: Column(
        children: [
          // ── Search bar ──
          Container(
            color: _AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onSubmitted: (_) => _search(),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontSize: 14, color: _AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search papers, authors…',
                        hintStyle: const TextStyle(
                            color: _AppColors.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: _AppColors.textMuted, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: _AppColors.textMuted),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                  ref
                                      .read(researchProvider.notifier)
                                      .loadResearch(
                                          category: _selectedCategory);
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
                // Category filter button
                _FilterButton(
                  selected: _selectedCategory,
                  categories: _allCategories,
                  onSelected: (v) {
                    setState(() => _selectedCategory = v);
                    ref.read(researchProvider.notifier).loadResearch(
                        category: v,
                        search: _searchCtrl.text.trim().isEmpty
                            ? null
                            : _searchCtrl.text.trim());
                  },
                ),
              ],
            ),
          ),

          // ── Active filter chip ──
          if (_selectedCategory != null)
            Container(
              color: _AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _meta(_selectedCategory!).light,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _meta(_selectedCategory!).color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_meta(_selectedCategory!).icon,
                            size: 12, color: _meta(_selectedCategory!).color),
                        const SizedBox(width: 5),
                        Text(
                          _meta(_selectedCategory!).label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _meta(_selectedCategory!).color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = null);
                            ref.read(researchProvider.notifier).loadResearch(
                                search: _searchCtrl.text.trim().isEmpty
                                    ? null
                                    : _searchCtrl.text.trim());
                          },
                          child: Icon(Icons.close_rounded,
                              size: 13,
                              color: _meta(_selectedCategory!).color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── List ──
          Expanded(
            child: Builder(builder: (_) {
              if (state.isLoading && state.items.isEmpty) {
                return const AppLoadingWidget(
                    message: 'Loading research…');
              }
              if (state.error != null && state.items.isEmpty) {
                return AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(researchProvider.notifier).loadResearch(),
                );
              }
              if (state.items.isEmpty) {
                return const _EmptyState();
              }
              return RefreshIndicator(
                color: _AppColors.accent,
                backgroundColor: _AppColors.surface,
                onRefresh: () =>
                    ref.read(researchProvider.notifier).loadResearch(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: state.items.length,
                  itemBuilder: (_, i) =>
                      _ResearchCard(item: state.items[i], index: i),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Button ────────────────────────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final String? selected;
  final List<String> categories;
  final ValueChanged<String?> onSelected;

  const _FilterButton({
    required this.selected,
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected != null;
    return GestureDetector(
      onTap: () async {
        final picked = await showModalBottomSheet<String?>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _CategoryPickerSheet(
              selected: selected, categories: categories),
        );
        // null means "All" was chosen or sheet dismissed
        if (picked != null || selected != null) {
          onSelected(picked == '__clear__' ? null : picked);
        }
      },
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: active ? _AppColors.accent : _AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? _AppColors.accent : _AppColors.border,
          ),
        ),
        child: Icon(
          Icons.filter_list_rounded,
          size: 20,
          color: active ? Colors.white : _AppColors.textMuted,
        ),
      ),
    );
  }
}

// ─── Category Picker Sheet ────────────────────────────────────────────────────
class _CategoryPickerSheet extends StatelessWidget {
  final String? selected;
  final List<String> categories;
  const _CategoryPickerSheet(
      {required this.selected, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _AppColors.surface,
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
                  color: _AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text(
            'Filter by Category',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          // "All" option
          _CatOption(
            label: 'All Categories',
            icon: Icons.all_inclusive_rounded,
            color: _AppColors.accent,
            light: _AppColors.accentLight,
            isSelected: selected == null,
            onTap: () => Navigator.pop(context, '__clear__'),
          ),
          const SizedBox(height: 8),
          ...categories.map((c) {
            final m = _meta(c);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CatOption(
                label: m.label,
                icon: m.icon,
                color: m.color,
                light: m.light,
                isSelected: selected == c,
                onTap: () => Navigator.pop(context, c),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CatOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color light;
  final bool isSelected;
  final VoidCallback onTap;
  const _CatOption({
    required this.label, required this.icon,
    required this.color, required this.light,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : _AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.4) : _AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: light, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : _AppColors.textPrimary,
                )),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── Research Card ────────────────────────────────────────────────────────────
class _ResearchCard extends StatefulWidget {
  final ResearchModel item;
  final int index;
  const _ResearchCard({required this.item, required this.index});

  @override
  State<_ResearchCard> createState() => _ResearchCardState();
}

class _ResearchCardState extends State<_ResearchCard>
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
            milliseconds: 380 + (widget.index * 50).clamp(0, 400)));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 50),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final m    = _meta(item.category);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push('/research/${item.id}'),
              splashColor: m.light,
              highlightColor: m.light.withOpacity(0.5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _AppColors.borderSoft),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Category header strip
                    Container(
                      decoration: BoxDecoration(
                        color: m.color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(17),
                          topRight: Radius.circular(17),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(m.icon, size: 13, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            m.label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          // Stats row
                          if (item.downloads > 0)
                            _StatPill(
                                icon: Icons.download_rounded,
                                value: '${item.downloads}'),
                          if (item.citations > 0) ...[
                            const SizedBox(width: 6),
                            _StatPill(
                                icon: Icons.format_quote_rounded,
                                value: '${item.citations}'),
                          ],
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
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
                          const SizedBox(height: 4),
                          Text(
                            item.authors.join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: m.color,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.doi != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'DOI: ${item.doi}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _AppColors.textMuted),
                            ),
                          ],

                          // Tags
                          if (item.tags.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: item.tags.take(4).map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _AppColors.border),
                                ),
                                child: Text(
                                  _tagLabel(t),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _AppColors.textSecondary,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],

                          if (item.createdAt != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded,
                                    size: 12,
                                    color: _AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  timeAgo(item.createdAt!),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _AppColors.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: _AppColors.textMuted),
                              ],
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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  const _StatPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
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
                borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.science_rounded,
                size: 36, color: _AppColors.accent),
          ),
          const SizedBox(height: 20),
          const Text('No research found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          const Text('Try a different search or filter',
              style: TextStyle(
                  fontSize: 14, color: _AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Create Research Sheet ────────────────────────────────────────────────────
class _CreateResearchSheet extends ConsumerStatefulWidget {
  const _CreateResearchSheet();

  @override
  ConsumerState<_CreateResearchSheet> createState() =>
      _CreateResearchSheetState();
}

class _CreateResearchSheetState
    extends ConsumerState<_CreateResearchSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _abstractCtrl = TextEditingController();
  final _doiCtrl     = TextEditingController();
  final _docUrlCtrl  = TextEditingController();
  // Authors: managed as a list with an add-field
  final _authorCtrl  = TextEditingController();
  final List<String> _authors  = [];
  final List<String> _selectedTags = [];
  String _category   = 'PAPER';
  bool   _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _abstractCtrl.dispose();
    _doiCtrl.dispose();
    _docUrlCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  void _addAuthor() {
    final name = _authorCtrl.text.trim();
    if (name.isEmpty || _authors.contains(name)) return;
    setState(() {
      _authors.add(name);
      _authorCtrl.clear();
    });
  }

  void _removeAuthor(String name) =>
      setState(() => _authors.remove(name));

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_authors.isEmpty) {
      setState(() => _submitError = 'Add at least one author.');
      return;
    }

    setState(() { _submitting = true; _submitError = null; });

    final ok = await ref.read(researchProvider.notifier).create({
      'title':            _titleCtrl.text.trim(),
      'researchAbstract': _abstractCtrl.text.trim(),
      'authors':          _authors,
      'category':         _category,
      'tags':             _selectedTags,
      'doi':              _doiCtrl.text.trim().isEmpty ? null : _doiCtrl.text.trim(),
      'documentUrl':      _docUrlCtrl.text.trim().isEmpty ? null : _docUrlCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _submitError = 'Failed to publish. Please try again.');
    }
  }

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
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: _AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: _AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.science_rounded,
                        color: _AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Publish Research',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _AppColors.textPrimary,
                              letterSpacing: -0.5,
                            )),
                        Text('Share your work with the alumni network',
                            style: TextStyle(
                                fontSize: 13,
                                color: _AppColors.textMuted)),
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
                  label: 'Title',
                  hint: 'Full title of your research',
                  prefixIcon: const Icon(Icons.title_rounded,
                      size: 18, color: _AppColors.textMuted),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),

              // ── Abstract ──
              TextFormField(
                controller: _abstractCtrl,
                maxLines: 4,
                minLines: 3,
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                  label: 'Abstract',
                  hint: 'Brief summary of your research…',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(Icons.notes_rounded,
                        size: 18, color: _AppColors.textMuted),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Abstract is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Category ──
              _SectionLabel(label: 'Category'),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _allCategories.map((cat) {
                    final m        = _meta(cat);
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
                            color: selected ? m.color : m.light,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? m.color
                                  : m.color.withOpacity(0.25),
                              width: selected ? 0 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(m.icon,
                                  size: 13,
                                  color: selected ? Colors.white : m.color),
                              const SizedBox(width: 5),
                              Text(m.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : m.color,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Tags ──
              _SectionLabel(label: 'Tags'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allTags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () => _toggleTag(tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? _AppColors.accent
                            : _AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _AppColors.accent
                              : _AppColors.border,
                        ),
                      ),
                      child: Text(
                        _tagLabel(tag),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : _AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Authors ──
              _SectionLabel(label: 'Authors'),
              const SizedBox(height: 8),
              if (_authors.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _authors
                      .map((a) => _AuthorChip(
                            name: a,
                            onRemove: () => _removeAuthor(a),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _authorCtrl,
                      onSubmitted: (_) => _addAuthor(),
                      style: const TextStyle(
                          fontSize: 14, color: _AppColors.textPrimary),
                      decoration: _fieldDeco(
                        label: 'Author name',
                        hint: 'Full name',
                        prefixIcon: const Icon(Icons.person_rounded,
                            size: 18, color: _AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52, width: 52,
                    child: ElevatedButton(
                      onPressed: _addAuthor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Icon(Icons.add_rounded, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── DOI (optional) ──
              TextFormField(
                controller: _doiCtrl,
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                  label: 'DOI (optional)',
                  hint: 'e.g. 10.1000/xyz123',
                  prefixIcon: const Icon(Icons.link_rounded,
                      size: 18, color: _AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),

              // ── Document URL (optional) ──
              TextFormField(
                controller: _docUrlCtrl,
                style: const TextStyle(
                    fontSize: 14, color: _AppColors.textPrimary),
                decoration: _fieldDeco(
                  label: 'Document URL (optional)',
                  hint: 'https://…',
                  prefixIcon: const Icon(Icons.insert_drive_file_rounded,
                      size: 18, color: _AppColors.textMuted),
                ),
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
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.publish_rounded, size: 18),
                  label: Text(
                    _submitting ? 'Publishing…' : 'Publish Research',
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

// ─── Author Chip ──────────────────────────────────────────────────────────────
class _AuthorChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;
  const _AuthorChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 5, 5),
      decoration: BoxDecoration(
        color: _AppColors.accentLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
                color: _AppColors.accent.withOpacity(0.15),
                shape: BoxShape.circle),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.accent)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                  color: _AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  size: 10, color: _AppColors.accent),
            ),
          ),
        ],
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
    return Text(label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _AppColors.textSecondary,
          letterSpacing: 0.3,
        ));
  }
}