import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/submission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/submission_provider.dart';
import 'widgets/comment_section.dart';

// Provider: stream a single submission by ID so vote count stays live
final _submissionProvider =
    StreamProvider.family<SubmissionModel?, String>((ref, id) {
  final authAsync = ref.watch(authStateProvider);
  // Still loading auth — keep stream pending so UI shows loading indicator
  if (authAsync.isLoading) return const Stream.empty();
  final uid = authAsync.value?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('submissions')
      .doc(id)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return SubmissionModel.fromMap(doc.data()!, doc.id);
  });
});

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  bool? _voted; // null = not yet loaded
  bool _voting = false;
  String? _toast;

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 2500),
        () => mounted ? setState(() => _toast = null) : null);
  }

  Future<void> _handleVote(SubmissionModel submission) async {
    if (_voting) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    if (uid == submission.userId) return; // can't vote own post

    final user = ref.read(userModelProvider).value;
    if (user == null) return;
    final isVoted = _voted ?? false;

    if (!isVoted && user.dailyVotesGiven >= 10) {
      _showToast('Jatah vote harian kamu sudah habis!');
      return;
    }

    setState(() {
      _voting = true;
      _voted = !isVoted; // optimistic
    });

    try {
      final service = ref.read(firestoreServiceProvider);
      await service.toggleVote(
        voterId: uid,
        submissionId: submission.submissionId,
        challengeId: submission.challengeId,
        submissionOwnerId: submission.userId,
        voterUsername: user.username,
        challengeTitle: ref.read(todayChallengeProvider).value?.title ?? 'tantangan',
      );
      _showToast(isVoted ? 'Vote dibatalkan' : '+1 vote dikirim!');
    } catch (e) {
      // Revert optimistic
      setState(() => _voted = isVoted);
      _showToast(e.toString().contains('Batas') ? 'Batas vote harian (10) telah habis' : 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _handleReport(String submissionId) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final user = ref.read(userModelProvider).value;
    if (user == null) return;

    if (user.dailyReportsRemaining <= 0) {
      _showToast('Jatah laporan harian kamu sudah habis.');
      return;
    }

    try {
      final service = ref.read(firestoreServiceProvider);
      final alreadyReported = await service.hasReported(uid, submissionId);
      if (alreadyReported) {
        _showToast('Kamu sudah melaporkan foto ini.');
        return;
      }
      await service.createReport(uid, submissionId);
      await service.incrementReportCount(submissionId);
      await service.checkAndHideSubmission(submissionId);
      await service.incrementUserField(uid, 'daily_reports_remaining', -1);
      _showToast('Laporan terkirim. Terima kasih!');
    } catch (_) {
      _showToast('Gagal melaporkan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionAsync = ref.watch(_submissionProvider(widget.postId));
    final votedIdsAsync = ref.watch(userVotedIdsProvider);
    final uid = ref.watch(authStateProvider).value?.uid;

    // Sync _voted from server once
    ref.listen(userVotedIdsProvider, (_, next) {
      if (_voted == null && next.value != null) {
        setState(
            () => _voted = next.value!.contains(widget.postId));
      }
    });
    if (_voted == null && votedIdsAsync.value != null) {
      _voted = votedIdsAsync.value!.contains(widget.postId);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: submissionAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary)),
              error: (e, _) => Center(
                child: Text('Gagal memuat: $e',
                    style: const TextStyle(
                        color: AppColors.textMuted)),
              ),
              data: (submission) {
                if (submission == null) {
                  return const Center(
                      child: Text('Foto tidak ditemukan',
                          style: TextStyle(
                              color: AppColors.textMuted)));
                }

                final isVoted = _voted ?? false;
                final isOwn = uid == submission.userId;

                return Column(
                  children: [
                    // Top bar
                    Container(
                      color: AppColors.navBackground,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          child: _ActionBtn(
                              icon: Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Detail Foto',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                '@${submission.username}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!isOwn)
                          GestureDetector(
                            onTap: () =>
                                _handleReport(submission.submissionId),
                            child: _ActionBtn(
                                icon: Icons.flag_outlined),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _showToast('Link disalin ke clipboard!'),
                          child: _ActionBtn(icon: Icons.share_outlined),
                        ),
                      ]),
                    ),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          // Photo
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: GestureDetector(
                                onDoubleTap: isOwn
                                    ? null
                                    : () {
                                        if (!isVoted) {
                                          _handleVote(submission);
                                        }
                                      },
                                child: AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: submission.photoUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: submission.photoUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (c, u) =>
                                              Container(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color: AppColors
                                                            .primary,
                                                        strokeWidth: 2)),
                                          ),
                                          errorWidget: (c, u, e) =>
                                              Container(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            child: const Center(
                                                child: Icon(
                                                    Icons
                                                        .broken_image_rounded,
                                                    size: 48,
                                                    color: AppColors
                                                        .textMuted)),
                                          ),
                                        )
                                      : Container(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          child: const Center(
                                              child: Icon(
                                                  Icons.image_rounded,
                                                  size: 64,
                                                  color:
                                                      AppColors.textMuted)),
                                        ),
                                ),
                              ),
                            ),
                          ),

                          // Info card
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                20, 12, 20, 0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2),
                                    width: 1.5),
                              ),
                              child: Column(children: [
                                // User row
                                Row(children: [
                                  _UserAvatar(
                                      photoUrl:
                                          submission.userPhotoUrl,
                                      username:
                                          submission.username),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(submission.username,
                                            style: const TextStyle(
                                                color: AppColors
                                                    .textPrimary,
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight.w700)),
                                        Text(
                                          _timeAgo(
                                              submission.submittedAt),
                                          style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]),

                                if (submission.caption.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(submission.caption,
                                        style: const TextStyle(
                                            color:
                                                AppColors.textSecondary,
                                            fontSize: 14,
                                            height: 1.7)),
                                  ),
                                ],

                                const SizedBox(height: 14),
                                // Vote count + comment count + action
                                Row(children: [
                                  const Icon(Icons.favorite_rounded,
                                      size: 14,
                                      color: AppColors.amber),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${submission.voteCount}',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.chat_bubble_outline_rounded,
                                      size: 14,
                                      color: AppColors.textMuted),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${submission.commentsCount}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 3),
                                  const Text('komentar',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                  const Spacer(),
                                  if (!isOwn)
                                    ElevatedButton.icon(
                                      onPressed: _voting
                                          ? null
                                          : () =>
                                              _handleVote(submission),
                                      icon: Icon(
                                          isVoted
                                              ? Icons.favorite_rounded
                                              : Icons
                                                  .favorite_border_rounded,
                                          size: 16),
                                      label: Text(
                                          isVoted ? 'Voted' : 'Vote'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isVoted
                                            ? AppColors.amber
                                                .withValues(alpha: 0.15)
                                            : AppColors.primary,
                                        foregroundColor: isVoted
                                            ? AppColors.amber
                                            : Colors.white,
                                        elevation: 0,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 11),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12)),
                                        textStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  if (isOwn)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: const Text('Foto kamu',
                                          style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                                ]),

                                if (!isOwn) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Ketuk 2x pada foto untuk vote cepat',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11)),
                                ],
                              ]),
                            ),
                          ),

                          // Comments
                          CommentSection(
                            submissionId: submission.submissionId,
                            submissionOwnerId: submission.userId,
                          ),

                          // Other photos in this challenge
                          _RelatedFeed(
                              challengeId: submission.challengeId,
                              currentId: submission.submissionId),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          if (_toast != null)
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.5)),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black38, blurRadius: 16)
                    ],
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 10),
                    Text(_toast!,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

// ─── Related feed ─────────────────────────────
class _RelatedFeed extends ConsumerWidget {
  final String challengeId;
  final String currentId;
  const _RelatedFeed(
      {required this.challengeId, required this.currentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(challengeFeedProvider(challengeId));

    return feedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e2, s2) => const SizedBox.shrink(),
      data: (submissions) {
        final others =
            submissions.where((s) => s.submissionId != currentId).toList();
        if (others.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                const Text('Foto Lain di Challenge Ini',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: others.length > 8 ? 8 : others.length,
                  itemBuilder: (ctx, i) {
                    final s = others[i];
                    return GestureDetector(
                      onTap: () => context.push('/post/${s.submissionId}'),
                      child: Container(
                        width: 112,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(fit: StackFit.expand, children: [
                          s.photoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: s.photoUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (c, u, e) => Container(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      child: const Icon(Icons.image_rounded,
                                          color: AppColors.textMuted)),
                                )
                              : Container(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  child: const Icon(Icons.image_rounded,
                                      color: AppColors.textMuted)),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: Row(children: [
                                const Icon(Icons.favorite_rounded,
                                    size: 10, color: Colors.white),
                                const SizedBox(width: 3),
                                Text('${s.voteCount}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── User avatar ──────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String photoUrl;
  final String username;
  const _UserAvatar({required this.photoUrl, required this.username});

  Color get _color {
    try {
      if (photoUrl.startsWith('#') && photoUrl.length == 7) {
        return Color(int.parse('FF${photoUrl.substring(1)}', radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        username.isNotEmpty ? username[0].toUpperCase() : 'U';
    if (photoUrl.isNotEmpty && !photoUrl.startsWith('#')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorWidget: (c, u, e) => _circle(initial),
        ),
      );
    }
    return _circle(initial);
  }

  Widget _circle(String initial) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(initial,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
      );
}

// ─── Action button ────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  const _ActionBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.5),
      ),
      child: Icon(icon,
          color: AppColors.textSecondary,
          size: 20),
    );
  }
}
