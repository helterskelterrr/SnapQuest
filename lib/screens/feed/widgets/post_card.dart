import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/submission_model.dart';
import 'avatar.dart';

class PostCard extends StatelessWidget {
  final SubmissionModel submission;
  final bool isVoted;
  final bool isOwn;
  final VoidCallback onVote;
  final VoidCallback onReport;
  final VoidCallback onTap;
  final VoidCallback onUserTap;
  final VoidCallback? onComment;

  const PostCard({
    super.key,
    required this.submission,
    required this.isVoted,
    required this.isOwn,
    required this.onVote,
    required this.onReport,
    required this.onTap,
    required this.onUserTap,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row
          GestureDetector(
            onTap: onUserTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  FeedAvatar(
                    photoUrl: submission.userPhotoUrl,
                    username: submission.username,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(submission.username,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text(_timeAgo(submission.submittedAt),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  // Challenge label
                  if (submission.challengeTitle.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        submission.challengeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Image
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                    minWidth: double.infinity,
                  ),
                  child: submission.photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: submission.photoUrl,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          placeholder: (ctx2, url2) => Container(
                            height: 240,
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 2)),
                          ),
                          errorWidget: (ctx2, url2, err2) => Container(
                            height: 240,
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Center(
                                child: Icon(Icons.broken_image_rounded,
                                    color: AppColors.textMuted, size: 40)),
                          ),
                        )
                      : Container(
                          height: 240,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Center(
                              child: Icon(Icons.image_rounded,
                                  size: 48, color: AppColors.textMuted)),
                        ),
                ),
                // Vote count overlay
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Icon(Icons.favorite_rounded,
                          size: 12,
                          color: isVoted ? AppColors.amber : AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${submission.voteCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Caption + Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (submission.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(submission.caption,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5)),
                  ),
                Row(
                  children: [
                    // Heart toggle
                    GestureDetector(
                      onTap: isOwn ? null : onVote,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isVoted
                              ? AppColors.amber.withValues(alpha: 0.15)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          Icon(Icons.favorite_rounded,
                              size: 19,
                              color: isVoted
                                  ? AppColors.amber
                                  : AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text('${submission.voteCount}',
                              style: TextStyle(
                                  color: isVoted
                                      ? AppColors.amber
                                      : AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Comment count button
                    GestureDetector(
                      onTap: onComment ?? onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 17, color: AppColors.textMuted),
                          const SizedBox(width: 5),
                          Text('${submission.commentsCount}',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    // Report button (hide for own posts)
                    if (!isOwn) ...[
                      GestureDetector(
                        onTap: onReport,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.2)),
                          ),
                          child: const Icon(Icons.flag_rounded,
                              size: 14, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onVote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isVoted
                              ? AppColors.amber.withValues(alpha: 0.15)
                              : AppColors.primary,
                          foregroundColor:
                              isVoted ? AppColors.amber : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(isVoted ? 'Voted ✓' : 'Vote',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(Timestamp ts) {
    final now = DateTime.now();
    final diff = now.difference(ts.toDate());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}