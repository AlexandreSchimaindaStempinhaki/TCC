import '../../models/boarding_entity.dart';

abstract class IGetOrCreateDailyBoardingUseCase {
  Future<BoardingModel> call({
    required String routeId,
    required String userId,
    required DateTime date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  });
}

abstract class IFetchBoardingsByRouteAndDateUseCase {
  Future<List<BoardingModel>> call({
    required String routeId,
    required DateTime date,
  });
}

abstract class IFetchBoardingsByTripUseCase {
  Future<List<BoardingModel>> call(String tripId);
}

abstract class IFetchUserBoardingHistoryUseCase {
  Future<List<BoardingModel>> call({
    required String routeId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

abstract class IWatchPassengerBoardingUseCase {
  Stream<BoardingModel?> call({
    required String routeId,
    required String userId,
    required DateTime date,
  });
}

abstract class IWatchRouteBoardingsByDateUseCase {
  Stream<List<BoardingModel>> call({
    required String routeId,
    required DateTime date,
  });
}

abstract class ISaveBoardingUseCase {
  Future<BoardingModel> call(BoardingModel boarding);
}

abstract class IUpdateBoardingAttendanceUseCase {
  Future<BoardingModel> call({
    required String routeId,
    required String userId,
    required DateTime date,
    required bool willGoOutbound,
    required bool willGoReturn,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    String? tripId,
  });
}

abstract class ISetReadyForBoardingUseCase {
  Future<BoardingModel> call({
    required String boardingId,
    required bool isReady,
  });
}

abstract class IMarkBoardingOutcomeUseCase {
  Future<BoardingModel> call({
    required String boardingId,
    required BoardingAttendanceStatus status,
  });
}

abstract class IRegisterBoardingNotificationUseCase {
  Future<BoardingModel> call({
    required String boardingId,
    bool? tripStartNotified,
    int? etaThresholdMinutes,
  });
}

abstract class IDeleteBoardingUseCase {
  Future<void> call(String boardingId);
}