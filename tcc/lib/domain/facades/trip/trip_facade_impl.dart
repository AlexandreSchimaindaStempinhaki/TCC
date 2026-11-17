import '../../models/trip_entity.dart';
import '../../usecases/trip/i_trip_usecases.dart';
import 'i_trip_facade.dart';

class TripFacadeImpl implements ITripFacade {
  final IFetchTripsByRouteUseCase _fetchTripsByRouteUseCase;
  final IFetchTripsByDriverUseCase _fetchTripsByDriverUseCase;
  final IFetchTripsByCompanyUseCase _fetchTripsByCompanyUseCase;
  final IGetTripByIdUseCase _getTripByIdUseCase;
  final IWatchTripByIdUseCase _watchTripByIdUseCase;
  final IWatchActiveTripsByRouteUseCase _watchActiveTripsByRouteUseCase;
  final ICreateTripUseCase _createTripUseCase;
  final IGenerateScaledTripsUseCase _generateScaledTripsUseCase;
  final IUpdateTripUseCase _updateTripUseCase;
  final IStartTripUseCase _startTripUseCase;
  final IFinishTripUseCase _finishTripUseCase;
  final ICancelTripUseCase _cancelTripUseCase;
  final IUpdateDriverLocationUseCase _updateDriverLocationUseCase;
  final IMarkStopCompletedUseCase _markStopCompletedUseCase;
  final ISetPassengerReadyAtStopUseCase _setPassengerReadyAtStopUseCase;
  final IDeleteTripUseCase _deleteTripUseCase;

  TripFacadeImpl(
    this._fetchTripsByRouteUseCase,
    this._fetchTripsByDriverUseCase,
    this._fetchTripsByCompanyUseCase,
    this._getTripByIdUseCase,
    this._watchTripByIdUseCase,
    this._watchActiveTripsByRouteUseCase,
    this._createTripUseCase,
    this._generateScaledTripsUseCase,
    this._updateTripUseCase,
    this._startTripUseCase,
    this._finishTripUseCase,
    this._cancelTripUseCase,
    this._updateDriverLocationUseCase,
    this._markStopCompletedUseCase,
    this._setPassengerReadyAtStopUseCase,
    this._deleteTripUseCase,
  );

  @override
  Future<List<TripModel>> fetchTripsByRoute({
    required String routeId,
    DateTime? date,
  }) =>
      _fetchTripsByRouteUseCase(routeId: routeId, date: date);

  @override
  Future<List<TripModel>> fetchTripsByDriver({
    required String driverId,
    DateTime? date,
  }) =>
      _fetchTripsByDriverUseCase(driverId: driverId, date: date);

  @override
  Future<List<TripModel>> fetchTripsByCompany({
    required String companyCnpj,
    DateTime? date,
  }) =>
      _fetchTripsByCompanyUseCase(companyCnpj: companyCnpj, date: date);

  @override
  Future<TripModel?> getTripById(String tripId) => _getTripByIdUseCase(tripId);

  @override
  Stream<TripModel?> watchTripById(String tripId) =>
      _watchTripByIdUseCase(tripId);

  @override
  Stream<List<TripModel>> watchActiveTripsByRoute(String routeId) =>
      _watchActiveTripsByRouteUseCase(routeId);

  @override
  Future<TripModel> createTrip(TripModel trip) => _createTripUseCase(trip);

  @override
  Future<List<TripModel>> generateScaledTrips({
    required TripModel baseTrip,
    required List<TripStopPoint> confirmedStops,
  }) =>
      _generateScaledTripsUseCase(
        baseTrip: baseTrip,
        confirmedStops: confirmedStops,
      );

  @override
  Future<TripModel> updateTrip(TripModel trip) => _updateTripUseCase(trip);

  @override
  Future<TripModel> startTrip({
    required String tripId,
    double? initialLatitude,
    double? initialLongitude,
  }) =>
      _startTripUseCase(
        tripId: tripId,
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      );

  @override
  Future<TripModel> finishTrip(String tripId) => _finishTripUseCase(tripId);

  @override
  Future<TripModel> cancelTrip(String tripId) => _cancelTripUseCase(tripId);

  @override
  Future<TripModel> updateDriverLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    required bool isSharingLocation,
    double averageSpeedKmh = 35.0,
  }) =>
      _updateDriverLocationUseCase(
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
      _markStopCompletedUseCase(
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
      _setPassengerReadyAtStopUseCase(
        tripId: tripId,
        passengerId: passengerId,
        isReady: isReady,
      );

  @override
  Future<void> deleteTrip(String tripId) => _deleteTripUseCase(tripId);
}