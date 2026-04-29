import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/submission_model.dart';
import '../../providers/submission_provider.dart';

class AllSubmissionsScreen extends ConsumerStatefulWidget {
  const AllSubmissionsScreen({super.key});

  @override
  ConsumerState<AllSubmissionsScreen> createState() =>
      _AllSubmissionsScreenState();
}

class _AllSubmissionsScreenState
    extends ConsumerState<AllSubmissionsScreen> {
  String _filter = 'all'; // all | top3
  String _sortBy = 'date'; // date | votes

  List<SubmissionModel> _applyFilter(List<SubmissionModel> list) {
    var result = List<SubmissionModel>.from(list);
    if (_filter == 'top3') {
      // top3 = submissions with at least 1 vote, top by votes
      result.sort((a, b) => b.voteCount - a.voteCount);
      result = result.take(3).toList();
      return result;
    }
    switch (_sortBy) {
      case 'votes':
        result.sort((a, b) => b.voteCount - a.voteCount);
      default: // date – already newest first from Firestore
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(userSubmissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
                height: 4,
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient)),

            // Header
            submissionsAsync.when(
              loading: () => _buildHeader(context, [], isLoading: true),
              error: (e, s) => _buildHeader(context, []),
              data: (subs) => _buildHeader(context, subs),
            ),

            // Grid
            Expanded(
              child: submissionsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Text('Gagal memuat: $e',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ),
                data: (subs) {
                  final list = _applyFilter(subs);
                  if (list.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 40, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text('Tidak ada submission',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _SubmissionCard(sub: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<SubmissionModel> subs,
      {bool isLoading = false}) {
    final totalVotes = subs.fold<int>(0, (s, a) => s + a.voteCount);
    final top3Count =
        subs.where((s) => s.voteCount > 0).toList()
          ..sort((a, b) => b.voteCount - a.voteCount);

    return Container(
      color: AppColors.navBackground,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Semua Submission',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  Text(
                    isLoading ? 'Memuat...' : '${subs.length} foto terkirim',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Sort dropdown
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: DropdownButton<String>(
                value: _sortBy,
                isDense: true,
                underline: const SizedBox.shrink(),
                dropdownColor: AppColors.cardSurface,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
                icon: const Icon(Icons.arrow_drop_down_rounded,
                    size: 16, color: AppColors.textMuted),
                items: const [
                  DropdownMenuItem(
                      value: 'date',
                      child: Text('Terbaru',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12))),
                  DropdownMenuItem(
                      value: 'votes',
                      child: Text('Vote',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _sortBy = v ?? 'date'),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Stats
          Row(children: [
            _StatBadge(
                icon: Icons.camera_alt_rounded,
                color: AppColors.primary,
                value: '${subs.length}',
                label: 'Total'),
            const SizedBox(width: 8),
            _StatBadge(
                icon: Icons.favorite_rounded,
                color: AppColors.error,
                value: '$totalVotes',
                label: 'Vote'),
            const SizedBox(width: 8),
            _StatBadge(
                icon: Icons.star_rounded,
                color: AppColors.success,
                value: '${top3Count.length > 3 ? 3 : top3Count.length}',
                label: 'Top 3'),
          ]),
          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                    label: 'Semua',
                    active: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Top 3',
                    active: _filter == 'top3',
                    onTap: () => setState(() => _filter = 'top3')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter chip ──────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8)
                ]
              : [],
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Stat badge ───────────────────────────────
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatBadge(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }
}

// ─── Submission card ──────────────────────────
class _SubmissionCard extends StatelessWidget {
  final SubmissionModel sub;
  const _SubmissionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${sub.submissionId}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  sub.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: sub.photoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              child: const Center(
                                  child: Icon(Icons.image_rounded,
                                      color: AppColors.textMuted,
                                      size: 40))),
                        )
                      : Container(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          child: const Center(
                              child: Icon(Icons.image_rounded,
                                  color: AppColors.textMuted, size: 40)),
                        ),
                  // Gradient + stats overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black45, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      alignment: Alignment.bottomLeft,
                      child: Row(children: [
                        const Icon(Icons.favorite_rounded,
                            size: 10, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('${sub.voteCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Container(
              color: AppColors.cardSurface,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.caption.isNotEmpty ? sub.caption : 'Tanpa caption',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(sub.submittedAt.toDate()),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
