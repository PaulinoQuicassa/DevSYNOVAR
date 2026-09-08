import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/fila_certa_bottom_nav.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'my_appointments_screen.dart';
import 'my_queues_screen.dart';
import 'profile_screen.dart';

/// Hosts the persistent bottom navigation. Fila Certa 2.0 (redesign
/// UX/UI): todos os 5 separadores são agora páginas reais trocadas via
/// [IndexedStack] -- a versão anterior tinha um separador central
/// ("Entrar na fila") que só empurrava uma sub-navegação sem página
/// própria, o que quebrava a expectativa normal de uma bottom nav (ver
/// UX Audit Report, achado #16/secção 28). "Entrar na fila" continua a
/// existir como acção, agora dentro de [ExploreScreen]/[HomeScreen], não
/// como separador.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const _pages = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    MyQueuesScreen(),
    MyAppointmentsScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: IndexedStack(index: rootTabController.value, children: _pages)),
      bottomNavigationBar: FilaCertaBottomNav(currentIndex: rootTabController.value, onTap: (i) => rootTabController.value = i),
    );
  }
}
