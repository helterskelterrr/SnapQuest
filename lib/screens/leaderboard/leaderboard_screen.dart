import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/submission_provider.dart';

const _podiumColors = [
  Color(0xFFF59E0B), // 1st – gold
  Color(0xFFA5B4FC), // 2nd – silver/lavender
  Color(0xFF8B5CF6), // 3rd – bronze/purple
];

const _tierIcons = {
  'Grandmaster':     Icons.auto_awesome_rounded,
  'Legend':          Icons.emoji_events_rounded,
  'Pro Shooter':     Icons.military_tech_rounded,
  'Sharp Eye':       Icons.bolt_rounded,
  'Rising Shooter':  Icons.star_rounded,
  'Amateur':         Icons.radio_button_checked_rounded,
  'Rookie Snapper':  Icons.local_fire_department_rounded,
};

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _showWeekly = true;

  @override
  Widget build(BuildContext context) {
    // UX-05: Only watch the active provider to avoid two simultaneous Firestore streams
    final leaderboardAsync = ref.watch(
      _showWeekly ? weeklyLeaderboardProvider : allTimeLeaderboardProvider,
    );
    final currentUid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.amber, size: 22),
                      const SizedBox(width: 8),
                      const Text('Leaderboard',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: const Text('Live',
                            style: TextStyle(
                                color: AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(children: [
                      _LeadTab(
                          label: 'Minggu Ini',
                          active: _showWeekly,
                          onTap: () => setState(() => _showWeekly = true)),
                      _LeadTab(
                          label: 'Semua Waktu',
                          active: !_showWeekly,
                          onTap: () => setState(() => _showWeekly = false)),
                    ]),
                  ),
                ],
              ),
            ),

            Expanded(
              child: leaderboardAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Text('Gagal memuat: $e',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ),
                data: (users) {
                  if (users.isEmpty) {
                    return const Center(
                      child: Text('Belum ada data leaderboard',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                    );
                  }

                  final top3 = users.take(3).toList();
                  final rest = users.skip(3).toList();
                  final meIndex = users.indexWhere((u) => u.userId == currentUid);
                  final me = meIndex >= 0 ? users[meIndex] : null;
                  final myRank = meIndex >= 0 ? meIndex + 1 : null;
                  // User is in scrollable rest list (position 4+)
                  final meInRestList = meIndex >= 3;
                  // User is in podium (top 3) — section might be scrolled out of view
                  final meInPodium = meIndex >= 0 && meIndex < 3;

                  return Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            // Podium
                            Container(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.08),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (top3.length > 1)
                                    _PodiumCard(
                                        user: top3[1],
                                        position: 2,
                                        isMe: top3[1].userId == currentUid,
                                        showWeekly: _showWeekly),
                                  const SizedBox(width: 12),
                                  if (top3.isNotEmpty)
                                    _PodiumCard(
                                        user: top3[0],
                                        position: 1,
                                        isMe: top3[0].userId == currentUid,
                                        showWeekly: _showWeekly),
                                  const SizedBox(width: 12),
                                  if (top3.length > 2)
                                    _PodiumCard(
                                        user: top3[2],
                                        position: 3,
                                        isMe: top3[2].userId == currentUid,
                                        showWeekly: _showWeekly),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: List.generate(rest.length, (i) {
                                  final user = rest[i];
                                  final rank = i + 4;
                                  return _PlayerRow(
                                    user: user,
                                    rank: rank,
                                    isMe: user.userId == currentUid,
                                    showWeekly: _showWeekly,
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      // Show sticky rank bar when user's row is not visible:
                      // - in podium (top 3) and has scrolled down past it
                      // - in rest list (rank 4+) — always show so they can see rank
                      if (me != null && myRank != null && (meInPodium || meInRestList))
                        _MyStickyRank(
                            user: me, rank: myRank, showWeekly: _showWeekly),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Podium card ──────────────────────────────
class _PodiumCard extends StatelessWidget {
  final UserModel user;
  final int position;
  final bool isMe;
  final bool showWeekly;
  const _PodiumCard(
      {required this.user, required this.position, required this.isMe, required this.showWeekly});

  @override
  Widget build(BuildContext context) {
    final sizes = {1: 62.0, 2: 50.0, 3: 46.0};
    final heights = {1: 100.0, 2: 72.0, 3: 56.0};
    final color = _podiumColors[position - 1];
    final sz = sizes[position]!;
    final h = heights[position]!;
    final initial = user.username.isNotEmpty
        ? user.username[0].toUpperCase()
        : 'U';
    final avatarColor = _colorFromHex(user.photoUrl);

    return GestureDetector(
      onTap: () => context.push('/user/${user.userId}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded,
            size: position == 1 ? 26 : 20, color: color),
        const SizedBox(height: 6),
        Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            color: avatarColor,
            shape: BoxShape.circle,
            border: Border.all(
                color: isMe ? AppColors.primary : color, width: isMe ? 3 : 2),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.4), blurRadius: 12)
            ],
          ),
          alignment: Alignment.center,
          child: Text(initial,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: position == 1 ? 18.0 : 13.0,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          child: Text(user.username,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: isMe ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.star_rounded, size: 9, color: AppColors.amber),
            const SizedBox(width: 3),
            Text('${showWeekly ? user.weeklyPoints : user.totalXp}',
                style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 6),
        Container(
          width: position == 1 ? 88 : 74,
          height: h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.5)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          alignment: Alignment.center,
            child: Text('$position',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

// ─── Player row ───────────────────────────────
class _PlayerRow extends StatelessWidget {
  final UserModel user;
  final int rank;
  final bool isMe;
  final bool showWeekly;
  const _PlayerRow(
      {required this.user,
      required this.rank,
      required this.isMe,
      required this.showWeekly});

  @override
  Widget build(BuildContext context) {
    final initial =
        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';
    final avatarColor = _colorFromHex(user.photoUrl);
    final points = showWeekly ? user.weeklyPoints : user.totalXp;

    return GestureDetector(
      onTap: () => context.push('/user/${user.userId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.primary.withValues(alpha: 0.15),
            width: 1.5),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text('#$rank',
              style: TextStyle(
                  color: isMe ? AppColors.primary : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 4),
        Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(color: avatarColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(user.username,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isMe
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1),
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
              Row(children: [
                Icon(
                    _tierIcons[user.rank] ??
                        Icons.star_rounded,
                    size: 11,
                    color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(user.rank,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ]),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.star_rounded, size: 11, color: AppColors.amber),
            const SizedBox(width: 4),
            Text('$points',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    ));
  }
}

// ─── My sticky rank bar ───────────────────────
class _MyStickyRank extends StatelessWidget {
  final UserModel user;
  final int rank;
  final bool showWeekly;
  const _MyStickyRank(
      {required this.user, required this.rank, required this.showWeekly});

  @override
  Widget build(BuildContext context) {
    final points = showWeekly ? user.weeklyPoints : user.totalXp;
    final initial =
        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U';
    final avatarColor = _colorFromHex(user.photoUrl);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
            top: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.15))),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Row(children: [
          Text('#$rank',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(user.username,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1),
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
                ]),
                Row(children: [
                  Icon(
                      _tierIcons[user.rank] ?? Icons.star_rounded,
                      size: 11,
                      color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(user.rank,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Icon(Icons.star_rounded,
                  size: 11, color: AppColors.amber),
              const SizedBox(width: 4),
              Text('$points',
                  style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Tab ──────────────────────────────────────
class _LeadTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LeadTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: active ? Colors.white : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────
Color _colorFromHex(String hex) {
  try {
    if (hex.startsWith('#') && hex.length == 7) {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    }
  } catch (_) {}
  return AppColors.primary;
}
