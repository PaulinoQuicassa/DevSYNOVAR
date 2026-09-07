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

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      // Sem tracing/session replay -- só rastreio de erros (é o que foi
      // pedido; tracing teria custo de performance e quota sem
      // necessidade comprovada ainda).
      options.tracesSampleRate = 0.0;
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
