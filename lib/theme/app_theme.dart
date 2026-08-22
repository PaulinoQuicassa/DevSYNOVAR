import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF2F5FEA);
  static const primaryDark = Color(0xFF1E3FBF);
  static const primaryTint = Color(0xFFEAF0FE);
  static const accentPurple = Color(0xFF7C3AED);

  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);

  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFEF3C7);
  static const amber = Color(0xFFF59E0B);

  static const critical = Color(0xFFDC2626);
  static const criticalBg = Color(0xFFFEE2E2);

  static const background = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF12151C);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  static const border = Color(0xFFE7EAF3);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accentPurple],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const almostGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF17307E)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
