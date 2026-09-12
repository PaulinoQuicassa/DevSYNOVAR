/// Estado real das notificações por WhatsApp da conta com sessão
/// iniciada -- lido directamente do servidor (RPC
/// `whatsapp_notifications_status`), nunca só da preferência local
/// gravada em `user_settings`. `phone` vem já em E.164 (+244...),
/// `null` para uma conta sem telefone (ex.: conta antiga por email).
class WhatsappStatus {
  final String? phone;
  final bool phoneVerified;
  final bool notificationsEnabled;

  const WhatsappStatus({
    required this.phone,
    required this.phoneVerified,
    required this.notificationsEnabled,
  });

  static const none = WhatsappStatus(phone: null, phoneVerified: false, notificationsEnabled: false);
}
