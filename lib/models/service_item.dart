import 'package:flutter/material.dart';

class ServiceItem {
  final String name;
  final String description;
  final int peopleInQueue;
  final int etaMinutes;
  final IconData icon;
  final Color color;

  const ServiceItem({
    required this.name,
    required this.description,
    required this.peopleInQueue,
    required this.etaMinutes,
    required this.icon,
    required this.color,
  });
}
