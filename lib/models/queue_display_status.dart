import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'live_ticket.dart';

/// Linguagem visual única de estado de fila (Fila Certa 2.0, secção 31 do
/// master prompt do redesign). O backend só distingue
/// `waiting/serving/done/no_show` (+ motivo do no_show e uma flag
/// `was_transferred`) -- ver `TicketStatus`/`live_ticket.dart`. Este mapa
/// traduz essa forma real para os rótulos pedidos, sem inventar estados
/// que o servidor não distingue: "chamado" e "em atendimento" partilham
/// o mesmo `serving` (o servidor não regista um momento "chamado"
/// separado -- confirmado por auditoria: `'called'` nunca é escrito),
/// e "SKIPPED"/"NO_SHOW" do master prompt colapsam ambos no único
/// `no_show` que existe, distinguidos só pelo texto.
enum QueueDisplayStatus { waiting, transferred, serving, completed, cancelled, noShow, unknown }

QueueDisplayStatus queueDisplayStatusOf(TicketStatus status, {bool wasTransferred = false}) {
  switch (status) {
    case TicketStatus.waiting:
      return wasTransferred ? QueueDisplayStatus.transferred : QueueDisplayStatus.waiting;
    case TicketStatus.serving:
      return QueueDisplayStatus.serving;
    case TicketStatus.done:
      return QueueDisplayStatus.completed;
    case TicketStatus.noShow:
      return QueueDisplayStatus.cancelled; // afinado abaixo com noShowReason quando disponível
    case TicketStatus.unknown:
      return QueueDisplayStatus.unknown;
  }
}

/// Versão que também distingue quem causou o `no_show` -- usar esta
/// sempre que o motivo estiver disponível (é o caso normal).
QueueDisplayStatus queueDisplayStatusFrom({
  required TicketStatus status,
  bool wasTransferred = false,
  NoShowReason? noShowReason,
}) {
  if (status == TicketStatus.noShow) {
    return noShowReason == NoShowReason.customerCancelled ? QueueDisplayStatus.cancelled : QueueDisplayStatus.noShow;
  }
  return queueDisplayStatusOf(status, wasTransferred: wasTransferred);
}

extension QueueDisplayStatusX on QueueDisplayStatus {
  String get label {
    switch (this) {
      case QueueDisplayStatus.waiting:
        return 'Em espera';
      case QueueDisplayStatus.transferred:
        return 'Transferido — em espera';
      case QueueDisplayStatus.serving:
        return 'Em atendimento';
      case QueueDisplayStatus.completed:
        return 'Concluído';
      case QueueDisplayStatus.cancelled:
        return 'Saiu da fila';
      case QueueDisplayStatus.noShow:
        return 'Não compareceu';
      case QueueDisplayStatus.unknown:
        return 'Estado desconhecido';
    }
  }

  Color get color {
    switch (this) {
      case QueueDisplayStatus.waiting:
      case QueueDisplayStatus.transferred:
        return AppColors.primary;
      case QueueDisplayStatus.serving:
        return AppColors.critical;
      case QueueDisplayStatus.completed:
        return AppColors.success;
      case QueueDisplayStatus.cancelled:
      case QueueDisplayStatus.noShow:
        return AppColors.textSecondary;
      case QueueDisplayStatus.unknown:
        return AppColors.textMuted;
    }
  }

  Color get background => color.withValues(alpha: 0.14);

  IconData get icon {
    switch (this) {
      case QueueDisplayStatus.waiting:
      case QueueDisplayStatus.transferred:
        return Icons.hourglass_top_rounded;
      case QueueDisplayStatus.serving:
        return Icons.notifications_active_rounded;
      case QueueDisplayStatus.completed:
        return Icons.check_circle_rounded;
      case QueueDisplayStatus.cancelled:
        return Icons.logout_rounded;
      case QueueDisplayStatus.noShow:
        return Icons.person_off_rounded;
      case QueueDisplayStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }
}

/// Os 3 estados de proximidade da secção 17 do master prompt -- linguagem
/// visual separada da anterior: esta descreve "quão perto está a sua
/// vez", não o estado bruto da senha.
enum ProximityState { relaxed, prepare, now }

extension ProximityStateX on ProximityState {
  Color get color {
    switch (this) {
      case ProximityState.relaxed:
        return AppColors.success;
      case ProximityState.prepare:
        return AppColors.warning;
      case ProximityState.now:
        return AppColors.critical;
    }
  }

  String get label {
    switch (this) {
      case ProximityState.relaxed:
        return 'Acompanhe';
      case ProximityState.prepare:
        return 'Prepare-se';
      case ProximityState.now:
        return 'É a sua vez';
    }
  }
}
