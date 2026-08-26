import 'live_ticket.dart';
import 'queue_location.dart';
import 'service_item.dart';

/// Uma senha real do cliente, com o contexto de exibição (banco/serviço)
/// já resolvido — usado por "Os meus atendimentos"
/// (`my_appointments_screen.dart`) para mostrar um histórico ao vivo em
/// vez do registo estático de sempre (`Visit`/`historyStore`).
class MyTicket {
  final String id;
  final LiveTicketRef ref;
  final QueueLocation location;
  final ServiceItem? service;
  final String code;
  final TicketStatus status;
  final String? counterId;
  final NoShowReason? noShowReason;
  final bool wasTransferred;
  final DateTime? createdAt;
  final DateTime? calledAt;
  final DateTime? doneAt;

  const MyTicket({
    required this.id,
    required this.ref,
    required this.location,
    required this.service,
    required this.code,
    required this.status,
    required this.counterId,
    required this.noShowReason,
    required this.wasTransferred,
    required this.createdAt,
    required this.calledAt,
    required this.doneAt,
  });

  String get serviceName => service?.name ?? '';

  /// Rótulo amigável do estado actual — cobre exactamente os exemplos
  /// pedidos ("Não Compareceu", "Transferido", "Em atendimento",
  /// "Atendimento concluído"). "A ser chamado novamente" fica de fora de
  /// propósito: é um instante (aviso global), não um estado persistente
  /// da senha.
  String get statusLabel {
    switch (status) {
      case TicketStatus.waiting:
        return wasTransferred ? 'Transferido — em espera' : 'Em espera';
      case TicketStatus.serving:
        return 'Em atendimento';
      case TicketStatus.done:
        return 'Atendimento concluído';
      case TicketStatus.noShow:
        return noShowReason == NoShowReason.customerCancelled ? 'Saiu da fila' : 'Não compareceu';
      case TicketStatus.unknown:
        return '—';
    }
  }

  bool get isActive => status == TicketStatus.waiting || status == TicketStatus.serving;
}
