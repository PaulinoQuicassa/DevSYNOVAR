import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../app_state.dart';
import '../auth/require_auth.dart';
import '../domain/queue_insights.dart';
import '../location_service.dart' as location_service;
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/document_checklist.dart';
import '../widgets/flow_scaffold.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_summary_card.dart';
import '../widgets/queue_insight_widgets.dart';
import '../widgets/screen_header.dart';
import 'queue_screen.dart';

/// Ecrã de confirmação antes de entrar na fila (secção 15 do master
/// prompt) -- um dos ecrãs mais importantes do produto: resume tudo o
/// que o utilizador precisa de saber (espera, distância, documentos,
/// quando sair) antes do compromisso, evitando ambiguidade. A conta só é
/// pedida aqui, no momento exacto em que faz sentido (`requireAuth`) --
/// nunca antes de o utilizador chegar a esta decisão.
class ServiceConfirmScreen extends StatefulWidget {
  final QueueLocation location;
  final ServiceItem service;

  const ServiceConfirmScreen({super.key, required this.location, required this.service});

  @override
  State<ServiceConfirmScreen> createState() => _ServiceConfirmScreenState();
}

class _ServiceConfirmScreenState extends State<ServiceConfirmScreen> {
  bool _submitting = false;

  double? get _distanceKm => location_service.realDistanceKm(widget.location.latitude, widget.location.longitude) ??
      (widget.location.distanceKm > 0 ? widget.location.distanceKm : null);

  Future<void> _confirm() async {
    if (_submitting) return;
    final ok = await requireAuth(
      context,
      reason: 'Precisamos de uma conta para guardar o seu lugar na fila e avisá-lo quando for a sua vez.',
    );
    if (!ok || !mounted) return;

    final institutionId = widget.location.institutionId;
    final branchId = widget.location.branchId;
    if (institutionId == null || branchId == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QueueScreen(location: widget.location, service: widget.service)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final ref = await ticket_service.pullTicket(
        institutionId: institutionId,
        branchId: branchId,
        serviceName: widget.service.name,
      );
      addActiveTicket(ref);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QueueScreen(location: widget.location, service: widget.service, liveTicket: ref)),
      );
    } catch (e, stackTrace) {
      unawaited(Sentry.captureException(e, stackTrace: stackTrace, withScope: (scope) {
        scope.setContexts('queue', {'institutionId': institutionId, 'branchId': branchId, 'service': widget.service.name});
      }));
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível tirar a senha. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = filaCertaScore(widget.location);
    final distanceKm = _distanceKm;
    return FlowScaffold(
      currentIndex: 1,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          ScreenHeader(title: 'Confirmar entrada', subtitle: widget.service.name),
          const SizedBox(height: 8),
          LocationSummaryCard(location: widget.location),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Espera estimada', style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${widget.service.etaMinutes} min', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${widget.service.peopleInQueue} pessoas na fila', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                const SizedBox(height: 14),
                ScoreBadge(score: score),
              ],
            ),
          ),
          if (distanceKm != null) ...[
            const SizedBox(height: 12),
            LeaveNowCard(waitMinutes: widget.service.etaMinutes, distanceKm: distanceKm),
          ],
          const SizedBox(height: 16),
          DocumentChecklist(documents: widget.service.documents),
          const SizedBox(height: 20),
          GradientButton(
            label: _submitting ? 'A entrar…' : 'Entrar na fila',
            icon: Icons.confirmation_number_outlined,
            onTap: _submitting ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
