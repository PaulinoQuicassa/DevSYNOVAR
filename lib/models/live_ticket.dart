/// Estado de uma senha real, espelhando `TicketStatus` de
/// `fila-certa-staff/src/types.ts` — `'called'` existe do lado da app da
/// equipa mas nunca é escrito (`callNext` grava `'serving'`), por isso não
/// tem equivalente aqui.
enum TicketStatus { waiting, serving, done, noShow, unknown }

TicketStatus ticketStatusFromString(String s) => switch (s) {
      'waiting' => TicketStatus.waiting,
      'serving' => TicketStatus.serving,
      'done' => TicketStatus.done,
      'no_show' => TicketStatus.noShow,
      _ => TicketStatus.unknown,
    };

/// Identidade de uma senha real — passada entre os ecrãs do fluxo
/// (Queue → Almost → Called → Rating) via construtor, tal como
/// `location`/`service` já são.
class LiveTicketRef {
  final String institutionId;
  final String branchId;
  final String ticketId;

  const LiveTicketRef({
    required this.institutionId,
    required this.branchId,
    required this.ticketId,
  });
}

/// Leitura de `institutions/{institutionId}/branches/{branchId}/tickets/{ticketId}`.
class LiveTicket {
  final String code;
  final String service;
  final TicketStatus status;
  final String? counterId;
  final DateTime? createdAt;
  final DateTime? calledAt;

  const LiveTicket({
    required this.code,
    required this.service,
    required this.status,
    this.counterId,
    this.createdAt,
    this.calledAt,
  });
}

/// Última chamada do painel ao vivo — mesma forma de
/// `institutions/{institutionId}/branches/{branchId}/liveBoard/current`
/// que o painel de TV (`fila-certa-staff`) já lê.
class LiveBoardEntry {
  final String code;
  final String counterLabel;

  const LiveBoardEntry({required this.code, required this.counterLabel});
}
