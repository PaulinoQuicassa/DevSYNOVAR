import 'package:flutter/material.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';

class MockData {
  MockData._();

  static const locations = <QueueLocation>[
    QueueLocation(
      name: 'Banco de Poupança e Crédito (BPC)',
      subtitle: 'Agência Talatona',
      address: 'Talatona, Luanda',
      distance: '350 m',
      distanceKm: 0.35,
      peopleInQueue: 8,
      etaMinutes: 15,
      load: QueueLoad.low,
      monogram: 'BPC',
      brandColor: Color(0xFF1D3F91),
      phone: '+244923000101',
    ),
    QueueLocation(
      name: 'Banco BFA',
      subtitle: 'Agência Belas',
      address: 'Belas, Luanda',
      distance: '4,2 km',
      distanceKm: 4.2,
      peopleInQueue: 12,
      etaMinutes: 18,
      load: QueueLoad.medium,
      monogram: 'BFA',
      brandColor: Color(0xFFE8622C),
      phone: '+244923000102',
    ),
    QueueLocation(
      name: 'Banco BAI',
      subtitle: 'Agência Viana',
      address: 'Viana, Luanda',
      distance: '6,1 km',
      distanceKm: 6.1,
      peopleInQueue: 20,
      etaMinutes: 28,
      load: QueueLoad.high,
      monogram: 'BAI',
      brandColor: Color(0xFF1E7A4C),
      phone: '+244923000103',
    ),
    QueueLocation(
      name: 'Banco BCI',
      subtitle: 'Agência Kilamba',
      address: 'Kilamba, Luanda',
      distance: '7,5 km',
      distanceKm: 7.5,
      peopleInQueue: 6,
      etaMinutes: 12,
      load: QueueLoad.low,
      monogram: 'BCI',
      brandColor: Color(0xFF15171C),
      phone: '+244923000104',
    ),
    QueueLocation(
      name: 'SIAC — Centro de Atendimento',
      subtitle: 'Serviços ao Cidadão',
      address: 'Talatona, Luanda',
      distance: '1,1 km',
      distanceKm: 1.1,
      peopleInQueue: 10,
      etaMinutes: 16,
      load: QueueLoad.medium,
      monogram: 'SIAC',
      brandColor: Color(0xFF2E7CB8),
      phone: '+244923000105',
    ),
  ];

  static const services = <ServiceItem>[
    ServiceItem(
      name: 'Atendimento Balcão',
      description: 'Serviços gerais no balcão',
      peopleInQueue: 5,
      etaMinutes: 15,
      icon: Icons.groups_outlined,
      color: Color(0xFF2F5FEA),
    ),
    ServiceItem(
      name: 'Depósitos e Levantamentos',
      description: 'Depósitos, levantamentos e outras operações',
      peopleInQueue: 3,
      etaMinutes: 12,
      icon: Icons.payments_outlined,
      color: Color(0xFF16A34A),
    ),
    ServiceItem(
      name: 'Cartões',
      description: 'Pedidos, desbloqueios e informações de cartões',
      peopleInQueue: 2,
      etaMinutes: 10,
      icon: Icons.credit_card_outlined,
      color: Color(0xFF7C3AED),
    ),
    ServiceItem(
      name: 'Crédito Habitação',
      description: 'Informações e processos de crédito habitação',
      peopleInQueue: 4,
      etaMinutes: 18,
      icon: Icons.home_outlined,
      color: Color(0xFFEA7C2F),
    ),
    ServiceItem(
      name: 'Crédito Pessoal',
      description: 'Informações e processos de crédito pessoal',
      peopleInQueue: 6,
      etaMinutes: 20,
      icon: Icons.description_outlined,
      color: Color(0xFF0EA5A5),
    ),
    ServiceItem(
      name: 'Reclamações',
      description: 'Registo e acompanhamento de reclamações',
      peopleInQueue: 1,
      etaMinutes: 8,
      icon: Icons.support_agent_outlined,
      color: Color(0xFFDC2626),
    ),
  ];

  static const ticketProgress = <String>['A019', 'A020', 'A021', 'A022', 'A023', 'A024', 'A025'];
  static const currentTicket = 'A023';
  static const counterNumber = '03';
  static const lastCalledTicket = 'A019';

  static const supportPhone = '+244900000000';
  static const supportEmail = 'suporte@filacerta.ao';
  static const supportWhatsapp = '244900000000';

  static const timeSlots = <String>[
    '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  ];
}
