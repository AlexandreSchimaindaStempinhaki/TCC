import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_entity.dart';

class RouteModel {
  final int id;
  final String companyCnpj;
  final GeoPoint origin;
  final GeoPoint destination;
  final String? originName;
  final String? destinationName;
  final List<DateTime> schedules;
  final List<int> operatingDays;
  final String? imageUrl;
  final String? driverId;
  final bool isTripActive;
  final DateTime? tripStartedAt;
  final List<String> passengerIds;
  final List<String> pendingPassengerIds;
  final List<String> confirmedPassengerIds;
  final CompanyModel? company;

  const RouteModel({
    required this.id,
    required this.companyCnpj,
    required this.origin,
    required this.destination,
    this.originName,
    this.destinationName,
    required this.schedules,
    this.operatingDays = const [1, 2, 3, 4, 5],
    this.imageUrl,
    this.driverId,
    this.isTripActive = false,
    this.tripStartedAt,
    this.passengerIds = const [],
    this.pendingPassengerIds = const [],
    this.confirmedPassengerIds = const [],
    this.company,
  });

  RouteModel copyWith({
    int? id,
    String? companyCnpj,
    GeoPoint? origin,
    GeoPoint? destination,
    String? originName,
    String? destinationName,
    List<DateTime>? schedules,
    List<int>? operatingDays,
    String? imageUrl,
    String? driverId,
    bool? isTripActive,
    DateTime? tripStartedAt,
    List<String>? passengerIds,
    List<String>? pendingPassengerIds,
    List<String>? confirmedPassengerIds,
    CompanyModel? company,
  }) {
    return RouteModel(
      id: id ?? this.id,
      companyCnpj: companyCnpj ?? this.companyCnpj,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      originName: originName ?? this.originName,
      destinationName: destinationName ?? this.destinationName,
      schedules: schedules ?? this.schedules,
      operatingDays: operatingDays ?? this.operatingDays,
      imageUrl: imageUrl ?? this.imageUrl,
      driverId: driverId ?? this.driverId,
      isTripActive: isTripActive ?? this.isTripActive,
      tripStartedAt: tripStartedAt ?? this.tripStartedAt,
      passengerIds: passengerIds ?? this.passengerIds,
      pendingPassengerIds: pendingPassengerIds ?? this.pendingPassengerIds,
      confirmedPassengerIds:
          confirmedPassengerIds ?? this.confirmedPassengerIds,
      company: company ?? this.company,
    );
  }

