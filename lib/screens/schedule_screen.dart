import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';
import '../widgets/bank_logo.dart';
import '../widgets/gradient_button.dart';
import 'appointment_detail_screen.dart';
import 'choose_location_screen.dart';
import 'schedule_datetime_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  void _newAppointment(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const ChooseLocationScreen(isScheduling: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Appointment>>(
      valueListenable: appointmentsStore,
      builder: (context, appointments, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const Text('Agendamentos', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Marque hora e evite esperar na fila.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            GradientButton(label: 'Novo agendamento', icon: Icons.add, onTap: () => _newAppointment(context)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Próximos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                if (appointments.isNotEmpty)
                  Text('${appointments.length}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            if (appointments.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.event_busy_outlined, color: AppColors.textMuted, size: 32),
                    SizedBox(height: 10),
                    Text('Sem agendamentos marcados', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ],
                ),
              )
            else
              ...appointments.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            BankLogo(monogram: a.location.monogram, color: a.location.brandColor, size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.location.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                  const SizedBox(height: 2),
                                  Text(a.service.name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.event_outlined, size: 13, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${formatShortDate(a.date)}  ·  ${a.time}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(a.code, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
