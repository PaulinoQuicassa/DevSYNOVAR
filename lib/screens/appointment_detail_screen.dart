import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_stores.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';
import '../widgets/bank_logo.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/gradient_button.dart';
import '../widgets/screen_header.dart';
import 'schedule_datetime_screen.dart';

class AppointmentDetailScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Cancelar agendamento?',
      message: 'O agendamento ${appointment.code} para ${formatShortDate(appointment.date)} às ${appointment.time} será cancelado.',
      confirmLabel: 'Cancelar agendamento',
      cancelLabel: 'Manter',
      danger: true,
    );
    if (confirmed && context.mounted) {
      appointmentsStore.cancel(appointment);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agendamento cancelado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const ScreenHeader(title: 'Detalhe do agendamento'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      BankLogo(monogram: appointment.location.monogram, color: appointment.location.brandColor, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appointment.location.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                            const SizedBox(height: 2),
                            Text(appointment.location.subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: QrImageView(
                      data: 'filacerta:appointment:${appointment.code}',
                      version: QrVersions.auto,
                      size: 140,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(appointment.code, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 20),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  _Row(label: 'Serviço', value: appointment.service.name),
                  _Row(label: 'Data', value: formatShortDate(appointment.date)),
                  _Row(label: 'Hora', value: appointment.time),
                  _Row(label: 'Morada', value: appointment.location.address, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlineButton(
              label: 'Cancelar agendamento',
              icon: Icons.close,
              color: AppColors.critical,
              onTap: () => _cancel(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _Row({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
