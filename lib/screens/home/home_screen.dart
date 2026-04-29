import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_helper.dart';
import '../../models/user_model.dart';
import '../../models/challenge_model.dart';
import '../../models/submission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/submission_provider.dart';



class _Quest {
  final int id;
  final IconData icon;
  final String label;
  String detail;
  final String xp;
  bool done;

  _Quest({
    required this.id,
    required this.icon,
    required this.label,
    required this.detail,
    required this.xp,
    required this.done,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  // Track which quest IDs have already been auto-awarded this session
  final Set<int> _awardedQuests = {};

  final List<_Quest> _quests = [
    _Quest(
      id: 1,
      icon: Icons.camera_alt_rounded,
      label: 'Submit foto hari ini',
      detail: 'Selesaikan tantangan',
      xp: '+10 XP',
      done: false,
    ),
    _Quest(
      id: 2,
      icon: Icons.favorite_rounded,
      label: 'Dapat 3 vote',
      detail: '0/3 vote diterima',
      xp: '+15 XP',
      done: false,
    ),
    _Quest(
      id: 3,
      icon: Icons.thumb_up_rounded,
      label: 'Vote 5 foto orang lain',
      detail: '0/5 divote',
      xp: '+10 XP',
      done: false,
    ),
  ];

  final List<String> _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  String? _toastMsg;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _updateTimeLeft());
    });

    // Listen to total votes across all user submissions today — award Quest #2 XP once
    ref.listenManual(userSubmissionsProvider, (prev, next) {
      final today = DateTime.now();
      int todayVotes(List<SubmissionModel>? subs) {
        if (subs == null) return 0;
        return subs.where((s) {
          final d = s.submittedAt.toDate();
          return d.year == today.year && d.month == today.month && d.day == today.day;
        }).fold(0, (sum, s) => sum + s.voteCount);
      }

      final prevVotes = todayVotes(prev?.value);
      final nextVotes = todayVotes(next.value);
      if (prevVotes < 3 && nextVotes >= 3 && !_awardedQuests.contains(2)) {
        _awardedQuests.add(2);
        _awardQuestXp(15);
        _showToast('+15 XP didapat!');
      }
    });

    // Listen to dailyVotesGiven — award Quest #3 XP exactly once when threshold crossed.
    ref.listenManual(userModelProvider, (prev, next) {
      final prevGiven = prev?.value?.dailyVotesGiven ?? 0;
      final nextGiven = next.value?.dailyVotesGiven ?? 0;
      if (prevGiven < 5 && nextGiven >= 5 && !_awardedQuests.contains(3)) {
        _awardedQuests.add(3);
        _awardQuestXp(10);
        _showToast('+10 XP didapat!');
      }
    });
  }

  void _updateTimeLeft() {
    _timeLeft = DateHelper.countdownToMidnight();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Selamat pagi';
    if (h < 17) return 'Selamat siang';
    if (h < 20) return 'Selamat sore';
    return 'Selamat malam';
  }

  String get _countdownLabel {
    final h = _timeLeft.inHours;
    final m = _timeLeft.inMinutes.remainder(60);
    final s = _timeLeft.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  bool get _countdownUrgent =>
      _timeLeft.inHours == 0 && _timeLeft.inMinutes < 30;

  Future<void> _awardQuestXp(int xpAmount) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    final service = ref.read(firestoreServiceProvider);
    await service.incrementUserField(uid, 'total_xp', xpAmount);
    await service.incrementUserField(uid, 'weekly_points', xpAmount);
    await service.updateRankFromXp(uid,
        (ref.read(userModelProvider).value?.totalXp ?? 0) + xpAmount);
  }



  void _showToast(String msg) {
    setState(() => _toastMsg = msg);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _toastMsg = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelProvider);
    final challengesAsync = ref.watch(todayChallengesProvider);
    final submissionAsync = ref.watch(userTodaySubmissionProvider);
    final photoOfDayAsync = ref.watch(photoOfDayProvider);
    final allSubmissions = ref.watch(userSubmissionsProvider).value ?? [];

    final user = userAsync.value;
    final isAdmin = ref.watch(authStateProvider).value?.email == AppStrings.adminEmail;
    final challenges = challengesAsync.value ?? [];
    final submission = submissionAsync.value;
    final photoOfDay = photoOfDayAsync.value;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final streakDays = List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      return allSubmissions.any((s) {
        final d = s.submittedAt.toDate();
        return d.year == day.year && d.month == day.month && d.day == day.day;
      });
    });

    if (submission != null) {
      _quests[0].done = true;
      _quests[0].detail = 'Sudah terupload!';
    } else {
      _quests[0].done = false;
      _quests[0].detail = 'Selesaikan tantangan';
    }

    // Quest #2: total votes across all submissions today
    final today = DateTime.now();
    final votesReceived = allSubmissions.where((s) {
      final d = s.submittedAt.toDate();
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).fold<int>(0, (sum, s) => sum + s.voteCount);
    if (votesReceived >= 3) {
      _quests[1].done = true;
      _quests[1].detail = '3/3 vote diterima';
    } else {
      _quests[1].done = false;
      _quests[1].detail = '$votesReceived/3 vote diterima';
    }

    // Quest #3: UI only — XP is awarded in initState listener
    final votesGiven = user?.dailyVotesGiven ?? 0;
    if (votesGiven >= 5) {
      _quests[2].done = true;
      _quests[2].detail = '5/5 divote';
    } else {
      _quests[2].done = false;
      _quests[2].detail = '$votesGiven/5 divote';
    }

    final doneCount = _quests.where((q) => q.done).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                _buildHeader(context, user),
                const SizedBox(height: 24),
                _buildStatsRow(user),
                const SizedBox(height: 12),
                _buildXpBar(user),
                const SizedBox(height: 24),
                if (challenges.isNotEmpty)
                  _buildChallengesSection(context, challenges, submission)
                else
                  _buildNoChallengeCard(isAdmin),
                const SizedBox(height: 24),
                _buildStreakSection(streakDays),
                const SizedBox(height: 24),
                _buildQuestSection(doneCount),
                const SizedBox(height: 24),
                if (photoOfDay != null) _buildPhotoOfDay(context, photoOfDay),
              ],
            ),
          ),
          if (_toastMsg != null) _buildToast(_toastMsg!),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user) {
    final hasUnread = ref.watch(notificationsProvider).value
            ?.any((n) => n['read'] == false) ??
        false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user?.username ?? 'Pengguna',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _IconButton(
              onTap: () => context.push('/search'),
              child: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 8),
            _IconButton(
              onTap: () => context.push('/notifications'),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: AppColors.textSecondary, size: 22),
                  if (hasUnread)
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.cardSurface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Stack(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: (user != null &&
                            user.photoUrl.isNotEmpty &&
                            !user.photoUrl.startsWith('#'))
                        ? CachedNetworkImage(
                            imageUrl: user.photoUrl,
                            fit: BoxFit.cover,
                            width: 42,
                            height: 42,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(strokeWidth: 2),
                            errorWidget: (context, url, error) => Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                          )
                        : Text(
                            user?.username.isNotEmpty == true
                                ? user!.username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow(UserModel? user) {
    final points = user?.weeklyPoints ?? 0;
    final totalXp = user?.totalXp ?? 0;

    return Row(
      children: [
        _StatCard(
          icon: Icons.star_rounded,
          iconColor: AppColors.amber,
          label: 'Poin Minggu',
          value: points.toString(),
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.emoji_events_outlined,
          iconColor: AppColors.primary,
          label: 'Ranking',
          value: user?.rank ?? 'Rookie',
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFF22C55E),
          label: 'Total XP',
          value: totalXp.toString(),
        ),
      ],
    );
  }

  Widget _buildXpBar(UserModel? user) {
    final currentXp = user?.totalXp ?? 0;
    final nextXp = DateHelper.nextRankXp(currentXp);
    final progress = (currentXp / nextXp).clamp(0.0, 1.0);
    final rank = user?.rank ?? 'Rookie Snapper';

    String nextRankStr = 'SnapMaster';
    if (currentXp < 500) {
      nextRankStr = 'Rising Shooter';
    } else if (currentXp < 1500) {
      nextRankStr = 'Creative Eye';
    } else if (currentXp < 3000) {
      nextRankStr = 'SnapMaster';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rank,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_rounded,
                  size: 12, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(nextRankStr,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
              const Spacer(),
              if (currentXp < 3000)
                Text('$currentXp / $nextXp XP',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))
              else
                const Text('MAX RANK',
                    style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (_, val, w) => LinearProgressIndicator(
                value: val,
                minHeight: 7,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (currentXp < 3000)
            Text('${nextXp - currentXp} XP lagi untuk naik rank',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11))
          else
            const Text('Kamu telah mencapai rank tertinggi!',
                style: TextStyle(
                    color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNoChallengeCard(bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.camera_alt_rounded,
              color: AppColors.textMuted, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Belum ada tantangan hari ini',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isAdmin
                ? 'Buat tantangan baru atau seed data dummy'
                : 'Tunggu admin membuat tantangan hari ini.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12, height: 1.5),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/challenge/create'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Buat Tantangan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Menampilkan semua challenge hari ini (1–3) beserta tombol submit
  Widget _buildChallengesSection(BuildContext context,
      List<ChallengeModel> challenges, SubmissionModel? firstSubmission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        _SectionLabel(
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.access_time_rounded,
                size: 12,
                color: _countdownUrgent ? AppColors.amber : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(_countdownLabel,
                style: TextStyle(
                    color: _countdownUrgent
                        ? AppColors.amber
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
          child: Row(children: [
            const Icon(Icons.camera_alt_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              challenges.length > 1
                  ? 'Tantangan Hari Ini (${challenges.length})'
                  : 'Tantangan Hari Ini',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // One card per challenge
        ...challenges.map((c) => _buildSingleChallengeCard(context, c)),
        // Single submit button at bottom
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/camera'),
            icon: const Icon(Icons.camera_alt_rounded,
                size: 18, color: Colors.white),
            label: const Text('Ambil Foto Sekarang',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleChallengeCard(
      BuildContext context, ChallengeModel challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(challenge.title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2)),
          const SizedBox(height: 4),
          Text(challenge.description,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStreakSection(List<bool> streakDays) {
    final doneThisWeek = streakDays.where((d) => d).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 16, color: AppColors.amber),
              const SizedBox(width: 6),
              Text('$doneThisWeek Hari Minggu Ini',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(streakDays.length, (i) {
                  final done = streakDays[i];
                  final isToday = i == (DateTime.now().weekday - 1);
                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 5),
                      Text(_dayLabels[i],
                          style: TextStyle(
                            color: done
                                ? AppColors.primary
                                : isToday
                                    ? AppColors.textSecondary
                                    : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: done || isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text(
                doneThisWeek >= 7
                    ? 'Minggu sempurna! Pertahankan.'
                    : '$doneThisWeek/7 hari · jangan putus sekarang',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestSection(int doneCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          trailing: Text(
            '$doneCount/${_quests.length} selesai',
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          child: const Text('Quest Harian',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: _quests.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return _buildQuestTile(q, showDivider: i < _quests.length - 1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestTile(_Quest q, {required bool showDivider}) {
    return Column(
      children: [
        InkWell(
          onTap: null,
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            color: q.done
                ? AppColors.background.withValues(alpha: 0.5)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    q.done
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    key: ValueKey(q.done),
                    color: q.done ? AppColors.primary : AppColors.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.label,
                        style: TextStyle(
                          color: q.done
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: q.done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(q.detail,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: q.done
                        ? AppColors.background
                        : AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    q.xp,
                    style: TextStyle(
                      color: q.done ? AppColors.textMuted : AppColors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
              height: 1,
              color: AppColors.background,
              indent: 16,
              endIndent: 16),
      ],
    );
  }

  Widget _buildPhotoOfDay(BuildContext context, SubmissionModel photoOfDay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          trailing: GestureDetector(
            onTap: () => context.push('/feed'),
            child: const Text('Lihat semua',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          child: const Text('Photo of the Day',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.push('/post/${photoOfDay.submissionId}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: const Color(0xFFE8E0D8),
                      child: CachedNetworkImage(
                        imageUrl: photoOfDay.photoUrl,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) =>
                            const _PlaceholderPortraitImage(),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events_rounded,
                                size: 11, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Pemenang Kemarin',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        clipBehavior: Clip.antiAlias,
                        child: photoOfDay.userPhotoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: photoOfDay.userPhotoUrl,
                                fit: BoxFit.cover,
                              )
                            : Text(
                                photoOfDay.username.isNotEmpty
                                    ? photoOfDay.username[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(photoOfDay.username,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const Text('Challenge kemarin',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded,
                              size: 14, color: AppColors.amber),
                          const SizedBox(width: 4),
                          Text('${photoOfDay.voteCount}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToast(String msg) {
    return Positioned(
      top: 16,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF22C55E), size: 18),
              const SizedBox(width: 10),
              Text(msg,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _IconButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(height: 6),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final Widget child;
  final Widget? trailing;

  const _SectionLabel({required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: child),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Placeholder painters ──────────────────────────────────────────────────────

class _PlaceholderPortraitImage extends StatelessWidget {
  const _PlaceholderPortraitImage();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PortraitPatternPainter(),
      child: Container(),
    );
  }
}

class _PortraitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFE8E0D8);
    canvas.drawRect(Offset.zero & size, paint);

    paint.color = AppColors.amber.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 45, paint);
    paint.color = AppColors.primary.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), 55, paint);

    paint.color = AppColors.primary.withValues(alpha: 0.35);
    canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.35), 22, paint);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.72),
          width: 46,
          height: 44),
      const Radius.circular(23),
    );
    canvas.drawRRect(bodyRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
