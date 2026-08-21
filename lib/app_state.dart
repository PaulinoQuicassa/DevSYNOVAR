import 'package:flutter/material.dart';

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
