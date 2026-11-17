import '../../../data/repositories/trip/i_trip_repository.dart';
import '../../models/trip_entity.dart';
import 'i_trip_usecases.dart';

class FetchTripsByRouteUseCaseImpl implements IFetchTripsByRouteUseCase {
  final ITripRepository _repository;
  FetchTripsByRouteUseCaseImpl(this._repository);

  @override
  Future<List<TripModel>> call({required String routeId, DateTime? date}) =>
      _repository.fetchTripsByRoute(routeId: routeId, date: date);
}

class FetchTripsByDriverUseCaseImpl implements IFetchTripsByDriverUseCase {
  final ITripRepository _repository;
  FetchTripsByDriverUseCaseImpl(this._repository);

  @override
  Future<List<TripModel>> call({required String driverId, DateTime? date}) =>
      _repository.fetchTripsByDriver(driverId: driverId, date: date);
}

class FetchTripsByCompanyUseCaseImpl implements IFetchTripsByCompanyUseCase {
  final ITripRepository _repository;
  FetchTripsByCompanyUseCaseImpl(this._repository);

  @override
  Future<List<TripModel>> call({required String companyCnpj, DateTime? date}) =>
      _repository.fetchTripsByCompany(companyCnpj: companyCnpj, date: date);
}

class GetTripByIdUseCaseImpl implements IGetTripByIdUseCase {
  final ITripRepository _repository;
  GetTripByIdUseCaseImpl(this._repository);

  @override
  Future<TripModel?> call(String tripId) => _repository.getTripById(tripId);
}

class WatchTripByIdUseCaseImpl implements IWatchTripByIdUseCase {
  final ITripRepository _repository;
  WatchTripByIdUseCaseImpl(this._repository);

  @override
  Stream<TripModel?> call(String tripId) => _repository.watchTripById(tripId);
}

class WatchActiveTripsByRouteUseCaseImpl
    implements IWatchActiveTripsByRouteUseCase {
  final ITripRepository _repository;
  WatchActiveTripsByRouteUseCaseImpl(this._repository);

  @override
  Stream<List<TripModel>> call(String routeId) =>
      _repository.watchActiveTripsByRoute(routeId);
}

class CreateTripUseCaseImpl implements ICreateTripUseCase {
  final ITripRepository _repository;
  CreateTripUseCaseImpl(this._repository);

  @override
  Future<TripModel> call(TripModel trip) {
    if (trip.routeId.trim().isEmpty) {
      throw Exception('A rota da viagem é obrigatória.');
    }
    return _repository.createTrip(trip);
  }
}

class GenerateScaledTripsUseCaseImpl implements IGenerateScaledTripsUseCase {
  final ITripRepository _repository;
  GenerateScaledTripsUseCaseImpl(this._repository);

  @override
  Future<List<TripModel>> call({
    required TripModel baseTrip,
    required List<TripStopPoint> confirmedStops,
  }) =>
      _repository.generateScaledTrips(
        baseTrip: baseTrip,
        confirmedStops: confirmedStops,
      );
}

class UpdateTripUseCaseImpl implements IUpdateTripUseCase {
  final ITripRepository _repository;
  UpdateTripUseCaseImpl(this._repository);

  @override
  Future<TripModel> call(TripModel trip) => _repository.updateTrip(trip);
}

class StartTripUseCaseImpl implements IStartTripUseCase {
  final ITripRepository _repository;
  StartTripUseCaseImpl(this._repository);

  @override
  Future<TripModel> call({
    required String tripId,
    double? initialLatitude,
    double? initialLongitude,
  }) =>
      _repository.startTrip(
        tripId: tripId,
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      );
}

class FinishTripUseCaseImpl implements IFinishTripUseCase {
  final ITripRepository _repository;
  FinishTripUseCaseImpl(this._repository);

  @override
  Future<TripModel> call(String tripId) => _repository.finishTrip(tripId);
}

class CancelTripUseCaseImpl implements ICancelTripUseCase {
  final ITripRepository _repository;
  CancelTripUseCaseImpl(this._repository);

  @override
  Future<TripModel> call(String tripId) => _repository.cancelTrip(tripId);
}

class UpdateDriverLocationUseCaseImpl implements IUpdateDriverLocationUseCase {
  final ITripRepository _repository;
  UpdateDriverLocationUseCaseImpl(this._repository);

  @override
  Future<TripModel> call({
    required String tripId,
    required double latitude,
    required double longitude,
    required bool isSharingLocation,
    double averageSpeedKmh = 35.0,
  }) =>
      _repository.updateDriverLocationAndCalculateEta(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        isSharingLocation: isSharingLocation,
        averageSpeedKmh: averageSpeedKmh,
      );
}

class MarkStopCompletedUseCaseImpl implements IMarkStopCompletedUseCase {
  final ITripRepository _repository;
  MarkStopCompletedUseCaseImpl(this._repository);

  @override
  Future<TripModel> call({
    required String tripId,
    required String passengerId,
    required bool isCompleted,
  }) =>
      _repository.markStopCompleted(
        tripId: tripId,
        passengerId: passengerId,
        isCompleted: isCompleted,
      );
}

class SetPassengerReadyAtStopUseCaseImpl
    implements ISetPassengerReadyAtStopUseCase {
  final ITripRepository _repository;
  SetPassengerReadyAtStopUseCaseImpl(this._repository);

  @override
  Future<TripModel> call({
    required String tripId,
    required String passengerId,
    required bool isReady,
  }) =>
      _repository.setPassengerReadyAtStop(
        tripId: tripId,
        passengerId: passengerId,
        isReady: isReady,
      );
}

class DeleteTripUseCaseImpl implements IDeleteTripUseCase {
  final ITripRepository _repository;
  DeleteTripUseCaseImpl(this._repository);

  @override
  Future<void> call(String tripId) => _repository.deleteTrip(tripId);
}