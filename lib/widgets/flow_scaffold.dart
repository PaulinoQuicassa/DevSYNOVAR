import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import 'filaja_bottom_nav.dart';

/// Shared chrome for every screen inside the "Entrar na fila" flow:
/// keeps the bottom nav visible (with "Entrar na fila" active) so a tap
/// on any other tab jumps back to [RootShell] from anywhere in the flow.
class FlowScaffold extends StatelessWidget {
  final Widget body;

  const FlowScaffold({super.key, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
      bottomNavigationBar: FilajaBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          goToRootTab(context, i);
        },
      ),
    );
  }
}
