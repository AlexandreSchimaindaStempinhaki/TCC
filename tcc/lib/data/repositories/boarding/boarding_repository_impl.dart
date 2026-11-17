import '../../../domain/models/boarding_entity.dart';
import '../../services/boarding/i_boarding_service.dart';
import 'i_boarding_repository.dart';

class BoardingRepositoryImpl implements IBoardingRepository {
  final IBoardingService _service;

  BoardingRepositoryImpl(this._service);

  @override
  Future<BoardingModel> getOrCreateDailyBoarding({
    required String routeId,
    required String userId,
    required DateTime date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  }) =>
      _service.getOrCreateDailyBoarding(
        routeId: routeId,
        userId: userId,
        date: date,
        tripId: tripId,
        defaultDepartureTime: defaultDepartureTime,
        defaultReturnTime: defaultReturnTime,
      );

  @override
  Future<List<BoardingModel>> fetchBoardingsByRouteAndDate({
    required String routeId,
    required DateTime date,
  }) =>
      _service.fetchBoardingsByRouteAndDate(routeId: routeId, date: date);

  @override
  Future<List<BoardingModel>> fetchBoardingsByTrip(String tripId) =>
      _service.fetchBoardingsByTrip(tripId);

  @override
  Future<List<BoardingModel>> fetchUserBoardingHistory({
    required String routeId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _service.fetchUserBoardingHistory(
        routeId: routeId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

  @override
  Stream<BoardingModel?> watchPassengerBoarding({
    required String routeId,
    required String userId,
    required DateTime date,
  }) =>
      _service.watchPassengerBoarding(
        routeId: routeId,
        userId: userId,
        date: date,
      );

  @override
  Stream<List<BoardingModel>> watchRouteBoardingsByDate({
    required String routeId,
    required DateTime date,
  }) =>
      _service.watchRouteBoardingsByDate(routeId: routeId, date: date);

  @override
  Future<BoardingModel> saveBoarding(BoardingModel boarding) =>
      _service.saveBoarding(boarding);

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
  }) =>
      _service.updateAttendance(
        routeId: routeId,
        userId: userId,
        date: date,
        willGoOutbound: willGoOutbound,
        willGoReturn: willGoReturn,
        selectedDepartureTime: selectedDepartureTime,
        selectedReturnTime: selectedReturnTime,
        tripId: tripId,
      );

  @override
  Future<BoardingModel> setReadyForBoarding({
    required String boardingId,
    required bool isReady,
  }) =>
      _service.setReadyForBoarding(boardingId: boardingId, isReady: isReady);

  @override
  Future<BoardingModel> markBoardingOutcome({
    required String boardingId,
    required BoardingAttendanceStatus status,
  }) =>
      _service.markBoardingOutcome(boardingId: boardingId, status: status);

  @override
  Future<BoardingModel> registerNotificationSent({
    required String boardingId,
    bool? tripStartNotified,
    int? etaThresholdMinutes,
  }) =>
      _service.registerNotificationSent(
        boardingId: boardingId,
        tripStartNotified: tripStartNotified,
        etaThresholdMinutes: etaThresholdMinutes,
      );

  @override
  Future<void> deleteBoarding(String boardingId) =>
      _service.deleteBoarding(boardingId);
}