import '../../models/trip_entity.dart';

abstract class IFetchTripsByRouteUseCase {
  Future<List<TripModel>> call({required String routeId, DateTime? date});
}

abstract class IFetchTripsByDriverUseCase {
  Future<List<TripModel>> call({required String driverId, DateTime? date});
}

abstract class IFetchTripsByCompanyUseCase {
  Future<List<TripModel>> call({required String companyCnpj, DateTime? date});
}

abstract class IGetTripByIdUseCase {
  Future<TripModel?> call(String tripId);
}

abstract class IWatchTripByIdUseCase {
  Stream<TripModel?> call(String tripId);
}

abstract class IWatchActiveTripsByRouteUseCase {
  Stream<List<TripModel>> call(String routeId);
}

abstract class ICreateTripUseCase {
  Future<TripModel> call(TripModel trip);
}

abstract class IGenerateScaledTripsUseCase {
  Future<List<TripModel>> call({
    required TripModel baseTrip,
    required List<TripStopPoint> confirmedStops,
  });
}

abstract class IUpdateTripUseCase {
  Future<TripModel> call(TripModel trip);
}

abstract class IStartTripUseCase {
  Future<TripModel> call({
    required String tripId,
    double? initialLatitude,
    double? initialLongitude,
  });
}

abstract class IFinishTripUseCase {
  Future<TripModel> call(String tripId);
}

abstract class ICancelTripUseCase {
  Future<TripModel> call(String tripId);
}

abstract class IUpdateDriverLocationUseCase {
  Future<TripModel> call({
    required String tripId,
    required double latitude,
    required double longitude,
    required bool isSharingLocation,
    double averageSpeedKmh = 35.0,
  });
}

abstract class IMarkStopCompletedUseCase {
  Future<TripModel> call({
    required String tripId,
    required String passengerId,
    required bool isCompleted,
  });
}

abstract class ISetPassengerReadyAtStopUseCase {
  Future<TripModel> call({
    required String tripId,
    required String passengerId,
    required bool isReady,
  });
}

abstract class IDeleteTripUseCase {
  Future<void> call(String tripId);
}