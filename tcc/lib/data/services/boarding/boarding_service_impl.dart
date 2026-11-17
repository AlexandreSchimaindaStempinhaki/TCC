import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/boarding_entity.dart';
import 'i_boarding_service.dart';

class BoardingServiceImpl implements IBoardingService {
  final FirebaseFirestore _firestore;

  BoardingServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('boardings');

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String _formatDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _buildDocId({
    required String routeId,
    required String userId,
    required DateTime date,
  }) {
    final cleanUser = userId.trim();
    final dateKey = _formatDateKey(date);
    return '${routeId.trim()}_${cleanUser}_$dateKey';
  }

  DateTime _parseDateTime(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim()) ?? (fallback ?? DateTime.now());
    }
    return fallback ?? DateTime.now();
  }

  String _statusToString(BoardingAttendanceStatus status) {
    switch (status) {
      case BoardingAttendanceStatus.confirmed:
        return 'confirmed';
      case BoardingAttendanceStatus.declined:
        return 'declined';
      case BoardingAttendanceStatus.readyAtStop:
        return 'ready_at_stop';
      case BoardingAttendanceStatus.boarded:
        return 'boarded';
      case BoardingAttendanceStatus.missed:
        return 'missed';
    }
  }

  BoardingAttendanceStatus _statusFromString(String raw, {bool present = true}) {
    switch (raw.trim().toLowerCase()) {
      case 'declined':
      case 'recusado':
      case 'ausente_avisado':
        return BoardingAttendanceStatus.declined;
      case 'ready_at_stop':
      case 'readyatstop':
      case 'pronto':
        return BoardingAttendanceStatus.readyAtStop;
      case 'boarded':
      case 'embarcado':
        return BoardingAttendanceStatus.boarded;
      case 'missed':
      case 'faltou':
        return BoardingAttendanceStatus.missed;
      case 'confirmed':
      case 'confirmado':
        return BoardingAttendanceStatus.confirmed;
      default:
        return present
            ? BoardingAttendanceStatus.confirmed
            : BoardingAttendanceStatus.declined;
    }
  }

  Map<String, dynamic> _toMap(BoardingModel boarding) {
    final normalizedDate = _normalizeDate(boarding.date);
    final dateKey = _formatDateKey(normalizedDate);

    return {
      'id': boarding.id,
      'routeId': boarding.routeId.trim(),
      'tripId': boarding.tripId?.trim(),
      'userId': boarding.userId.trim(),
      'cpfPessoa': boarding.userId.trim(),
      'date': Timestamp.fromDate(normalizedDate),
      'data': Timestamp.fromDate(normalizedDate),
      'dateKey': dateKey,
      'timestamp': Timestamp.fromDate(boarding.timestamp),
      'horario': Timestamp.fromDate(boarding.timestamp),
      'present': boarding.present,
      'presente': boarding.present,
      'willGoOutbound': boarding.willGoOutbound,
      'vaiIda': boarding.willGoOutbound,
      'willGoReturn': boarding.willGoReturn,
      'vaiVolta': boarding.willGoReturn,
      'selectedDepartureTime': boarding.selectedDepartureTime,
      'selectedReturnTime': boarding.selectedReturnTime,
      'isReadyForBoarding': boarding.isReadyForBoarding,
      'prontoParaEmbarque': boarding.isReadyForBoarding,
      'attendanceStatus': _statusToString(boarding.attendanceStatus),
      'statusPresenca': _statusToString(boarding.attendanceStatus),
      'isDefaultDaily': boarding.isDefaultDaily,
      'wasTripStartNotified': boarding.wasTripStartNotified,
      'notifiedEtaThresholds': boarding.notifiedEtaThresholds,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BoardingModel? _fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) return null;
    final rawData = doc.data();
    if (rawData is! Map) return null;

    final map = Map<String, dynamic>.from(rawData);
    return _fromMap(map, doc.id);
  }

  BoardingModel _fromMap(Map<String, dynamic> map, String docId) {
    final parsedDate = _normalizeDate(
      _parseDateTime(map['date'] ?? map['data']),
    );

    final rawPresent = map['present'] ?? map['presente'];
    final bool isPresent = rawPresent is bool
        ? rawPresent
        : (rawPresent?.toString().toLowerCase() != 'false');

    final rawOutbound = map['willGoOutbound'] ?? map['vaiIda'];
    final bool willGoOutbound = rawOutbound is bool
        ? rawOutbound
        : (rawOutbound != null
              ? rawOutbound.toString().toLowerCase() != 'false'
              : isPresent);

    final rawReturn = map['willGoReturn'] ?? map['vaiVolta'];
    final bool willGoReturn = rawReturn is bool
        ? rawReturn
        : (rawReturn != null
              ? rawReturn.toString().toLowerCase() != 'false'
              : isPresent);

    final rawReady = map['isReadyForBoarding'] ?? map['prontoParaEmbarque'];
    final bool isReady = rawReady is bool
        ? rawReady
        : (rawReady?.toString().toLowerCase() == 'true');

    final rawDefault = map['isDefaultDaily'];
    final bool isDefaultDaily = rawDefault is bool
        ? rawDefault
        : (rawDefault?.toString().toLowerCase() == 'true');

    final rawStartNotified = map['wasTripStartNotified'];
    final bool wasTripStartNotified = rawStartNotified is bool
        ? rawStartNotified
        : (rawStartNotified?.toString().toLowerCase() == 'true');

    final rawThresholds = map['notifiedEtaThresholds'];
    final thresholds = rawThresholds is List
        ? rawThresholds
            .map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList()
        : <int>[];

    final statusRaw =
        (map['attendanceStatus'] ?? map['statusPresenca'] ?? '').toString();

    return BoardingModel(
      id: (docId.trim().isNotEmpty ? docId : (map['id'] ?? '')).toString(),
      routeId: (map['routeId'] ?? '').toString(),
      tripId: map['tripId']?.toString(),
      userId: (map['userId'] ?? map['cpfPessoa'] ?? '').toString(),
      date: parsedDate,
      timestamp: _parseDateTime(
        map['timestamp'] ?? map['horario'],
        fallback: parsedDate,
      ),
      present: isPresent && (willGoOutbound || willGoReturn),
      willGoOutbound: willGoOutbound,
      willGoReturn: willGoReturn,
      selectedDepartureTime: map['selectedDepartureTime']?.toString(),
      selectedReturnTime: map['selectedReturnTime']?.toString(),
      isReadyForBoarding: isReady,
      attendanceStatus: _statusFromString(statusRaw, present: isPresent),
      isDefaultDaily: isDefaultDaily,
      wasTripStartNotified: wasTripStartNotified,
      notifiedEtaThresholds: thresholds,
    );
  }

  BoardingModel _createDefaultModel({
    required String routeId,
    required String userId,
    required DateTime date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  }) {
    final normalizedDate = _normalizeDate(date);
    final docId = _buildDocId(
      routeId: routeId,
      userId: userId,
      date: normalizedDate,
    );

    return BoardingModel(
      id: docId,
      routeId: routeId.trim(),
      tripId: tripId,
      userId: userId.trim(),
      date: normalizedDate,
      timestamp: DateTime.now(),
      present: true,
      willGoOutbound: true,
      willGoReturn: true,
      selectedDepartureTime: defaultDepartureTime,
      selectedReturnTime: defaultReturnTime,
      isReadyForBoarding: false,
      attendanceStatus: BoardingAttendanceStatus.confirmed,
      isDefaultDaily: true,
    );
  }

  @override
  Future<BoardingModel> getOrCreateDailyBoarding({
    required String routeId,
    required String userId,
    required DateTime date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  }) async {
    final normalizedDate = _normalizeDate(date);
    final docId = _buildDocId(
      routeId: routeId,
      userId: userId,
      date: normalizedDate,
    );

    final doc = await _collection.doc(docId).get();
    final existing = _fromDoc(doc);
    if (existing != null) return existing;

    final defaultModel = _createDefaultModel(
      routeId: routeId,
      userId: userId,
      date: normalizedDate,
      tripId: tripId,
      defaultDepartureTime: defaultDepartureTime,
      defaultReturnTime: defaultReturnTime,
    );

    await _collection.doc(docId).set(
      _toMap(defaultModel),
      SetOptions(merge: true),
    );
    return defaultModel;
  }

  @override
  Future<List<BoardingModel>> fetchBoardingsByRouteAndDate({
    required String routeId,
    required DateTime date,
  }) async {
    final trimmedRoute = routeId.trim();
    if (trimmedRoute.isEmpty) return [];

    final dateKey = _formatDateKey(date);
    final snapshot = await _collection
        .where('routeId', isEqualTo: trimmedRoute)
        .where('dateKey', isEqualTo: dateKey)
        .get();

    return snapshot.docs.map(_fromDoc).whereType<BoardingModel>().toList();
  }

  @override
  Future<List<BoardingModel>> fetchBoardingsByTrip(String tripId) async {
    final trimmedTrip = tripId.trim();
    if (trimmedTrip.isEmpty) return [];

    final snapshot = await _collection
        .where('tripId', isEqualTo: trimmedTrip)
        .get();

    return snapshot.docs.map(_fromDoc).whereType<BoardingModel>().toList();
  }

  @override
  Future<List<BoardingModel>> fetchUserBoardingHistory({
    required String routeId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final trimmedRoute = routeId.trim();
    final trimmedUser = userId.trim();
    if (trimmedRoute.isEmpty || trimmedUser.isEmpty) return [];

    final snapshot = await _collection
        .where('routeId', isEqualTo: trimmedRoute)
        .where('userId', isEqualTo: trimmedUser)
        .get();

    var list = snapshot.docs.map(_fromDoc).whereType<BoardingModel>().toList();

    if (startDate != null) {
      final minDate = _normalizeDate(startDate);
      list = list.where((b) => !b.date.isBefore(minDate)).toList();
    }
    if (endDate != null) {
      final maxDate = _normalizeDate(endDate);
      list = list.where((b) => !b.date.isAfter(maxDate)).toList();
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Stream<BoardingModel?> watchPassengerBoarding({
    required String routeId,
    required String userId,
    required DateTime date,
  }) {
    final docId = _buildDocId(
      routeId: routeId,
      userId: userId,
      date: date,
    );

    return _collection.doc(docId).snapshots().map((doc) {
      final parsed = _fromDoc(doc);
      if (parsed != null) return parsed;
      return _createDefaultModel(
        routeId: routeId,
        userId: userId,
        date: date,
      );
    });
  }

  @override
  Stream<List<BoardingModel>> watchRouteBoardingsByDate({
    required String routeId,
    required DateTime date,
  }) {
    final trimmedRoute = routeId.trim();
    final dateKey = _formatDateKey(date);

    return _collection
        .where('routeId', isEqualTo: trimmedRoute)
        .where('dateKey', isEqualTo: dateKey)
        .snapshots()
        .map(
          (snap) => snap.docs.map(_fromDoc).whereType<BoardingModel>().toList(),
        );
  }

  @override
  Future<BoardingModel> saveBoarding(BoardingModel boarding) async {
    final normalizedDate = _normalizeDate(boarding.date);
    final docId = boarding.id.trim().isNotEmpty
        ? boarding.id.trim()
        : _buildDocId(
            routeId: boarding.routeId,
            userId: boarding.userId,
            date: normalizedDate,
          );

    final toSave = boarding.copyWith(
      id: docId,
      date: normalizedDate,
    );

    await _collection.doc(docId).set(_toMap(toSave), SetOptions(merge: true));
    return toSave;
  }

  @override
  Future<BoardingModel> updateAttendance({
    required String routeId,
    required String userId,
    required DateTime date,
    required bool willGoOutbound,
    required bool willGoReturn,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    String? tripId,
  }) async {
    final current = await getOrCreateDailyBoarding(
      routeId: routeId,
      userId: userId,
      date: date,
      tripId: tripId,
      defaultDepartureTime: selectedDepartureTime,
      defaultReturnTime: selectedReturnTime,
    );

    final isGoing = willGoOutbound || willGoReturn;
    final newStatus = isGoing
        ? (current.isReadyForBoarding
              ? BoardingAttendanceStatus.readyAtStop
              : BoardingAttendanceStatus.confirmed)
        : BoardingAttendanceStatus.declined;

    final updated = current.copyWith(
      tripId: tripId ?? current.tripId,
      timestamp: DateTime.now(),
      present: isGoing,
      willGoOutbound: willGoOutbound,
      willGoReturn: willGoReturn,
      selectedDepartureTime:
          selectedDepartureTime ?? current.selectedDepartureTime,
      selectedReturnTime: selectedReturnTime ?? current.selectedReturnTime,
      isReadyForBoarding: isGoing ? current.isReadyForBoarding : false,
      attendanceStatus: newStatus,
      isDefaultDaily: false,
    );

    return saveBoarding(updated);
  }

  @override
  Future<BoardingModel> setReadyForBoarding({
    required String boardingId,
    required bool isReady,
  }) async {
    final doc = await _collection.doc(boardingId.trim()).get();
    final existing = _fromDoc(doc);
    if (existing == null) {
      throw Exception('Registro de embarque não encontrado.');
    }

    final updated = existing.copyWith(
      timestamp: DateTime.now(),
      present: isReady ? true : existing.present,
      isReadyForBoarding: isReady,
      attendanceStatus: isReady
          ? BoardingAttendanceStatus.readyAtStop
          : (existing.present
                ? BoardingAttendanceStatus.confirmed
                : BoardingAttendanceStatus.declined),
      isDefaultDaily: false,
    );

    return saveBoarding(updated);
  }

  @override
  Future<BoardingModel> markBoardingOutcome({
    required String boardingId,
    required BoardingAttendanceStatus status,
  }) async {
    final doc = await _collection.doc(boardingId.trim()).get();
    final existing = _fromDoc(doc);
    if (existing == null) {
      throw Exception('Registro de embarque não encontrado.');
    }

    final boarded = status == BoardingAttendanceStatus.boarded;
    final updated = existing.copyWith(
      timestamp: DateTime.now(),
      present: boarded,
      isReadyForBoarding: false,
      attendanceStatus: status,
      isDefaultDaily: false,
    );

    return saveBoarding(updated);
  }

  @override
  Future<BoardingModel> registerNotificationSent({
    required String boardingId,
    bool? tripStartNotified,
    int? etaThresholdMinutes,
  }) async {
    final doc = await _collection.doc(boardingId.trim()).get();
    final existing = _fromDoc(doc);
    if (existing == null) {
      throw Exception('Registro de embarque não encontrado.');
    }

    final updatedThresholds = List<int>.from(existing.notifiedEtaThresholds);
    if (etaThresholdMinutes != null &&
        !updatedThresholds.contains(etaThresholdMinutes)) {
      updatedThresholds.add(etaThresholdMinutes);
    }

    final updated = existing.copyWith(
      wasTripStartNotified: tripStartNotified ?? existing.wasTripStartNotified,
      notifiedEtaThresholds: updatedThresholds,
    );

    return saveBoarding(updated);
  }

  @override
  Future<void> deleteBoarding(String boardingId) async {
    final trimmed = boardingId.trim();
    if (trimmed.isEmpty) return;
    await _collection.doc(trimmed).delete();
  }
}