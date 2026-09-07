import 'package:flutter/material.dart';
import 'service_item.dart';

enum QueueLoad { low, medium, high }

extension QueueLoadX on QueueLoad {
  Color get color {
    switch (this) {
      case QueueLoad.low:
        return const Color(0xFF16A34A);
      case QueueLoad.medium:
        return const Color(0xFFD97706);
      case QueueLoad.high:
        return const Color(0xFFDC2626);
    }
  }

  Color get bgColor {
    switch (this) {
      case QueueLoad.low:
        return const Color(0xFFDCFCE7);
      case QueueLoad.medium:
        return const Color(0xFFFEF3C7);
      case QueueLoad.high:
        return const Color(0xFFFEE2E2);
    }
  }
}

class QueueLocation {
  final String name;
  final String subtitle;
  final String address;
  final String distance;
  final double distanceKm;
  final int peopleInQueue;
  final int etaMinutes;
  final QueueLoad load;
  final String monogram;
  final Color brandColor;
  final String phone;
  final List<ServiceItem> services;

  /// Quando ambos definidos, esta localização está ligada a dados reais
  /// no Postgres (tabelas `institutions`/`branches` do Supabase) — tirar
  /// uma senha aqui cria uma linha real, visível na app da equipa. `null`
  /// (o caso das restantes localizações) mantém o comportamento
  /// mock/estático de sempre.
  final String? institutionId;
  final String? branchId;

  /// Coordenadas reais da agência — usadas por `location_service.dart`
  /// para calcular a distância real ao dispositivo (GPS) quando
  /// disponível; `distance`/`distanceKm` continuam a servir de recurso
  /// quando a localização do dispositivo não está disponível/autorizada.
  final double? latitude;
  final double? longitude;

  const QueueLocation({
    required this.name,
    required this.subtitle,
    required this.address,
    required this.distance,
    required this.distanceKm,
    required this.peopleInQueue,
    required this.etaMinutes,
    required this.load,
    required this.monogram,
    required this.brandColor,
    required this.phone,
    required this.services,
    this.institutionId,
    this.branchId,
    this.latitude,
    this.longitude,
  });
}
