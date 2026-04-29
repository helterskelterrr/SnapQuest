import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

const _colors = [
  Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF22C55E),
  Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF06B6D4),
  Color(0xFFF97316), Color(0xFF14B8A6),
];

// Map color object → hex string stored in Firestore
String _colorToHex(Color c) {
  final r = (c.r * 255.0).round().clamp(0, 255);
  final g = (c.g * 255.0).round().clamp(0, 255);
  final b = (c.b * 255.0).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
}

int _hexToIndex(String hex) {
  for (int i = 0; i < _colors.length; i++) {
    if (_colorToHex(_colors[i]) == hex.toLowerCase()) return i;
  }
  return 0;
}

bool _isNetworkUrl(String s) =>
    s.startsWith('http://') || s.startsWith('https://');

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _userCtrl;
  late TextEditingController _bioCtrl;

  int _colorIdx = 0;
  bool _saving = false;
  bool _nameTouched = false;
  bool _userTouched = false;
  String? _usernameValidationError;
  String? _toast;
  bool _initialized = false;

  // Originals (set once data loads)
  String _origName = '';
  String _origUser = '';
  String _origBio = '';
  int _origColor = 0;
  String _origPhotoUrl = '';

  // Foto yang dipilih dari galeri
  File? _pickedImage;
  // URL foto profil saat ini (dari Firestore)
  String _currentPhotoUrl = '';

  // Apakah user memilih warna (bukan foto)
  bool _useColor = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _userCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
  }

  void _initFromUser() {
    final user = ref.read(userModelProvider).value;
    if (user == null || _initialized) return;
    _initialized = true;
    _origName = user.username;
    _origUser = user.username;
    _origBio = user.bio;
    _origPhotoUrl = user.photoUrl;
    _currentPhotoUrl = user.photoUrl;

    if (_isNetworkUrl(user.photoUrl)) {
      // Sudah punya foto asli
      _useColor = false;
    } else {
      _useColor = true;
      _origColor = _hexToIndex(user.photoUrl);
      _colorIdx = _origColor;
    }

    _nameCtrl.text = user.username;
    _userCtrl.text = user.username;
    _bioCtrl.text = user.bio;
    _nameCtrl.addListener(() => setState(() { _usernameValidationError = null; }));
    _userCtrl.addListener(() => setState(() { _usernameValidationError = null; }));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _nameCtrl.text != _origName ||
      _userCtrl.text != _origUser ||
      _bioCtrl.text != _origBio ||
      _pickedImage != null ||
      (_useColor && _colorIdx != _origColor) ||
      (!_useColor && _currentPhotoUrl != _origPhotoUrl);

  String get _nameErr {
    if (!_nameTouched) return '';
    if (_nameCtrl.text.trim().isEmpty) return 'Nama tidak boleh kosong';
    if (_nameCtrl.text.trim().length < 2) return 'Nama minimal 2 karakter';
    return '';
  }

  String get _userErr {
    if (!_userTouched) return '';
    if (_userCtrl.text.trim().isEmpty) return 'Username tidak boleh kosong';
    if (_userCtrl.text.trim().length < 3) return 'Username minimal 3 karakter';
    if (_usernameValidationError != null) return _usernameValidationError!;
    return '';
  }

  String get _initials => _nameCtrl.text.trim().length >= 2
      ? _nameCtrl.text.trim().substring(0, 2).toUpperCase()
      : '?';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (xfile == null) return;
      setState(() {
        _pickedImage = File(xfile.path);
        _useColor = false;
      });
    } catch (e) {
      _showToast('Gagal memilih foto: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Pilih dari Galeri',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.amber),
              ),
              title: const Text('Ambil Foto',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
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
                  color: AppColors.textMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.palette_rounded,
                    color: AppColors.textMuted),
              ),
              title: const Text('Gunakan Warna Avatar',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _pickedImage = null;
                  _useColor = true;
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _nameTouched = true;
      _userTouched = true;
    });
    if (_nameErr.isNotEmpty || _userErr.isNotEmpty) {
      _showToast('Harap periksa kembali isian');
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) throw Exception('Tidak terautentikasi');

      String photoValue;

      if (_pickedImage != null) {
        // Upload foto ke Firebase Storage
        final storageService = StorageService();
        photoValue = await storageService.uploadAvatar(uid, _pickedImage!);
      } else if (_useColor) {
        photoValue = _colorToHex(_colors[_colorIdx]);
      } else {
        photoValue = _currentPhotoUrl;
      }

      final newUsername = _nameCtrl.text.trim();
      final service = ref.read(firestoreServiceProvider);

      // Check if username is taken by someone else
      final taken = await service.isUsernameTaken(newUsername, excludeUid: uid);
      if (taken) {
        setState(() {
          _saving = false;
          _usernameValidationError = 'Username sudah dipakai';
        });
        return;
      }

      await service.updateUserProfile(uid, newUsername, photoValue, bio: _bioCtrl.text.trim());

      if (!mounted) return;
      setState(() => _saving = false);
      _showToast('Profil berhasil disimpan!');
      Future.delayed(const Duration(milliseconds: 1000),
          () { if (mounted) context.pop(); });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showToast('Gagal menyimpan: $e');
    }
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(milliseconds: 2500),
        () => mounted ? setState(() => _toast = null) : null);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userModelProvider, (_, next) {
      if (!_initialized && next.value != null) {
        setState(() => _initFromUser());
      }
    });
    _initFromUser();

    final avatarColor = _colors[_colorIdx];

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
                      horizontal: 16, vertical: 12),
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
                    const Expanded(
                      child: Text('Edit Profil',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ),
                    AnimatedOpacity(
                      opacity: _isDirty ? 1 : 0.4,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton.icon(
                        onPressed: (_saving || !_isDirty) ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_rounded, size: 15),
                        label: const Text('Simpan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ]),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    children: [
                      // Avatar picker
                      Center(
                        child: Column(children: [
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Stack(
                              children: [
                                // Avatar preview
                                _buildAvatarPreview(avatarColor),
                                // Edit overlay
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.amber,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.background,
                                          width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: const Text('Ubah foto profil',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),

                          // Color picker — hanya tampil saat mode warna
                          if (_useColor) ...[
                            const SizedBox(height: 16),
                            const Text('Pilih warna avatar',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: List.generate(
                                _colors.length,
                                (i) => GestureDetector(
                                  onTap: () => setState(() => _colorIdx = i),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _colors[i],
                                      shape: BoxShape.circle,
                                      boxShadow: _colorIdx == i
                                          ? [
                                              BoxShadow(
                                                  color: _colors[i]
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 8,
                                                  spreadRadius: 2)
                                            ]
                                          : [],
                                      border: _colorIdx == i
                                          ? Border.all(
                                              color: Colors.white, width: 2.5)
                                          : null,
                                    ),
                                    child: _colorIdx == i
                                        ? const Icon(Icons.check_rounded,
                                            size: 18, color: Colors.white)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ]),
                      ),

                      // Name field
                      _Label(label: 'Nama Tampilan', hasErr: _nameErr.isNotEmpty),
                      const SizedBox(height: 8),
                      _ThemedField(
                        controller: _nameCtrl,
                        maxLength: 32,
                        hasErr: _nameErr.isNotEmpty,
                        onChanged: (_) => setState(() {}),
                        onBlur: () => setState(() => _nameTouched = true),
                      ),
                      if (_nameErr.isNotEmpty) _ErrText(err: _nameErr),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('${_nameCtrl.text.length}/32',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ),
                      const SizedBox(height: 14),

                      // Username field
                      _Label(label: 'Username', hasErr: _userErr.isNotEmpty),
                      const SizedBox(height: 8),
                      _ThemedField(
                        controller: _userCtrl,
                        maxLength: 20,
                        prefix: const Text('@',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 15)),
                        hasErr: _userErr.isNotEmpty,
                        onChanged: (v) {
                          final clean = v
                              .toLowerCase()
                              .replaceAll(RegExp(r'[^a-z0-9_]'), '');
                          _userCtrl.value = TextEditingValue(
                            text: clean,
                            selection: TextSelection.collapsed(
                                offset: clean.length),
                          );
                          setState(() {});
                        },
                        onBlur: () => setState(() => _userTouched = true),
                      ),
                      if (_userErr.isNotEmpty)
                        _ErrText(err: _userErr)
                      else
                        const Text(
                            'Huruf kecil, angka, dan underscore saja',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('${_userCtrl.text.length}/20',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ),
                      const SizedBox(height: 14),

                      // Bio textarea
                      const _Label(label: 'Bio'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bioCtrl,
                        maxLength: 120,
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.cardSurface,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.2),
                                width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_bioCtrl.text.length}/120',
                          style: TextStyle(
                              color: _bioCtrl.text.length > 100
                                  ? AppColors.error
                                  : AppColors.textMuted,
                              fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildAvatarPreview(Color avatarColor) {
    const double size = 88;

    if (_pickedImage != null) {
      return ClipOval(
        child: Image.file(
          _pickedImage!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (!_useColor && _isNetworkUrl(_currentPhotoUrl)) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _currentPhotoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, _) => _colorAvatar(avatarColor, size),
        ),
      );
    }

    return _colorAvatar(avatarColor, size);
  }

  Widget _colorAvatar(Color color, double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardSurface, width: 3),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      alignment: Alignment.center,
      child: Text(_initials,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800)),
    );
  }
}

// ─── Helper widgets ───────────────────────────
class _Label extends StatelessWidget {
  final String label;
  final bool hasErr;
  const _Label({required this.label, this.hasErr = false});

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          color: hasErr ? AppColors.error : AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600));
}

class _ErrText extends StatelessWidget {
  final String err;
  const _ErrText({required this.err});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              size: 13, color: AppColors.error),
          const SizedBox(width: 4),
          Text(err,
              style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ]),
      );
}

class _ThemedField extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;
  final bool hasErr;
  final Widget? prefix;
  final ValueChanged<String> onChanged;
  final VoidCallback onBlur;

  const _ThemedField({
    required this.controller,
    required this.maxLength,
    required this.hasErr,
    required this.onChanged,
    required this.onBlur,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) {
        if (!f) onBlur();
      },
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        onChanged: onChanged,
        style:
            const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: prefix != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: prefix)
              : null,
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: AppColors.cardSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: hasErr
                    ? AppColors.error
                    : AppColors.primary.withValues(alpha: 0.2),
                width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: hasErr ? AppColors.error : AppColors.primary,
                width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
