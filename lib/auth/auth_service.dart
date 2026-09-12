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

  /// Envia um código de verificação por SMS para `phone` (formato E.164,
  /// ex.: "+244923456789"). A mesma chamada serve para conta nova e para
  /// entrar numa já existente -- o Supabase decide sozinho ao confirmar o
  /// código (`verifyPhoneOtp`), não há um passo de registo à parte.
  Future<String?> sendPhoneOtp(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
      return null;
    } on AuthException catch (e) {
      return _message(e);
    } catch (_) {
      return 'Não foi possível enviar o código. Tenta novamente.';
    }
  }

  /// Confirma o código de 6 dígitos recebido por SMS -- sucesso cria a
  /// sessão (conta nova ou já existente, o que se aplicar).
  Future<String?> verifyPhoneOtp({required String phone, required String token}) async {
    try {
      await _client.auth.verifyOTP(type: OtpType.sms, phone: phone, token: token.trim());
      return null;
    } on AuthException catch (e) {
      return _message(e);
    } catch (_) {
      return 'Não foi possível confirmar o código. Tenta novamente.';
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
    if (code == 'invalid_phone_number' || (msg.contains('phone') && msg.contains('invalid'))) {
      return 'Número de telefone inválido.';
    }
    if (code == 'otp_expired' || msg.contains('token has expired') || msg.contains('otp_expired')) {
      return 'Código expirado. Pede um código novo.';
    }
    if (code == 'otp_disabled') {
      return 'Não foi possível enviar o código -- serviço de SMS ainda não está configurado.';
    }
    if (msg.contains('token') && (msg.contains('invalid') || msg.contains('incorrect'))) {
      return 'Código incorreto. Confirma os 6 dígitos e tenta novamente.';
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
