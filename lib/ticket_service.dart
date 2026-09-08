import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/live_ticket.dart';
import 'models/my_ticket.dart';
import 'models/queue_location.dart';
import 'models/service_item.dart';
import 'supabase_client.dart';

/// Camada de acesso ao ciclo de vida real de uma senha -- tabela `tickets`
/// no Postgres do Supabase (`institution_id`/`branch_id`/`id`), o mesmo
/// esquema que `fila-certa-staff/src/lib/queue.ts` lê/escreve do lado da
/// equipa. Funções livres ao nível do módulo (mesma convenção de
/// `app_stores.dart`), sempre via `supabaseClient` (mutável, ver
/// `supabase_client.dart`) para poderem ser substituídas em testes.

const _ticketColumns =
    'id, code, service, status, counter_id, created_at, called_at, no_show_reason';

LiveTicket _ticketFromRow(Map<String, dynamic> data) {
  return LiveTicket(
    code: data['code'] as String? ?? '',
    service: data['service'] as String? ?? '',
    status: ticketStatusFromString(data['status'] as String? ?? ''),
    counterId: data['counter_id'] as String?,
    createdAt: _parseTime(data['created_at']),
    calledAt: _parseTime(data['called_at']),
    noShowReason: noShowReasonFromString(data['no_show_reason'] as String?),
  );
}

DateTime? _parseTime(dynamic value) => value == null ? null : DateTime.parse(value as String).toLocal();

/// Assina mudanças numa tabela filtrada por uma coluna/valor e chama
/// `fetch` sempre que algo muda -- o filtro do canal só decide QUANDO
/// voltar a ler; `fetch` é sempre a fonte da verdade (sempre com o seu
/// próprio filtro completo), por isso é seguro mesmo que o filtro do
/// canal seja mais largo do que os dados finais devolvidos.
Stream<T> _watchTable<T>({
  required String table,
  required String filterColumn,
  required String filterValue,
  required Future<T> Function() fetch,
}) {
  late final StreamController<T> controller;
  RealtimeChannel? channel;

  Future<void> emit() async {
    if (controller.isClosed) return;
    try {
      final value = await fetch();
      if (!controller.isClosed) controller.add(value);
    } catch (e, stackTrace) {
      // Fila Certa 2.0 (secção 34 do redesign, "offline/rede instável"):
      // antes desta correcção, uma falha aqui (rede em baixo, timeout)
      // ficava muda -- o ecrã continuava preso no último valor visto sem
      // nenhum sinal de que a ligação caiu. `ConnectionBanner` escuta
      // este erro para mostrar isso ao utilizador.
      if (!controller.isClosed) controller.addError(e, stackTrace);
    }
  }

  controller = StreamController<T>.broadcast(
    onListen: () {
      channel = supabaseClient
          .channel('$table:$filterColumn:$filterValue:${DateTime.now().microsecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: filterColumn, value: filterValue),
            callback: (_) => emit(),
          )
          // `emit()` corre sempre que o canal fica `subscribed` -- não só
          // na primeira vez, mas também depois de uma reconexão automática
          // (perda de rede, app em background, etc.). O Postgres Changes
          // não reenvia eventos perdidos enquanto o socket esteve em
          // baixo, por isso sem isto o ecrã ficaria preso no último
          // estado visto antes de cair a ligação -- ao reconectar, o
          // estado é sempre resincronizado a partir da base de dados.
          .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) emit();
          });
    },
    onCancel: () {
      final ch = channel;
      if (ch != null) unawaited(supabaseClient.removeChannel(ch));
    },
  );
  return controller.stream;
}

