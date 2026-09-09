import 'dart:web_audio';

/// `SystemSound.play` não existe na Web (o Flutter não implementa esse
/// canal de plataforma lá -- fica sempre em silêncio, sem erro nenhum
/// visível, o que escondeu este problema até agora). Gera o mesmo tipo
/// de aviso sonoro (dois tons) directamente via Web Audio API, tal como
/// já é feito em fila-certa-staff/src/pages/PublicDisplay.tsx.
void playAlertSound() {
  try {
    final ctx = AudioContext();
    final notes = <(double, double)>[(880, 0), (660, 0.18)];
    for (final (frequency, start) in notes) {
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency!.value = frequency;
      osc.connectNode(gain);
      gain.connectNode(ctx.destination!);
      final t0 = ctx.currentTime! + start;
      gain.gain!.setValueAtTime(0, t0);
      gain.gain!.linearRampToValueAtTime(0.3, t0 + 0.02);
      gain.gain!.exponentialRampToValueAtTime(0.001, t0 + 0.32);
      osc.start(t0);
      osc.stop(t0 + 0.32);
    }
  } catch (_) {
    // Alguns browsers só permitem áudio depois de uma interacção do
    // utilizador na página -- nesse caso o alerta continua a aparecer
    // (o banner/registo nunca dependem do som), só fica sem som desta
    // vez em concreto.
  }
}
