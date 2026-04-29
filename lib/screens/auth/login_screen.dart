import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  bool _emailTouched = false;
  bool _passTouched = false;

  String get _emailErr {
    if (!_emailTouched) return '';
    if (_emailCtrl.text.isEmpty) return 'Email tidak boleh kosong';
    if (!_emailRegex.hasMatch(_emailCtrl.text)) return 'Format email tidak valid';
    return '';
  }

  String get _passErr {
    if (!_passTouched) return '';
    if (_passCtrl.text.isEmpty) return 'Password tidak boleh kosong';
    if (_passCtrl.text.length < 6) return 'Password minimal 6 karakter';
    return '';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailTouched = true;
      _passTouched = true;
    });
    if (_emailErr.isNotEmpty || _passErr.isNotEmpty) return;

    setState(() => _loading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      // Save FCM token for push notifications
      if (credential.user != null) {
        await NotificationService().saveFcmToken(credential.user!.uid);
        
        // Sync ke Supabase untuk pengguna lama agar tidak error Foreign Key
        try {
          final firestoreDoc = await ref.read(firestoreServiceProvider)
              .getUser(credential.user!.uid);
              
          if (firestoreDoc != null) {
            await SupabaseService.instance.createUser(
              uid: credential.user!.uid,
              username: firestoreDoc.username.toLowerCase(),
              email: firestoreDoc.email,
              photoUrl: firestoreDoc.photoUrl,
            );
          }
        } catch (e) {
          debugPrint('Gagal sinkronisasi user ke Supabase saat login: $e');
        }
      }
      // GoRouter akan otomatis redirect ke /home karena authState berubah
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.mapAuthError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan email terlebih dahulu untuk reset password'),
        ),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link reset password telah dikirim ke email kamu'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.mapAuthError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient top bar
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  _BackButton(onTap: () => context.pop()),
                  const SizedBox(height: 32),

                  // Hero
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selamat Datang\nKembali',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk dan lanjutkan tantangan foto harianmu',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.6),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  _InputField(
                    label: 'Email',
                    hint: 'nama@email.com',
                    controller: _emailCtrl,
                    icon: Icons.mail_outline_rounded,
                    error: _emailErr,
                    onChanged: (_) => setState(() {}),
                    onBlur: () => setState(() => _emailTouched = true),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _InputField(
                    label: 'Password',
                    hint: 'Minimal 6 karakter',
                    controller: _passCtrl,
                    icon: Icons.lock_outline_rounded,
                    error: _passErr,
                    obscure: !_showPass,
                    showPassword: _showPass,
                    onTogglePassword: () => setState(() => _showPass = !_showPass),
                    onChanged: (_) => setState(() {}),
                    onBlur: () => setState(() => _passTouched = true),
                  ),
                  const SizedBox(height: 8),

                  // Forgot
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleForgotPassword,
                      child: const Text('Lupa password?',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _AuthSubmitButton(
                    label: 'Masuk',
                    loading: _loading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text('Daftar sekarang',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Register Screen
// ─────────────────────────────────────────────
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();

  bool _showPass = false;
  bool _showConf = false;
  bool _loading = false;
  int _selectedColor = 0;

  final _avatarColors = const [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
  ];

  Map<String, bool> _touched = {
    'name': false,
    'user': false,
    'email': false,
    'pass': false,
    'conf': false
  };

  String err(String key) {
    if (!_touched[key]!) return '';
    switch (key) {
      case 'name':
        if (_nameCtrl.text.isEmpty) return 'Nama tidak boleh kosong';
        if (_nameCtrl.text.length < 2) return 'Nama minimal 2 karakter';
        return '';
      case 'user':
        if (_userCtrl.text.isEmpty) return 'Username tidak boleh kosong';
        if (_userCtrl.text.length < 3) return 'Username minimal 3 karakter';
        return '';
      case 'email':
        if (_emailCtrl.text.isEmpty) return 'Email tidak boleh kosong';
        if (!_emailRegex.hasMatch(_emailCtrl.text)) return 'Format email tidak valid';
        return '';
      case 'pass':
        if (_passCtrl.text.isEmpty) return 'Password tidak boleh kosong';
        if (_passCtrl.text.length < 6) return 'Password minimal 6 karakter';
        return '';
      case 'conf':
        if (_confCtrl.text != _passCtrl.text) return 'Password tidak cocok';
        return '';
    }
    return '';
  }

  static final _uppercaseRegex = RegExp(r'[A-Z]');
  static final _digitRegex = RegExp(r'[0-9]');
  static final _specialRegex = RegExp(r'[^A-Za-z0-9]');

  int get _strength {
    final p = _passCtrl.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(_uppercaseRegex)) s++;
    if (p.contains(_digitRegex)) s++;
    if (p.contains(_specialRegex)) s++;
    return s;
  }

  Future<void> _handleRegister() async {
    setState(() => _touched = {for (var k in _touched.keys) k: true});
    if (['name', 'user', 'email', 'pass', 'conf'].any((k) => err(k).isNotEmpty)) {
      return;
    }

    setState(() => _loading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      // 1. Create user in Firebase Auth
      final credential = await authService.signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );

      if (credential.user != null) {
        // 2. Create user document in Firestore
        final hexColor = '#${_avatarColors[_selectedColor].value.toRadixString(16).substring(2).toUpperCase()}';

        await firestoreService.createUser(
          uid: credential.user!.uid,
          email: _emailCtrl.text.trim(),
          displayName: _nameCtrl.text.trim(),
          username: _userCtrl.text.trim().toLowerCase(),
          avatarColor: hexColor,
        );

        // Sync user ke Supabase (relational database)
        await SupabaseService.instance.createUser(
          uid: credential.user!.uid,
          username: _userCtrl.text.trim().toLowerCase(),
          email: _emailCtrl.text.trim(),
          photoUrl: hexColor,
        );

        // 3. Save FCM token while we still have the authenticated uid
        await NotificationService().saveFcmToken(credential.user!.uid);
        // 4. Sign out so user must log in manually
        await authService.signOut();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat! Silakan masuk.'),
        ),
      );
      context.go('/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.mapAuthError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColors[_selectedColor];
    final initials = _nameCtrl.text.length >= 2
        ? _nameCtrl.text.substring(0, 2).toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
                height: 4,
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Row(
                    children: [
                      _BackButton(onTap: () => context.pop()),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Buat Akun Baru',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('Bergabung dan mulai tantangan harianmu',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar picker
                  Column(
                    children: [
                      Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: avatarColor,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.cardSurface, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: avatarColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8))
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.background, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _avatarColors.length,
                          (i) => GestureDetector(
                            onTap: () => setState(() => _selectedColor = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _avatarColors[i],
                                shape: BoxShape.circle,
                                boxShadow: _selectedColor == i
                                    ? [
                                        BoxShadow(
                                            color: _avatarColors[i]
                                                .withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2)
                                      ]
                                    : [],
                                border: _selectedColor == i
                                    ? Border.all(
                                        color: Colors.white, width: 2.5)
                                    : null,
                              ),
                              child: _selectedColor == i
                                  ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _InputField(
                    label: 'Nama Tampilan',
                    hint: 'Nama lengkap kamu',
                    controller: _nameCtrl,
                    icon: Icons.person_outline_rounded,
                    error: err('name'),
                    onChanged: (_) => setState(() {}),
                    onBlur: () => setState(() => _touched['name'] = true),
                  ),
                  const SizedBox(height: 14),
                  _InputField(
                    label: 'Username',
                    hint: 'username_kamu',
                    controller: _userCtrl,
                    icon: Icons.alternate_email_rounded,
                    error: err('user'),
                    onChanged: (_) => setState(() {}),
                    onBlur: () => setState(() => _touched['user'] = true),
                  ),
                  const SizedBox(height: 14),
                  _InputField(
                    label: 'Email',
                    hint: 'nama@email.com',
                    controller: _emailCtrl,
                    icon: Icons.mail_outline_rounded,
                    error: err('email'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    onBlur: () => setState(() => _touched['email'] = true),
                  ),
                  const SizedBox(height: 14),
                  _InputField(
                    label: 'Password',
                    hint: 'Minimal 6 karakter',
                    controller: _passCtrl,
                    icon: Icons.lock_outline_rounded,
                    obscure: !_showPass,
                    showPassword: _showPass,
                    onTogglePassword: () => setState(() => _showPass = !_showPass),
                    error: err('pass'),
                    onChanged: (_) => setState(() {}),
                    onBlur: () => setState(() => _touched['pass'] = true),
                  ),
                  if (_passCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _StrengthBar(strength: _strength),
                  ],
                  const SizedBox(height: 14),
                  _InputField(
                    label: 'Konfirmasi Password',
                    hint: 'Ulangi password',
                    controller: _confCtrl,
                    icon: Icons.lock_outline_rounded,
                    obscure: !_showConf,
                    showPassword: _showConf,
                    onTogglePassword: () => setState(() => _showConf = !_showConf),
                    error: err('conf'),
                    onChanged: (_) => setState(() {}),
                    onBlur: () => setState(() => _touched['conf'] = true),
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.6),
                      children: [
                        TextSpan(text: 'Dengan mendaftar, kamu setuju dengan '),
                        TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                        TextSpan(text: ' dan '),
                        TextSpan(
                            text: 'Kebijakan Privasi',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AuthSubmitButton(
                    label: 'Buat Akun',
                    loading: _loading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun? ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text('Masuk',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared back button widget
// ─────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25), width: 1.5),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared auth submit button
// ─────────────────────────────────────────────
class _AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _AuthSubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared input field widget
// ─────────────────────────────────────────────
class _InputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final String error;
  final bool obscure;
  final bool? showPassword;
  final VoidCallback? onTogglePassword;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;
  final VoidCallback onBlur;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.error,
    required this.onChanged,
    required this.onBlur,
    this.obscure = false,
    this.showPassword,
    this.onTogglePassword,
    this.keyboardType,
  });

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final hasErr = widget.error.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: hasErr ? AppColors.error : AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (f) {
            setState(() => _focused = f);
            if (!f) widget.onBlur();
          },
          child: TextField(
            controller: widget.controller,
            obscureText: widget.obscure,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                  color: AppColors.textMuted, fontSize: 15),
              prefixIcon: Icon(widget.icon,
                  color: _focused ? AppColors.primary : AppColors.textMuted,
                  size: 20),
              suffixIcon: widget.onTogglePassword != null
                  ? IconButton(
                      onPressed: widget.onTogglePassword,
                      icon: Icon(
                        widget.showPassword == true
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: _focused
                  ? AppColors.cardSurface
                  : AppColors.cardSurface.withValues(alpha: 0.6),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasErr
                      ? AppColors.error
                      : AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: hasErr ? AppColors.error : AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (hasErr) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 13),
              const SizedBox(width: 5),
              Text(widget.error,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 12)),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Password strength bar
// ─────────────────────────────────────────────
class _StrengthBar extends StatelessWidget {
  final int strength;
  const _StrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.transparent,
      AppColors.error,
      AppColors.error,
      AppColors.amber,
      AppColors.success,
    ];
    final labels = ['', 'Lemah', 'Cukup', 'Kuat', 'Sangat Kuat'];
    final color = colors[strength.clamp(0, 4)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i < strength
                      ? color
                      : AppColors.textMuted.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        if (strength > 0) ...[
          const SizedBox(height: 4),
          Text(labels[strength.clamp(0, 4)],
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}
