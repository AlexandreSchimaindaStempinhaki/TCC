import '../../../domain/models/trip_entity.dart';
import 'i_trip_repository.dart';
import '../../services/trip/i_trip_service.dart';

class TripRepositoryImpl implements ITripRepository {
  final ITripService _service;

  TripRepositoryImpl(this._service);

  @override
  Future<List<TripModel>> fetchTripsByRoute({
    required String routeId,
    DateTime? date,
  }) =>
      _service.fetchTripsByRoute(routeId: routeId, date: date);

  @override
  Future<List<TripModel>> fetchTripsByDriver({
    required String driverId,
    DateTime? date,
  }) =>
      _service.fetchTripsByDriver(driverId: driverId, date: date);

  @override
  Future<List<TripModel>> fetchTripsByCompany({
    required String companyCnpj,
    DateTime? date,
  }) =>
      _service.fetchTripsByCompany(companyCnpj: companyCnpj, date: date);

  @override
  Future<TripModel?> getTripById(String tripId) => _service.getTripById(tripId);

  @override
  Stream<TripModel?> watchTripById(String tripId) =>
      _service.watchTripById(tripId);

  @override
  Stream<List<TripModel>> watchActiveTripsByRoute(String routeId) =>
      _service.watchActiveTripsByRoute(routeId);

  @override
  Future<TripModel> createTrip(TripModel trip) => _service.createTrip(trip);

  @override
  Future<List<TripModel>> generateScaledTrips({
    required TripModel baseTrip,
    required List<TripStopPoint> confirmedStops,
  }) =>
      _service.generateScaledTrips(
        baseTrip: baseTrip,
        confirmedStops: confirmedStops,
      );

  @override
  Future<TripModel> updateTrip(TripModel trip) => _service.updateTrip(trip);

  @override
  Future<TripModel> startTrip({
    required String tripId,
    double? initialLatitude,
    double? initialLongitude,
  }) =>
      _service.startTrip(
        tripId: tripId,
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      );

  @override
  Future<TripModel> finishTrip(String tripId) => _service.finishTrip(tripId);

  @override
  Future<TripModel> cancelTrip(String tripId) => _service.cancelTrip(tripId);

  @override
  Future<TripModel> updateDriverLocationAndCalculateEta({
    required String tripId,
    required double latitude,
    required double longitude,
    required bool isSharingLocation,
    double averageSpeedKmh = 35.0,
  }) =>
      _service.updateDriverLocationAndCalculateEta(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        isSharingLocation: isSharingLocation,
        averageSpeedKmh: averageSpeedKmh,
      );

  @override
  Future<TripModel> markStopCompleted({
    required String tripId,
    required String passengerId,
    required bool isCompleted,
  }) =>
      _service.markStopCompleted(
        tripId: tripId,
        passengerId: passengerId,
        isCompleted: isCompleted,
      );

  @override
  Future<TripModel> setPassengerReadyAtStop({
    required String tripId,
    required String passengerId,
    required bool isReady,
  }) =>
      _service.setPassengerReadyAtStop(
        tripId: tripId,
        passengerId: passengerId,
        isReady: isReady,
      );

  @override
  Future<void> deleteTrip(String tripId) => _service.deleteTrip(tripId);
}