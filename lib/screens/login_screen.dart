import 'dart:async';

import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/gradient_button.dart';
import 'email_login_screen.dart';

/// Entrar/criar conta por telefone -- entrada principal (Fila Certa 2.0),
/// pedida explicitamente em vez de email/palavra-passe: um número de
/// telefone identifica a pessoa de forma mais directa para uma app de
/// filas (é também o número que recebe os avisos por WhatsApp, quando
/// esse canal estiver ligado), e um código de 6 dígitos por SMS evita
/// palavras-passe esquecidas. Uma única chamada (`sendPhoneOtp` +
/// `verifyPhoneOtp`) serve tanto para criar conta como para entrar numa
/// já existente -- o Supabase decide sozinho ao confirmar o código, sem
/// passo de registo à parte. Contas antigas (email/palavra-passe)
/// continuam a entrar por [EmailLoginScreen], acessível a partir daqui.
class LoginScreen extends StatefulWidget {
  /// Explica, no momento certo, porque é que esta acção concreta precisa
  /// de uma conta (Fila Certa 2.0, secção 4 do master prompt: "a
  /// autenticação deve acontecer no momento em que existe uma razão
  /// clara"). `null` mantém o texto genérico (ex.: alguém que entra aqui
  /// por iniciativa própria a partir do Perfil, não por ter sido barrado
  /// a meio de uma acção).
  final String? reason;

  const LoginScreen({super.key, this.reason});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { phone, code }

class _LoginScreenState extends State<LoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  _Step _step = _Step.phone;
  String? _e164Phone;
  bool _submitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Angola só, tal como todo o resto do catálogo piloto (ver
  /// mock_data.dart -- todas as agências ficam em Luanda) -- número
  /// local de 9 dígitos, prefixo fixo "+244".
  String? _e164From(String rawLocalNumber) {
    final digits = rawLocalNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return null;
    return '+244$digits';
  }

  Future<void> _sendCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    final e164 = _e164From(_phoneController.text)!;
    setState(() => _submitting = true);
    final error = await authService.sendPhoneOtp(e164);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      _e164Phone = e164;
      _step = _Step.code;
    });
  }

  Future<void> _verifyCode() async {
    if (!_codeFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final error = await authService.verifyPhoneOtp(phone: _e164Phone!, token: _codeController.text);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    // Só para auditoria (ver docs/phone-auth.md) -- nunca bloqueia o
    // login se falhar por algum motivo (rede, etc.), por isso sem
    // await no fluxo principal nem tratamento de erro visível.
    unawaited(ticket_service.recordPhoneVerifiedEvent());
    // Empurrada contextualmente (ver `requireAuth`) -- devolve o sucesso
    // a quem chamou. No-op se esta instância for a única rota (não há o
    // que fechar).
    Navigator.of(context, rootNavigator: true).maybePop(true);
  }

  Future<void> _resendCode() async {
    if (_e164Phone == null) return;
    setState(() => _submitting = true);
    final error = await authService.sendPhoneOtp(_e164Phone!);
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Enviámos um novo código.')),
    );
  }

  void _changeNumber() {
    setState(() {
      _step = _Step.phone;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context, rootNavigator: true).maybePop(false),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: _step == _Step.phone ? _buildPhoneStep() : _buildCodeStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 24),
          const Text('Fila Certa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            widget.reason ?? 'Entre com o seu número de telemóvel para ver os seus atendimentos em qualquer aparelho.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Número de telemóvel',
              prefixText: '+244 ',
              prefixIcon: Icon(Icons.phone_iphone),
              hintText: '9XX XXX XXX',
            ),
            validator: (v) => _e164From(v ?? '') == null ? 'Escreva os 9 dígitos do número.' : null,
            onFieldSubmitted: (_) => _submitting ? null : _sendCode(),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _submitting ? 'A enviar código…' : 'Receber código',
            onTap: _submitting ? null : _sendCode,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context, rootNavigator: true).push<bool>(
                        MaterialPageRoute(builder: (_) => EmailLoginScreen(reason: widget.reason)),
                      ).then((result) {
                        if (result == true && mounted) Navigator.of(context, rootNavigator: true).maybePop(true);
                      }),
              child: const Text('Entrar com email (contas antigas)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.sms_outlined, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 24),
          const Text('Código de verificação', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'Enviámos um código para o seu número.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 8),
            decoration: const InputDecoration(labelText: 'Código', counterText: ''),
            maxLength: 6,
            validator: (v) => (v == null || v.trim().length != 6) ? 'O código tem 6 dígitos.' : null,
            onFieldSubmitted: (_) => _submitting ? null : _verifyCode(),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _submitting ? 'A entrar…' : 'Entrar',
            onTap: _submitting ? null : _verifyCode,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _submitting ? null : _changeNumber,
                child: const Text('Trocar número'),
              ),
              TextButton(
                onPressed: _submitting ? null : _resendCode,
                child: const Text('Reenviar código'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
