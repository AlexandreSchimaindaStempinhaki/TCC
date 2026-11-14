import 'dart:io';
import '../../models/route_entity.dart';
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

  RouteUseCaseFacadeImpl(
    this._fetchAllRoutesUseCase,
    this._fetchRoutesByCompanyUseCase,
    this._getRouteByIdUseCase,
    this._createRouteUseCase,
    this._updateRouteUseCase,
    this._updateRouteImageUseCase,
    this._deleteRouteUseCase,
  );

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
}