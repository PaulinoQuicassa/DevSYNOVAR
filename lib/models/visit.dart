import 'package:flutter/material.dart';

enum VisitStatus { completed, missed }

extension VisitStatusX on VisitStatus {
  String get label => this == VisitStatus.completed ? 'Concluído' : 'Não compareceu';
  Color get color => this == VisitStatus.completed ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
  Color get background => this == VisitStatus.completed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
}

class Visit {
  final String bank;
  final String monogram;
  final Color color;
  final String service;
  final String date;
  final String ticket;
  final VisitStatus status;
  final int? rating;

  const Visit({
    required this.bank,
    required this.monogram,
    required this.color,
    required this.service,
    required this.date,
    required this.ticket,
    required this.status,
    this.rating,
  });
}
