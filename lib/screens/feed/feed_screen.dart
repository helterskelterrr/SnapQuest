
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../models/submission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/submission_provider.dart';
import '../../services/supabase_service.dart';
import 'widgets/post_card.dart';
import 'widgets/report_sheet.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String? _reportingSubmissionId;
  final Map<String, bool> _pendingVotes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) return;
      await ref.read(firestoreServiceProvider).checkDailyReset(uid);
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _handleVote(SubmissionModel submission, bool currentlyVoted) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final user = ref.read(userModelProvider).value;
    if (user == null) return;

    setState(() => _pendingVotes[submission.submissionId] = !currentlyVoted);

    final service = ref.read(firestoreServiceProvider);
    try {
      await service.toggleVote(
        voterId: uid,
        submissionId: submission.submissionId,
        challengeId: submission.challengeId,
        submissionOwnerId: submission.userId,
        voterUsername: user.username,
        challengeTitle: submission.challengeTitle,
      );

      // Sync vote ke Supabase (relational database)
      try {
        final alreadyVoted = await SupabaseService.instance.hasVoted(uid, submission.submissionId);
        if (alreadyVoted) {
          await SupabaseService.instance.deleteVote(voterId: uid, submissionId: submission.submissionId);
        } else {
          await SupabaseService.instance.createVote(voterId: uid, submissionId: submission.submissionId);
        }
      } catch (e) {
        // Silently ignore Supabase error for dummy data so it doesn't break the UI
        debugPrint('Gagal sync vote ke Supabase: $e');
      }

      setState(() => _pendingVotes.remove(submission.submissionId));
    } catch (e) {
      setState(() => _pendingVotes.remove(submission.submissionId));
      _showSnackBar('Gagal: $e');
    }
  }

  Future<void> _handleReport(String submissionId, String reason) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;

    final user = ref.read(userModelProvider).value;
    if (user == null) return;

    setState(() => _reportingSubmissionId = null);

    if (user.dailyReportsRemaining <= 0) {
      _showSnackBar('Jatah laporan harian kamu sudah habis.');
      return;
    }

    try {
      final service = ref.read(firestoreServiceProvider);
      final alreadyReported = await service.hasReported(uid, submissionId);
      if (alreadyReported) {
        _showSnackBar('Kamu sudah melaporkan foto ini.');
        return;
      }
      await service.createReport(uid, submissionId);
      await service.incrementReportCount(submissionId);
      await service.checkAndHideSubmission(submissionId);
      await service.incrementUserField(uid, 'daily_reports_remaining', -1);
      _showSnackBar('Laporan terkirim. Terima kasih!');
    } catch (e) {
      _showSnackBar('Gagal melaporkan, coba lagi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider);
    final votedIdsAsync = ref.watch(userVotedIdsProvider);
    final sort = ref.watch(feedSortProvider);

    final votedIds = votedIdsAsync.value ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const Text('Feed',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        _Tab(
                          label: 'Terbaru',
                          active: sort == FeedSort.latest,
                          onTap: () => ref.read(feedSortProvider.notifier).state =
                              FeedSort.latest,
                        ),
                        _Tab(
                          label: 'Terpopuler',
                          active: sort == FeedSort.popular,
                          onTap: () => ref.read(feedSortProvider.notifier).state =
                              FeedSort.popular,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // List
                Expanded(
                  child: feedAsync.when(
                    loading: () => _SkeletonList(),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('Gagal memuat feed\n$e',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    data: (submissions) {
                      if (submissions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_library_outlined,
                                  size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              const Text('Belum ada foto hari ini',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              const Text('Jadilah yang pertama submit!',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/camera'),
                                icon: const Icon(Icons.camera_alt_rounded,
                                    size: 16),
                                label: const Text('Ambil Foto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        itemCount: submissions.length,
                        itemBuilder: (ctx, i) {
                          final s = submissions[i];
                          final isVoted = _pendingVotes.containsKey(s.submissionId)
                              ? _pendingVotes[s.submissionId]!
                              : votedIds.contains(s.submissionId);
                          return PostCard(
                            submission: s,
                            isVoted: isVoted,
                            isOwn: ref.read(authStateProvider).value?.uid ==
                                s.userId,
                            onVote: () => _handleVote(s, isVoted),
                            onReport: () => setState(
                                () => _reportingSubmissionId = s.submissionId),
                            onTap: () =>
                                context.push('/post/${s.submissionId}'),
                            onUserTap: () =>
                                context.push('/user/${s.userId}'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_reportingSubmissionId != null)
            ReportSheet(
              onClose: () => setState(() => _reportingSubmissionId = null),
              onConfirm: (reason) =>
                  _handleReport(_reportingSubmissionId!, reason),
            ),
        ],
      ),
    );
  }
}

// ─── Tab button ───────────────────────────────
class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 36,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ─── Skeleton loading list ────────────────────
class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      itemCount: 3,
      itemBuilder: (ctx, i) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardSurface,
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 12, color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 6)),
                      Container(width: 72, height: 10, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            Container(height: 240, color: Colors.white),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Container(width: 70, height: 32, color: Colors.white,
                      margin: const EdgeInsets.only(right: 8)),
                  const Spacer(),
                  Container(width: 80, height: 36, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}