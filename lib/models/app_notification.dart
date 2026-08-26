/// Uma notificação recebida pelo cliente (ex.: "É a sua vez!", "O seu
/// atendimento foi concluído") — persistida em
/// `users/{uid}/notifications/{id}` para o sino no `HomeScreen` mostrar
/// uma contagem real de não lidas, em vez de um indicador decorativo.
class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final DateTime? createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.read,
  });
}
