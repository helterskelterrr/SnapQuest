import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/submission_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/submission_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showLogout = false;

  Future<void> _logout() async {
    setState(() => _showLogout = false);
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelProvider);
    final submissionsAsync = ref.watch(userSubmissionsProvider);

    final user = userAsync.value;
    final submissions = submissionsAsync.value ?? [];

    final totalVotes =
        submissions.fold<int>(0, (sum, s) => sum + s.voteCount);
    final currentXp = user?.totalXp ?? 0;
    final nextXp = DateHelper.nextRankXp(currentXp);
    final progress = (currentXp / nextXp).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: userAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style:
                          const TextStyle(color: AppColors.textMuted))),
              data: (_) => ListView(
                children: [
                  // Hero header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.background,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Profil Saya',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            GestureDetector(
                              onTap: () => context.push('/settings'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.2),
                                      width: 1.5),
                                ),
                                child: const Icon(Icons.settings_rounded,
                                    color: AppColors.textSecondary,
                                    size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Avatar + info
                        Row(
                          children: [
                            Stack(
                              children: [
                                _AvatarWidget(user: user, size: 84),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.push('/profile/edit'),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.amber,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.background,
                                            width: 2),
                                      ),
                                      child: const Icon(
                                          Icons.edit_rounded,
                                          size: 13,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(
                                      child: Text(
                                        user?.username ?? 'Pengguna',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () =>
                                          context.push('/profile/edit'),
                                      child: const Icon(Icons.edit_rounded,
                                          size: 14,
                                          color: AppColors.textMuted),
                                    ),
                                  ]),
                                  if (user?.email != null)
                                    Text(user!.email,
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12)),
                                  if (user?.bio != null && user!.bio.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(user.bio,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            height: 1.4)),
                                  ],
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bolt_rounded,
                                            size: 11,
                                            color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          user?.rank ?? 'Rookie Snapper',
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (user?.createdAt != null)
                          Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 5),
                            Text(
                              'Bergabung ${_formatDate(user!.createdAt.toDate())}',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ]),
                      ],
                    ),
                  ),

                  // Stats strip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1.5),
                      ),
                      child: Row(children: [
                        _StatCell(
                            icon: Icons.star_rounded,
                            color: AppColors.amber,
                            label: 'Poin Minggu',
                            value: '${user?.weeklyPoints ?? 0}'),
                        _Divider(),
                        _StatCell(
                            icon: Icons.camera_alt_rounded,
                            color: AppColors.primary,
                            label: 'Total Submit',
                            value: '${submissions.length}'),
                        _Divider(),
                        _StatCell(
                            icon: Icons.favorite_rounded,
                            color: AppColors.error,
                            label: 'Vote Diterima',
                            value: '$totalVotes'),
                        _Divider(),
                        _StatCell(
                            icon: Icons.bolt_rounded,
                            color: AppColors.amber,
                            label: 'Total XP',
                            value: '$currentXp'),
                      ]),
                    ),
                  ),

                  // XP Progress
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.bolt_rounded,
                                size: 13, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              user?.rank ?? 'Rookie Snapper',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$currentXp / $nextXp XP',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 1200),
                            builder: (ctx, val, child) => ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: val,
                                minHeight: 8,
                                backgroundColor: AppColors.background,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('${nextXp - currentXp} XP lagi untuk naik level',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),

                  // Photo Grid
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                            title: 'Riwayat Submission',
                            trailing: submissions.isNotEmpty
                                ? GestureDetector(
                                    onTap: () =>
                                        context.push('/profile/submissions'),
                                    child: Row(children: const [
                                      Text('Lihat semua',
                                          style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                      Icon(Icons.chevron_right_rounded,
                                          size: 14, color: AppColors.primary),
                                    ]),
                                  )
                                : null),
                        const SizedBox(height: 10),
                        if (submissions.isEmpty)
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15)),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded,
                                      color: AppColors.textMuted, size: 28),
                                  SizedBox(height: 6),
                                  Text('Belum ada submission',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: GridView.count(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              mainAxisSpacing: 3,
                              crossAxisSpacing: 3,
                              children: submissions
                                  .take(6)
                                  .map((s) => _SubmissionThumb(
                                      submission: s,
                                      onTap: () => context
                                          .push('/post/${s.submissionId}')))
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Logout
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showLogout = true),
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Keluar dari Akun'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.3)),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logout dialog
          if (_showLogout)
            _ConfirmDialog(
              title: 'Keluar dari Akun?',
              body:
                  'Kamu perlu login kembali untuk mengakses SnapQuest.',
              confirmLabel: 'Ya, Keluar',
              onConfirm: _logout,
              onCancel: () => setState(() => _showLogout = false),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${months[dt.month]} ${dt.year}';
  }
}

// ─── Avatar ───────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final UserModel? user;
  final double size;
  const _AvatarWidget({required this.user, required this.size});

  Color get _color {
    final hex = user?.photoUrl ?? '';
    try {
      if (hex.startsWith('#') && hex.length == 7) {
        return Color(int.parse('FF${hex.substring(1)}', radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final initial = user?.username.isNotEmpty == true
        ? user!.username[0].toUpperCase()
        : 'U';
    final photoUrl = user?.photoUrl ?? '';

    if (photoUrl.isNotEmpty && !photoUrl.startsWith('#')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (c2, u2, e2) => _initials(initial, size),
        ),
      );
    }
    return _initials(initial, size);
  }

  Widget _initials(String initial, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardSurface, width: 3),
        boxShadow: [
          BoxShadow(
              color: _color.withValues(alpha: 0.4), blurRadius: 20)
        ],
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.32,
              fontWeight: FontWeight.w800)),
    );
  }
}

// ─── Submission thumb ─────────────────────────
class _SubmissionThumb extends StatelessWidget {
  final SubmissionModel submission;
  final VoidCallback onTap;
  const _SubmissionThumb({required this.submission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          submission.photoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: submission.photoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c2, u2, e2) => Container(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(Icons.image_rounded,
                          color: AppColors.textMuted)),
                )
              : Container(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  child: const Center(
                      child: Icon(Icons.image_rounded,
                          color: AppColors.textMuted, size: 28)),
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Row(children: [
                const Icon(Icons.star_rounded,
                    size: 9, color: Colors.white),
                const SizedBox(width: 2),
                Text('${submission.voteCount}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────
class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatCell(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 40,
      color: AppColors.primary.withValues(alpha: 0.15));
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
      const Spacer(),
      if (trailing != null) trailing!,
    ]);
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _ConfirmDialog(
      {required this.title,
      required this.body,
      required this.confirmLabel,
      required this.onConfirm,
      required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: BorderSide(
                            color: AppColors.textMuted
                                .withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(confirmLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
