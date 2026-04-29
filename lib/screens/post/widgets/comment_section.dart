import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/comment_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/submission_provider.dart';
import '../../../services/supabase_service.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String submissionId;
  final String submissionOwnerId;

  const CommentSection({
    super.key,
    required this.submissionId,
    required this.submissionOwnerId,
  });

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty || _submitting) return;

    final uid = ref.read(authStateProvider).value?.uid;
    final user = ref.read(userModelProvider).value;
    if (uid == null || user == null) return;

    setState(() => _submitting = true);
    _ctrl.clear();
    _focusNode.unfocus();

    try {
      final service = ref.read(firestoreServiceProvider);
      final comment = CommentModel(
        commentId: '',
        submissionId: widget.submissionId,
        userId: uid,
        username: user.username,
        userPhotoUrl: user.photoUrl,
        body: body,
        createdAt: Timestamp.now(),
      );
      await service.addComment(comment);

      // Sync comment ke Supabase (relational database)
      try {
        await SupabaseService.instance.addComment(
          userId: uid,
          submissionId: widget.submissionId,
          content: body,
        );
      } catch (e) {
        debugPrint('Gagal sync comment ke Supabase (data dummy tidak ada di DB): $e');
      }

      // Notify submission owner
      await service.sendCommentNotification(
        recipientId: widget.submissionOwnerId,
        commenterId: uid,
        commenterUsername: user.username,
        submissionId: widget.submissionId,
        commentPreview: body,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim komentar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(CommentModel comment) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .deleteComment(comment.commentId, widget.submissionId);

      // Sync delete ke Supabase (relational database)
      try {
        await SupabaseService.instance.deleteComment(comment.commentId);
      } catch (e) {
        debugPrint('Gagal sync delete comment ke Supabase: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus komentar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync =
        ref.watch(commentsProvider(widget.submissionId));
    final uid = ref.watch(authStateProvider).value?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Komentar',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              commentsAsync.when(
                data: (list) => Text(
                  '(${list.length})',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // ── Comment list ────────────────────────────────
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Gagal memuat komentar',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13)),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Belum ada komentar. Jadilah yang pertama!',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: comments.length,
              itemBuilder: (_, i) => _CommentTile(
                comment: comments[i],
                isOwn: comments[i].userId == uid,
                onDelete: () => _delete(comments[i]),
              ),
            );
          },
        ),

        // ── Input bar ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.5),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 1,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar…',
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _submitting
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _submitting
                      ? const Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Single comment tile ────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final bool isOwn;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isOwn,
    required this.onDelete,
  });

  Color _avatarColor() {
    try {
      final hex = comment.userPhotoUrl;
      if (hex.startsWith('#') && hex.length == 7) {
        return Color(int.parse('FF${hex.substring(1)}', radix: 16));
      }
    } catch (_) {}
    return AppColors.primary;
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(comment.createdAt.toDate());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final initial = comment.username.isNotEmpty
        ? comment.username[0].toUpperCase()
        : 'U';
    final isPhoto = comment.userPhotoUrl.isNotEmpty &&
        !comment.userPhotoUrl.startsWith('#');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPhoto ? Colors.transparent : _avatarColor(),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: isPhoto
                ? Image.network(comment.userPhotoUrl,
                    fit: BoxFit.cover,
                    width: 32,
                    height: 32,
                    errorBuilder: (context2, error2, stack2) => Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)))
                : Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),

          // Body
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isOwn
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOwn
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.username,
                        style: TextStyle(
                          color: isOwn
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Kamu',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _timeAgo(),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 10),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}