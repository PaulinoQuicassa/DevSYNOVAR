import 'package:flutter/material.dart';
import 'data/mock_data.dart';
import 'models/live_ticket.dart';
import 'models/queue_location.dart';
import 'models/service_item.dart';
import 'screens/almost_screen.dart';
import 'screens/called_screen.dart';
import 'ticket_service.dart' as ticket_service;

/// Reabre o ecrã ao vivo de uma senha a partir só do `LiveTicketRef` +
/// `LiveTicket` — sem precisar de um ecrã de origem já aberto. Usado por
/// `GlobalQueueAlerts` (o ecrã original pode já ter sido fechado, ex.:
/// por `goToRootTab` ao voltar ao início para tirar uma segunda senha) e
/// por "Os meus atendimentos" (a lista nunca teve um ecrã aberto para
/// reabrir — só sabe da senha através do Postgres).
Future<void> openLiveTicketScreen(NavigatorState nav, LiveTicketRef ref, LiveTicket ticket) async {
  QueueLocation? location;
  for (final loc in MockData.locations) {
    if (loc.institutionId == ref.institutionId && loc.branchId == ref.branchId) {
      location = loc;
      break;
    }
  }
  if (location == null) return;

  ServiceItem? service;
  for (final s in location.services) {
    if (s.name == ticket.service) {
      service = s;
      break;
    }
  }
  service ??= location.services.first;

  if (ticket.status == TicketStatus.serving) {
    final counterLabel = ticket.counterId == null
        ? null
        : await ticket_service.getCounterLabel(ref.institutionId, ref.branchId, ticket.counterId!);
    nav.push(MaterialPageRoute(
      builder: (_) => CalledScreen(
        location: location!,
        service: service!,
        liveTicket: ref,
        ticketCode: ticket.code,
        counterLabel: counterLabel,
      ),
    ));
  } else {
    nav.push(MaterialPageRoute(
      builder: (_) => AlmostScreen(location: location!, service: service!, liveTicket: ref),
    ));
  }
}
