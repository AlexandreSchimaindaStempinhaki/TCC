import 'dart:io';
import '../../models/route_entity.dart';
import '../../models/user_entity.dart';

// ===========================================================================
//   CRUD DE ROTAS
// ===========================================================================

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

// ===========================================================================
//   ENTRADA, APROVAÇÃO E VISUALIZAÇÃO DE MEMBROS DA ROTA
// ===========================================================================

abstract class IRequestToJoinRouteUseCase {
  Future<void> call(int routeId, String userId);
}

abstract class ICancelJoinRequestUseCase {
  Future<void> call(int routeId, String userId);
}

abstract class IApprovePassengerInRouteUseCase {
  Future<void> call(int routeId, String userId);
}

abstract class IRemovePassengerFromRouteUseCase {
  Future<void> call(int routeId, String userId);
}

abstract class IFetchRouteUsersByIdsUseCase {
  Future<List<UserModel>> call(List<String> userIds);
}

// ===========================================================================
//   OPERAÇÃO DA ROTA (MOTORISTA E EMBARQUE DE PASSAGEIROS)
// ===========================================================================

abstract class IAssignDriverToRouteUseCase {
  Future<void> call(int routeId, String? driverId);
}

abstract class ITogglePassengerPresenceUseCase {
  Future<void> call(int routeId, String userId, bool isPresent);
}

abstract class IStartRouteTripUseCase {
  Future<RouteModel> call(int routeId, String driverId);
}

abstract class IFinishRouteTripUseCase {
  Future<RouteModel> call(int routeId);
}