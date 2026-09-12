# Registo/login por telefone

Implementado em 2026-09-12, a pedido explícito: o registo passa a ser
por número de telefone + código de verificação, em vez de email/
palavra-passe. Usa a autenticação por telefone nativa do Supabase
(`signInWithOtp`/`verifyOTP`, tipo `sms`) -- a mesma chamada serve para
criar conta e para entrar numa já existente, o Supabase decide sozinho
ao confirmar o código.

## Estado: código pronto, por testar de verdade

**O Supabase deste projecto não tem nenhum fornecedor de SMS
configurado.** Sem isso, tocar em "Enviar código" no ecrã de entrada
vai falhar -- o código está correcto, mas não há ninguém a enviar o
SMS. Isto é o mesmo tipo de bloqueio já documentado para o canal
WhatsApp (`docs/whatsapp-channel.md`) e para a Play Store
(`docs/android-release.md`): só o dono da conta Supabase consegue
resolver isto.

### Para activar a sério

1. Dashboard do Supabase → Authentication → Providers → Phone.
2. Escolher e configurar um fornecedor de SMS suportado (Twilio,
   MessageBird, Vonage ou TextLocal) -- precisa de uma conta paga
   nesse fornecedor, com um número de origem.
3. Confirmar que o código de país por omissão faz sentido (a app já
   fixa `+244`, Angola, no ecrã -- só envia o número local de 9
   dígitos).

### WhatsApp em vez de SMS

O Supabase suporta pedir o código por WhatsApp em vez de SMS
(`OtpChannel.whatsapp` em vez do `OtpChannel.sms` por omissão usado
hoje em `sendPhoneOtp`) -- mas só funciona se o fornecedor de SMS
escolhido acima também tiver a integração com WhatsApp Business API
activada (a maioria exige o mesmo processo de aprovação da Meta já em
curso para o canal WhatsApp desta app). Por agora fica em SMS, que é
mais simples de activar primeiro; mudar para WhatsApp depois é alterar
um parâmetro, não uma reescrita.

## O que ficou assim

- **`lib/screens/login_screen.dart`** -- ecrã principal agora: número
  de telefone → código de 6 dígitos → sessão. Entrada única de
  `requireAuth` (contextual, ver `auth/require_auth.dart`).
- **`lib/screens/email_login_screen.dart`** (novo) -- entrar com email/
  palavra-passe, para contas criadas antes desta mudança. Acessível a
  partir de um link discreto em `login_screen.dart`. Continua a
  permitir criar conta nova por email (`signup_screen.dart`,
  inalterado) -- não foi removido de propósito, para nunca haver um
  bloqueio total de registo enquanto o SMS não estiver configurado.
- **`lib/auth/auth_service.dart`** -- `sendPhoneOtp`/`verifyPhoneOtp`
  novos, ao lado dos métodos de email já existentes (não removidos).
- Ecrãs que mostravam `user.email` (perfil, saudação da Home) passam a
  mostrar o telefone quando a conta for por telefone.

## Contas de teste desta sessão

As contas `agente@*.test`/`gestor@*.test` e a conta de director
continuam por email/palavra-passe -- entram por "Entrar com email
(contas antigas)", sem qualquer mudança de comportamento.
