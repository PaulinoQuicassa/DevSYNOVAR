import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state.dart';
import 'screens/auth_gate.dart';
import 'supabase_client.dart';
import 'theme/app_theme.dart';

// DSN não é secreta (mesma natureza da publishable key do Supabase) --
// identifica só o projecto Sentry para onde os eventos são enviados,
// não dá acesso a nada. Projecto: Synovaris / fila-certa-client.
const _sentryDsn = 'https://a50dd41a0ecba3f5f1252d30f9a23848@o4512046055161856.ingest.us.sentry.io/4512046083670016';

// Nunca deixar sair um destes valores para o Sentry, mesmo por engano
// num `extra`/scope de contexto (Fase 16: "NUNCA enviar OTP, password,
// tokens, telefone completo") -- rede de segurança aplicada a
// QUALQUER string do evento antes de sair, mesmo com
// `sendDefaultPii = false` já por omissão no SDK.
final _phonePattern = RegExp(r'(\+?\d[\d\s-]{7,}\d)');
final _jwtPattern = RegExp(r'eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}');

String _redactString(String value) {
  return value
      .replaceAll(_jwtPattern, '[jwt-removido]')
      .replaceAllMapped(_phonePattern, (m) => '${m.group(0)!.substring(0, 3)}…[oculto]');
}

SentryEvent _redactEvent(SentryEvent event, Hint hint) {
  // Mutação directa dos campos (não `copyWith`) -- `SentryEvent` já os
  // expõe como propriedades atribuíveis, e `copyWith` está marcado
  // como deprecated no SDK ("Assign values directly to the instance").
  final message = event.message;
  if (message != null) {
    event.message = SentryMessage(_redactString(message.formatted));
  }
  for (final ex in event.exceptions ?? const <SentryException>[]) {
    if (ex.value != null) ex.value = _redactString(ex.value!);
  }
  return event;
}

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      // Sem tracing/session replay -- só rastreio de erros (é o que foi
      // pedido; tracing teria custo de performance e quota sem
      // necessidade comprovada ainda).
      options.tracesSampleRate = 0.0;
      options.sendDefaultPii = false;
      options.beforeSend = _redactEvent;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
      runApp(const FilaCertaApp());
    },
  );
}

class FilaCertaApp extends StatelessWidget {
  const FilaCertaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fila Certa',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}
