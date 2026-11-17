enum TripStatus {
  scheduled,
  boarding,
  inProgress,
  completed,
  cancelled,
}

enum TripDirection {
  outbound, // Ida
  returnTrip, // Volta
}

class TripStopPoint {
  final String passengerId;
  final String passengerName;
  final String? passengerPhotoUrl;
  final double latitude;
  final double longitude;
  final int orderIndex;
  final bool isPassengerReady;
  final bool isCompleted;
  final int? estimatedMinutesRemaining;
  final List<int> notifiedThresholds;

  const TripStopPoint({
    required this.passengerId,
    required this.passengerName,
    this.passengerPhotoUrl,
    required this.latitude,
    required this.longitude,
    required this.orderIndex,
    this.isPassengerReady = false,
    this.isCompleted = false,
    this.estimatedMinutesRemaining,
    this.notifiedThresholds = const [],
  });

  TripStopPoint copyWith({
    String? passengerId,
    String? passengerName,
    String? passengerPhotoUrl,
    double? latitude,
    double? longitude,
    int? orderIndex,
    bool? isPassengerReady,
    bool? isCompleted,
    int? estimatedMinutesRemaining,
    List<int>? notifiedThresholds,
  }) {
    return TripStopPoint(
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhotoUrl: passengerPhotoUrl ?? this.passengerPhotoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      orderIndex: orderIndex ?? this.orderIndex,
      isPassengerReady: isPassengerReady ?? this.isPassengerReady,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedMinutesRemaining:
          estimatedMinutesRemaining ?? this.estimatedMinutesRemaining,
      notifiedThresholds: notifiedThresholds ?? this.notifiedThresholds,
    );
  }
}

class TripModel {
  final String id;
  final String routeId;
  final String companyCnpj;
  final String vehicleId;
  final String driverId;

  // Atributos do Diagrama de Classes
  final DateTime date; // data
  final DateTime departureTime; // horarioSaida
  final DateTime? arrivalTime; // horarioChegada
  final TripStatus status; // status
  final int passengerCount; // numeroPassageiros

  // Controle de Turno, Lotação (Van 1 / Van 2) e Localização em Tempo Real
  final TripDirection direction;
  final int tripGroupIndex;
  final int vehicleCapacity;
  final List<String> assignedPassengerIds;
  final double? driverLatitude;
  final double? driverLongitude;
  final bool isSharingLocation;
  final List<TripStopPoint> stops;

  const TripModel({
    required this.id,
    required this.routeId,
    required this.companyCnpj,
    required this.vehicleId,
    required this.driverId,
    required this.date,
    required this.departureTime,
    this.arrivalTime,
    this.status = TripStatus.scheduled,
    this.passengerCount = 0,
    this.direction = TripDirection.outbound,
    this.tripGroupIndex = 1,
    this.vehicleCapacity = 15,
    this.assignedPassengerIds = const [],
    this.driverLatitude,
    this.driverLongitude,
    this.isSharingLocation = false,
    this.stops = const [],
  });

  bool get isFull => passengerCount >= vehicleCapacity;
  bool get isInProgress => status == TripStatus.inProgress;
  bool get isCompleted => status == TripStatus.completed;

  TripModel copyWith({
    String? id,
    String? routeId,
    String? companyCnpj,
    String? vehicleId,
    String? driverId,
    DateTime? date,
    DateTime? departureTime,
    DateTime? arrivalTime,
    TripStatus? status,
    int? passengerCount,
    TripDirection? direction,
    int? tripGroupIndex,
    int? vehicleCapacity,
    List<String>? assignedPassengerIds,
    double? driverLatitude,
    double? driverLongitude,
    bool? isSharingLocation,
    List<TripStopPoint>? stops,
  }) {
    return TripModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      companyCnpj: companyCnpj ?? this.companyCnpj,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      date: date ?? this.date,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      status: status ?? this.status,
      passengerCount: passengerCount ?? this.passengerCount,
      direction: direction ?? this.direction,
      tripGroupIndex: tripGroupIndex ?? this.tripGroupIndex,
      vehicleCapacity: vehicleCapacity ?? this.vehicleCapacity,
      assignedPassengerIds: assignedPassengerIds ?? this.assignedPassengerIds,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      isSharingLocation: isSharingLocation ?? this.isSharingLocation,
      stops: stops ?? this.stops,
    );
  }
}