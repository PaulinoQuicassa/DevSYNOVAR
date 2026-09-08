import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/login_screen.dart';

/// Autenticação contextual (Fila Certa 2.0, princípio "não obrigar login
/// cedo demais" -- secção 4 do master prompt do redesign): em vez de
/// bloquear a app inteira à entrada, cada acção que realmente precisa de
/// uma conta chama isto no momento exacto em que precisa dela, com uma
/// explicação do motivo. Devolve `true` se já havia sessão ou se o
/// utilizador acabou de iniciar sessão com sucesso; `false` se cancelou.
Future<bool> requireAuth(BuildContext context, {required String reason}) async {
  if (authService.currentUser != null) return true;
  final result = await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute(builder: (_) => LoginScreen(reason: reason)),
  );
  return result == true;
}
