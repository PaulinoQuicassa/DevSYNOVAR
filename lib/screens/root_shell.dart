import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/fila_certa_bottom_nav.dart';
import 'choose_location_screen.dart';
import 'home_screen.dart';
import 'my_appointments_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';

/// Hosts the persistent bottom navigation. Tabs 0, 1, 3 and 4 are simple
/// pages swapped via [IndexedStack]; tab 2 ("Entrar na fila") has no page
/// of its own — tapping it pushes the queue-joining flow on the root
/// navigator instead, which carries its own copy of this same bottom nav
/// (see [FlowScaffold]) so the chrome never disappears mid-flow.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const _pages = <Widget>[
    HomeScreen(),
    MyAppointmentsScreen(),
    SizedBox.shrink(),
    ScheduleScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    rootTabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    rootTabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  void _handleTap(int index) {
    if (index == 2) {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const ChooseLocationScreen()),
      );
      return;
    }
    rootTabController.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = rootTabController.value == 2 ? 0 : rootTabController.value;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: IndexedStack(index: activeIndex, children: _pages)),
      bottomNavigationBar: FilaCertaBottomNav(currentIndex: rootTabController.value, onTap: _handleTap),
    );
  }
}
