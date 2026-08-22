import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import 'fila_certa_bottom_nav.dart';

/// Shared chrome for every screen inside the "Entrar na fila" flow:
/// keeps the bottom nav visible (with "Entrar na fila" active) so a tap
/// on any other tab jumps back to [RootShell] from anywhere in the flow.
class FlowScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;

  const FlowScaffold({super.key, required this.body, this.currentIndex = 2});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
      bottomNavigationBar: FilaCertaBottomNav(
        currentIndex: currentIndex,
        onTap: (i) {
          if (i == currentIndex) return;
          goToRootTab(context, i);
        },
      ),
    );
  }
}
