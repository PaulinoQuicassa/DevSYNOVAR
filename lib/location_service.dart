import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Posição actual do dispositivo, uma vez obtida — `null` enquanto ainda
/// não foi pedida, a permissão foi recusada, o GPS está desligado, ou o
/// pedido falhou por qualquer razão. Todos os ecrãs que ordenam
/// localizações por distância tratam `null` da mesma forma: caem para a
/// distância fixa (`QueueLocation.distanceKm`) que já existia antes desta
/// funcionalidade, nunca bloqueiam nem mostram erro por causa disto.
final currentPosition = ValueNotifier<Position?>(null);

bool _fetching = false;

/// Pede a localização do dispositivo uma única vez por sessão da app —
/// chamadas seguintes são no-op enquanto já houver um valor ou um pedido
/// em curso. Nunca lança exceções: qualquer falha (permissão recusada,
/// serviço de localização desligado, temporizado) só deixa
/// [currentPosition] a `null`.
Future<void> ensureCurrentPosition() async {
  if (currentPosition.value != null || _fetching) return;
  _fetching = true;
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }
    currentPosition.value = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 8)),
    );
  } catch (_) {
    // Sem GPS real disponível — os ecrãs caem para a distância fixa.
  } finally {
    _fetching = false;
  }
}

/// Distância real, em km, até `(lat, lng)` — `null` se a posição do
/// dispositivo ainda não estiver disponível ou a localização não tiver
/// coordenadas próprias.
double? realDistanceKm(double? lat, double? lng) {
  final pos = currentPosition.value;
  if (pos == null || lat == null || lng == null) return null;
  return Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng) / 1000;
}
