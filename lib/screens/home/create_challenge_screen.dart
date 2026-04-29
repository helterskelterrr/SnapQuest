import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_helper.dart';
import '../../providers/auth_provider.dart';

class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;
  bool _seeding = false;
  String? _toast;

  bool get _isAdmin {
    final user = ref.read(authStateProvider).value;
    return user?.email == AppStrings.adminEmail;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 2500),
        () => mounted ? setState(() => _toast = null) : null);
  }

  Future<void> _createChallenge() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showToast('Judul tidak boleh kosong');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _showToast('Deskripsi tidak boleh kosong');
      return;
    }
    setState(() => _saving = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final today = DateHelper.todayString();

      final count = await service.getChallengeCountForDate(today);
      if (count >= 3) {
        _showToast('Sudah ada 3 tantangan untuk hari ini (maksimal)');
        setState(() => _saving = false);
        return;
      }

      await service.createChallenge(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        date: today,
      );

      if (!mounted) return;
      _showToast('Tantangan ke-${count + 1} berhasil dibuat!');
      _titleCtrl.clear();
      _descCtrl.clear();
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.pop();
    } catch (e) {
      _showToast('Gagal membuat tantangan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _seedAll() async {
    setState(() => _seeding = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      await service.seedAll();
      if (!mounted) return;
      _showToast('Data dummy berhasil diseed!');
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.pop();
    } catch (e) {
      _showToast('Gagal seed data: $e');
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Akses Terbatas',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hanya admin yang bisa membuat tantangan.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

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
                    const Text('Buat Tantangan',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Buat tantangan manual ──
                      _SectionHeader(label: 'Tantangan Baru Hari Ini (maks. 3)'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Judul Tantangan',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _titleCtrl,
                              maxLength: 80,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 15),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'Contoh: Foto bayangan yang unik',
                                hintStyle: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 14),
                                filled: true,
                                fillColor: AppColors.background,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2),
                                      width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text('Deskripsi',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descCtrl,
                              maxLength: 200,
                              maxLines: 3,
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 15),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText:
                                    'Jelaskan tantangan dengan detail...',
                                hintStyle: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 14),
                                filled: true,
                                fillColor: AppColors.background,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2),
                                      width: 1.5),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _createChallenge,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.add_circle_rounded,
                                        size: 18),
                                label: const Text('Buat Tantangan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Seed data dummy ──
                      _SectionHeader(label: 'Data Dummy (Dev)'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.science_rounded,
                                  color: AppColors.amber, size: 16),
                              const SizedBox(width: 8),
                              const Text('Seed Semua Data',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 6),
                            const Text(
                              'Tambahkan tantangan 7 hari, 5 user dummy dengan poin & XP, dan submission dummy untuk leaderboard & Photo of the Day.',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _seeding ? null : _seedAll,
                                icon: _seeding
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.auto_fix_high_rounded,
                                        size: 18),
                                label: const Text('Seed Data Sekarang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.amber,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        color: AppColors.primary.withValues(alpha: 0.5)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 16)
                    ],
                  ),
                  child: Text(_toast!,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
    ]);
  }
}
