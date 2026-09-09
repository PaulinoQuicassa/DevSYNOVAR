import 'package:flutter/services.dart';

/// Compilado quando não é web (Android/iOS/desktop) -- aí
/// `SystemSound.play` funciona mesmo.
void playAlertSound() {
  SystemSound.play(SystemSoundType.alert);
}
