import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_state.dart';
import '../models/appointment.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'schedule_datetime_screen.dart';

class AppointmentConfirmedScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentConfirmedScreen({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Agendamento confirmado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Guarde o código ou mostre o QR no dia do atendimento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
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
                      size: 160,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.textPrimary),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appointment.code,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  _Row(label: 'Localização', value: appointment.location.name),
                  _Row(label: 'Agência', value: appointment.location.subtitle),
                  _Row(label: 'Serviço', value: appointment.service.name),
                  _Row(label: 'Data', value: formatShortDate(appointment.date)),
                  _Row(label: 'Hora', value: appointment.time, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Concluir',
              icon: Icons.check,
              onTap: () => goToRootTab(context, 3),
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
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
