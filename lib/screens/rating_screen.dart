import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../models/live_ticket.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/flow_scaffold.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_summary_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/star_rating.dart';

// Chaves fixas partilhadas com Rating/RatingAspects em
// fila-certa-staff/src/types.ts, para o dashboard agregar por aspeto.
const _aspectKeys = {
  'Atendimento do colaborador': 'atendimento',
  'Tempo de espera': 'tempoEspera',
  'Organização do serviço': 'organizacao',
  'Instalações e ambiente': 'instalacoes',
};

class RatingScreen extends StatefulWidget {
  final QueueLocation location;
  final ServiceItem service;
  final LiveTicketRef? liveTicket;
  final String? ticketCode;
  final String? counterLabel;

  const RatingScreen({
    super.key,
    required this.location,
    required this.service,
    this.liveTicket,
    this.ticketCode,
    this.counterLabel,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _overall = 4;
  bool? _recommend = true;
  final _commentController = TextEditingController();

  final _aspects = <String, IconData>{
    'Atendimento do colaborador': Icons.emoji_emotions_outlined,
    'Tempo de espera': Icons.access_time,
    'Organização do serviço': Icons.apartment_outlined,
    'Instalações e ambiente': Icons.shield_outlined,
  };
  late final Map<String, int> _aspectRatings = {
    'Atendimento do colaborador': 5,
    'Tempo de espera': 4,
    'Organização do serviço': 4,
    'Instalações e ambiente': 5,
  };

  static const _labels = ['Muito fraco', 'Fraco', 'Razoável', 'Bom', 'Muito bom'];
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Antes desta correcção, esta chamada era fire-and-forget e o ecrã
  // mostrava sempre "Avaliação enviada" mesmo que o insert falhasse --
  // o utilizador nunca saberia que a sua avaliação não chegou a ficar
  // guardada. Agora espera pelo resultado real antes de confirmar.
  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ref = widget.liveTicket;
    try {
      if (ref != null) {
        await ticket_service.submitRating(
          ref: ref,
          serviceName: widget.service.name,
          overall: _overall,
          recommend: _recommend ?? true,
          comment: _commentController.text.trim(),
          aspects: {
            for (final entry in _aspectRatings.entries) _aspectKeys[entry.key]!: entry.value,
          },
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação enviada. Obrigado pelo seu feedback!')),
      );
      goToRootTab(context, 0);
    } catch (e, stackTrace) {
      unawaited(Sentry.captureException(e, stackTrace: stackTrace, withScope: (scope) {
        scope.setContexts('rating', {'ticketId': ref?.ticketId, 'service': widget.service.name});
      }));
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar a avaliação. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayCode = widget.ticketCode ?? MockData.currentTicket;
    final counterDisplay = widget.counterLabel ?? MockData.counterNumber;
    return FlowScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          ScreenHeader(
            title: 'Avalie o atendimento',
            subtitle: 'A sua opinião ajuda-nos a melhorar.',
            trailingIcon: Icons.close,
            onTrailing: () => goToRootTab(context, 0),
          ),
          const SizedBox(height: 8),
          LocationSummaryCard(
            location: widget.location,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Senha', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(displayCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 6),
                const Text('Balcão', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(counterDisplay, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text('Como foi o seu atendimento?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 4),
                const Text('Toque numa estrela para avaliar.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                StarRating(value: _overall, onChanged: (v) => setState(() => _overall = v)),
                const SizedBox(height: 10),
                Text(
                  _overall == 0 ? '' : _labels[_overall - 1],
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recomendaria este atendimento?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ChoiceButton(
                        label: 'Sim, recomendaria',
                        icon: Icons.thumb_up_alt_outlined,
                        color: AppColors.success,
                        background: AppColors.successBg,
                        selected: _recommend == true,
                        onTap: () => setState(() => _recommend = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ChoiceButton(
                        label: 'Não recomendaria',
                        icon: Icons.thumb_down_alt_outlined,
                        color: AppColors.textSecondary,
                        background: AppColors.background,
                        selected: _recommend == false,
                        onTap: () => setState(() => _recommend = false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conte-nos como foi (opcional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 3),
                const Text(
                  'O seu comentário é muito importante para nós.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLength: 300,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Escreva o seu comentário aqui…',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    counterText: '${_commentController.text.length}/300',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Avalie aspetos específicos (opcional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 14),
                ..._aspects.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(9)),
                          child: Icon(entry.value, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                        StarRating(
                          value: _aspectRatings[entry.key]!,
                          size: 18,
                          onChanged: (v) => setState(() => _aspectRatings[entry.key] = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEAF0FE), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.verified_user_outlined, size: 17, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'A sua avaliação é anónima e ajuda-nos a oferecer um serviço cada vez melhor.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _submitting ? 'A enviar…' : 'Enviar avaliação',
            icon: Icons.send_outlined,
            onTap: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? background : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : AppColors.border, width: selected ? 1.4 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppColors.textMuted, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
