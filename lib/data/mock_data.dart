import 'package:flutter/material.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';

class MockData {
  MockData._();

  static const bankServices = <ServiceItem>[
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

  // Catálogo real do SIAC — Serviço Integrado de Atendimento ao Cidadão:
  // um balcão único que reúne identificação, registos, trânsito, migração,
  // finanças (AGT/INSS) e licenciamento de várias entidades públicas.
  static const siacServices = <ServiceItem>[
    ServiceItem(
      name: 'Bilhete de Identidade',
      description: '1.ª via, 2.ª via e substituição do Bilhete de Identidade',
      peopleInQueue: 14,
      etaMinutes: 25,
      icon: Icons.badge_outlined,
      color: Color(0xFF2F5FEA),
    ),
    ServiceItem(
      name: 'Registo Civil',
      description: 'Registo de nascimento, casamento e óbito',
      peopleInQueue: 9,
      etaMinutes: 20,
      icon: Icons.family_restroom_outlined,
      color: Color(0xFF16A34A),
    ),
    ServiceItem(
      name: 'Trânsito e Matrículas (DTSER)',
      description: 'Matrícula de veículos e Título Único de Veículo (TUV)',
      peopleInQueue: 7,
      etaMinutes: 18,
      icon: Icons.directions_car_filled_outlined,
      color: Color(0xFFEA7C2F),
    ),
    ServiceItem(
      name: 'Passaporte e Residência',
      description: 'Passaporte ordinário, entrega e cartão de residente (SME)',
      peopleInQueue: 11,
      etaMinutes: 22,
      icon: Icons.flight_takeoff_outlined,
      color: Color(0xFF0EA5A5),
    ),
    ServiceItem(
      name: 'Cartório Notarial',
      description: 'Autenticação de fotocópias, termos e abertura de sinal',
      peopleInQueue: 5,
      etaMinutes: 12,
      icon: Icons.approval_outlined,
      color: Color(0xFF7C3AED),
    ),
    ServiceItem(
      name: 'Registo Automóvel',
      description: 'Registo de propriedade e registo inicial de veículos',
      peopleInQueue: 4,
      etaMinutes: 15,
      icon: Icons.assignment_ind_outlined,
      color: Color(0xFF4338CA),
    ),
    ServiceItem(
      name: 'Registo Comercial',
      description: 'Constituição e registo de empresas, elaboração de contratos',
      peopleInQueue: 3,
      etaMinutes: 20,
      icon: Icons.business_center_outlined,
      color: Color(0xFFDC2626),
    ),
    ServiceItem(
      name: 'Registo Predial',
      description: 'Registo de imóveis e hipotecas',
      peopleInQueue: 3,
      etaMinutes: 18,
      icon: Icons.home_work_outlined,
      color: Color(0xFF1D3F91),
    ),
    ServiceItem(
      name: 'NIF — AGT',
      description: 'Emissão de NIF para pessoas singulares e coletivas',
      peopleInQueue: 8,
      etaMinutes: 14,
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFD97706),
    ),
    ServiceItem(
      name: 'INSS',
      description: 'Guias de contribuição, abono de família e subsídio de maternidade',
      peopleInQueue: 6,
      etaMinutes: 16,
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFF0891B2),
    ),
    ServiceItem(
      name: 'Ficheiro Central',
      description: 'Certificados de admissibilidade, denominação e antecedentes',
      peopleInQueue: 2,
      etaMinutes: 10,
      icon: Icons.folder_shared_outlined,
      color: Color(0xFF64748B),
    ),
    ServiceItem(
      name: 'Licenciamento Comercial (CAEC)',
      description: 'Licenciamento de atividades comerciais e apoio ao empreendedorismo',
      peopleInQueue: 2,
      etaMinutes: 12,
      icon: Icons.storefront_outlined,
      color: Color(0xFFEA580C),
    ),
    ServiceItem(
      name: 'Administração Distrital',
      description: 'Atestado de residência, multas e taxas',
      peopleInQueue: 5,
      etaMinutes: 15,
      icon: Icons.location_city_outlined,
      color: Color(0xFF9333EA),
    ),
  ];

  // Serviços do balcão piloto (institutionId/branchId reais — ver
  // `locations` abaixo) — mesmos nomes usados pelo seed da app da equipa
  // (fila-certa-staff/scripts/seed-prod.mjs), para os textos baterem certo
  // dos dois lados.
  static const pilotServices = <ServiceItem>[
    ServiceItem(
      name: 'Abertura de conta',
      description: 'Abertura de conta à ordem ou poupança',
      peopleInQueue: 3,
      etaMinutes: 15,
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF0F766E),
    ),
    ServiceItem(
      name: 'Cartão bancário',
      description: 'Pedidos, desbloqueios e informações de cartões',
      peopleInQueue: 2,
      etaMinutes: 10,
      icon: Icons.credit_card_outlined,
      color: Color(0xFF7C3AED),
    ),
    ServiceItem(
      name: 'Empréstimo',
      description: 'Informações e processos de crédito',
      peopleInQueue: 4,
      etaMinutes: 18,
      icon: Icons.description_outlined,
      color: Color(0xFFEA7C2F),
    ),
    ServiceItem(
      name: 'Reclamação',
      description: 'Registo e acompanhamento de reclamações',
      peopleInQueue: 1,
      etaMinutes: 8,
      icon: Icons.support_agent_outlined,
      color: Color(0xFFDC2626),
    ),
  ];

  static const locations = <QueueLocation>[
    // Localização piloto — ligada a dados reais no Firestore (ver
    // QueueLocation.institutionId/branchId). As restantes continuam
    // puramente mock: bancos reais sem backend por trás, propositadamente,
    // para não sugerir que têm dados ao vivo.
    QueueLocation(
      name: 'Banco Exemplo',
      subtitle: 'Agência Maianga — piloto ao vivo',
      address: 'Maianga, Luanda',
      distance: '—',
      distanceKm: 0,
      peopleInQueue: 0,
      etaMinutes: 0,
      load: QueueLoad.low,
      monogram: 'BEX',
      brandColor: Color(0xFF0F766E),
      phone: '+244923000199',
      services: pilotServices,
      institutionId: 'banco-exemplo',
      branchId: 'agencia-maianga',
      latitude: -8.8115,
      longitude: 13.2302,
    ),
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
      services: bankServices,
      latitude: -8.9167,
      longitude: 13.1833,
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
      services: bankServices,
      latitude: -8.9833,
      longitude: 13.1500,
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
      services: bankServices,
      latitude: -8.9036,
      longitude: 13.3708,
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
      services: bankServices,
      latitude: -8.9978,
      longitude: 13.2564,
    ),
    QueueLocation(
      name: 'SIAC — Serviço Integrado de Atendimento ao Cidadão',
      subtitle: 'Balcão Talatona',
      address: 'Talatona, Luanda',
      distance: '1,1 km',
      distanceKm: 1.1,
      peopleInQueue: 10,
      etaMinutes: 16,
      load: QueueLoad.medium,
      monogram: 'SIAC',
      brandColor: Color(0xFF2E7CB8),
      phone: '+244923000105',
      services: siacServices,
      latitude: -8.9180,
      longitude: 13.1810,
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