/// Reavalia `fetch` a um intervalo fixo, em vez de reagir a
/// postgres_changes -- usado só para agregados calculados no servidor
/// (`branch_queue_summary`, `waiting_ahead_count`) que dependem de linhas
/// de `tickets` pertencentes a OUTROS clientes: depois do hardening de
/// segurança (docs/security-rls.md), um cliente sem senha activa nessa
/// filial já não recebe eventos de mudança dessas linhas via Realtime
/// (a política de RLS bloqueia-os também aí), por isso não há forma de
/// saber "quando" reler -- só reavaliar a espaços regulares.
Stream<T> _pollValue<T>({required Duration interval, required Future<T> Function() fetch}) {
  late final StreamController<T> controller;
  Timer? timer;

  Future<void> emit() async {
    if (controller.isClosed) return;
    try {
      final value = await fetch();
      if (!controller.isClosed) controller.add(value);
    } catch (e, stackTrace) {
      if (!controller.isClosed) controller.addError(e, stackTrace);
    }
  }

  controller = StreamController<T>.broadcast(
    onListen: () {
      emit();
      timer = Timer.periodic(interval, (_) => emit());
    },
    onCancel: () {
      timer?.cancel();
      timer = null;
    },
  );
  return controller.stream;
}

/// Gera um código sem colisão e cria a senha já na forma que a app da
/// equipa espera -- via `pull_ticket`, que faz o incremento atómico e a
/// escrita numa única transacção no servidor (RLS bloqueia INSERT directo
/// em `tickets`, ver docs/security.md).
Future<LiveTicketRef> pullTicket({
  required String institutionId,
  required String branchId,
  required String serviceName,
}) async {
  final row = await supabaseClient.rpc('pull_ticket', params: {
    'p_institution_id': institutionId,
    'p_branch_id': branchId,
    'p_service': serviceName,
  }) as Map<String, dynamic>;
  return LiveTicketRef(institutionId: institutionId, branchId: branchId, ticketId: row['id'] as String);
}

Stream<LiveTicket?> subscribeTicket(LiveTicketRef ref) {
  return _watchTable<LiveTicket?>(
    table: 'tickets',
    filterColumn: 'id',
    filterValue: ref.ticketId,
    fetch: () async {
      final row = await supabaseClient.from('tickets').select(_ticketColumns).eq('id', ref.ticketId).maybeSingle();
      return row == null ? null : _ticketFromRow(row);
    },
  );
}

Future<LiveTicket?> getTicketOnce(LiveTicketRef ref) async {
  final row = await supabaseClient.from('tickets').select(_ticketColumns).eq('id', ref.ticketId).maybeSingle();
  return row == null ? null : _ticketFromRow(row);
}

/// Nome do balcão (ex.: "Balcão 3") a partir do `counterId` atribuído à
/// senha -- leitura única, só precisa de ser resolvida depois de chamada.
Future<String?> getCounterLabel(String institutionId, String branchId, String counterId) async {
  final row = await supabaseClient
      .from('counters')
      .select('label')
      .eq('institution_id', institutionId)
      .eq('branch_id', branchId)
      .eq('id', counterId)
      .maybeSingle();
  return row?['label'] as String?;
}

/// Mesma informação que o painel de TV (`PublicDisplay.tsx`) já lê --
/// última senha chamada e em que balcão (tabela `ticket_calls`, log
/// append-only que substitui o antigo `liveBoard/current`).
Stream<LiveBoardEntry?> subscribeLiveBoardCurrent(String institutionId, String branchId) {
  return _watchTable<LiveBoardEntry?>(
    table: 'ticket_calls',
    filterColumn: 'branch_id',
    filterValue: branchId,
    fetch: () async {
      final row = await supabaseClient
          .from('ticket_calls')
          .select('code, counter_label, called_at')
          .eq('institution_id', institutionId)
          .eq('branch_id', branchId)
          .order('called_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return LiveBoardEntry(
        code: row['code'] as String? ?? '',
        counterLabel: row['counter_label'] as String? ?? '',
        updatedAt: _parseTime(row['called_at']),
      );
    },
  );
}

/// Estado do balcão (disponível/em atendimento/pausa) -- usado pelo
/// cliente para saber se o balcão que o está a atender está de momento em
/// pausa.
Stream<String?> subscribeCounterStatus(String institutionId, String branchId, String counterId) {
  return _watchTable<String?>(
    table: 'counters',
    filterColumn: 'branch_id',
    filterValue: branchId,
    fetch: () async {
      final row = await supabaseClient
          .from('counters')
          .select('status')
          .eq('institution_id', institutionId)
          .eq('branch_id', branchId)
          .eq('id', counterId)
          .maybeSingle();
      return row?['status'] as String?;
    },
  );
}

