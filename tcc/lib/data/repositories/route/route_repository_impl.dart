import 'dart:io';
import '../../../domain/models/route_entity.dart';
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
}