import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/route_entity.dart';

class RouteListState {
  static const String _favoritesPrefsKey = 'indigo_favorite_route_ids';

  final routes = signal<List<RouteModel>>([]);
  final companyRoutes = signal<List<RouteModel>>([]);
  final favoriteRouteIds = signal<Set<int>>({});

  final message = signal<String?>(null);

  RouteListState() {
    _loadFavoritesFromStorage();
  }

  bool get hasRoutes => routes.value.isNotEmpty;
  bool get hasCompanyRoutes => companyRoutes.value.isNotEmpty;

  // ========================================================
  //   PERSISTÊNCIA LOCAL DE FAVORITOS (SHARED PREFERENCES)
  // ========================================================
  Future<void> _loadFavoritesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_favoritesPrefsKey) ?? [];
      final parsedIds = savedList
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .toSet();
      favoriteRouteIds.value = parsedIds;
    } catch (_) {}
  }

  Future<void> _saveFavoritesToStorage(Set<int> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favoritesPrefsKey,
        ids.map((id) => id.toString()).toList(),
      );
    } catch (_) {}
  }

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
    final updated = Set<int>.from(ids);
    favoriteRouteIds.value = updated;
    _saveFavoritesToStorage(updated);
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
    _saveFavoritesToStorage(updated);
  }

  void clearRoutes() {
    routes.value = [];
    companyRoutes.value = [];
    message.value = null;
  }

  void clearMessage() => message.value = null;

  void setMessage(String msg) => message.value = msg;
}