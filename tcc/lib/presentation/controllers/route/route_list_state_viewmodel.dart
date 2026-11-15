import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/route_entity.dart';

class RouteListState {
  final routes = signal<List<RouteModel>>([]);
  final companyRoutes = signal<List<RouteModel>>([]);
  final favoriteRouteIds = signal<Set<int>>({});

  final message = signal<String?>(null);

  bool get hasRoutes => routes.value.isNotEmpty;
  bool get hasCompanyRoutes => companyRoutes.value.isNotEmpty;

  // ========================================================
  //   CONSULTAS REATIVAS DO PASSAGEIRO E MOTORISTA
  // ========================================================

  bool isFavorite(int routeId) => favoriteRouteIds.value.contains(routeId);

  List<RouteModel> get favoriteRoutes =>
      routes.value.where((r) => favoriteRouteIds.value.contains(r.id)).toList();

  List<RouteModel> getPendingRoutesForUser(String userId) =>
      routes.value.where((r) => r.pendingPassengerIds.contains(userId)).toList();

  List<RouteModel> getJoinedRoutesForUser(String userId) =>
      routes.value.where((r) => r.passengerIds.contains(userId)).toList();

  List<RouteModel> getDriverRoutesForUser(String driverId) =>
      routes.value.where((r) => r.isUserDriver(driverId)).toList();

  // ========================================================
  //   MUTAÇÕES EM TEMPO DE EXECUÇÃO
  // ========================================================

  void setRoutes(List<RouteModel> list) {
    routes.value = List<RouteModel>.from(list);
    message.value = null;
  }

  void setCompanyRoutes(List<RouteModel> list) {
    companyRoutes.value = List<RouteModel>.from(list);
    message.value = null;
  }

  void setFavoriteRouteIds(Iterable<int> ids) {
    favoriteRouteIds.value = Set<int>.from(ids);
  }

  void upsertRoute(RouteModel route) {
    final currentCompany = List<RouteModel>.from(companyRoutes.value);
    final companyIndex = currentCompany.indexWhere((r) => r.id == route.id);
    if (companyIndex >= 0) {
      currentCompany[companyIndex] = route;
    } else {
      currentCompany.add(route);
    }
    companyRoutes.value = currentCompany;

    final currentAll = List<RouteModel>.from(routes.value);
    final allIndex = currentAll.indexWhere((r) => r.id == route.id);
    if (allIndex >= 0) {
      currentAll[allIndex] = route;
    } else {
      currentAll.add(route);
    }
    routes.value = currentAll;
  }

  void removeRouteById(int routeId) {
    companyRoutes.value =
        companyRoutes.value.where((r) => r.id != routeId).toList();
    routes.value = routes.value.where((r) => r.id != routeId).toList();
  }

  void toggleFavorite(int routeId) {
    final updated = Set<int>.from(favoriteRouteIds.value);
    if (updated.contains(routeId)) {
      updated.remove(routeId);
    } else {
      updated.add(routeId);
    }
    favoriteRouteIds.value = updated;
  }

  void clearRoutes() {
    routes.value = [];
    companyRoutes.value = [];
    message.value = null;
  }

  void clearMessage() => message.value = null;

  void setMessage(String msg) => message.value = msg;
}