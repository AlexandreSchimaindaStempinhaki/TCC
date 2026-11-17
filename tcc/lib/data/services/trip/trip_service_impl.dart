import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/trip_entity.dart';
import 'i_trip_service.dart';

class TripServiceImpl implements ITripService {
  final FirebaseFirestore _firestore;

  TripServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('trips');
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  static const List<int> _etaThresholds = [30, 20, 10, 5, 0];

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _formatDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _parseDateTime(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim()) ?? (fallback ?? DateTime.now());
    }
    return fallback ?? DateTime.now();
  }

  String _statusToString(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
        return 'scheduled';
      case TripStatus.boarding:
        return 'boarding';
      case TripStatus.inProgress:
        return 'in_progress';
      case TripStatus.completed:
        return 'completed';
      case TripStatus.cancelled:
        return 'cancelled';
    }
  }

  TripStatus _statusFromString(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'boarding':
        return TripStatus.boarding;
      case 'in_progress':
      case 'inprogress':
      case 'em_andamento':
        return TripStatus.inProgress;
      case 'completed':
      case 'concluida':
        return TripStatus.completed;
      case 'cancelled':
      case 'cancelada':
        return TripStatus.cancelled;
      default:
        return TripStatus.scheduled;
    }
  }

  String _directionToString(TripDirection direction) {
    return direction == TripDirection.returnTrip ? 'return' : 'outbound';
  }

  TripDirection _directionFromString(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'return' ||
        normalized == 'returntrip' ||
        normalized == 'volta') {
      return TripDirection.returnTrip;
    }
    return TripDirection.outbound;
  }

  Map<String, dynamic> _stopToMap(TripStopPoint stop) {
    return {
      'passengerId': stop.passengerId,
      'passengerName': stop.passengerName,
      'passengerPhotoUrl': stop.passengerPhotoUrl,
      'latitude': stop.latitude,
      'longitude': stop.longitude,
      'location': GeoPoint(stop.latitude, stop.longitude),
      'orderIndex': stop.orderIndex,
      'isPassengerReady': stop.isPassengerReady,
      'isCompleted': stop.isCompleted,
      'estimatedMinutesRemaining': stop.estimatedMinutesRemaining,
      'notifiedThresholds': stop.notifiedThresholds,
    };
  }

  TripStopPoint _stopFromMap(Map<String, dynamic> map) {
    double lat = 0.0;
    double lng = 0.0;

    if (map['latitude'] != null && map['longitude'] != null) {
      lat = double.tryParse(map['latitude'].toString()) ?? 0.0;
      lng = double.tryParse(map['longitude'].toString()) ?? 0.0;
    } else if (map['location'] is GeoPoint) {
      final gp = map['location'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    }

    final rawThresholds = map['notifiedThresholds'];
    final thresholds = rawThresholds is List
        ? rawThresholds
            .map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList()
        : <int>[];

    final rawReady = map['isPassengerReady'];
    final isReady = rawReady is bool
        ? rawReady
        : (rawReady?.toString().toLowerCase() == 'true');

    final rawCompleted = map['isCompleted'];
    final isCompleted = rawCompleted is bool
        ? rawCompleted
        : (rawCompleted?.toString().toLowerCase() == 'true');

    return TripStopPoint(
      passengerId: (map['passengerId'] ?? '').toString(),
      passengerName: (map['passengerName'] ?? 'Passageiro').toString(),
      passengerPhotoUrl: map['passengerPhotoUrl']?.toString(),
      latitude: lat,
      longitude: lng,
      orderIndex: int.tryParse((map['orderIndex'] ?? '0').toString()) ?? 0,
      isPassengerReady: isReady,
      isCompleted: isCompleted,
      estimatedMinutesRemaining: map['estimatedMinutesRemaining'] != null
          ? int.tryParse(map['estimatedMinutesRemaining'].toString())
          : null,
      notifiedThresholds: thresholds,
    );
  }

  Map<String, dynamic> _toMap(TripModel trip) {
    final normalizedDate = _normalizeDate(trip.date);
    final cleanCnpj = _cleanDigits(trip.companyCnpj);

    return {
      'id': trip.id,
      'routeId': trip.routeId.trim(),
      'companyCnpj': cleanCnpj,
      'vehicleId': trip.vehicleId.trim(),
      'driverId': trip.driverId.trim(),
      'date': Timestamp.fromDate(normalizedDate),
      'data': Timestamp.fromDate(normalizedDate),
      'dateKey': _formatDateKey(normalizedDate),
      'departureTime': Timestamp.fromDate(trip.departureTime),
      'horarioSaida': Timestamp.fromDate(trip.departureTime),
      'arrivalTime': trip.arrivalTime != null
          ? Timestamp.fromDate(trip.arrivalTime!)
          : null,
      'horarioChegada': trip.arrivalTime != null
          ? Timestamp.fromDate(trip.arrivalTime!)
          : null,
      'status': _statusToString(trip.status),
      'passengerCount': trip.passengerCount,
      'numeroPassageiros': trip.passengerCount,
      'direction': _directionToString(trip.direction),
      'sentido': _directionToString(trip.direction),
      'tripGroupIndex': trip.tripGroupIndex,
      'indiceGrupo': trip.tripGroupIndex,
      'vehicleCapacity': trip.vehicleCapacity,
      'assignedPassengerIds': trip.assignedPassengerIds,
      'driverLatitude': trip.driverLatitude,
      'driverLongitude': trip.driverLongitude,
      'driverCurrentLocation':
          (trip.driverLatitude != null && trip.driverLongitude != null)
              ? GeoPoint(trip.driverLatitude!, trip.driverLongitude!)
              : null,
      'isSharingLocation': trip.isSharingLocation,
      'stops': trip.stops.map(_stopToMap).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  TripModel? _fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) return null;
    final rawData = doc.data();
    if (rawData is! Map) return null;

    final map = Map<String, dynamic>.from(rawData);
    return _fromMap(map, doc.id);
  }

  TripModel _fromMap(Map<String, dynamic> map, String docId) {
    final parsedDate = _normalizeDate(
      _parseDateTime(map['date'] ?? map['data']),
    );

    double? driverLat = map['driverLatitude'] != null
        ? double.tryParse(map['driverLatitude'].toString())
        : null;
    double? driverLng = map['driverLongitude'] != null
        ? double.tryParse(map['driverLongitude'].toString())
        : null;

    if ((driverLat == null || driverLng == null) &&
        map['driverCurrentLocation'] is GeoPoint) {
      final gp = map['driverCurrentLocation'] as GeoPoint;
      driverLat = gp.latitude;
      driverLng = gp.longitude;
    }

    final rawStops = map['stops'];
    final parsedStops = <TripStopPoint>[];
    if (rawStops is List) {
      for (final item in rawStops) {
        if (item is Map) {
          parsedStops.add(_stopFromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    parsedStops.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final rawAssigned = map['assignedPassengerIds'];
    final assignedIds = rawAssigned is List
        ? rawAssigned.map((e) => e.toString()).toList()
        : <String>[];

    final rawSharing = map['isSharingLocation'];
    final isSharing = rawSharing is bool
        ? rawSharing
        : (rawSharing?.toString().toLowerCase() == 'true');

    return TripModel(
      id: (docId.trim().isNotEmpty ? docId : (map['id'] ?? '')).toString(),
      routeId: (map['routeId'] ?? '').toString(),
      companyCnpj: (map['companyCnpj'] ?? map['cnpjEmpresa'] ?? '').toString(),
      vehicleId: (map['vehicleId'] ?? '').toString(),
      driverId: (map['driverId'] ?? '').toString(),
      date: parsedDate,
      departureTime: _parseDateTime(
        map['departureTime'] ?? map['horarioSaida'],
        fallback: parsedDate,
      ),
      arrivalTime:
          (map['arrivalTime'] != null || map['horarioChegada'] != null)
              ? _parseDateTime(map['arrivalTime'] ?? map['horarioChegada'])
              : null,
      status: _statusFromString((map['status'] ?? 'scheduled').toString()),
      passengerCount: int.tryParse(
            (map['passengerCount'] ?? map['numeroPassageiros'] ?? '0')
                .toString(),
          ) ??
          0,
      direction: _directionFromString(
        (map['direction'] ?? map['sentido'] ?? 'outbound').toString(),
      ),
      tripGroupIndex: int.tryParse(
            (map['tripGroupIndex'] ?? map['indiceGrupo'] ?? '1').toString(),
          ) ??
          1,
      vehicleCapacity:
          int.tryParse((map['vehicleCapacity'] ?? '15').toString()) ?? 15,
      assignedPassengerIds: assignedIds,
      driverLatitude: driverLat,
      driverLongitude: driverLng,
      isSharingLocation: isSharing,
      stops: parsedStops,
    );
  }

  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  int? _resolveEtaThresholdToTrigger({
    required int currentEtaMinutes,
    required List<int> alreadyNotified,
  }) {
    if (currentEtaMinutes < 0) return null;
    for (final threshold in _etaThresholds) {
      if (currentEtaMinutes <= threshold &&
          currentEtaMinutes >= (threshold - 2) &&
          !alreadyNotified.contains(threshold)) {
        return threshold;
      }
    }
    return null;
  }

  Future<void> _dispatchPassengerNotification({
    required String passengerId,
    required String tripId,
    required String routeId,
    required String title,
    required String body,
    required String type,
    int? thresholdMinutes,
  }) async {
    try {
      final docId = thresholdMinutes != null
          ? '${tripId}_${passengerId}_eta_$thresholdMinutes'
          : '${tripId}_${passengerId}_$type';

      await _notificationsCollection.doc(docId).set({
        'id': docId,
        'userId': passengerId,
        'tripId': tripId,
        'routeId': routeId,
        'title': title,
        'body': body,
        'type': type,
        'thresholdMinutes': thresholdMinutes,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<List<TripModel>> fetchTripsByRoute({
    required String routeId,
    DateTime? date,
  }) async {
    final trimmedRoute = routeId.trim();
    if (trimmedRoute.isEmpty) return [];

    Query query = _collection.where('routeId', isEqualTo: trimmedRoute);
    if (date != null) {
      query = query.where('dateKey', isEqualTo: _formatDateKey(date));
    }

    final snapshot = await query.get();
    final trips = snapshot.docs.map(_fromDoc).whereType<TripModel>().toList();

    trips.sort((a, b) {
      final cmpDate = a.departureTime.compareTo(b.departureTime);
      if (cmpDate != 0) return cmpDate;
      return a.tripGroupIndex.compareTo(b.tripGroupIndex);
    });
    return trips;
  }

  @override
  Future<List<TripModel>> fetchTripsByDriver({
    required String driverId,
    DateTime? date,
  }) async {
    final trimmedDriver = driverId.trim();
    if (trimmedDriver.isEmpty) return [];

    Query query = _collection.where('driverId', isEqualTo: trimmedDriver);
    if (date != null) {
      query = query.where('dateKey', isEqualTo: _formatDateKey(date));
    }

    final snapshot = await query.get();
    final trips = snapshot.docs.map(_fromDoc).whereType<TripModel>().toList();

    trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return trips;
  }

  @override
  Future<List<TripModel>> fetchTripsByCompany({
    required String companyCnpj,
    DateTime? date,
  }) async {
    final cleanCnpj = _cleanDigits(companyCnpj);
    if (cleanCnpj.isEmpty) return [];

    Query query = _collection.where('companyCnpj', isEqualTo: cleanCnpj);
    if (date != null) {
      query = query.where('dateKey', isEqualTo: _formatDateKey(date));
    }

    final snapshot = await query.get();
    final trips = snapshot.docs.map(_fromDoc).whereType<TripModel>().toList();

    trips.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return trips;
  }

  @override
  Future<TripModel?> getTripById(String tripId) async {
    final trimmed = tripId.trim();
    if (trimmed.isEmpty) return null;

    final doc = await _collection.doc(trimmed).get();
    return _fromDoc(doc);
  }

  @override
  Stream<TripModel?> watchTripById(String tripId) {
    final trimmed = tripId.trim();
    if (trimmed.isEmpty) return Stream.value(null);

    return _collection.doc(trimmed).snapshots().map(_fromDoc);
  }

  @override
  Stream<List<TripModel>> watchActiveTripsByRoute(String routeId) {
    final trimmed = routeId.trim();
    if (trimmed.isEmpty) return Stream.value(const []);

    return _collection
        .where('routeId', isEqualTo: trimmed)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(_fromDoc)
          .whereType<TripModel>()
          .where(
            (t) =>
                t.status == TripStatus.inProgress ||
                t.status == TripStatus.boarding,
          )
          .toList();
      list.sort((a, b) => a.tripGroupIndex.compareTo(b.tripGroupIndex));
      return list;
    });
  }

  @override
  Future<TripModel> createTrip(TripModel trip) async {
    final dateKey = _formatDateKey(trip.date);
    final dirStr = _directionToString(trip.direction);
    final docId = trip.id.trim().isNotEmpty
        ? trip.id.trim()
        : '${trip.routeId}_${dateKey}_${dirStr}_v${trip.tripGroupIndex}';

    final tripToSave = trip.copyWith(
      id: docId,
      companyCnpj: _cleanDigits(trip.companyCnpj),
      date: _normalizeDate(trip.date),
      passengerCount: trip.assignedPassengerIds.isNotEmpty
          ? trip.assignedPassengerIds.length
          : trip.stops.length,
    );

    final data = _toMap(tripToSave);
    data['createdAt'] = FieldValue.serverTimestamp();

    await _collection.doc(docId).set(data, SetOptions(merge: true));
    return tripToSave;
  }

  @override
  Future<List<TripModel>> generateScaledTrips({
    required TripModel baseTrip,
    required List<TripStopPoint> confirmedStops,
  }) async {
    final capacity = baseTrip.vehicleCapacity > 0
        ? baseTrip.vehicleCapacity
        : 15;

    if (confirmedStops.isEmpty) {
      final single = await createTrip(
        baseTrip.copyWith(
          tripGroupIndex: 1,
          passengerCount: 0,
          assignedPassengerIds: const [],
          stops: const [],
        ),
      );
      return [single];
    }

    final totalGroups = (confirmedStops.length / capacity).ceil();
    final createdTrips = <TripModel>[];

    for (int groupIdx = 0; groupIdx < totalGroups; groupIdx++) {
      final start = groupIdx * capacity;
      final end = math.min(start + capacity, confirmedStops.length);
      final slice = confirmedStops.sublist(start, end);

      final reindexedStops = List<TripStopPoint>.generate(slice.length, (i) {
        return slice[i].copyWith(orderIndex: i + 1);
      });

      final passengerIds = reindexedStops.map((s) => s.passengerId).toList();
      final groupNumber = groupIdx + 1;

      final dateKey = _formatDateKey(baseTrip.date);
      final dirStr = _directionToString(baseTrip.direction);
      final tripId = '${baseTrip.routeId}_${dateKey}_${dirStr}_v$groupNumber';

      final scaledTrip = await createTrip(
        baseTrip.copyWith(
          id: tripId,
          tripGroupIndex: groupNumber,
          passengerCount: passengerIds.length,
          assignedPassengerIds: passengerIds,
          stops: reindexedStops,
        ),
      );

      createdTrips.add(scaledTrip);
    }

    return createdTrips;
  }

  @override
  Future<TripModel> updateTrip(TripModel trip) async {
    final docId = trip.id.trim();
    if (docId.isEmpty) {
      throw Exception('ID da viagem inválido para atualização.');
    }

    await _collection.doc(docId).set(_toMap(trip), SetOptions(merge: true));
    return trip;
  }

  @override
  Future<TripModel> startTrip({
    required String tripId,
    double? initialLatitude,
    double? initialLongitude,
  }) async {
    final existing = await getTripById(tripId);
    if (existing == null) {
      throw Exception('Viagem não encontrada.');
    }

    final updated = existing.copyWith(
      status: TripStatus.inProgress,
      isSharingLocation: true,
      driverLatitude: initialLatitude ?? existing.driverLatitude,
      driverLongitude: initialLongitude ?? existing.driverLongitude,
    );

    await updateTrip(updated);

    // Notifica todos os passageiros confirmados de que a viagem iniciou
    for (final stop in updated.stops) {
      await _dispatchPassengerNotification(
        passengerId: stop.passengerId,
        tripId: updated.id,
        routeId: updated.routeId,
        title: 'Viagem Iniciada!',
        body:
            'O motorista iniciou a viagem (Van ${updated.tripGroupIndex}). Acompanhe o trajeto em tempo real.',
        type: 'trip_started',
      );
    }

    if (initialLatitude != null && initialLongitude != null) {
      return updateDriverLocationAndCalculateEta(
        tripId: updated.id,
        latitude: initialLatitude,
        longitude: initialLongitude,
        isSharingLocation: true,
      );
    }

    return updated;
  }

  @override
  Future<TripModel> finishTrip(String tripId) async {
    final existing = await getTripById(tripId);
    if (existing == null) {
      throw Exception('Viagem não encontrada.');
    }

    final completedStops = existing.stops
        .map((s) => s.copyWith(isCompleted: true, estimatedMinutesRemaining: 0))
        .toList();

    final updated = existing.copyWith(
      status: TripStatus.completed,
      arrivalTime: DateTime.now(),
      isSharingLocation: false,
      stops: completedStops,
    );

    await updateTrip(updated);
    return updated;
  }

  @override
  Future<TripModel> cancelTrip(String tripId) async {
    final existing = await getTripById(tripId);
    if (existing == null) {
      throw Exception('Viagem não encontrada.');
    }

    final updated = existing.copyWith(
      status: TripStatus.cancelled,
      isSharingLocation: false,
    );

    await updateTrip(updated);
    return updated;
  }

  @override
  Future<TripModel> updateDriverLocationAndCalculateEta({
    required String tripId,
    required double latitude,
    required double longitude,
    required bool isSharingLocation,
    double averageSpeedKmh = 35.0,
  }) async {
    final existing = await getTripById(tripId);
    if (existing == null) {
      throw Exception('Viagem não encontrada para atualizar localização.');
    }

    final speedMetersPerMin =
        ((averageSpeedKmh > 5 ? averageSpeedKmh : 35.0) * 1000.0) / 60.0;

    double currentLegLat = latitude;
    double currentLegLng = longitude;
    double cumulativeMeters = 0.0;

    final updatedStops = <TripStopPoint>[];

    for (final stop in existing.stops) {
      if (stop.isCompleted) {
        updatedStops.add(stop.copyWith(estimatedMinutesRemaining: 0));
        continue;
      }

      final legDistance = _calculateDistanceMeters(
        currentLegLat,
        currentLegLng,
        stop.locationLatitudeOrZero,
        stop.locationLongitudeOrZero,
      );

      // Fator de tortuosidade urbana (1.3x a distância em linha reta)
      cumulativeMeters += (legDistance * 1.3);
      currentLegLat = stop.latitude;
      currentLegLng = stop.longitude;

      final etaMinutes = (cumulativeMeters / speedMetersPerMin).round();
      final thresholdToTrigger = _resolveEtaThresholdToTrigger(
        currentEtaMinutes: etaMinutes,
        alreadyNotified: stop.notifiedThresholds,
      );

      final updatedThresholds = List<int>.from(stop.notifiedThresholds);

      if (thresholdToTrigger != null) {
        updatedThresholds.add(thresholdToTrigger);
        final msgBody = thresholdToTrigger == 0
            ? 'O motorista chegou ao seu ponto de embarque!'
            : 'O motorista está a aproximadamente $thresholdToTrigger minutos do seu ponto.';

        await _dispatchPassengerNotification(
          passengerId: stop.passengerId,
          tripId: existing.id,
          routeId: existing.routeId,
          title: thresholdToTrigger == 0
              ? 'Sua van chegou!'
              : 'Motorista a $thresholdToTrigger min',
          body: msgBody,
          type: 'eta_alert',
          thresholdMinutes: thresholdToTrigger,
        );
      }

      updatedStops.add(
        stop.copyWith(
          estimatedMinutesRemaining: etaMinutes,
          notifiedThresholds: updatedThresholds,
        ),
      );
    }

    final updatedTrip = existing.copyWith(
      driverLatitude: latitude,
      driverLongitude: longitude,
      isSharingLocation: isSharingLocation,
      stops: updatedStops,
    );

    await updateTrip(updatedTrip);
    return updatedTrip;
  }

  @override
  Future<TripModel> markStopCompleted({
    required String tripId,
    required String passengerId,
    required bool isCompleted,
  }) async {
    final existing = await getTripById(tripId);
    if (existing == null) {
      throw Exception('Viagem não encontrada.');
    }

    final updatedStops = existing.stops.map((stop) {
      if (stop.passengerId == passengerId) {
        return stop.copyWith(
          isCompleted: isCompleted,
          estimatedMinutesRemaining:
              isCompleted ? 0 : stop.estimatedMinutesRemaining,
        );
      }
      return stop;
    }).toList();

    final updatedTrip = existing.copyWith(stops: updatedStops);
    await updateTrip(updatedTrip);
    return updatedTrip;
  }

  @override
  Future<TripModel> setPassengerReadyAtStop({
    required String tripId,
    required String passengerId,
    required bool isReady,
  }) async {
    final existing = await getTripById(tripId);
    if (existing == null) {
      throw Exception('Viagem não encontrada.');
    }

    final updatedStops = existing.stops.map((stop) {
      if (stop.passengerId == passengerId) {
        return stop.copyWith(isPassengerReady: isReady);
      }
      return stop;
    }).toList();

    final updatedTrip = existing.copyWith(stops: updatedStops);
    await updateTrip(updatedTrip);
    return updatedTrip;
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    final trimmed = tripId.trim();
    if (trimmed.isEmpty) return;
    await _collection.doc(trimmed).delete();
  }
}

extension _StopCoordsFallback on TripStopPoint {
  double get locationLatitudeOrZero => latitude;
  double get locationLongitudeOrZero => longitude;
}