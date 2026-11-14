import 'dart:io';
import '../../models/route_entity.dart';

abstract class IFetchAllRoutesUseCase {
  Future<List<RouteModel>> call();
}

abstract class IFetchRoutesByCompanyUseCase {
  Future<List<RouteModel>> call(String companyCnpj);
}

abstract class IGetRouteByIdUseCase {
  Future<RouteModel?> call(int routeId);
}

abstract class ICreateRouteUseCase {
  Future<RouteModel> call(RouteModel route, {File? imageFile});
}

abstract class IUpdateRouteUseCase {
  Future<RouteModel> call(RouteModel route, {File? imageFile});
}

abstract class IUpdateRouteImageUseCase {
  Future<String> call(int routeId, File imageFile);
}

abstract class IDeleteRouteUseCase {
  Future<void> call(int routeId);
}