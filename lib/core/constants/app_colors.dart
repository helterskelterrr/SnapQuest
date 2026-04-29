import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Accent colors (same in both themes) ─────────────────────────
  static const Color primary = Color(0xFF97B3AE);
  static const Color amber = Color(0xFFE07B65);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  // ── Light theme ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF0EEEA);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3A37);
  static const Color textSecondary = Color(0xFF627370);
  static const Color textMuted = Color(0xFFB8C9C7);

  // ── Dark theme ───────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF161C1B);
  static const Color cardSurfaceDark = Color(0xFF1F2827);
  static const Color navBackgroundDark = Color(0xFF1A2221);
  static const Color textPrimaryDark = Color(0xFFE8F0EE);
  static const Color textSecondaryDark = Color(0xFF8FABA7);
  static const Color textMutedDark = Color(0xFF4A6260);

  // ── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF97B3AE), Color(0xFFD2E0D3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFE07B65), Color(0xFFF2C3B9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF9F9F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Dynamic colors that adapt to current brightness.
class DynamicColors {
  final bool isDark;
  const DynamicColors(this.isDark);

  Color get background => isDark ? AppColors.backgroundDark : AppColors.background;
  Color get cardSurface => isDark ? AppColors.cardSurfaceDark : AppColors.cardSurface;
  Color get navBackground => isDark ? AppColors.navBackgroundDark : AppColors.navBackground;
  Color get textPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textMuted => isDark ? AppColors.textMutedDark : AppColors.textMuted;

  // Accents unchanged
  Color get primary => AppColors.primary;
  Color get amber => AppColors.amber;
  Color get error => AppColors.error;
  Color get success => AppColors.success;
}

extension AppColorsContext on BuildContext {
  DynamicColors get colors {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return DynamicColors(isDark);
  }
}
