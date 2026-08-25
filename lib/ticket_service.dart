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

/// Avança o contador partilhado `meta/ticketSeq` dentro de uma transação
/// já em curso e devolve o próximo número — usado por `pullTicket` (senha
/// e incremento atómicos na mesma transação) e por `nextAppointmentCode`
/// (só reserva um número, ver abaixo porquê não pode ser tão atómico).
Future<int> _incrementSequence(Transaction transaction, String institutionId, String branchId) async {
  final seqRef = firestoreInstance.doc('${_branchPath(institutionId, branchId)}/meta/ticketSeq');
  final seqSnap = await transaction.get(seqRef);
  final nextSeq = (seqSnap.data()?['seq'] as int? ?? 0) + 1;
  transaction.set(seqRef, {'seq': nextSeq});
  return nextSeq;
}

/// Gera um código sem colisão e cria a senha já na forma que a app da
/// equipa espera. Prefixo `B` deliberado, só para se distinguir a olho das
/// senhas semeadas manualmente (`A05x`) durante um teste ao vivo.
Future<LiveTicketRef> pullTicket({
  required String institutionId,
  required String branchId,
  required String serviceName,
  required String customerUid,
}) async {
  final branchPath = _branchPath(institutionId, branchId);
  final ticketRef = firestoreInstance.collection('$branchPath/tickets').doc();

  await firestoreInstance.runTransaction((transaction) async {
    final nextSeq = await _incrementSequence(transaction, institutionId, branchId);
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

/// Quantas senhas estão em espera agora nesta agência — usado antes de
/// entrar na fila (ex.: `LocationCard`), para substituir o número fixo
/// de `QueueLocation.peopleInQueue` por um valor real.
Stream<int> subscribeQueueSize(String institutionId, String branchId) {
  return firestoreInstance
      .collection('${_branchPath(institutionId, branchId)}/tickets')
      .where('status', isEqualTo: 'waiting')
      .snapshots()
      .map((snap) => snap.docs.length);
}

/// Nomes de serviço de todas as senhas em espera agora — usado para
/// contar, por serviço, quantas pessoas estão à espera (substitui o
/// número fixo de `ServiceItem.peopleInQueue`). Uma só subscrição
/// partilhada por `ChooseServiceScreen`, em vez de uma por cartão.
Stream<List<String>> subscribeWaitingServiceNames(String institutionId, String branchId) {
  return firestoreInstance
      .collection('${_branchPath(institutionId, branchId)}/tickets')
      .where('status', isEqualTo: 'waiting')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()['service'] as String? ?? '').toList());
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

/// Reserva o próximo código de agendamento sem colisão (`AG001`,
/// `AG002`, ...), na mesma sequência partilhada `meta/ticketSeq` das
/// senhas — só reserva o número (não cria nenhum documento) porque o
/// código gerado aqui é escrito por `AppointmentsStore.add` em DOIS
/// sítios (o agendamento privado e este espelho), não é possível fazer
/// tudo numa única transação. Só chamado para a localização piloto; as
/// restantes continuam com o código local antigo (sem risco de colisão
/// partilhada, porque nunca saem da coleção privada do próprio cliente).
Future<String> nextAppointmentCode(String institutionId, String branchId) async {
  final seq = await firestoreInstance.runTransaction(
    (transaction) => _incrementSequence(transaction, institutionId, branchId),
  );
  return 'AG${seq.toString().padLeft(3, '0')}';
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

/// Avaliação do cliente depois de concluído o atendimento (RatingScreen)
/// — id do documento é o próprio ticketId, um por senha; alimenta o
/// resumo de qualidade do dashboard da equipa.
Future<void> submitRating({
  required LiveTicketRef ref,
  required String customerUid,
  required String serviceName,
  required int overall,
  required bool recommend,
  required String comment,
  required Map<String, int> aspects,
}) {
  return firestoreInstance.doc('${_branchPath(ref.institutionId, ref.branchId)}/ratings/${ref.ticketId}').set({
    'customerUid': customerUid,
    'serviceName': serviceName,
    'overall': overall,
    'recommend': recommend,
    'comment': comment,
    'aspects': aspects,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
