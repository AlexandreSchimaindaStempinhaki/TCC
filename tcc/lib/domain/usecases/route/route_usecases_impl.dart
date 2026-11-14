import 'dart:io';
import '../../models/route_entity.dart';
import '../../../data/repositories/route/i_route_repository.dart';
import 'i_route_usecases.dart';

class FetchAllRoutesUseCaseImpl implements IFetchAllRoutesUseCase {
  final IRouteRepository _repository;

  FetchAllRoutesUseCaseImpl(this._repository);

  @override
  Future<List<RouteModel>> call() {
    return _repository.fetchAllRoutes();
  }
}

class FetchRoutesByCompanyUseCaseImpl implements IFetchRoutesByCompanyUseCase {
  final IRouteRepository _repository;

  FetchRoutesByCompanyUseCaseImpl(this._repository);

  @override
  Future<List<RouteModel>> call(String companyCnpj) {
    if (companyCnpj.trim().isEmpty) {
      throw Exception('Company CNPJ is required to fetch routes.');
    }
    return _repository.fetchRoutesByCompany(companyCnpj);
  }
}

class GetRouteByIdUseCaseImpl implements IGetRouteByIdUseCase {
  final IRouteRepository _repository;

  GetRouteByIdUseCaseImpl(this._repository);

  @override
  Future<RouteModel?> call(int routeId) {
    return _repository.getRouteById(routeId);
  }
}

class CreateRouteUseCaseImpl implements ICreateRouteUseCase {
  final IRouteRepository _repository;

  CreateRouteUseCaseImpl(this._repository);

  @override
  Future<RouteModel> call(RouteModel route, {File? imageFile}) {
    if (route.companyCnpj.trim().isEmpty) {
      throw Exception('Invalid company CNPJ.');
    }
    if (route.schedules.isEmpty) {
      throw Exception('Add at least one departure schedule for the route.');
    }
    return _repository.createRoute(route, imageFile: imageFile);
  }
}

class UpdateRouteUseCaseImpl implements IUpdateRouteUseCase {
  final IRouteRepository _repository;

  UpdateRouteUseCaseImpl(this._repository);

  @override
  Future<RouteModel> call(RouteModel route, {File? imageFile}) {
    if (route.schedules.isEmpty) {
      throw Exception('The route must have at least one schedule.');
    }
    return _repository.updateRoute(route, imageFile: imageFile);
  }
}

class UpdateRouteImageUseCaseImpl implements IUpdateRouteImageUseCase {
  final IRouteRepository _repository;

  UpdateRouteImageUseCaseImpl(this._repository);

  @override
  Future<String> call(int routeId, File imageFile) {
    return _repository.updateRouteImage(routeId, imageFile);
  }
}

class DeleteRouteUseCaseImpl implements IDeleteRouteUseCase {
  final IRouteRepository _repository;

  DeleteRouteUseCaseImpl(this._repository);

  @override
  Future<void> call(int routeId) {
    return _repository.deleteRoute(routeId);
  }
}