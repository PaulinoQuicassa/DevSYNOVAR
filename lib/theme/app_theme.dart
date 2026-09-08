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

/// Escala única de espaçamento -- Fila Certa 2.0 (redesign UX/UI):
/// substitui os `EdgeInsets`/tamanhos ad hoc espalhados pelos ecrãs por
/// um pequeno conjunto de valores reutilizáveis.
class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

class AppRadius {
  AppRadius._();

  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Larguras acima das quais o layout deixa de ser tratado como "telemóvel
/// estreito" -- usado só para limitar a largura do conteúdo em ecrã largo
/// (web/tablet), nunca para reescrever a lógica de negócio dos ecrãs.
class AppBreakpoints {
  AppBreakpoints._();

  static const tablet = 600.0;
  static const desktopWeb = 900.0;

  /// Largura máxima de uma coluna de conteúdo central -- em ecrãs largos
  /// (web em desktop) o conteúdo fica centrado nesta largura em vez de
  /// esticar de ponta a ponta.
  static const maxContentWidth = 480.0;
}

/// Escala tipográfica nomeada -- antes desta alteração cada ecrã escrevia
/// o seu próprio `TextStyle(...)` inline (186 ocorrências espalhadas por
/// 34 ficheiros, sem nenhuma escala partilhada). Construída sobre a mesma
/// família (Plus Jakarta Sans) já usada por `AppTheme.light`.
class AppTextStyles {
  AppTextStyles._();

  static const display = TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2, color: AppColors.textPrimary);
  static const h1 = TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const h2 = TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const h3 = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const body = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4);
  static const bodyStrong = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, height: 1.4);
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted);
  static const label = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6);
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
