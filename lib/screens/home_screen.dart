import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_card.dart';
import 'choose_location_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _enterQueue(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const ChooseLocationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearby = MockData.locations.take(2).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Boa tarde,', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  SizedBox(height: 2),
                  Text(
                    'Paulino Quicassa',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Stack(
                  children: [
                    const Center(child: Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary)),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.critical, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 14))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.confirmation_number_outlined, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text('Fila Certa', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Entre na fila.\nNão fique na fila.',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
                ),
                const SizedBox(height: 10),
                Text(
                  'Escolha um banco ou serviço público e acompanhe a sua vez sem sair de onde está.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Entrar numa fila',
            icon: Icons.confirmation_number_outlined,
            onTap: () => _enterQueue(context),
          ),
          const SizedBox(height: 12),
          OutlineButton(
            label: 'Os meus agendamentos',
            icon: Icons.calendar_month_outlined,
            onTap: () => goToRootTab(context, 3),
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Localizações próximas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          ...nearby.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LocationCard(location: loc, onTap: () => _enterQueue(context)),
            ),
          ),
        ],
      ),
    );
  }
}
