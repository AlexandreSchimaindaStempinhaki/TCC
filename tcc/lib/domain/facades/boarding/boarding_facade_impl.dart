import '../../models/boarding_entity.dart';
import '../../usecases/boarding/i_boarding_usecases.dart';
import 'i_boarding_facade.dart';

class BoardingFacadeImpl implements IBoardingFacade {
  final IGetOrCreateDailyBoardingUseCase _getOrCreateDailyBoardingUseCase;
  final IFetchBoardingsByRouteAndDateUseCase
      _fetchBoardingsByRouteAndDateUseCase;
  final IFetchBoardingsByTripUseCase _fetchBoardingsByTripUseCase;
  final IFetchUserBoardingHistoryUseCase _fetchUserBoardingHistoryUseCase;
  final IWatchPassengerBoardingUseCase _watchPassengerBoardingUseCase;
  final IWatchRouteBoardingsByDateUseCase _watchRouteBoardingsByDateUseCase;
  final ISaveBoardingUseCase _saveBoardingUseCase;
  final IUpdateBoardingAttendanceUseCase _updateBoardingAttendanceUseCase;
  final ISetReadyForBoardingUseCase _setReadyForBoardingUseCase;
  final IMarkBoardingOutcomeUseCase _markBoardingOutcomeUseCase;
  final IRegisterBoardingNotificationUseCase
      _registerBoardingNotificationUseCase;
  final IDeleteBoardingUseCase _deleteBoardingUseCase;

  BoardingFacadeImpl(
    this._getOrCreateDailyBoardingUseCase,
    this._fetchBoardingsByRouteAndDateUseCase,
    this._fetchBoardingsByTripUseCase,
    this._fetchUserBoardingHistoryUseCase,
    this._watchPassengerBoardingUseCase,
    this._watchRouteBoardingsByDateUseCase,
    this._saveBoardingUseCase,
    this._updateBoardingAttendanceUseCase,
    this._setReadyForBoardingUseCase,
    this._markBoardingOutcomeUseCase,
    this._registerBoardingNotificationUseCase,
    this._deleteBoardingUseCase,
  );

  @override
  Future<BoardingModel> getOrCreateDailyBoarding({
    required String routeId,
    required String userId,
    required DateTime date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  }) =>
      _getOrCreateDailyBoardingUseCase(
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
      _fetchBoardingsByRouteAndDateUseCase(routeId: routeId, date: date);

  @override
  Future<List<BoardingModel>> fetchBoardingsByTrip(String tripId) =>
      _fetchBoardingsByTripUseCase(tripId);

  @override
  Future<List<BoardingModel>> fetchUserBoardingHistory({
    required String routeId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _fetchUserBoardingHistoryUseCase(
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
      _watchPassengerBoardingUseCase(
        routeId: routeId,
        userId: userId,
        date: date,
      );

  @override
  Stream<List<BoardingModel>> watchRouteBoardingsByDate({
    required String routeId,
    required DateTime date,
  }) =>
      _watchRouteBoardingsByDateUseCase(routeId: routeId, date: date);

  @override
  Future<BoardingModel> saveBoarding(BoardingModel boarding) =>
      _saveBoardingUseCase(boarding);

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
      _updateBoardingAttendanceUseCase(
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
      _setReadyForBoardingUseCase(boardingId: boardingId, isReady: isReady);

  @override
  Future<BoardingModel> markBoardingOutcome({
    required String boardingId,
    required BoardingAttendanceStatus status,
  }) =>
      _markBoardingOutcomeUseCase(boardingId: boardingId, status: status);

  @override
  Future<BoardingModel> registerNotificationSent({
    required String boardingId,
    bool? tripStartNotified,
    int? etaThresholdMinutes,
  }) =>
      _registerBoardingNotificationUseCase(
        boardingId: boardingId,
        tripStartNotified: tripStartNotified,
        etaThresholdMinutes: etaThresholdMinutes,
      );

  @override
  Future<void> deleteBoarding(String boardingId) =>
      _deleteBoardingUseCase(boardingId);
}