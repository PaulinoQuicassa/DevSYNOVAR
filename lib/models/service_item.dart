import 'package:flutter/material.dart';

class ServiceItem {
  final String name;
  final String description;
  final int peopleInQueue;
  final int etaMinutes;
  final IconData icon;
  final Color color;

  /// "O que preciso levar?" (secção 13 do redesign) -- lista curta e
  /// genérica dos documentos normalmente pedidos para este serviço.
  /// Dado de referência estático (mesmo tratamento que o resto de
  /// `mock_data.dart`), não uma garantia contratual -- por isso o ecrã
  /// que a mostra inclui sempre o aviso "confirme antes de sair".
  final List<String> documents;

  const ServiceItem({
    required this.name,
    required this.description,
    required this.peopleInQueue,
    required this.etaMinutes,
    required this.icon,
    required this.color,
    this.documents = const [],
  });
}