/// Quantas senhas em espera foram criadas antes da minha -- calculado no
/// servidor (`waiting_ahead_count`, confirma a posse da senha antes de
/// contar), sem expor as linhas de outros clientes. Reavaliado a cada 10s
/// (ver `_pollValue`).
Stream<int> subscribeWaitingAhead(LiveTicketRef ref, DateTime myCreatedAt) {
  return _pollValue<int>(
    interval: const Duration(seconds: 10),
    fetch: () async {
      final count = await supabaseClient.rpc('waiting_ahead_count', params: {'p_ticket_id': ref.ticketId});
      return count as int;
    },
  );
}

Future<List<Map<String, dynamic>>> _queueSummary(String institutionId, String branchId) async {
  final rows = await supabaseClient.rpc('branch_queue_summary', params: {
    'p_institution_id': institutionId,
    'p_branch_id': branchId,
  });
  return (rows as List).cast<Map<String, dynamic>>();
}

/// Quantas senhas estão em espera agora nesta agência -- usado antes de
/// entrar na fila (ex.: `LocationCard`), para substituir o número fixo de
/// `QueueLocation.peopleInQueue` por um valor real. Soma do agregado
/// `branch_queue_summary` (não lê as linhas de `tickets` directamente --
/// ver docs/security-rls.md).
Stream<int> subscribeQueueSize(String institutionId, String branchId) {
  return _pollValue<int>(
    interval: const Duration(seconds: 15),
    fetch: () async {
      final rows = await _queueSummary(institutionId, branchId);
      return rows.fold<int>(0, (sum, r) => sum + (r['waiting_count'] as num).toInt());
    },
  );
}

/// Nomes de serviço de todas as senhas em espera agora -- usado para
/// contar, por serviço, quantas pessoas estão à espera. Reconstrói a
/// mesma forma (uma entrada por senha) a partir do agregado
/// `branch_queue_summary`, para não obrigar os ecrãs que já contam
/// ocorrências nesta lista (`choose_service_screen.dart`) a mudar.
Stream<List<String>> subscribeWaitingServiceNames(String institutionId, String branchId) {
  return _pollValue<List<String>>(
    interval: const Duration(seconds: 15),
    fetch: () async {
      final rows = await _queueSummary(institutionId, branchId);
      return [
        for (final r in rows)
          for (var i = 0; i < (r['waiting_count'] as num).toInt(); i++) r['service'] as String? ?? '',
      ];
    },
  );
}

/// Todas as senhas reais do cliente numa localização (qualquer estado --
/// em espera, em atendimento, concluída, não compareceu...) -- alimenta
/// "Os meus atendimentos" (`my_appointments_screen.dart`).
Stream<List<MyTicket>> subscribeMyTickets(QueueLocation location, String customerUid) {
  final institutionId = location.institutionId;
  final branchId = location.branchId;
  if (institutionId == null || branchId == null) return Stream.value(const []);
  return _watchTable<List<MyTicket>>(
    table: 'tickets',
    filterColumn: 'branch_id',
    filterValue: branchId,
    fetch: () async {
      final rows = await supabaseClient
          .from('tickets')
          .select(
              'id, code, service, status, counter_id, no_show_reason, was_transferred, created_at, called_at, done_at')
          .eq('institution_id', institutionId)
          .eq('branch_id', branchId)
          .eq('customer_id', customerUid);
      return (rows as List)
          .map((row) => _myTicketFromRow(row as Map<String, dynamic>, location, institutionId, branchId))
          .toList();
    },
  );
}

MyTicket _myTicketFromRow(
  Map<String, dynamic> data,
  QueueLocation location,
  String institutionId,
  String branchId,
) {
  final serviceName = data['service'] as String? ?? '';
  ServiceItem? service;
  for (final s in location.services) {
    if (s.name == serviceName) {
      service = s;
      break;
    }
  }
  return MyTicket(
    id: data['id'] as String,
    ref: LiveTicketRef(institutionId: institutionId, branchId: branchId, ticketId: data['id'] as String),
    location: location,
    service: service,
    code: data['code'] as String? ?? '',
    status: ticketStatusFromString(data['status'] as String? ?? ''),
    counterId: data['counter_id'] as String?,
    noShowReason: noShowReasonFromString(data['no_show_reason'] as String?),
    wasTransferred: data['was_transferred'] as bool? ?? false,
    createdAt: _parseTime(data['created_at']),
    calledAt: _parseTime(data['called_at']),
    doneAt: _parseTime(data['done_at']),
  );
}

