import 'dart:io';
import '../../models/route_entity.dart';
import '../../models/user_entity.dart';
import '../../usecases/route/i_route_usecases.dart';
import 'i_route_facade.dart';

class RouteUseCaseFacadeImpl implements IRouteUseCaseFacade {
  final IFetchAllRoutesUseCase _fetchAllRoutesUseCase;
  final IFetchRoutesByCompanyUseCase _fetchRoutesByCompanyUseCase;
  final IGetRouteByIdUseCase _getRouteByIdUseCase;
  final ICreateRouteUseCase _createRouteUseCase;
  final IUpdateRouteUseCase _updateRouteUseCase;
  final IUpdateRouteImageUseCase _updateRouteImageUseCase;
  final IDeleteRouteUseCase _deleteRouteUseCase;

  final IRequestToJoinRouteUseCase _requestToJoinRouteUseCase;
  final ICancelJoinRequestUseCase _cancelJoinRequestUseCase;
  final IApprovePassengerInRouteUseCase _approvePassengerInRouteUseCase;
  final IRemovePassengerFromRouteUseCase _removePassengerFromRouteUseCase;
  final IFetchRouteUsersByIdsUseCase _fetchRouteUsersByIdsUseCase;

  final IAssignDriverToRouteUseCase _assignDriverToRouteUseCase;
  final ITogglePassengerPresenceUseCase _togglePassengerPresenceUseCase;
  final IStartRouteTripUseCase _startRouteTripUseCase;
  final IFinishRouteTripUseCase _finishRouteTripUseCase;

  RouteUseCaseFacadeImpl(
    this._fetchAllRoutesUseCase,
    this._fetchRoutesByCompanyUseCase,
    this._getRouteByIdUseCase,
    this._createRouteUseCase,
    this._updateRouteUseCase,
    this._updateRouteImageUseCase,
    this._deleteRouteUseCase,
    this._requestToJoinRouteUseCase,
    this._cancelJoinRequestUseCase,
    this._approvePassengerInRouteUseCase,
    this._removePassengerFromRouteUseCase,
    this._fetchRouteUsersByIdsUseCase,
    this._assignDriverToRouteUseCase,
    this._togglePassengerPresenceUseCase,
    this._startRouteTripUseCase,
    this._finishRouteTripUseCase,
  );

  // ===========================================================================
  //   CRUD DE ROTAS
  // ===========================================================================

  @override
  Future<List<RouteModel>> fetchAllRoutes() {
    return _fetchAllRoutesUseCase();
  }

  @override
  Future<List<RouteModel>> fetchRoutesByCompany(String companyCnpj) {
    return _fetchRoutesByCompanyUseCase(companyCnpj);
  }

  @override
  Future<RouteModel?> getRouteById(int routeId) {
    return _getRouteByIdUseCase(routeId);
  }

  @override
  Future<RouteModel> createRoute(RouteModel route, {File? imageFile}) {
    return _createRouteUseCase(route, imageFile: imageFile);
  }

  @override
  Future<RouteModel> updateRoute(RouteModel route, {File? imageFile}) {
    return _updateRouteUseCase(route, imageFile: imageFile);
  }

  @override
  Future<String> updateRouteImage(int routeId, File imageFile) {
    return _updateRouteImageUseCase(routeId, imageFile);
  }

  @override
  Future<void> deleteRoute(int routeId) {
    return _deleteRouteUseCase(routeId);
  }

  // ===========================================================================
  //   ENTRADA, APROVAÇÃO E VISUALIZAÇÃO DE MEMBROS DA ROTA
  // ===========================================================================

  @override
  Future<void> requestToJoinRoute(int routeId, String userId) {
    return _requestToJoinRouteUseCase(routeId, userId);
  }

  @override
  Future<void> cancelJoinRequest(int routeId, String userId) {
    return _cancelJoinRequestUseCase(routeId, userId);
  }

  @override
  Future<void> approvePassengerInRoute(int routeId, String userId) {
    return _approvePassengerInRouteUseCase(routeId, userId);
  }

  @override
  Future<void> removePassengerFromRoute(int routeId, String userId) {
    return _removePassengerFromRouteUseCase(routeId, userId);
  }

  @override
  Future<List<UserModel>> fetchUsersByIds(List<String> userIds) {
    return _fetchRouteUsersByIdsUseCase(userIds);
  }

  // ===========================================================================
  //   OPERAÇÃO DA ROTA (MOTORISTA E EMBARQUE DE PASSAGEIROS)
  // ===========================================================================

  @override
  Future<void> assignDriverToRoute(int routeId, String? driverId) {
    return _assignDriverToRouteUseCase(routeId, driverId);
  }

  @override
  Future<void> togglePassengerPresence(
    int routeId,
    String userId,
    bool isPresent,
  ) {
    return _togglePassengerPresenceUseCase(routeId, userId, isPresent);
  }

  @override
  Future<RouteModel> startRouteTrip(int routeId, String driverId) {
    return _startRouteTripUseCase(routeId, driverId);
  }

  @override
  Future<RouteModel> finishRouteTrip(int routeId) {
    return _finishRouteTripUseCase(routeId);
  }
}