import 'dart:io';
import '../../models/route_entity.dart';
import '../../models/user_entity.dart';

abstract class IRouteUseCaseFacade {
  Future<List<RouteModel>> fetchAllRoutes();
  Future<List<RouteModel>> fetchRoutesByCompany(String companyCnpj);
  Future<RouteModel?> getRouteById(int routeId);
  Future<RouteModel> createRoute(RouteModel route, {File? imageFile});
  Future<RouteModel> updateRoute(RouteModel route, {File? imageFile});
  Future<String> updateRouteImage(int routeId, File imageFile);
  Future<void> deleteRoute(int routeId);

  Future<void> requestToJoinRoute(int routeId, String userId);
  Future<void> cancelJoinRequest(int routeId, String userId);
  Future<void> approvePassengerInRoute(int routeId, String userId);
  Future<void> removePassengerFromRoute(int routeId, String userId);
  Future<List<UserModel>> fetchUsersByIds(List<String> userIds);

  Future<void> assignDriverToRoute(int routeId, String? driverId);
  Future<void> togglePassengerPresence(
    int routeId,
    String userId,
    bool isPresent,
  );
  Future<RouteModel> startRouteTrip(int routeId, String driverId);
  Future<RouteModel> finishRouteTrip(int routeId);
}