// Escolhe a implementação certa em tempo de compilação -- `dart:html`
// só está disponível quando o alvo é web, por isso este import
// condicional é a forma correcta de ramificar sem depender de um
// pacote novo.
export 'alert_sound_stub.dart' if (dart.library.html) 'alert_sound_web.dart';
