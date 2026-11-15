import 'dart:io';
import '../../../domain/models/route_entity.dart';
import '../../../domain/models/user_entity.dart';
import 'i_route_repository.dart';
import '../../services/route/i_route_service.dart';

class RouteRepositoryImpl implements IRouteRepository {
  final IRouteRemoteService _service;

  RouteRepositoryImpl(this._service);

  @override
  Future<List<RouteModel>> fetchAllRoutes() {
    return _service.fetchAllRoutes();
  }

  @override
  Future<List<RouteModel>> fetchRoutesByCompany(String companyCnpj) {
    return _service.fetchRoutesByCompany(companyCnpj);
  }

  @override
  Future<RouteModel?> getRouteById(int routeId) {
    return _service.getRouteById(routeId);
  }

  @override
  Future<RouteModel> createRoute(RouteModel route, {File? imageFile}) {
    return _service.createRoute(route, imageFile: imageFile);
  }

  @override
  Future<RouteModel> updateRoute(RouteModel route, {File? imageFile}) {
    return _service.updateRoute(route, imageFile: imageFile);
  }

  @override
  Future<String> updateRouteImage(int routeId, File imageFile) {
    return _service.updateRouteImage(routeId, imageFile);
  }

  @override
  Future<void> deleteRoute(int routeId) {
    return _service.deleteRoute(routeId);
  }

  // ===========================================================================
  //   ENTRADA, APROVAÇÃO E VISUALIZAÇÃO DE MEMBROS DA ROTA
  // ===========================================================================

  @override
  Future<void> requestToJoinRoute(int routeId, String userId) {
    return _service.requestToJoinRoute(routeId, userId);
  }

  @override
  Future<void> cancelJoinRequest(int routeId, String userId) {
    return _service.cancelJoinRequest(routeId, userId);
  }

  @override
  Future<void> approvePassengerInRoute(int routeId, String userId) {
    return _service.approvePassengerInRoute(routeId, userId);
  }

  @override
  Future<void> removePassengerFromRoute(int routeId, String userId) {
    return _service.removePassengerFromRoute(routeId, userId);
  }

  @override
  Future<List<UserModel>> fetchUsersByIds(List<String> userIds) {
    return _service.fetchUsersByIds(userIds);
  }

  // ===========================================================================
  //   OPERAÇÃO DA ROTA (MOTORISTA E EMBARQUE DE PASSAGEIROS)
  // ===========================================================================

  @override
  Future<void> assignDriverToRoute(int routeId, String? driverId) {
    return _service.assignDriverToRoute(routeId, driverId);
  }

  @override
  Future<void> togglePassengerPresence(
    int routeId,
    String userId,
    bool isPresent,
  ) {
    return _service.togglePassengerPresence(routeId, userId, isPresent);
  }

  @override
  Future<RouteModel> startRouteTrip(int routeId, String driverId) {
    return _service.startRouteTrip(routeId, driverId);
  }

  @override
  Future<RouteModel> finishRouteTrip(int routeId) {
    return _service.finishRouteTrip(routeId);
  }
}