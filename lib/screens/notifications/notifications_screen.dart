import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final notifsAsync = ref.watch(notificationsProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final uid = ref.read(authStateProvider).value?.uid;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: notifsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (notifs) {
            final unread = notifs.where((n) => n['read'] == false).length;

            return Column(
              children: [
                Container(height: 4, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),

                // Header
                Container(
                  color: c.navBackground,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: c.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.primary.withValues(alpha: 0.2), width: 1.5),
                            ),
                            child: Icon(Icons.arrow_back_rounded, color: c.textSecondary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Notifikasi', style: TextStyle(color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(20)),
                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                        const Spacer(),
                        if (unread > 0 && uid != null)
                          TextButton.icon(
                            onPressed: () => firestoreService.markAllNotificationsRead(uid),
                            icon: Icon(Icons.done_all_rounded, size: 14, color: c.primary),
                            label: Text('Baca semua', style: TextStyle(color: c.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                      ]),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: notifs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: c.cardSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: c.primary.withValues(alpha: 0.15)),
                                ),
                                child: Icon(Icons.notifications_off_rounded, color: c.textMuted, size: 28),
                              ),
                              const SizedBox(height: 12),
                              Text('Belum Ada Notifikasi', style: TextStyle(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                              Text('Notifikasi baru akan muncul di sini', style: TextStyle(color: c.textMuted, fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: notifs.length,
                          itemBuilder: (context, i) {
                            final n = notifs[i];
                            return _NotifTile(
                              notif: n,
                              onTap: () {
                                if (n['read'] == false) {
                                  firestoreService.markNotificationRead(n['id'] as String);
                                }
                                final subId = n['submission_id'] as String?;
                                if (subId != null) context.push('/post/$subId');
                              },
                              onDelete: () => firestoreService.deleteNotification(n['id'] as String),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotifTile({required this.notif, required this.onTap, required this.onDelete});

  IconData get _icon {
    switch (notif['type']) {
      case 'vote': return Icons.favorite_rounded;
      case 'challenge': return Icons.camera_alt_rounded;
      case 'achievement': return Icons.star_rounded;
      case 'rank': return Icons.emoji_events_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color get _iconColor {
    switch (notif['type']) {
      case 'vote': return const Color(0xFFF59E0B);
      case 'challenge': return AppColors.success;
      case 'achievement': return AppColors.amber;
      case 'rank': return AppColors.primary;
      default: return AppColors.primary;
    }
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    final ts = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} mnt lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isRead = notif['read'] == true;
    final sender = notif['sender_username'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? c.cardSurface : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? c.primary.withValues(alpha: 0.15) : c.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or icon
            sender != null && sender.isNotEmpty
                ? CircleAvatar(
                    radius: 22,
                    backgroundColor: _iconColor,
                    child: Text(
                      sender[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  )
                : Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_icon, size: 20, color: _iconColor),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif['title'] as String? ?? '',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(notif['body'] as String? ?? '', style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(_timeAgo(notif['created_at']), style: TextStyle(color: c.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.delete_outline_rounded, size: 15, color: c.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
