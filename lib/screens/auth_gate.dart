import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../app_stores.dart';
import '../auth/auth_service.dart';
import '../widgets/global_queue_alerts.dart';
import 'login_screen.dart';
import 'root_shell.dart';

/// Decides between [LoginScreen] and [RootShell] as Supabase Auth state
/// changes, and keeps every store's realtime listener (`app_stores.dart`)
/// pointed at the right account — started on sign-in, stopped on sign-out,
/// so no data from one account leaks into the next session on this device.
///
/// Seeds [_user] from `authService.currentUser` synchronously instead of
/// waiting for the first `userChanges` event: a fresh subscriber to
/// `onAuthStateChange` isn't guaranteed to replay an already-signed-in
/// state, which would otherwise leave this widget stuck showing nothing
/// forever.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<User?> _sub;
  late User? _user = authService.currentUser;
  String? _syncedUid;

  @override
  void initState() {
    super.initState();
    _applySync(_user);
    _sub = authService.userChanges.listen(_onUser);
  }

  void _onUser(User? user) {
    _applySync(user);
    setState(() => _user = user);
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
    return _user == null ? const LoginScreen() : const GlobalQueueAlerts(child: RootShell());
  }
}
