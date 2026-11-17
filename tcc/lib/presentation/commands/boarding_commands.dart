import '../../domain/facades/boarding/i_boarding_facade.dart';
import '../../domain/models/boarding_entity.dart';

class GetOrCreateDailyBoardingCommand {
  final IBoardingFacade _facade;
  GetOrCreateDailyBoardingCommand(this._facade);

  Future<BoardingModel> execute({
    required String routeId,
    required String userId,
    required DateTime date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  }) =>
      _facade.getOrCreateDailyBoarding(
        routeId: routeId,
        userId: userId,
        date: date,
        tripId: tripId,
        defaultDepartureTime: defaultDepartureTime,
        defaultReturnTime: defaultReturnTime,
      );
}

class FetchBoardingsByRouteAndDateCommand {
  final IBoardingFacade _facade;
  FetchBoardingsByRouteAndDateCommand(this._facade);

  Future<List<BoardingModel>> execute({
    required String routeId,
    required DateTime date,
  }) =>
      _facade.fetchBoardingsByRouteAndDate(routeId: routeId, date: date);
}

class FetchBoardingsByTripCommand {
  final IBoardingFacade _facade;
  FetchBoardingsByTripCommand(this._facade);

  Future<List<BoardingModel>> execute(String tripId) =>
      _facade.fetchBoardingsByTrip(tripId);
}

class FetchUserBoardingHistoryCommand {
  final IBoardingFacade _facade;
  FetchUserBoardingHistoryCommand(this._facade);

  Future<List<BoardingModel>> execute({
    required String routeId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      _facade.fetchUserBoardingHistory(
        routeId: routeId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
}

class WatchPassengerBoardingCommand {
  final IBoardingFacade _facade;
  WatchPassengerBoardingCommand(this._facade);

  Stream<BoardingModel?> execute({
    required String routeId,
    required String userId,
    required DateTime date,
  }) =>
      _facade.watchPassengerBoarding(
        routeId: routeId,
        userId: userId,
        date: date,
      );
}

class WatchRouteBoardingsByDateCommand {
  final IBoardingFacade _facade;
  WatchRouteBoardingsByDateCommand(this._facade);

  Stream<List<BoardingModel>> execute({
    required String routeId,
    required DateTime date,
  }) =>
      _facade.watchRouteBoardingsByDate(routeId: routeId, date: date);
}

class SaveBoardingCommand {
  final IBoardingFacade _facade;
  SaveBoardingCommand(this._facade);

  Future<BoardingModel> execute(BoardingModel boarding) =>
      _facade.saveBoarding(boarding);
}

class UpdateBoardingAttendanceCommand {
  final IBoardingFacade _facade;
  UpdateBoardingAttendanceCommand(this._facade);

  Future<BoardingModel> execute({
    required String routeId,
    required String userId,
    required DateTime date,
    required bool willGoOutbound,
    required bool willGoReturn,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    String? tripId,
  }) =>
      _facade.updateAttendance(
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

class SetReadyForBoardingCommand {
  final IBoardingFacade _facade;
  SetReadyForBoardingCommand(this._facade);

  Future<BoardingModel> execute({
    required String boardingId,
    required bool isReady,
  }) =>
      _facade.setReadyForBoarding(boardingId: boardingId, isReady: isReady);
}

class MarkBoardingOutcomeCommand {
  final IBoardingFacade _facade;
  MarkBoardingOutcomeCommand(this._facade);

  Future<BoardingModel> execute({
    required String boardingId,
    required BoardingAttendanceStatus status,
  }) =>
      _facade.markBoardingOutcome(boardingId: boardingId, status: status);
}

class RegisterBoardingNotificationCommand {
  final IBoardingFacade _facade;
  RegisterBoardingNotificationCommand(this._facade);

  Future<BoardingModel> execute({
    required String boardingId,
    bool? tripStartNotified,
    int? etaThresholdMinutes,
  }) =>
      _facade.registerNotificationSent(
        boardingId: boardingId,
        tripStartNotified: tripStartNotified,
        etaThresholdMinutes: etaThresholdMinutes,
      );
}

class DeleteBoardingCommand {
  final IBoardingFacade _facade;
  DeleteBoardingCommand(this._facade);

  Future<void> execute(String boardingId) => _facade.deleteBoarding(boardingId);
}