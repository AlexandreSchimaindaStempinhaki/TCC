import '../../../data/repositories/boarding/i_boarding_repository.dart';
import '../../models/boarding_entity.dart';
import 'i_boarding_usecases.dart';

class GetOrCreateDailyBoardingUseCaseImpl
    implements IGetOrCreateDailyBoardingUseCase {
  final IBoardingRepository _repository;
  GetOrCreateDailyBoardingUseCaseImpl(this._repository);

  @override
  Future<BoardingModel> call({
    required String routeId,
    required String userId,
    required DateTime date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  }) =>
      _repository.getOrCreateDailyBoarding(
        routeId: routeId,
        userId: userId,
        date: date,
        tripId: tripId,
        defaultDepartureTime: defaultDepartureTime,
        defaultReturnTime: defaultReturnTime,
      );
}

class FetchBoardingsByRouteAndDateUseCaseImpl
    implements IFetchBoardingsByRouteAndDateUseCase {
  final IBoardingRepository _repository;
  FetchBoardingsByRouteAndDateUseCaseImpl(this._repository);

  @override
  Future<List<BoardingModel>> call({
    required String routeId,
    required DateTime date,
  }) =>
      _repository.fetchBoardingsByRouteAndDate(routeId: routeId, date: date);
}

class FetchBoardingsByTripUseCaseImpl implements IFetchBoardingsByTripUseCase {
  final IBoardingRepository _repository;
  FetchBoardingsByTripUseCaseImpl(this._repository);

  @override
  Future<List<BoardingModel>> call(String tripId) =>
      _repository.fetchBoardingsByTrip(tripId);
}

class FetchUserBoardingHistoryUseCaseImpl
    implements IFetchUserBoardingHistoryUseCase {
  final IBoardingRepository _repository;
  FetchUserBoardingHistoryUseCaseImpl(this._repository);

  @override
  Future<List<BoardingModel>> call({
    required String routeId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _repository.fetchUserBoardingHistory(
        routeId: routeId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
}

class WatchPassengerBoardingUseCaseImpl
    implements IWatchPassengerBoardingUseCase {
  final IBoardingRepository _repository;
  WatchPassengerBoardingUseCaseImpl(this._repository);

  @override
  Stream<BoardingModel?> call({
    required String routeId,
    required String userId,
    required DateTime date,
  }) =>
      _repository.watchPassengerBoarding(
        routeId: routeId,
        userId: userId,
        date: date,
      );
}

class WatchRouteBoardingsByDateUseCaseImpl
    implements IWatchRouteBoardingsByDateUseCase {
  final IBoardingRepository _repository;
  WatchRouteBoardingsByDateUseCaseImpl(this._repository);

  @override
  Stream<List<BoardingModel>> call({
    required String routeId,
    required DateTime date,
  }) =>
      _repository.watchRouteBoardingsByDate(routeId: routeId, date: date);
}

class SaveBoardingUseCaseImpl implements ISaveBoardingUseCase {
  final IBoardingRepository _repository;
  SaveBoardingUseCaseImpl(this._repository);

  @override
  Future<BoardingModel> call(BoardingModel boarding) =>
      _repository.saveBoarding(boarding);
}

class UpdateBoardingAttendanceUseCaseImpl
    implements IUpdateBoardingAttendanceUseCase {
  final IBoardingRepository _repository;
  UpdateBoardingAttendanceUseCaseImpl(this._repository);

  @override
  Future<BoardingModel> call({
    required String routeId,
    required String userId,
    required DateTime date,
    required bool willGoOutbound,
    required bool willGoReturn,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    String? tripId,
  }) =>
      _repository.updateAttendance(
        routeId: routeId,
        userId: userId,
        date: date,
        willGoOutbound: willGoOutbound,
        willGoReturn: willGoReturn,
        selectedDepartureTime: selectedDepartureTime,
        selectedReturnTime: selectedReturnTime,
        tripId: tripId,
      );
}

class SetReadyForBoardingUseCaseImpl implements ISetReadyForBoardingUseCase {
  final IBoardingRepository _repository;
  SetReadyForBoardingUseCaseImpl(this._repository);

  @override
  Future<BoardingModel> call({
    required String boardingId,
    required bool isReady,
  }) =>
      _repository.setReadyForBoarding(boardingId: boardingId, isReady: isReady);
}

class MarkBoardingOutcomeUseCaseImpl implements IMarkBoardingOutcomeUseCase {
  final IBoardingRepository _repository;
  MarkBoardingOutcomeUseCaseImpl(this._repository);

  @override
  Future<BoardingModel> call({
    required String boardingId,
    required BoardingAttendanceStatus status,
  }) =>
      _repository.markBoardingOutcome(boardingId: boardingId, status: status);
}

class RegisterBoardingNotificationUseCaseImpl
    implements IRegisterBoardingNotificationUseCase {
  final IBoardingRepository _repository;
  RegisterBoardingNotificationUseCaseImpl(this._repository);

  @override
  Future<BoardingModel> call({
    required String boardingId,
    bool? tripStartNotified,
    int? etaThresholdMinutes,
  }) =>
      _repository.registerNotificationSent(
        boardingId: boardingId,
        tripStartNotified: tripStartNotified,
        etaThresholdMinutes: etaThresholdMinutes,
      );
}

class DeleteBoardingUseCaseImpl implements IDeleteBoardingUseCase {
  final IBoardingRepository _repository;
  DeleteBoardingUseCaseImpl(this._repository);

  @override
  Future<void> call(String boardingId) =>
      _repository.deleteBoarding(boardingId);
}