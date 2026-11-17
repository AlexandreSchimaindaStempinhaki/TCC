import '../../domain/facades/trip/i_trip_facade.dart';
import '../../domain/models/trip_entity.dart';

class FetchTripsByRouteCommand {
  final ITripFacade _facade;
  FetchTripsByRouteCommand(this._facade);

  Future<List<TripModel>> execute({
    required String routeId,
    DateTime? date,
  }) =>
      _facade.fetchTripsByRoute(routeId: routeId, date: date);
}

class FetchTripsByDriverCommand {
  final ITripFacade _facade;
  FetchTripsByDriverCommand(this._facade);

  Future<List<TripModel>> execute({
    required String driverId,
    DateTime? date,
  }) =>
      _facade.fetchTripsByDriver(driverId: driverId, date: date);
}

class FetchTripsByCompanyCommand {
  final ITripFacade _facade;
  FetchTripsByCompanyCommand(this._facade);

  Future<List<TripModel>> execute({
    required String companyCnpj,
    DateTime? date,
  }) =>
      _facade.fetchTripsByCompany(companyCnpj: companyCnpj, date: date);
}

class GetTripByIdCommand {
  final ITripFacade _facade;
  GetTripByIdCommand(this._facade);

  Future<TripModel?> execute(String tripId) => _facade.getTripById(tripId);
}

class WatchTripByIdCommand {
  final ITripFacade _facade;
  WatchTripByIdCommand(this._facade);

  Stream<TripModel?> execute(String tripId) => _facade.watchTripById(tripId);
}

class WatchActiveTripsByRouteCommand {
  final ITripFacade _facade;
  WatchActiveTripsByRouteCommand(this._facade);

  Stream<List<TripModel>> execute(String routeId) =>
      _facade.watchActiveTripsByRoute(routeId);
}

class CreateTripCommand {
  final ITripFacade _facade;
  CreateTripCommand(this._facade);

  Future<TripModel> execute(TripModel trip) => _facade.createTrip(trip);
}

class GenerateScaledTripsCommand {
  final ITripFacade _facade;
  GenerateScaledTripsCommand(this._facade);

  Future<List<TripModel>> execute({
    required TripModel baseTrip,
    required List<TripStopPoint> confirmedStops,
  }) =>
      _facade.generateScaledTrips(
        baseTrip: baseTrip,
        confirmedStops: confirmedStops,
      );
}

class UpdateTripCommand {
  final ITripFacade _facade;
  UpdateTripCommand(this._facade);

  Future<TripModel> execute(TripModel trip) => _facade.updateTrip(trip);
}

class StartTripCommand {
  final ITripFacade _facade;
  StartTripCommand(this._facade);

  Future<TripModel> execute({
    required String tripId,
    double? initialLatitude,
    double? initialLongitude,
  }) =>
      _facade.startTrip(
        tripId: tripId,
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      );
}

class FinishTripCommand {
  final ITripFacade _facade;
  FinishTripCommand(this._facade);

  Future<TripModel> execute(String tripId) => _facade.finishTrip(tripId);
}

class CancelTripCommand {
  final ITripFacade _facade;
  CancelTripCommand(this._facade);

  Future<TripModel> execute(String tripId) => _facade.cancelTrip(tripId);
}

class UpdateDriverLocationCommand {
  final ITripFacade _facade;
  UpdateDriverLocationCommand(this._facade);

  Future<TripModel> execute({
    required String tripId,
    required double latitude,
    required double longitude,
    required bool isSharingLocation,
    double averageSpeedKmh = 35.0,
  }) =>
      _facade.updateDriverLocation(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        isSharingLocation: isSharingLocation,
        averageSpeedKmh: averageSpeedKmh,
      );
}

class MarkStopCompletedCommand {
  final ITripFacade _facade;
  MarkStopCompletedCommand(this._facade);

  Future<TripModel> execute({
    required String tripId,
    required String passengerId,
    required bool isCompleted,
  }) =>
      _facade.markStopCompleted(
        tripId: tripId,
        passengerId: passengerId,
        isCompleted: isCompleted,
      );
}

class SetPassengerReadyAtStopCommand {
  final ITripFacade _facade;
  SetPassengerReadyAtStopCommand(this._facade);

  Future<TripModel> execute({
    required String tripId,
    required String passengerId,
    required bool isReady,
  }) =>
      _facade.setPassengerReadyAtStop(
        tripId: tripId,
        passengerId: passengerId,
        isReady: isReady,
      );
}

class DeleteTripCommand {
  final ITripFacade _facade;
  DeleteTripCommand(this._facade);

  Future<void> execute(String tripId) => _facade.deleteTrip(tripId);
}