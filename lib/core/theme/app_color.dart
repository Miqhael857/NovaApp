import 'package:flutter/material.dart';

/// Colour tokens from the NovaPay design spec (design/artboards/Specs.dc.html).
abstract final class AppColors {
  static const navy900 = Color(0xFF0B1F3A);
  static const navy700 = Color(0xFF1B3A66);
  static const gold500 = Color(0xFFC9A227);
  static const gold600 = Color(0xFF8A6D0F);
  static const goldTint = Color(0xFFFBF3D5);
  static const navyTint = Color(0xFFE8EDF5);
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const inputBorder = Color(0xFFCBD5E1);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF64748B);
  static const onNavySecondary = Color(0xFFA9B8CF);
  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFDCFCE7);
  static const pending = Color(0xFFB45309);
  static const pendingBg = Color(0xFFFEF3C7);
  static const error = Color(0xFFB91C1C);
  static const errorBg = Color(0xFFFEE2E2);
  static const offlineBanner = Color(0xFF334155);
}

abstract final class AppColor {
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy900,
      primary: AppColors.navy900,
      onPrimary: AppColors.surface,
      secondary: AppColors.gold500,
      onSecondary: AppColors.navy900,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    );

    return ThemeData(
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.goldTint,
      ),
    );
  }
}
