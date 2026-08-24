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

/// Key of the app's root [Navigator] — lets [GlobalQueueAlerts] show an
/// overlay banner on top of whatever screen/tab is currently visible,
/// without depending on a screen's own [BuildContext].
final navigatorKey = GlobalKey<NavigatorState>();

/// The queue ticket the signed-in customer has "in progress" during this
/// app session (set once `pullTicket` succeeds, cleared on a terminal
/// status or sign-out) — read by [GlobalQueueAlerts] so important
/// notifications ("serás o próximo", "é a sua vez") keep firing no
/// matter which tab the customer wandered off to.
final activeTicketStore = ValueNotifier<LiveTicketRef?>(null);
