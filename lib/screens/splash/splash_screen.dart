import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _ready = false;

  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  late final AnimationController _contentCtrl;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack)
        .drive(Tween(begin: 0.6, end: 1.0));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _contentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _contentSlide =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic)
            .drive(Tween(begin: const Offset(0, 0.08), end: Offset.zero));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _logoCtrl.forward().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _contentCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),

              // Logo mark
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoOpacity,
                  child: _LogoMark(),
                ),
              ),

              const SizedBox(height: 36),

              // Title block
              FadeTransition(
                opacity: _logoOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Snap',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: 'Quest',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Satu foto.\nSatu tantangan.\nSetiap hari.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Bottom CTA section
              if (_ready)
                SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Primary CTA
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => context.push('/register'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textPrimary,
                              foregroundColor: AppColors.background,
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: const Text('Mulai Bermain'),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Secondary CTA
                        SizedBox(
                          height: 52,
                          child: TextButton(
                            onPressed: () => context.push('/login'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Sudah punya akun? Masuk',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

              if (!_ready) const SizedBox(height: 180),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.camera_alt_rounded, size: 36, color: Colors.white),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