/// O próprio cliente desiste da senha (sair da fila, ou avisar que não
/// pode comparecer já depois de chamado) -- via `cancel_ticket`, que
/// confirma no servidor que a senha é mesmo do utilizador autenticado.
/// Fire-and-forget pelos ecrãs, para não bloquear a navegação nem rebentar
/// se o servidor recusar (ex.: senha já concluída).
Future<void> cancelTicket(LiveTicketRef ref) {
  return supabaseClient.rpc('cancel_ticket', params: {'p_ticket_id': ref.ticketId});
}

/// O cliente avisa que está a caminho do balcão -- o ecrã do agente mostra
/// isto em tempo real junto da senha em atendimento.
Future<void> setOnTheWay(LiveTicketRef ref) {
  return supabaseClient.rpc('set_on_the_way', params: {'p_ticket_id': ref.ticketId});
}

/// Reserva o próximo código de agendamento sem colisão (`AG001`,
/// `AG002`, ...) -- mesma sequência partilhada das senhas
/// (`branch_counters` no servidor). Só chamado para localizações reais;
/// as restantes (sem institutionId/branchId) continuam com o código local
/// antigo, gerado no próprio ecrã.
Future<String> nextAppointmentCode(String institutionId, String branchId) async {
  final code = await supabaseClient.rpc('next_appointment_code', params: {
    'p_institution_id': institutionId,
    'p_branch_id': branchId,
  });
  return code as String;
}

/// Cria o agendamento (tabela única `appointments`, já unificada -- ver
/// docs/database-design.md, Decisão 3). O id do dono é sempre
/// `auth.uid()` no servidor, nunca confiado a partir do cliente.
Future<void> scheduleAppointment({
  required String institutionId,
  required String branchId,
  required String code,
  required String serviceName,
  required DateTime date,
  required String time,
}) {
  final isoDate = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return supabaseClient.rpc('schedule_appointment', params: {
    'p_institution_id': institutionId,
    'p_branch_id': branchId,
    'p_code': code,
    'p_service': serviceName,
    'p_date': isoDate,
    'p_time': time,
  });
}

/// Marca o agendamento como cancelado -- nunca apagado, para o KPI
/// "Agendamentos hoje" continuar a contar correctamente quantos foram
/// marcados hoje.
Future<void> cancelAppointmentMirror({required String code}) {
  return supabaseClient.rpc('cancel_appointment', params: {'p_code': code});
}

/// Avaliação do cliente depois de concluído o atendimento (RatingScreen)
/// -- uma linha por senha (`ticket_id` é `unique`); alimenta o resumo de
/// qualidade do dashboard da equipa. Insert directo (RLS confirma
/// `customer_id = auth.uid()` e que a senha é mesmo do cliente, ver
/// docs/security.md Decisão 4 -- sem concorrência a proteger aqui).
Future<void> submitRating({
  required LiveTicketRef ref,
  required String serviceName,
  required int overall,
  required bool recommend,
  required String comment,
  required Map<String, int> aspects,
}) {
  final uid = supabaseClient.auth.currentUser?.id;
  if (uid == null) return Future.value();
  return supabaseClient.from('ratings').insert({
    'ticket_id': ref.ticketId,
    'institution_id': ref.institutionId,
    'branch_id': ref.branchId,
    'customer_id': uid,
    'service': serviceName,
    'overall': overall,
    'recommend': recommend,
    'comment': comment,
    'aspect_atendimento': aspects['atendimento'] ?? 0,
    'aspect_tempo_espera': aspects['tempoEspera'] ?? 0,
    'aspect_organizacao': aspects['organizacao'] ?? 0,
    'aspect_instalacoes': aspects['instalacoes'] ?? 0,
  });
}
