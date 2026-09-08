import 'package:flutter/material.dart';
import 'models/live_ticket.dart';

/// Tracks which bottom-navigation tab is active on [RootShell].
/// Flow screens pushed on top of the shell (choose location/service,
/// queue tracking, rating, ...) read and write this so their own copy
/// of the bottom nav can jump back to any root tab from anywhere.
class RootTabController extends ValueNotifier<int> {
  RootTabController() : super(0);
}

final rootTabController = RootTabController();

/// Pops every route back to [RootShell] and switches its active tab.
void goToRootTab(BuildContext context, int index) {
  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  rootTabController.value = index;
}

/// Consulta escrita na Home e entregue ao separador "Explorar" (que o
/// `IndexedStack` do RootShell mantém sempre vivo, por isso não pode
/// receber isto por construtor). A Home escreve aqui e muda de
/// separador; o `ExploreScreen` lê, aplica à sua pesquisa e limpa, para
/// uma visita seguinte ao separador não repetir uma pesquisa antiga.
final pendingExploreQuery = ValueNotifier<String?>(null);

/// Key of the app's root [Navigator] — lets [GlobalQueueAlerts] show an
/// overlay banner on top of whatever screen/tab is currently visible,
/// without depending on a screen's own [BuildContext].
final navigatorKey = GlobalKey<NavigatorState>();

/// Every queue ticket the signed-in customer has "in progress" during this
/// app session (one entry added per successful `pullTicket`, removed on a
/// terminal status or sign-out) — read by [GlobalQueueAlerts] so important
/// notifications ("serás o próximo", "é a sua vez") keep firing no matter
/// which tab the customer wandered off to. A **list**, not a single ref:
/// a customer can perfectly well be waiting on more than one service at
/// once (e.g. "Abertura de conta" and "Empréstimo" in the same branch),
/// and each must keep being tracked independently.
final activeTicketStore = ValueNotifier<List<LiveTicketRef>>(const []);

void addActiveTicket(LiveTicketRef ref) {
  activeTicketStore.value = [...activeTicketStore.value, ref];
}

void removeActiveTicket(String ticketId) {
  activeTicketStore.value = activeTicketStore.value.where((r) => r.ticketId != ticketId).toList();
}
