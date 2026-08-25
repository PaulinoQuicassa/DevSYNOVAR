import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../data/mock_data.dart';
import '../models/appointment.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/flow_scaffold.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_summary_card.dart';
import '../widgets/screen_header.dart';
import 'appointment_confirmed_screen.dart';

const _weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const _monthLabels = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

String formatShortDate(DateTime date) => '${date.day} ${_monthLabels[date.month - 1]} ${date.year}';

class ScheduleDateTimeScreen extends StatefulWidget {
  final QueueLocation location;
  final ServiceItem service;

  const ScheduleDateTimeScreen({super.key, required this.location, required this.service});

  @override
  State<ScheduleDateTimeScreen> createState() => _ScheduleDateTimeScreenState();
}

class _ScheduleDateTimeScreenState extends State<ScheduleDateTimeScreen> {
  late final List<DateTime> _days = List.generate(14, (i) => DateTime.now().add(Duration(days: i + 1)));
  DateTime? _selectedDay;
  String? _selectedTime;
  bool _confirming = false;

  Future<void> _confirm() async {
    final day = _selectedDay!;
    final institutionId = widget.location.institutionId;
    final branchId = widget.location.branchId;

    setState(() => _confirming = true);
    // Localização piloto: código reservado atomicamente (mesma sequência
    // das senhas), para nunca colidir entre clientes diferentes no
    // espelho institucional partilhado. Localizações mock: código local,
    // sem risco, porque nunca sai da coleção privada do próprio cliente.
    final code = institutionId != null && branchId != null
        ? await ticket_service.nextAppointmentCode(institutionId, branchId)
        : 'AG-${1000 + appointmentsStore.value.length + DateTime.now().second}';
    if (!mounted) return;

    final appointment = Appointment(
      code: code,
      location: widget.location,
      service: widget.service,
      date: DateTime(day.year, day.month, day.day),
      time: _selectedTime!,
    );
    appointmentsStore.add(appointment);
    setState(() => _confirming = false);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AppointmentConfirmedScreen(appointment: appointment)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _selectedDay != null && _selectedTime != null;

    return FlowScaffold(
      currentIndex: 3,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const ScreenHeader(title: 'Novo agendamento', subtitle: 'Escolha a data e a hora.'),
          const SizedBox(height: 8),
          LocationSummaryCard(location: widget.location, tag: widget.service.name),
          const SizedBox(height: 24),
          const Text('Escolher data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final day = _days[i];
                final selected = _selectedDay != null &&
                    _selectedDay!.year == day.year &&
                    _selectedDay!.month == day.month &&
                    _selectedDay!.day == day.day;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: selected ? null : Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdayLabels[day.weekday - 1],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text('Escolher hora', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MockData.timeSlots.map((slot) {
              final selected = _selectedTime == slot;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedTime = slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: selected ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          if (canConfirm)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined, size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${formatShortDate(_selectedDay!)} às $_selectedTime',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          Opacity(
            opacity: canConfirm ? 1 : 0.45,
            child: GradientButton(
              label: _confirming ? 'A confirmar…' : (canConfirm ? 'Confirmar agendamento' : 'Escolha data e hora'),
              icon: Icons.event_available_outlined,
              onTap: canConfirm && !_confirming ? _confirm : null,
            ),
          ),
        ],
      ),
    );
  }
}
