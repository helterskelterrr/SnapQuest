import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helper.dart';
import '../../models/submission_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _publicUserProvider =
    FutureProvider.family<UserModel?, String>((ref, userId) async {
  return ref.read(firestoreServiceProvider).getUserById(userId);
});

final _publicSubmissionsProvider =
    StreamProvider.family<List<SubmissionModel>, String>((ref, userId) {
  return ref
      .read(firestoreServiceProvider)
      .getSubmissionsByUserStream(userId);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_publicUserProvider(userId));
    final submissionsAsync = ref.watch(_publicSubmissionsProvider(userId));
    final currentUid = ref.watch(authStateProvider).value?.uid;
    final isMe = currentUid == userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: userAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _buildError(context, e.toString()),
        data: (user) {
          if (user == null) return _buildNotFound(context);
          final submissions = submissionsAsync.value ?? [];
          return _buildProfile(context, user, submissions, isMe);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return SafeArea(
      child: Column(
        children: [
          _BackBar(title: 'Profil'),
          Expanded(
            child: Center(
              child: Text('Gagal memuat profil: $msg',
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _BackBar(title: 'Profil'),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded,
                      color: AppColors.textMuted, size: 48),
                  SizedBox(height: 12),
                  Text('Pengguna tidak ditemukan',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Akun ini mungkin sudah dihapus.',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    UserModel user,
    List<SubmissionModel> submissions,
    bool isMe,
  ) {
    final totalVotes =
        submissions.fold<int>(0, (sum, s) => sum + s.voteCount);
    final currentXp = user.totalXp;
    final nextXp = DateHelper.nextRankXp(currentXp);
    final progress = (currentXp / nextXp).clamp(0.0, 1.0);

    return SafeArea(
      child: ListView(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.28),
                  AppColors.background,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isMe ? 'Profilku' : 'Profil Pengguna',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (isMe)
                      GestureDetector(
                        onTap: () => context.push('/profile/edit'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: AppColors.textSecondary, size: 18),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Avatar + info
                Row(
                  children: [
                    _AvatarWidget(user: user, size: 84),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(
                                user.username,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Kamu',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 6),
                          // Rank badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded,
                                    size: 11, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(user.rank,
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Join date
                          Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 11, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              'Bergabung ${_formatDate(user.createdAt.toDate())}',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Stats strip ─────────────────────────────────────────────
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
                    value: '${user.weeklyPoints}'),
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

          // ── XP Progress bar ─────────────────────────────────────────
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
                    Text(user.rank,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
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
                    builder: (ctx, val, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: val,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(
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

          // ── Submission grid ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Riwayat Submission',
                  count: submissions.length,
                ),
                const SizedBox(height: 10),
                if (submissions.isEmpty)
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              color: AppColors.textMuted, size: 28),
                          SizedBox(height: 6),
                          Text('Belum ada submission',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 3,
                        crossAxisSpacing: 3,
                      ),
                      itemCount: submissions.length,
                      itemBuilder: (_, i) => _SubmissionThumb(
                        submission: submissions[i],
                        onTap: () => context
                            .push('/post/${submissions[i].submissionId}'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${months[dt.month]} ${dt.year}';
  }
}

// ── Back bar helper ───────────────────────────────────────────────────────────

class _BackBar extends StatelessWidget {
  final String title;
  const _BackBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final UserModel user;
  final double size;
  const _AvatarWidget({required this.user, required this.size});

  Color get _color {
    final hex = user.photoUrl;
    try {
      if (hex.startsWith('#') && hex.length == 7) {
        return Color(int.parse('FF${hex.substring(1)}', radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';
    final photoUrl = user.photoUrl;

    if (photoUrl.isNotEmpty && !photoUrl.startsWith('#')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (c2, u2, e2) => _initials(initial),
        ),
      );
    }
    return _initials(initial);
  }

  Widget _initials(String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardSurface, width: 3),
        boxShadow: [
          BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 20),
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

// ── Submission thumb ──────────────────────────────────────────────────────────

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
                        color: AppColors.textMuted),
                  ),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Row(children: [
                const Icon(Icons.star_rounded, size: 9, color: Colors.white),
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

// ── Stat cell ─────────────────────────────────────────────────────────────────

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
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 10)),
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

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
      const Spacer(),
      if (count > 0)
        Text('$count foto',
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
    ]);
  }
}
