import '../models/queue_location.dart';

/// Heurísticas puramente client-side para as funcionalidades "de produto"
/// pedidas no redesign (Fila Certa 2.0) que não dependem de nenhuma
/// alteração ao backend: pontuação indicativa, estimativa de deslocação,
/// e recomendação de melhor unidade. Nenhuma destas funções tem acesso a
/// dados que o servidor não forneça -- todas partem só de
/// `QueueLocation.etaMinutes`/`peopleInQueue`/`distanceKm` (ou a
/// distância real do GPS, já calculada em `location_service.dart`).
///
/// Documentado como heurística simples de propósito (master prompt,
/// secção 11: "o design deve deixar claro que é um indicador e não uma
/// verdade absoluta") -- não usa histórico real de desempenho (não
/// existe ainda um agregado no servidor para isso).

/// Pontuação indicativa 0-100 a partir só do tempo de espera actual --
/// quanto menor a espera, maior a pontuação. Não usa taxa de desistência,
/// satisfação nem estabilidade (secção 11 lista-os como possíveis
/// entradas futuras) porque nenhum desses agregados existe hoje no
/// servidor -- inventar um valor a partir de dados que não existem
/// violaria a regra de não fingir precisão que não temos.
int filaCertaScore(QueueLocation location) {
  final wait = location.etaMinutes;
  if (wait <= 5) return 96;
  if (wait >= 40) return 45;
  // Interpolação linear simples entre os dois extremos.
  return (96 - ((wait - 5) / 35 * 51)).round().clamp(45, 96);
}

String filaCertaScoreLabel(int score) {
  if (score >= 85) return 'Excelente';
  if (score >= 70) return 'Bom';
  if (score >= 55) return 'Razoável';
  return 'Fraco';
}

/// Velocidade média assumida para deslocação urbana em Luanda (mistura
/// de andar a pé/apanhar transporte/trânsito) -- proxy deliberadamente
/// conservador a partir da distância em linha recta, não uma rota real
/// (não há integração com nenhum serviço de mapas/routing nesta
/// funcionalidade -- ver relatório final, secção de limitações). Por
/// isso a UI que usa isto nunca promete precisão ("aproximadamente"),
/// conforme a secção 9 do master prompt.
const double _assumedAverageSpeedKmh = 22;

int estimateTravelMinutes(double distanceKm) {
  if (distanceKm <= 0) return 0;
  final minutes = (distanceKm / _assumedAverageSpeedKmh) * 60;
  return minutes.round().clamp(3, 120);
}

/// "Quando devo sair?" (secção 9): quantos minutos faltam até dever
/// sair de casa para chegar mesmo a tempo da sua vez -- espera estimada
/// menos tempo de deslocação estimado, nunca negativo.
int? minutesUntilShouldLeave({required int waitMinutes, required double distanceKm}) {
  final travel = estimateTravelMinutes(distanceKm);
  final result = waitMinutes - travel;
  return result < 0 ? 0 : result;
}

/// Recomendação de melhor unidade entre localizações que oferecem o
/// mesmo serviço (secção 10) -- compara espera vs. distância; só
/// recomenda uma alternativa mais distante quando a diferença de espera
/// for grande o suficiente para compensar claramente (>= 10 min),
/// evitando sugerir "vá mais longe" por uma diferença insignificante.
class UnitRecommendation {
  final QueueLocation best;
  final String reason;

  const UnitRecommendation({required this.best, required this.reason});
}

UnitRecommendation? recommendBestUnit(List<QueueLocation> candidates, {required double Function(QueueLocation) distanceOf}) {
  if (candidates.length < 2) return null;
  final byWait = candidates.toList()..sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
  final fastest = byWait.first;
  final nearest = (candidates.toList()..sort((a, b) => distanceOf(a).compareTo(distanceOf(b)))).first;

  if (fastest == nearest) {
    return UnitRecommendation(best: fastest, reason: 'É a unidade mais próxima e com menor espera.');
  }
  final waitDiff = nearest.etaMinutes - fastest.etaMinutes;
  if (waitDiff >= 10) {
    return UnitRecommendation(
      best: fastest,
      reason: 'Apesar de ser mais longe, a espera é significativamente menor '
          '(cerca de $waitDiff min a menos que na unidade mais próxima).',
    );
  }
  return UnitRecommendation(best: nearest, reason: 'É a unidade mais próxima e a diferença de espera é pequena.');
}
