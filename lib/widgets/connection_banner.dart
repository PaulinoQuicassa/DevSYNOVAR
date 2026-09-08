import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Aviso de "ligação interrompida" (secção 34 do redesign) -- os ecrãs de
/// acompanhamento de fila assumiam sempre uma ligação perfeita (nenhum
/// deles tratava erro de subscrição Realtime). Cada ecrã que subscreve
/// dados ao vivo passa a marcar `hasError` quando uma subscrição falha,
/// e mostra isto no topo em vez de ficar silenciosamente parado no
/// último valor visto.
class ConnectionBanner extends StatelessWidget {
  final bool visible;

  const ConnectionBanner({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: const Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.warning)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ligação interrompida — a tentar restabelecer.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
