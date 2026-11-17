import '../../models/boarding_entity.dart';

abstract class IBoardingFacade {
  Future<BoardingModel> getOrCreateDailyBoarding({
    required String routeId,
    required String userId,
    required DateTime date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  });

  Future<List<BoardingModel>> fetchBoardingsByRouteAndDate({
    required String routeId,
    required DateTime date,
  });

  Future<List<BoardingModel>> fetchBoardingsByTrip(String tripId);

  Future<List<BoardingModel>> fetchUserBoardingHistory({
    required String routeId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<BoardingModel?> watchPassengerBoarding({
    required String routeId,
    required String userId,
    required DateTime date,
  });

  Stream<List<BoardingModel>> watchRouteBoardingsByDate({
    required String routeId,
    required DateTime date,
  });

  Future<BoardingModel> saveBoarding(BoardingModel boarding);

  Future<BoardingModel> updateAttendance({
    required String routeId,
    required String userId,
    required DateTime date,
    required bool willGoOutbound,
    required bool willGoReturn,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    String? tripId,
  });

  Future<BoardingModel> setReadyForBoarding({
    required String boardingId,
    required bool isReady,
  });

  Future<BoardingModel> markBoardingOutcome({
    required String boardingId,
    required BoardingAttendanceStatus status,
  });

  Future<BoardingModel> registerNotificationSent({
    required String boardingId,
    bool? tripStartNotified,
    int? etaThresholdMinutes,
  });

  Future<void> deleteBoarding(String boardingId);
}