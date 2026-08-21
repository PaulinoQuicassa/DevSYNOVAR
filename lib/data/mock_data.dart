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
      peopleInQueue: 8,
      etaMinutes: 15,
      load: QueueLoad.low,
      monogram: 'BPC',
      brandColor: Color(0xFF1D3F91),
    ),
    QueueLocation(
      name: 'Banco BFA',
      subtitle: 'Agência Belas',
      address: 'Belas, Luanda',
      distance: '4,2 km',
      peopleInQueue: 12,
      etaMinutes: 18,
      load: QueueLoad.medium,
      monogram: 'BFA',
      brandColor: Color(0xFFE8622C),
    ),
    QueueLocation(
      name: 'Banco BAI',
      subtitle: 'Agência Viana',
      address: 'Viana, Luanda',
      distance: '6,1 km',
      peopleInQueue: 20,
      etaMinutes: 28,
      load: QueueLoad.high,
      monogram: 'BAI',
      brandColor: Color(0xFF1E7A4C),
    ),
    QueueLocation(
      name: 'Banco BCI',
      subtitle: 'Agência Kilamba',
      address: 'Kilamba, Luanda',
      distance: '7,5 km',
      peopleInQueue: 6,
      etaMinutes: 12,
      load: QueueLoad.low,
      monogram: 'BCI',
      brandColor: Color(0xFF15171C),
    ),
    QueueLocation(
      name: 'SIAC — Centro de Atendimento',
      subtitle: 'Serviços ao Cidadão',
      address: 'Talatona, Luanda',
      distance: '1,1 km',
      peopleInQueue: 10,
      etaMinutes: 16,
      load: QueueLoad.medium,
      monogram: 'SIAC',
      brandColor: Color(0xFF2E7CB8),
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
}
