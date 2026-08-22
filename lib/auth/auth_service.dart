import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth] — the only place in the app that
/// talks to it directly, so screens/tests never depend on Firebase types
/// beyond [User]. Every method returns a Portuguese error message on
/// failure (or `null` on success) instead of throwing, so callers can show
/// it directly without their own try/catch + error-code mapping.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get userChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'Não foi possível criar a conta. Tenta novamente.';
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'Não foi possível entrar. Tenta novamente.';
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _message(e.code);
    } catch (_) {
      return 'Não foi possível enviar o email. Tenta novamente.';
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _message(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou palavra-passe incorretos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este email.';
      case 'weak-password':
        return 'A palavra-passe deve ter pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem ligação à internet. Verifica a tua rede.';
      case 'too-many-requests':
        return 'Demasiadas tentativas. Aguarda um pouco e tenta novamente.';
      default:
        return 'Ocorreu um erro. Tenta novamente.';
    }
  }
}

/// Mutable (not `final`) so tests can swap in an `AuthService` wrapping a
/// fake `FirebaseAuth` (e.g. `firebase_auth_mocks`) before pumping widgets.
AuthService authService = AuthService();
