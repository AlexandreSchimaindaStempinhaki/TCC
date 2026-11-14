import 'dart:io';
import '../../../domain/models/route_entity.dart';

abstract class IRouteRemoteService {
  Future<List<RouteModel>> fetchAllRoutes();
  Future<List<RouteModel>> fetchRoutesByCompany(String companyCnpj);
  Future<RouteModel?> getRouteById(int routeId);
  Future<RouteModel> createRoute(RouteModel route, {File? imageFile});
  Future<RouteModel> updateRoute(RouteModel route, {File? imageFile});
  Future<String> updateRouteImage(int routeId, File imageFile);
  Future<void> deleteRoute(int routeId);
}