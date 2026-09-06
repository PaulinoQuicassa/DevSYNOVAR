import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

/// Thin wrapper around Supabase Auth — the only place in the app that
/// talks to it directly, so screens/tests never depend on Supabase types
/// beyond [User]. Every method returns a Portuguese error message on
/// failure (or `null` on success) instead of throwing, so callers can show
/// it directly without their own try/catch + error-code mapping.
class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? supabaseClient;

  final SupabaseClient _client;

  Stream<User?> get userChanges =>
      _client.auth.onAuthStateChange.map((state) => state.session?.user);

  User? get currentUser => _client.auth.currentSession?.user;

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return _message(e);
    } catch (_) {
      return 'Não foi possível criar a conta. Tenta novamente.';
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return _message(e);
    } catch (_) {
      return 'Não foi possível entrar. Tenta novamente.';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return null;
    } on AuthException catch (e) {
      return _message(e);
    } catch (_) {
      return 'Não foi possível enviar o email. Tenta novamente.';
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  String _message(AuthException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return 'Já existe uma conta com este email.';
    }
    if (code == 'weak_password' || msg.contains('password')) {
      return 'A palavra-passe deve ter pelo menos 6 caracteres.';
    }
    if (code == 'invalid_credentials' || msg.contains('invalid login credentials')) {
      return 'Email ou palavra-passe incorretos.';
    }
    if (msg.contains('email') && msg.contains('invalid')) {
      return 'Email inválido.';
    }
    if (code == 'over_request_rate_limit' || msg.contains('rate limit')) {
      return 'Demasiadas tentativas. Aguarda um pouco e tenta novamente.';
    }
    if (msg.contains('network')) {
      return 'Sem ligação à internet. Verifica a tua rede.';
    }
    return 'Ocorreu um erro. Tenta novamente.';
  }
}

/// Mutable (not `final`) so tests can swap in an `AuthService` wrapping a
/// fake Supabase client before pumping widgets.
AuthService authService = AuthService();
