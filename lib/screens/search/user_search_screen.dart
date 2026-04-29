import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

// ── Search state ──────────────────────────────────────────────────────────────

class _SearchState {
  final bool loading;
  final List<UserModel> results;
  final String? error;
  const _SearchState({
    this.loading = false,
    this.results = const [],
    this.error,
  });
  _SearchState copyWith({
    bool? loading,
    List<UserModel>? results,
    String? error,
  }) =>
      _SearchState(
        loading: loading ?? this.loading,
        results: results ?? this.results,
        error: error ?? this.error,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  _SearchState _state = const _SearchState();

  @override
  void initState() {
    super.initState();
    // Auto-focus on open
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _state = const _SearchState());
      return;
    }
    setState(() => _state = _state.copyWith(loading: true, error: null));
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String query) async {
    try {
      final results =
          await ref.read(firestoreServiceProvider).searchUsers(query);
      if (mounted) {
        setState(() => _state = _SearchState(results: results));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state =
            _SearchState(error: 'Gagal mencari user. Coba lagi.'));
      }
    }
  }

  void _clear() {
    _ctrl.clear();
    setState(() => _state = const _SearchState());
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header + search bar ────────────────────
            Container(
              color: AppColors.navBackground,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
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
                    const Text('Cari Pengguna',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1.5),
                    ),
                    child: Row(children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          onChanged: _onChanged,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'Cari username…',
                            hintStyle: TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 13),
                          ),
                        ),
                      ),
                      if (_ctrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: _clear,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 18),
                          ),
                        ),
                    ]),
                  ),
                ],
              ),
            ),

            // ── Results body ───────────────────────────
            Expanded(child: _buildBody(currentUid)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String? currentUid) {
    if (_ctrl.text.trim().isEmpty) {
      return _EmptyHint(
        icon: Icons.person_search_rounded,
        title: 'Cari pengguna SnapQuest',
        subtitle: 'Ketik username untuk menemukan teman',
      );
    }

    if (_state.loading) {
      return const Center(
          child:
              CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
    }

    if (_state.error != null) {
      return _EmptyHint(
        icon: Icons.wifi_off_rounded,
        title: 'Gagal memuat',
        subtitle: _state.error!,
      );
    }

    if (_state.results.isEmpty) {
      return _EmptyHint(
        icon: Icons.search_off_rounded,
        title: 'Tidak ada hasil',
        subtitle: 'Tidak ada pengguna dengan username "${_ctrl.text.trim()}"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _state.results.length,
      itemBuilder: (_, i) {
        final user = _state.results[i];
        final isMe = user.userId == currentUid;
        return _UserTile(
          user: user,
          isMe: isMe,
          onTap: () => context.push('/user/${user.userId}'),
        );
      },
    );
  }
}

// ── User result tile ──────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isMe;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isMe,
    required this.onTap,
  });

  Color _avatarColor() {
    try {
      final hex = user.photoUrl;
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
    final isPhoto =
        user.photoUrl.isNotEmpty && !user.photoUrl.startsWith('#');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isPhoto ? Colors.transparent : _avatarColor(),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: isPhoto
                ? Image.network(user.photoUrl,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorBuilder: (context2, error2, stack2) => Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)))
                : Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      user.username,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isMe
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.bolt_rounded,
                      size: 11, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(user.rank,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ]),
              ],
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.star_rounded,
                    size: 11, color: AppColors.amber),
                const SizedBox(width: 3),
                Text('${user.totalXp} XP',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ]),
      ),
    );
  }
}

// ── Empty / hint state ────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, color: AppColors.textMuted, size: 28),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}