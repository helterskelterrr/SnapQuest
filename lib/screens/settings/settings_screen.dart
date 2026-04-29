import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

// ─── Screen ───────────────────────────────────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifVote = true;
  bool _notifChallenge = true;
  bool _notifAchiev = true;
  bool _highQuality = false;
  bool _showDeleteConfirm = false;
  String? _toast;

  // Auto-update ranking timer
  Timer? _rankTimer;
  bool _rankUpdating = false;

  @override
  void initState() {
    super.initState();
    // Auto-update ranking setiap 3 menit
    _rankTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _autoUpdateRank();
    });
  }

  @override
  void dispose() {
    _rankTimer?.cancel();
    super.dispose();
  }

  Future<void> _autoUpdateRank() async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) return;
    try {
      setState(() => _rankUpdating = true);
      final service = ref.read(firestoreServiceProvider);
      final user = await service.getUser(uid);
      if (user != null) {
        await service.updateRankFromXp(uid, user.totalXp);
      }
    } catch (_) {
      // silent — background update
    } finally {
      if (mounted) setState(() => _rankUpdating = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    context.go('/login');
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 2500),
        () => mounted ? setState(() => _toast = null) : null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider.notifier).isDark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                    height: 4,
                    decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient)),
                // Header
                Container(
                  color: AppColors.navBackground,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Pengaturan',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                    // Indikator auto-rank update
                    if (_rankUpdating)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text('Update ranking...',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ]),
                ),

                // List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // ── Notifikasi ──
                      _SectionHeader(label: 'Notifikasi'),
                      _ToggleTile(
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.error,
                        title: 'Vote pada Foto Saya',
                        subtitle: 'Saat ada yang memvote fotomu',
                        value: _notifVote,
                        onChanged: (v) {
                          setState(() => _notifVote = v);
                          _showToast(v
                              ? 'Notifikasi vote diaktifkan'
                              : 'Notifikasi vote dimatikan');
                        },
                      ),
                      _ToggleTile(
                        icon: Icons.camera_alt_rounded,
                        iconColor: AppColors.success,
                        title: 'Tantangan Baru',
                        subtitle: 'Pengingat challenge harian',
                        value: _notifChallenge,
                        onChanged: (v) {
                          setState(() => _notifChallenge = v);
                          _showToast(v
                              ? 'Notifikasi tantangan diaktifkan'
                              : 'Notifikasi tantangan dimatikan');
                        },
                      ),
                      _ToggleTile(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppColors.amber,
                        title: 'Pencapaian & Reward',
                        subtitle: 'Badge dan sertifikat baru',
                        value: _notifAchiev,
                        onChanged: (v) {
                          setState(() => _notifAchiev = v);
                          _showToast(v
                              ? 'Notifikasi pencapaian diaktifkan'
                              : 'Notifikasi pencapaian dimatikan');
                        },
                      ),

                      // ── Tampilan ──
                      _SectionHeader(label: 'Tampilan'),
                      _ToggleTile(
                        icon: Icons.dark_mode_rounded,
                        iconColor: AppColors.primary,
                        title: 'Mode Gelap',
                        subtitle: isDark
                            ? 'Tema gelap aktif'
                            : 'Tema terang aktif',
                        value: isDark,
                        onChanged: (v) {
                          ref.read(themeModeProvider.notifier).toggle();
                          _showToast(v
                              ? 'Mode gelap diaktifkan'
                              : 'Mode terang diaktifkan');
                        },
                      ),

                      // ── Ranking ──
                      _SectionHeader(label: 'Ranking'),
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              width: 1.5),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.emoji_events_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Auto Update Ranking',
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text('Ranking diperbarui otomatis setiap 3 menit',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Aktif',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),

                      // ── Upload ──
                      _SectionHeader(label: 'Upload Foto'),
                      _ToggleTile(
                        icon: Icons.hd_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        title: 'Kualitas Tinggi',
                        subtitle: _highQuality
                            ? 'Upload resolusi penuh (lebih besar)'
                            : 'Hemat kuota dengan mode standar',
                        value: _highQuality,
                        onChanged: (v) {
                          setState(() => _highQuality = v);
                          _showToast(v
                              ? 'Mode kualitas tinggi diaktifkan'
                              : 'Mode hemat kuota diaktifkan');
                        },
                      ),

                      // ── Privasi & Keamanan ──
                      _SectionHeader(label: 'Privasi & Keamanan'),
                      _NavTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.primary,
                        title: 'Ubah Password',
                        subtitle: 'Perbarui keamanan akunmu',
                        onTap: () => _showToast('Fitur segera hadir'),
                      ),
                      _NavTile(
                        icon: Icons.mail_outline_rounded,
                        iconColor: AppColors.success,
                        title: 'Verifikasi Email',
                        subtitle: 'Cek status verifikasi emailmu',
                        onTap: () => _showToast('Email sudah terverifikasi'),
                      ),

                      // ── Tentang ──
                      _SectionHeader(label: 'Tentang & Bantuan'),
                      _NavTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.primary,
                        title: 'Versi Aplikasi',
                        subtitle: 'SnapQuest v1.2.0',
                        onTap: () {},
                      ),
                      _NavTile(
                        icon: Icons.gavel_rounded,
                        iconColor: AppColors.textMuted,
                        title: 'Syarat & Ketentuan',
                        onTap: () => _showToast('Membuka syarat & ketentuan'),
                      ),
                      _NavTile(
                        icon: Icons.privacy_tip_outlined,
                        iconColor: AppColors.textMuted,
                        title: 'Kebijakan Privasi',
                        onTap: () => _showToast('Membuka kebijakan privasi'),
                      ),

                      // ── Zona Bahaya ──
                      _SectionHeader(label: 'Zona Bahaya', danger: true),
                      _NavTile(
                        icon: Icons.logout_rounded,
                        iconColor: AppColors.error,
                        title: 'Keluar dari Akun',
                        danger: true,
                        onTap: _logout,
                      ),
                      _NavTile(
                        icon: Icons.delete_forever_rounded,
                        iconColor: AppColors.error,
                        title: 'Hapus Akun',
                        subtitle: 'Tindakan ini tidak dapat dibatalkan',
                        danger: true,
                        onTap: () =>
                            setState(() => _showDeleteConfirm = true),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Delete confirm
          if (_showDeleteConfirm)
            _DangerDialog(
              title: 'Hapus Akun?',
              body:
                  'Semua data, foto, dan progres kamu akan dihapus permanen dan tidak dapat dipulihkan.',
              confirmLabel: 'Ya, Hapus Akun',
              onConfirm: () {
                setState(() => _showDeleteConfirm = false);
                context.go('/login');
              },
              onCancel: () =>
                  setState(() => _showDeleteConfirm = false),
            ),

          // Toast
          if (_toast != null)
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 16)
                    ],
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
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
}

// ─── Tiles ────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool danger;
  const _SectionHeader({required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: danger ? AppColors.error : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.textMuted.withValues(alpha: 0.15),
        ),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: danger
              ? AppColors.error.withValues(alpha: 0.05)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: danger
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: danger
                            ? AppColors.error
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: danger ? AppColors.error : AppColors.textMuted,
              size: 18),
        ]),
      ),
    );
  }
}

// ─── Danger dialog ────────────────────────────
class _DangerDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DangerDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 28),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: BorderSide(
                            color: AppColors.textMuted.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(confirmLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
