import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_stores.dart';
import 'models/live_ticket.dart';

/// Camada de acesso ao ciclo de vida real de uma senha —
/// `institutions/{institutionId}/branches/{branchId}/tickets/{ticketId}`,
/// o mesmo esquema que `fila-certa-staff/src/lib/queue.ts` lê/escreve do
/// lado da equipa. Funções livres ao nível do módulo (mesma convenção de
/// `app_stores.dart`), sempre via `firestoreInstance` para poderem ser
/// testadas com `FakeFirebaseFirestore`.

String _branchPath(String institutionId, String branchId) =>
    'institutions/$institutionId/branches/$branchId';

LiveTicket? _ticketFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
  final data = snap.data();
  if (data == null) return null;
  return LiveTicket(
    code: data['code'] as String? ?? '',
    service: data['service'] as String? ?? '',
    status: ticketStatusFromString(data['status'] as String? ?? ''),
    counterId: data['counterId'] as String?,
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    calledAt: (data['calledAt'] as Timestamp?)?.toDate(),
    noShowReason: noShowReasonFromString(data['noShowReason'] as String?),
  );
}

/// Gera um código sem colisão (transacção sobre um contador dedicado — NÃO
/// a coleção `counters`, essa é só para os balcões físicos e é enumerada
/// inteira pelo ecrã de agente) e cria a senha já na forma que a app da
/// equipa espera. Prefixo `B` deliberado, só para se distinguir a olho das
/// senhas semeadas manualmente (`A05x`) durante um teste ao vivo.
Future<LiveTicketRef> pullTicket({
  required String institutionId,
  required String branchId,
  required String serviceName,
  required String customerUid,
}) async {
  final branchPath = _branchPath(institutionId, branchId);
  final seqRef = firestoreInstance.doc('$branchPath/meta/ticketSeq');
  final ticketRef = firestoreInstance.collection('$branchPath/tickets').doc();

  await firestoreInstance.runTransaction((transaction) async {
    final seqSnap = await transaction.get(seqRef);
    final nextSeq = (seqSnap.data()?['seq'] as int? ?? 0) + 1;
    transaction.set(seqRef, {'seq': nextSeq});
    transaction.set(ticketRef, {
      'code': 'B${nextSeq.toString().padLeft(3, '0')}',
      'service': serviceName,
      'priority': false,
      'status': 'waiting',
      'counterId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'calledAt': null,
      'doneAt': null,
      'transferredToCounterId': null,
      'customerUid': customerUid,
    });
  });

  return LiveTicketRef(institutionId: institutionId, branchId: branchId, ticketId: ticketRef.id);
}

Stream<LiveTicket?> subscribeTicket(LiveTicketRef ref) {
  return firestoreInstance
      .doc('${_branchPath(ref.institutionId, ref.branchId)}/tickets/${ref.ticketId}')
      .snapshots()
      .map(_ticketFromSnapshot);
}

Future<LiveTicket?> getTicketOnce(LiveTicketRef ref) async {
  final snap = await firestoreInstance
      .doc('${_branchPath(ref.institutionId, ref.branchId)}/tickets/${ref.ticketId}')
      .get();
  return _ticketFromSnapshot(snap);
}

/// Nome do balcão (ex.: "Balcão 3") a partir do `counterId` atribuído à
/// senha — leitura única, só precisa de ser resolvida depois de chamada.
Future<String?> getCounterLabel(String institutionId, String branchId, String counterId) async {
  final snap = await firestoreInstance.doc('${_branchPath(institutionId, branchId)}/counters/$counterId').get();
  return snap.data()?['label'] as String?;
}

