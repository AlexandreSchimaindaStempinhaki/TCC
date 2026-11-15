import 'dart:io';
import '../../models/route_entity.dart';
import '../../models/user_entity.dart';
import '../../../data/repositories/route/i_route_repository.dart';
import 'i_route_usecases.dart';

// ===========================================================================
//   CRUD DE ROTAS
// ===========================================================================

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

// ===========================================================================
//   ENTRADA, APROVAÇÃO E VISUALIZAÇÃO DE MEMBROS DA ROTA
// ===========================================================================

class RequestToJoinRouteUseCaseImpl implements IRequestToJoinRouteUseCase {
  final IRouteRepository _repository;

  RequestToJoinRouteUseCaseImpl(this._repository);

  @override
  Future<void> call(int routeId, String userId) {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required to request joining a route.');
    }
    return _repository.requestToJoinRoute(routeId, userId);
  }
}

class CancelJoinRequestUseCaseImpl implements ICancelJoinRequestUseCase {
  final IRouteRepository _repository;

  CancelJoinRequestUseCaseImpl(this._repository);

  @override
  Future<void> call(int routeId, String userId) {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required to cancel the request.');
    }
    return _repository.cancelJoinRequest(routeId, userId);
  }
}

class ApprovePassengerInRouteUseCaseImpl
    implements IApprovePassengerInRouteUseCase {
  final IRouteRepository _repository;

  ApprovePassengerInRouteUseCaseImpl(this._repository);

  @override
  Future<void> call(int routeId, String userId) {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required to approve passenger.');
    }
    return _repository.approvePassengerInRoute(routeId, userId);
  }
}

class RemovePassengerFromRouteUseCaseImpl
    implements IRemovePassengerFromRouteUseCase {
  final IRouteRepository _repository;

  RemovePassengerFromRouteUseCaseImpl(this._repository);

  @override
  Future<void> call(int routeId, String userId) {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required to remove passenger.');
    }
    return _repository.removePassengerFromRoute(routeId, userId);
  }
}

class FetchRouteUsersByIdsUseCaseImpl implements IFetchRouteUsersByIdsUseCase {
  final IRouteRepository _repository;

  FetchRouteUsersByIdsUseCaseImpl(this._repository);

  @override
  Future<List<UserModel>> call(List<String> userIds) {
    if (userIds.isEmpty) return Future.value([]);
    return _repository.fetchUsersByIds(userIds);
  }
}

// ===========================================================================
//   OPERAÇÃO DA ROTA (MOTORISTA E EMBARQUE DE PASSAGEIROS)
// ===========================================================================

class AssignDriverToRouteUseCaseImpl implements IAssignDriverToRouteUseCase {
  final IRouteRepository _repository;

  AssignDriverToRouteUseCaseImpl(this._repository);

  @override
  Future<void> call(int routeId, String? driverId) {
    return _repository.assignDriverToRoute(routeId, driverId);
  }
}

class TogglePassengerPresenceUseCaseImpl
    implements ITogglePassengerPresenceUseCase {
  final IRouteRepository _repository;

  TogglePassengerPresenceUseCaseImpl(this._repository);

  @override
  Future<void> call(int routeId, String userId, bool isPresent) {
    if (userId.trim().isEmpty) {
      throw Exception('User ID is required to confirm presence.');
    }
    return _repository.togglePassengerPresence(routeId, userId, isPresent);
  }
}

class StartRouteTripUseCaseImpl implements IStartRouteTripUseCase {
  final IRouteRepository _repository;

  StartRouteTripUseCaseImpl(this._repository);

  @override
  Future<RouteModel> call(int routeId, String driverId) {
    if (driverId.trim().isEmpty) {
      throw Exception('Driver ID is required to start the trip.');
    }
    return _repository.startRouteTrip(routeId, driverId);
  }
}

class FinishRouteTripUseCaseImpl implements IFinishRouteTripUseCase {
  final IRouteRepository _repository;

  FinishRouteTripUseCaseImpl(this._repository);

  @override
  Future<RouteModel> call(int routeId) {
    return _repository.finishRouteTrip(routeId);
  }
}