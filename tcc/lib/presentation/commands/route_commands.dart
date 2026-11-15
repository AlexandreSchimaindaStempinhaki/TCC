import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/route/i_route_facade.dart';
import '../../../domain/models/route_entity.dart';
import '../../../domain/models/user_entity.dart';

mixin RouteCommandSignalMixin<T> {
  final isExecuting = signal(false);
  final data = signal<T?>(null);
  final error = signal<String?>(null);
  final hasResult = signal(false);

  Future<T> runAction(Future<T> Function() action) async {
    isExecuting.value = true;
    error.value = null;
    hasResult.value = false;
    try {
      final result = await action();
      data.value = result;
      hasResult.value = true;
      return result;
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
      hasResult.value = true;
      rethrow;
    } finally {
      isExecuting.value = false;
    }
  }
}

// ===========================================================================
//   CRUD DE ROTAS
// ===========================================================================

class FetchAllRoutesCommand with RouteCommandSignalMixin<List<RouteModel>> {
  final IRouteUseCaseFacade _facade;

  FetchAllRoutesCommand(this._facade);

  Future<List<RouteModel>> execute() => runAction(_facade.fetchAllRoutes);
}

class FetchRoutesByCompanyCommand
    with RouteCommandSignalMixin<List<RouteModel>> {
  final IRouteUseCaseFacade _facade;

  FetchRoutesByCompanyCommand(this._facade);

  Future<List<RouteModel>> execute(String companyCnpj) =>
      runAction(() => _facade.fetchRoutesByCompany(companyCnpj));
}

class GetRouteByIdCommand with RouteCommandSignalMixin<RouteModel?> {
  final IRouteUseCaseFacade _facade;

  GetRouteByIdCommand(this._facade);

  Future<RouteModel?> execute(int routeId) =>
      runAction(() => _facade.getRouteById(routeId));
}

class CreateRouteCommand with RouteCommandSignalMixin<RouteModel> {
  final IRouteUseCaseFacade _facade;

  CreateRouteCommand(this._facade);

  Future<RouteModel> execute(RouteModel route, {File? imageFile}) =>
      runAction(() => _facade.createRoute(route, imageFile: imageFile));
}

class UpdateRouteCommand with RouteCommandSignalMixin<RouteModel> {
  final IRouteUseCaseFacade _facade;

  UpdateRouteCommand(this._facade);

  Future<RouteModel> execute(RouteModel route, {File? imageFile}) =>
      runAction(() => _facade.updateRoute(route, imageFile: imageFile));
}

class UpdateRouteImageCommand with RouteCommandSignalMixin<String> {
  final IRouteUseCaseFacade _facade;

  UpdateRouteImageCommand(this._facade);

  Future<String> execute(int routeId, File imageFile) =>
      runAction(() => _facade.updateRouteImage(routeId, imageFile));
}

class DeleteRouteCommand with RouteCommandSignalMixin<void> {
  final IRouteUseCaseFacade _facade;

  DeleteRouteCommand(this._facade);

  Future<void> execute(int routeId) =>
      runAction(() => _facade.deleteRoute(routeId));
}

// ===========================================================================
//   ENTRADA, APROVAÇÃO E VISUALIZAÇÃO DE MEMBROS DA ROTA
// ===========================================================================

class RequestToJoinRouteCommand with RouteCommandSignalMixin<void> {
  final IRouteUseCaseFacade _facade;
  int? lastRouteId;
  String? lastUserId;

  RequestToJoinRouteCommand(this._facade);

  Future<void> execute(int routeId, String userId) {
    lastRouteId = routeId;
    lastUserId = userId;
    return runAction(() => _facade.requestToJoinRoute(routeId, userId));
  }
}

class CancelJoinRequestCommand with RouteCommandSignalMixin<void> {
  final IRouteUseCaseFacade _facade;
  int? lastRouteId;
  String? lastUserId;

  CancelJoinRequestCommand(this._facade);

  Future<void> execute(int routeId, String userId) {
    lastRouteId = routeId;
    lastUserId = userId;
    return runAction(() => _facade.cancelJoinRequest(routeId, userId));
  }
}

class ApprovePassengerInRouteCommand with RouteCommandSignalMixin<void> {
  final IRouteUseCaseFacade _facade;
  int? lastRouteId;
  String? lastUserId;

  ApprovePassengerInRouteCommand(this._facade);

  Future<void> execute(int routeId, String userId) {
    lastRouteId = routeId;
    lastUserId = userId;
    return runAction(() => _facade.approvePassengerInRoute(routeId, userId));
  }
}

class RemovePassengerFromRouteCommand with RouteCommandSignalMixin<void> {
  final IRouteUseCaseFacade _facade;
  int? lastRouteId;
  String? lastUserId;

  RemovePassengerFromRouteCommand(this._facade);

  Future<void> execute(int routeId, String userId) {
    lastRouteId = routeId;
    lastUserId = userId;
    return runAction(() => _facade.removePassengerFromRoute(routeId, userId));
  }
}

class FetchRouteUsersByIdsCommand with RouteCommandSignalMixin<List<UserModel>> {
  final IRouteUseCaseFacade _facade;

  FetchRouteUsersByIdsCommand(this._facade);

  Future<List<UserModel>> execute(List<String> userIds) =>
      runAction(() => _facade.fetchUsersByIds(userIds));
}

// ===========================================================================
//   OPERAÇÃO DA ROTA (MOTORISTA E EMBARQUE DE PASSAGEIROS)
// ===========================================================================

class AssignDriverToRouteCommand with RouteCommandSignalMixin<void> {
  final IRouteUseCaseFacade _facade;
  int? lastRouteId;
  String? lastDriverId;

  AssignDriverToRouteCommand(this._facade);

  Future<void> execute(int routeId, String? driverId) {
    lastRouteId = routeId;
    lastDriverId = driverId;
    return runAction(() => _facade.assignDriverToRoute(routeId, driverId));
  }
}

class TogglePassengerPresenceCommand with RouteCommandSignalMixin<void> {
  final IRouteUseCaseFacade _facade;
  int? lastRouteId;
  String? lastUserId;
  bool? lastIsPresent;

  TogglePassengerPresenceCommand(this._facade);

  Future<void> execute(int routeId, String userId, bool isPresent) {
    lastRouteId = routeId;
    lastUserId = userId;
    lastIsPresent = isPresent;
    return runAction(
      () => _facade.togglePassengerPresence(routeId, userId, isPresent),
    );
  }
}

class StartRouteTripCommand with RouteCommandSignalMixin<RouteModel> {
  final IRouteUseCaseFacade _facade;

  StartRouteTripCommand(this._facade);

  Future<RouteModel> execute(int routeId, String driverId) =>
      runAction(() => _facade.startRouteTrip(routeId, driverId));
}

class FinishRouteTripCommand with RouteCommandSignalMixin<RouteModel> {
  final IRouteUseCaseFacade _facade;

  FinishRouteTripCommand(this._facade);

  Future<RouteModel> execute(int routeId) =>
      runAction(() => _facade.finishRouteTrip(routeId));
}