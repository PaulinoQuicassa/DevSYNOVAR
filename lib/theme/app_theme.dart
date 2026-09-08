import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Marca "Fila Certa" -- paleta oficial (master prompt de design,
/// 2026-09-08). Os nomes dos tokens mantêm-se estáveis face à versão
/// anterior (mesmo que os valores mudem por completo) para não obrigar a
/// reescrever todos os ecrãs que já os usam -- só os valores em si e os
/// tokens novos (mint/pink) são novidade desta ronda.
class AppColors {
  AppColors._();

  // Primária/marca -- coral.
  static const primary = Color(0xFFD85A30);
  static const primaryLight = Color(0xFFF5C4B3);
  static const primaryMedium = Color(0xFFF0997B);
  static const onPrimaryLight = Color(0xFF4A1B0C);
  // Mantidos por compatibilidade com ecrãs existentes -- já não são usados
  // para gradientes (ver secção "sem gradientes" abaixo), só como tons
  // sólidos auxiliares dentro da família coral.
  static const primaryDark = Color(0xFFB5461F);
  static const primaryTint = Color(0xFFFCEEE8);

  // Secundária -- verde-menta ("ao vivo", instituições públicas/SIAC).
  static const mint = Color(0xFF1D9E75);
  static const mintLight = Color(0xFF9FE1CB);
  static const mintBg = Color(0xFFE1F5EE);
  static const onMintDark = Color(0xFF04342C);
  static const onMintMedium = Color(0xFF0F6E56);

  // Acento -- âmbar (contagens, instituições em geral).
  static const amber = Color(0xFFEF9F27);
  static const amberLight = Color(0xFFFAC775);
  static const amberBg = Color(0xFFFAEEDA);
  static const onAmberDark = Color(0xFF412402);
  static const onAmberMedium = Color(0xFF854F0B);

  // Destaque -- rosa (favoritos).
  static const pink = Color(0xFFD4537E);
  static const pinkLight = Color(0xFFF4C0D1);
  static const onPinkDark = Color(0xFF4B1528);
  // Compat: código antigo referia "accentPurple" como segunda cor de
  // marca -- passa a apontar para o rosa de destaque, o equivalente mais
  // próximo no novo desenho (um acento secundário, não a cor de "ao vivo").
  static const accentPurple = pink;

  // Semânticos (sucesso/aviso/crítico) -- o master prompt não define um
  // tom de "erro" à parte; mint cobre sucesso/ao vivo, âmbar cobre aviso,
  // e mantém-se vermelho para crítico (sinal universal de perigo, fora
  // das 4 famílias de marca de propósito, para nunca se confundir com
  // "favoritos" ou "instituição pública").
  static const success = mint;
  static const successBg = mintBg;
  static const warning = amber;
  static const warningBg = amberBg;
  static const critical = Color(0xFFDC2626);
  static const criticalBg = Color(0xFFFEE2E2);

  // Neutros.
  static const textPrimary = Color(0xFF2C2C2A);
  static const textSecondary = Color(0xFF5F5E5A);
  static const textMuted = textSecondary;
  static const border = Color(0xFFD3D1C7);
  static const borderLight = Color(0xFFF1EFE8);

  // Fundo creme quente -- nunca branco puro (regra da marca).
  static const background = Color(0xFFFFFCF7);
  static const surface = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Sem gradientes -- todas as superfícies em cor sólida (regra
  // não-negociável do master prompt de design). Os tokens `primaryGradient`/
  // `heroGradient`/`almostGradient` que existiam foram removidos de
  // propósito -- qualquer novo ecrã deve usar `color: AppColors.primary`
  // (ou outro tom sólido), nunca `gradient:`.
  // ---------------------------------------------------------------------
}

/// Escala única de espaçamento -- substitui os `EdgeInsets`/tamanhos ad
/// hoc espalhados pelos ecrãs por um pequeno conjunto de valores
/// reutilizáveis.
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
  static const xl = 26.0;
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

/// Escala tipográfica nomeada. Regra da marca: logótipo/títulos usam uma
/// fonte arredondada (Baloo 2, peso 700) em sentence case; corpo/listas/
/// metadados usam a fonte de sistema (peso 400/500); números de senha
/// usam sempre monoespaçada.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.baloo2(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.textPrimary);
  static TextStyle get h1 => GoogleFonts.baloo2(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle get h2 => GoogleFonts.baloo2(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static TextStyle get h3 => GoogleFonts.baloo2(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static const body = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.4);
  static const bodyStrong = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4);
  static const caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
  static const label = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.4);

  /// Números de senha (ex. "A-047") -- sempre monoespaçada.
  static TextStyle ticketCode({double fontSize = 17, Color color = AppColors.textPrimary}) =>
      GoogleFonts.robotoMono(fontSize: fontSize, fontWeight: FontWeight.w700, color: color);
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

    // Corpo/listas/metadados usam a fonte de sistema (regra da marca) --
    // sem wrapper do Google Fonts aqui; só os títulos (`AppTextStyles.h*`)
    // usam Baloo 2, explicitamente onde são construídos.
    final textTheme = base.textTheme.apply(
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
