import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/role_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
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
  static const teal        = Color(0xFF00897B);
  static const tealLight   = Color(0xFFE0F2F1);
  static const purple      = Color(0xFF6A1B9A);
  static const purpleLight = Color(0xFFF3E5F5);
}

Color _avatarColor(String name) {
  const p = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF0277BD),
    Color(0xFF00838F), Color(0xFFF57C00), Color(0xFFAD1457),
  ];
  if (name.isEmpty) return p[0];
  return p[name.codeUnitAt(0) % p.length];
}

// ─── Theme Mode Provider (dummy — toggles in memory) ─────────────────────────
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

// ─── Profile Screen ───────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user              = ref.watch(currentUserProvider);
    final applicationsAsync = ref.watch(userApplicationsProvider);
    final jobsState         = ref.watch(jobsProvider);
    final themeMode         = ref.watch(themeModeProvider);

    if (user == null) return const SizedBox.shrink();

    final color = _avatarColor(user.fullName);

    return Scaffold(
      backgroundColor: _C.surfaceAlt,
      appBar: AppBar(
        backgroundColor: _C.accent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign out',
            onPressed: () =>
                _confirmLogout(context, ref),
          ),
        ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Identity card ──
            const SizedBox(height: 20),
            _IdentityCard(user: user, color: color),

            // ── Bio ──
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Bio',
                icon: Icons.notes_rounded,
                color: color,
                child: Text(
                  user.bio!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: _C.textSec,
                  ),
                ),
              ),
            ],

            // ── Job Applications ──
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Job Applications',
              icon: Icons.work_outline_rounded,
              color: _C.teal,
              child: applicationsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child: CircularProgressIndicator(color: _C.teal)),
                ),
                error: (e, _) => _InfoRow(
                  icon: Icons.error_outline_rounded,
                  label: 'Could not load applications',
                  color: _C.error,
                ),
                data: (applications) {
                  if (applications.isEmpty) {
                    return _EmptyInline(
                      icon: Icons.work_off_rounded,
                      label: 'No applications yet',
                      color: _C.teal,
                    );
                  }
                  return Column(
                    children: [
                      // Summary stat
                      Row(
                        children: [
                          Text(
                            '${applications.length}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _C.teal,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'application(s) submitted',
                            style: TextStyle(
                              fontSize: 13,
                              color: _C.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Application tiles — look up title from jobsState
                      ...applications.take(3).map((app) {
                        final job = jobsState.jobs
                            .where((j) => j.id == app.jobId)
                            .firstOrNull;
                        return _ApplicationTile(
                          app: app,
                          jobTitle: job?.title ?? 'Job #${app.jobId}',
                        );
                      }),
                      if (applications.length > 3) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.push('/jobs'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _C.tealLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _C.teal.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View all ${applications.length} applications',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _C.teal,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: _C.teal),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            // ── Appearance ──
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              color: _C.purple,
              child: _ThemePicker(
                  current: themeMode,
                  onChanged: (mode) =>
                      ref.read(themeModeProvider.notifier).state = mode),
            ),

            // ── Quick actions ──
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Account',
              icon: Icons.manage_accounts_rounded,
              color: _C.accent,
              child: Column(
                children: [
                  if (user.role == 'ADMIN') ...[
                    _ActionTile(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Admin Dashboard',
                      color: _C.purple,
                      onTap: () => context.push('/admin/analytics'),
                    ),
                    const _TileDivider(),
                  ],
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: _C.error,
                    onTap: () => _confirmLogout(context, ref),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text(
            'Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(authProvider.notifier).logout();
    }
  }
}

// ─── Identity Card ────────────────────────────────────────────────────────────
class _IdentityCard extends StatelessWidget {
  final dynamic user;
  final Color color;
  const _IdentityCard({required this.user, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: color.withOpacity(0.25), width: 2),
                ),
                child: Center(
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _C.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.border, width: 1.5),
                ),
                child: Icon(Icons.edit_rounded,
                    size: 14, color: _C.accent),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name
          Text(
            user.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _C.text,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            '@${user.username}',
            style: const TextStyle(
              fontSize: 14,
              color: _C.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Role badge
          RoleBadge(role: user.role),

          // Email
          if (user.email != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _C.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.email_outlined,
                      size: 14, color: _C.textMuted),
                  const SizedBox(width: 7),
                  Text(
                    user.email!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _C.textSec,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Application Tile ─────────────────────────────────────────────────────────
class _ApplicationTile extends StatelessWidget {
  final dynamic app;
  final String jobTitle;
  const _ApplicationTile({required this.app, required this.jobTitle});

  Color _statusColor(String s) => switch (s.toUpperCase()) {
        'ACCEPTED' => _C.green,
        'REJECTED' => _C.error,
        'PENDING'  => const Color(0xFFF57C00),
        _          => _C.textMuted,
      };

  Color _statusLight(String s) => switch (s.toUpperCase()) {
        'ACCEPTED' => _C.greenLight,
        'REJECTED' => _C.errorLight,
        'PENDING'  => const Color(0xFFFFF3E0),
        _          => _C.surfaceAlt,
      };

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(app.status ?? 'PENDING');
    final sl = _statusLight(app.status ?? 'PENDING');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            // Company icon
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _C.tealLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.business_rounded,
                  color: _C.teal, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jobTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.text,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (app.appliedAt != null)
                    Text(
                      'Applied ${timeAgo(app.appliedAt!)}',
                      style: const TextStyle(
                          fontSize: 11, color: _C.textMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sl,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: sc.withOpacity(0.25)),
              ),
              child: Text(
                (app.status ?? 'PENDING').toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: sc,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Theme Picker ─────────────────────────────────────────────────────────────
class _ThemePicker extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemePicker(
      {required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      (ThemeMode.light,  Icons.light_mode_rounded,  'Light'),
      (ThemeMode.dark,   Icons.dark_mode_rounded,   'Dark'),
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
    ];

    return Row(
      children: options.map((opt) {
        final (mode, icon, label) = opt;
        final selected = current == mode;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: mode != ThemeMode.system ? 8 : 0),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? _C.purple.withOpacity(0.08)
                      : _C.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? _C.purple.withOpacity(0.4)
                        : _C.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon,
                        size: 20,
                        color:
                            selected ? _C.purple : _C.textMuted),
                    const SizedBox(height: 5),
                    Text(label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? _C.purple
                              : _C.textSec,
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                      color: _C.text,
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

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? _C.error : _C.text,
                    )),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: _C.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tile Divider ─────────────────────────────────────────────────────────────
class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            _C.border,
            Colors.transparent,
          ]),
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoRow(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Empty Inline ─────────────────────────────────────────────────────────────
class _EmptyInline extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _EmptyInline(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color.withOpacity(0.5)),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7),
              )),
        ],
      ),
    );
  }
}