  factory RouteModel.fromMap(
    Map<String, dynamic> map, {
    CompanyModel? company,
  }) {
    final rawSchedules =
        (map['schedules'] ?? map['horarios']) as List<dynamic>? ?? [];
    final parsedSchedules = rawSchedules.map((item) {
      if (item is Timestamp) return item.toDate();
      if (item is DateTime) return item;
      if (item is String) return DateTime.tryParse(item) ?? DateTime.now();
      return DateTime.now();
    }).toList();

    final rawOperatingDays =
        (map['operatingDays'] ?? map['diasOperacao'] ?? map['operating_days'])
            as List<dynamic>?;
    final parsedOperatingDays = rawOperatingDays != null &&
            rawOperatingDays.isNotEmpty
        ? (rawOperatingDays
            .map((e) => (e as num?)?.toInt() ?? 0)
            .where((day) => day >= 1 && day <= 7)
            .toSet()
            .toList()
          ..sort())
        : <int>[1, 2, 3, 4, 5];

    final rawOrigin = map['origin'] ?? map['pontoPartida'];
    final rawDestination = map['destination'] ?? map['destino'];

    final rawPassengers =
        (map['passengerIds'] ?? map['listaIdPassageiros']) as List<dynamic>? ??
            [];
    final rawPending =
        (map['pendingPassengerIds'] ?? map['listaIdSolicitacoes'])
                as List<dynamic>? ??
            [];
    final rawConfirmed =
        (map['confirmedPassengerIds'] ?? map['listaIdConfirmados'])
                as List<dynamic>? ??
            [];

    DateTime? parsedTripStart;
    final rawStart = map['tripStartedAt'];
    if (rawStart is Timestamp) parsedTripStart = rawStart.toDate();
    if (rawStart is DateTime) parsedTripStart = rawStart;
    if (rawStart is String) parsedTripStart = DateTime.tryParse(rawStart);

    return RouteModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      companyCnpj: (map['companyCnpj'] ?? map['cnpj_empresa'] ?? '') as String,
      origin: rawOrigin is GeoPoint
          ? rawOrigin
          : const GeoPoint(-25.5204, -48.5095),
      destination: rawDestination is GeoPoint
          ? rawDestination
          : const GeoPoint(-25.5855, -48.5630),
      originName:
          (map['originName'] ?? map['origin_name'] ?? map['nomeOrigem'])
              as String?,
      destinationName: (map['destinationName'] ??
          map['destination_name'] ??
          map['nomeDestino']) as String?,
      schedules:
          parsedSchedules.isNotEmpty ? parsedSchedules : [DateTime.now()],
      operatingDays: parsedOperatingDays,
      imageUrl:
          (map['imageUrl'] ?? map['fotoRota'] ?? map['image']) as String?,
      driverId: (map['driverId'] ?? map['cpfMotorista']) as String?,
      isTripActive: (map['isTripActive'] as bool?) ?? false,
      tripStartedAt: parsedTripStart,
      passengerIds: rawPassengers.map((e) => e.toString()).toList(),
      pendingPassengerIds: rawPending.map((e) => e.toString()).toList(),
      confirmedPassengerIds: rawConfirmed.map((e) => e.toString()).toList(),
      company: company,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyCnpj': companyCnpj,
      'origin': origin,
      'destination': destination,
      'originName': originName,
      'destinationName': destinationName,
      'schedules': schedules.map((dt) => Timestamp.fromDate(dt)).toList(),
      'operatingDays': operatingDays,
      'imageUrl': imageUrl,
      'driverId': driverId,
      'isTripActive': isTripActive,
      'tripStartedAt':
          tripStartedAt != null ? Timestamp.fromDate(tripStartedAt!) : null,
      'passengerIds': passengerIds,
      'pendingPassengerIds': pendingPassengerIds,
      'confirmedPassengerIds': confirmedPassengerIds,
    };
  }

  bool isUserPassenger(String userId) => passengerIds.contains(userId);
  bool isUserPending(String userId) => pendingPassengerIds.contains(userId);
  bool isUserConfirmed(String userId) => confirmedPassengerIds.contains(userId);
  bool isUserDriver(String userId) =>
      driverId != null && driverId!.trim().isNotEmpty && driverId == userId;

  bool operatesOnDay(int weekday) => operatingDays.contains(weekday);

  bool get operatesToday => operatingDays.contains(DateTime.now().weekday);

  bool get isMondayToFriday {
    final sorted = [...operatingDays]..sort();
    return sorted.length == 5 &&
        sorted[0] == 1 &&
        sorted[1] == 2 &&
        sorted[2] == 3 &&
        sorted[3] == 4 &&
        sorted[4] == 5;
  }

  String get operatingDaysLabel {
    final sorted = operatingDays.toSet().toList()..sort();
    if (sorted.isEmpty) return 'Sem dias definidos';
    if (sorted.length == 7) return 'Todos os dias';
    if (isMondayToFriday) return 'Segunda a Sexta';
    if (sorted.length == 6 && !sorted.contains(7)) return 'Segunda a Sábado';
    if (sorted.length == 2 && sorted.contains(6) && sorted.contains(7)) {
      return 'Fins de semana';
    }

    const dayNames = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };

    return sorted
        .map((d) => dayNames[d] ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');
  }
}