/// Mesmo documento que o painel de TV (`PublicDisplay.tsx`) já lê —
/// última senha chamada e em que balcão.
Stream<LiveBoardEntry?> subscribeLiveBoardCurrent(String institutionId, String branchId) {
  return firestoreInstance.doc('${_branchPath(institutionId, branchId)}/liveBoard/current').snapshots().map((snap) {
    final data = snap.data();
    final current = data?['current'] as Map<String, dynamic>?;
    if (current == null) return null;
    return LiveBoardEntry(
      code: current['code'] as String? ?? '',
      counterLabel: current['counterLabel'] as String? ?? '',
      updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate(),
    );
  });
}

/// Estado do balcão (disponível/em atendimento/pausa) — usado pelo cliente
/// para saber se o balcão que o está a atender está de momento em pausa.
Stream<String?> subscribeCounterStatus(String institutionId, String branchId, String counterId) {
  return firestoreInstance
      .doc('${_branchPath(institutionId, branchId)}/counters/$counterId')
      .snapshots()
      .map((snap) => snap.data()?['status'] as String?);
}

/// Quantas senhas em espera foram criadas antes da minha — mesma forma de
/// query que `subscribeWaitingQueue` no repo irmão (sem `orderBy` no
/// servidor, para não exigir índice composto).
Stream<int> subscribeWaitingAhead(LiveTicketRef ref, DateTime myCreatedAt) {
  return firestoreInstance
      .collection('${_branchPath(ref.institutionId, ref.branchId)}/tickets')
      .where('status', isEqualTo: 'waiting')
      .snapshots()
      .map((snap) {
    var count = 0;
    for (final doc in snap.docs) {
      if (doc.id == ref.ticketId) continue;
      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null && createdAt.isBefore(myCreatedAt)) count++;
    }
    return count;
  });
}

/// O próprio cliente desiste da senha (sair da fila, ou avisar que não
/// pode comparecer já depois de chamado) — muda `status` e regista a
/// origem (`noShowReason`) para os KPIs do dashboard distinguirem de uma
/// ausência marcada pela equipa. Fire-and-forget pelos ecrãs, para não
/// bloquear a navegação nem rebentar se a regra recusar (ex.: senha já
/// concluída).
Future<void> cancelTicket(LiveTicketRef ref) {
  return firestoreInstance
      .doc('${_branchPath(ref.institutionId, ref.branchId)}/tickets/${ref.ticketId}')
      .update({'status': 'no_show', 'noShowReason': 'customer_cancelled'});
}

/// O cliente avisa que está a caminho do balcão — o ecrã do agente mostra
/// isto em tempo real junto da senha em atendimento.
Future<void> setOnTheWay(LiveTicketRef ref) {
  return firestoreInstance
      .doc('${_branchPath(ref.institutionId, ref.branchId)}/tickets/${ref.ticketId}')
      .update({'customerOnTheWay': true});
}

/// Espelho, visível à equipa, de um agendamento que o cliente marca em
/// users/{uid}/appointments (privado) — só chamado para a localização
/// piloto (ver `AppointmentsStore.add`). O id do documento é o mesmo
/// `code` do agendamento privado, para os dois lados ficarem ligados.
Future<void> scheduleAppointment({
  required String institutionId,
  required String branchId,
  required String code,
  required String customerUid,
  required String serviceName,
  required DateTime date,
  required String time,
}) {
  return firestoreInstance.doc('${_branchPath(institutionId, branchId)}/appointments/$code').set({
    'customerUid': customerUid,
    'serviceName': serviceName,
    'date': Timestamp.fromDate(date),
    'time': time,
    'createdAt': FieldValue.serverTimestamp(),
    'status': 'scheduled',
  });
}

/// Marca o espelho institucional do agendamento como cancelado — nunca
/// apagado, para o KPI "Agendamentos hoje" continuar a contar
/// correctamente quantos foram marcados hoje.
Future<void> cancelAppointmentMirror({
  required String institutionId,
  required String branchId,
  required String code,
}) {
  return firestoreInstance
      .doc('${_branchPath(institutionId, branchId)}/appointments/$code')
      .update({'status': 'cancelled'});
}
