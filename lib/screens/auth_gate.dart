import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../app_stores.dart';
import '../auth/auth_service.dart';
import '../widgets/global_queue_alerts.dart';
import 'root_shell.dart';

/// Fila Certa 2.0 (redesign UX/UI): já não decide entre [LoginScreen] e
/// [RootShell] -- o modo convidado (secção 4 do master prompt) mostra
/// sempre [RootShell], com ou sem sessão. [LoginScreen] só aparece
/// empurrada contextualmente por `requireAuth` (ver `auth/require_auth.dart`)
/// no momento em que uma acção concreta precisa de conta (entrar na fila,
/// favoritos, histórico pessoal, notificações). Este widget continua a
/// existir só para manter cada store (`app_stores.dart`) sincronizado com
/// a conta certa — iniciado ao entrar, parado ao sair, para não vazar
/// dados de uma conta para a sessão seguinte no mesmo aparelho.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<User?> _sub;
  String? _syncedUid;

  @override
  void initState() {
    super.initState();
    _applySync(authService.currentUser);
    _sub = authService.userChanges.listen(_applySync);
  }

  void _applySync(User? user) {
    if (user == null) {
      if (_syncedUid != null) {
        stopUserDataSync();
        _syncedUid = null;
      }
      activeTicketStore.value = const [];
    } else if (_syncedUid != user.id) {
      startUserDataSync(user.id);
      _syncedUid = user.id;
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const GlobalQueueAlerts(child: RootShell());
  }
}
