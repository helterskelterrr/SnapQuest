import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/challenge_model.dart';
import '../../models/submission_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../services/storage_service.dart';

const int _maxSubmissionsPerChallenge = 3;

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  File? _pickedFile;
  bool _submitting = false;
  double _uploadProgress = 0;
  bool _done = false;
  String? _error;
  final _captionCtrl = TextEditingController();
  ChallengeModel? _selectedChallenge;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final status = await permission.request();

    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      _showPermissionDialog(
        source == ImageSource.camera ? 'Kamera' : 'Galeri',
      );
      return;
    }

    if (!status.isGranted) return;

    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1200,
      );
      if (xfile == null) return;
      setState(() {
        _pickedFile = File(xfile.path);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Gagal memilih foto: $e');
    }
  }

  void _showPermissionDialog(String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Izin $type Diperlukan',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Buka Pengaturan dan aktifkan izin $type untuk SnapQuest.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final challenges = ref.read(todayChallengesProvider).value ?? [];
    final challenge = _selectedChallenge ?? (challenges.isNotEmpty ? challenges.first : null);
    final user = ref.read(userModelProvider).value;
    final uid = ref.read(authStateProvider).value?.uid;

    if (_pickedFile == null) return;
    if (challenge == null) {
      setState(() => _error = 'Tidak ada tantangan hari ini');
      return;
    }
    if (uid == null || user == null) {
      setState(() => _error = 'Tidak terautentikasi');
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0;
      _error = null;
    });

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final count = await firestoreService.getUserSubmissionCountForChallenge(
          uid, challenge.challengeId);
      if (count >= _maxSubmissionsPerChallenge) {
        setState(() {
          _submitting = false;
          _error = 'Kamu sudah submit $_maxSubmissionsPerChallenge foto untuk tantangan ini.';
        });
        return;
      }
    } catch (_) {
      // Jika check gagal, lanjut — Firestore rules sebagai guard akhir
    }

    try {
      final progressTimer = Timer.periodic(
          const Duration(milliseconds: 80), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() {
          if (_uploadProgress < 0.85) _uploadProgress += 0.05;
        });
      });

      final storageService = StorageService();
      final photoUrl = await storageService.uploadSubmission(
        challenge.challengeId,
        uid,
        _pickedFile!,
      );

      progressTimer.cancel();
      setState(() => _uploadProgress = 0.95);

      final submissionId = const Uuid().v4();
      final submission = SubmissionModel(
        submissionId: submissionId,
        userId: uid,
        challengeId: challenge.challengeId,
        challengeTitle: challenge.title,
        challengeDate: challenge.date,
        username: user.username,
        userPhotoUrl: user.photoUrl,
        photoUrl: photoUrl,
        caption: _captionCtrl.text.trim(),
        voteCount: 0,
        reportCount: 0,
        isHidden: false,
        submittedAt: Timestamp.now(),
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createSubmission(submission);

      // Award XP for submitting
      await firestoreService.incrementUserField(uid, 'total_xp', 10);
      await firestoreService.incrementUserField(uid, 'weekly_points', 10);
      final latestUser = await firestoreService.getUser(uid);
      if (latestUser != null) {
        await firestoreService.updateRankFromXp(uid, latestUser.totalXp);
      }

      setState(() {
        _uploadProgress = 1.0;
        _submitting = false;
        _done = true;
      });
    } catch (e) {
      setState(() {
        _submitting = false;
        _uploadProgress = 0;
        _error = 'Upload gagal: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(todayChallengesProvider);
    final challenges = challengesAsync.value ?? [];

    // Auto-select first challenge if none selected yet
    if (_selectedChallenge == null && challenges.isNotEmpty) {
      _selectedChallenge = challenges.first;
    }

    if (_done) return _DoneView();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.navBackground,
              child: Row(
                children: [
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
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Submit Foto',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        if (_selectedChallenge != null)
                          Text(_selectedChallenge!.title,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Challenge selector (jika > 1 challenge)
                  if (challenges.length > 1) ...[
                    _ChallengePicker(
                      challenges: challenges,
                      selected: _selectedChallenge,
                      onSelect: (c) => setState(() => _selectedChallenge = c),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_selectedChallenge != null) ...[
                    // Single challenge banner
                    _ChallengeBanner(challenge: _selectedChallenge!),
                    const SizedBox(height: 20),
                  ],

                  // Photo picker area
                  GestureDetector(
                    onTap: _submitting ? null : () => _showPickerSheet(context),
                    child: Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _pickedFile != null
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_pickedFile!, fit: BoxFit.cover),
                                if (!_submitting)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () => _showPickerSheet(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(children: [
                                          Icon(Icons.refresh_rounded,
                                              size: 14, color: Colors.white),
                                          SizedBox(width: 5),
                                          Text('Ganti',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                        ]),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_photo_alternate_rounded,
                                      size: 32, color: AppColors.primary),
                                ),
                                const SizedBox(height: 14),
                                const Text('Pilih atau ambil foto',
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                const Text('Ketuk untuk memilih dari galeri atau kamera',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Caption
                  TextField(
                    controller: _captionCtrl,
                    maxLength: 150,
                    maxLines: 3,
                    enabled: !_submitting,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tulis caption... (opsional)',
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.cardSurface,
                      counterStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: AppColors.textMuted.withValues(alpha: 0.15),
                            width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Upload progress
                  if (_submitting) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        minHeight: 6,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mengunggah... ${(_uploadProgress * 100).toInt()}%',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: (_pickedFile == null || _submitting || _selectedChallenge == null)
                          ? null
                          : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.upload_rounded, size: 20),
                      label: Text(
                        _submitting ? 'Mengunggah...' : 'Submit Foto',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.25)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.bolt_rounded, size: 14, color: AppColors.amber),
                      SizedBox(width: 8),
                      Text('+10 XP untuk setiap submission (max 3 per tantangan)',
                          style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Ambil Foto',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan kamera',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.amber),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                subtitle: const Text('Pilih foto yang sudah ada',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Challenge picker (multiple challenges) ───────────────────────────────────
class _ChallengePicker extends StatelessWidget {
  final List<ChallengeModel> challenges;
  final ChallengeModel? selected;
  final ValueChanged<ChallengeModel> onSelect;

  const _ChallengePicker({
    required this.challenges,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pilih Tantangan',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...challenges.map((c) {
          final isSelected = selected?.challengeId == c.challengeId;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Row(children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(c.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.4)),
                    ],
                  ),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Single challenge banner ──────────────────────────────────────────────────
class _ChallengeBanner extends StatelessWidget {
  final ChallengeModel challenge;
  const _ChallengeBanner({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tantangan Hari Ini',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text(challenge.title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(challenge.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Done view ────────────────────────────────────────────────────────────────
class _DoneView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 42, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text('Foto Terkirim!',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text(
                    'Foto kamu sudah masuk ke community feed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: AppColors.amber),
                      SizedBox(width: 6),
                      Text('+10 XP diperoleh!',
                          style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/feed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text('Lihat Feed',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Ke Home',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
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