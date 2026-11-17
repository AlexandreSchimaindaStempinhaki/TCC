import '../../../domain/models/trip_entity.dart';

abstract class ITripRepository {
  Future<List<TripModel>> fetchTripsByRoute({
    required String routeId,
    DateTime? date,
  });
  Future<List<TripModel>> fetchTripsByDriver({
    required String driverId,
    DateTime? date,
  });
  Future<List<TripModel>> fetchTripsByCompany({
    required String companyCnpj,
    DateTime? date,
  });
  Future<TripModel?> getTripById(String tripId);
  Stream<TripModel?> watchTripById(String tripId);
  Stream<List<TripModel>> watchActiveTripsByRoute(String routeId);

  Future<TripModel> createTrip(TripModel trip);
  Future<List<TripModel>> generateScaledTrips({
    required TripModel baseTrip,
    required List<TripStopPoint> confirmedStops,
  });
  Future<TripModel> updateTrip(TripModel trip);
  Future<TripModel> startTrip({
    required String tripId,
    double? initialLatitude,
    double? initialLongitude,
  });
  Future<TripModel> finishTrip(String tripId);
  Future<TripModel> cancelTrip(String tripId);

  Future<TripModel> updateDriverLocationAndCalculateEta({
    required String tripId,
    required double latitude,
    required double longitude,
    required bool isSharingLocation,
    double averageSpeedKmh = 35.0,
  });

  Future<TripModel> markStopCompleted({
    required String tripId,
    required String passengerId,
    required bool isCompleted,
  });

  Future<TripModel> setPassengerReadyAtStop({
    required String tripId,
    required String passengerId,
    required bool isReady,
  });

  Future<void> deleteTrip(String tripId);
}