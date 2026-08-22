import 'queue_location.dart';
import 'service_item.dart';

class Appointment {
  final String code;
  final QueueLocation location;
  final ServiceItem service;
  final DateTime date;
  final String time;

  const Appointment({
    required this.code,
    required this.location,
    required this.service,
    required this.date,
    required this.time,
  });
}
