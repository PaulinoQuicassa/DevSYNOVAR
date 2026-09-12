import 'package:flutter/material.dart';
import '../ticket_service.dart' as ticket_service;

/// "Espera estimada · X min" -- para uma localização real
/// (`institutionId`/`branchId` não nulos), o valor é ao vivo, recalculado
/// no servidor a partir das senhas de hoje (`branch_wait_stats`, ver
/// `ticket_service.subscribeEtaMinutes`); para o catálogo mock, ou
/// enquanto a amostra real ainda não existir, cai para o número fixo do
/// catálogo (`fallbackMinutes`) em vez de mostrar "a carregar"/"0 min".
class EtaLabel extends StatelessWidget {
  final String? institutionId;
  final String? branchId;
  final int fallbackMinutes;
  final TextStyle? style;

  const EtaLabel({
    super.key,
    required this.institutionId,
    required this.branchId,
    required this.fallbackMinutes,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final institutionId = this.institutionId;
    final branchId = this.branchId;
    if (institutionId == null || branchId == null) {
      return Text('Espera estimada · $fallbackMinutes min', style: style);
    }
    return StreamBuilder<int?>(
      stream: ticket_service.subscribeEtaMinutes(institutionId, branchId),
      builder: (context, snapshot) {
        final minutes = snapshot.data ?? fallbackMinutes;
        return Text('Espera estimada · $minutes min', style: style);
      },
    );
  }
}
