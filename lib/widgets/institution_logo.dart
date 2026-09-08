import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'bank_logo.dart';

/// Ficheiros descarregados uma única vez das páginas oficiais (nunca
/// hotlink em runtime -- ver `docs`/commit desta alteração) para
/// `assets/logos/`, declarados em `pubspec.yaml`. Só cobre as
/// instituições cujo logótipo oficial já foi identificado e transferido;
/// as restantes continuam com o fallback de iniciais coloridas -- nunca
/// um ícone partido.
const Map<String, String> _logoAssets = {
  'siac': 'assets/logos/siac.png',
  'bfa': 'assets/logos/bfa.svg',
};

/// Logótipo de uma instituição -- imagem real quando disponível
/// localmente, com fallback automático (e silencioso) para as iniciais
/// em círculo colorido do [BankLogo] caso o ficheiro não exista ou falhe
/// a carregar.
class InstitutionLogo extends StatelessWidget {
  final String institutionId;
  final String monogram;
  final Color color;
  final double size;

  const InstitutionLogo({
    super.key,
    required this.institutionId,
    required this.monogram,
    required this.color,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final asset = _logoAssets[institutionId];
    if (asset == null) {
      return BankLogo(monogram: monogram, color: color, size: size);
    }

    final fallback = BankLogo(monogram: monogram, color: color, size: size);
    final padding = size * 0.14;

    Widget image;
    if (asset.endsWith('.svg')) {
      image = SvgPicture.asset(
        asset,
        width: size - padding * 2,
        height: size - padding * 2,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      image = Image.asset(
        asset,
        width: size - padding * 2,
        height: size - padding * 2,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0xFFF1EFE8)),
      ),
      alignment: Alignment.center,
      child: image,
    );
  }
}
