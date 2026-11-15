import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/route_entity.dart';
import '../../commands/route_commands.dart';
import 'route_list_state_viewmodel.dart';

class RouteListCommands {
  final RouteListState state;
  final FetchAllRoutesCommand _fetchAllRoutesCommand;
  final FetchRoutesByCompanyCommand _fetchRoutesByCompanyCommand;
  final DeleteRouteCommand _deleteRouteCommand;
  final RequestToJoinRouteCommand _requestToJoinRouteCommand;
  final CancelJoinRequestCommand _cancelJoinRequestCommand;
  final ApprovePassengerInRouteCommand _approvePassengerInRouteCommand;
  final RemovePassengerFromRouteCommand _removePassengerFromRouteCommand;
  final TogglePassengerPresenceCommand _togglePassengerPresenceCommand;

  RouteListCommands({
    required this.state,
    required FetchAllRoutesCommand fetchAllRoutesCommand,
    required FetchRoutesByCompanyCommand fetchRoutesByCompanyCommand,
    required DeleteRouteCommand deleteRouteCommand,
    required RequestToJoinRouteCommand requestToJoinRouteCommand,
    required CancelJoinRequestCommand cancelJoinRequestCommand,
    required ApprovePassengerInRouteCommand approvePassengerInRouteCommand,
    required RemovePassengerFromRouteCommand removePassengerFromRouteCommand,
    required TogglePassengerPresenceCommand togglePassengerPresenceCommand,
  }) : _fetchAllRoutesCommand = fetchAllRoutesCommand,
       _fetchRoutesByCompanyCommand = fetchRoutesByCompanyCommand,
       _deleteRouteCommand = deleteRouteCommand,
       _requestToJoinRouteCommand = requestToJoinRouteCommand,
       _cancelJoinRequestCommand = cancelJoinRequestCommand,
       _approvePassengerInRouteCommand = approvePassengerInRouteCommand,
       _removePassengerFromRouteCommand = removePassengerFromRouteCommand,
       _togglePassengerPresenceCommand = togglePassengerPresenceCommand {
    _observeFetchAllRoutes();
    _observeFetchRoutesByCompany();
    _observeDeleteRoute();
    _observeRequestToJoinRoute();
    _observeCancelJoinRequest();
    _observeApprovePassengerInRoute();
    _observeRemovePassengerFromRoute();
    _observeTogglePassengerPresence();
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  FetchAllRoutesCommand get fetchAllRoutesCommand => _fetchAllRoutesCommand;
  FetchRoutesByCompanyCommand get fetchRoutesByCompanyCommand =>
      _fetchRoutesByCompanyCommand;
  DeleteRouteCommand get deleteRouteCommand => _deleteRouteCommand;
  RequestToJoinRouteCommand get requestToJoinRouteCommand =>
      _requestToJoinRouteCommand;
  CancelJoinRequestCommand get cancelJoinRequestCommand =>
      _cancelJoinRequestCommand;
  ApprovePassengerInRouteCommand get approvePassengerInRouteCommand =>
      _approvePassengerInRouteCommand;
  RemovePassengerFromRouteCommand get removePassengerFromRouteCommand =>
      _removePassengerFromRouteCommand;
  TogglePassengerPresenceCommand get togglePassengerPresenceCommand =>
      _togglePassengerPresenceCommand;

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<void> fetchAllRoutes() async {
    if (_fetchAllRoutesCommand.isExecuting.value) return;

    state.clearMessage();
    try {
      await _fetchAllRoutesCommand.execute();
    } catch (_) {}
  }

  Future<void> fetchRoutesByCompany(String companyCnpj) async {
    if (_fetchRoutesByCompanyCommand.isExecuting.value) return;

    state.clearMessage();
    try {
      await _fetchRoutesByCompanyCommand.execute(companyCnpj);
    } catch (_) {}
  }

  Future<bool> deleteRouteFromList(int routeId) async {
    if (_deleteRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _deleteRouteCommand.execute(routeId);
      state.removeRouteById(routeId);
      return true;
    } catch (_) {
      return false;
    }
  }

  RouteModel? _findRouteInLists(int routeId) {
    for (final r in state.routes.value) {
      if (r.id == routeId) return r;
    }
    for (final r in state.companyRoutes.value) {
      if (r.id == routeId) return r;
    }
    return null;
  }

  Future<bool> requestToJoinRoute(int routeId, String userId) async {
    if (_requestToJoinRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _requestToJoinRouteCommand.execute(routeId, userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelJoinRequest(int routeId, String userId) async {
    if (_cancelJoinRequestCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _cancelJoinRequestCommand.execute(routeId, userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> approvePassengerInRoute(int routeId, String userId) async {
    if (_approvePassengerInRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _approvePassengerInRouteCommand.execute(routeId, userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removePassengerFromRoute(int routeId, String userId) async {
    if (_removePassengerFromRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _removePassengerFromRouteCommand.execute(routeId, userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> togglePassengerPresence(
    int routeId,
    String userId,
    bool isPresent,
  ) async {
    if (_togglePassengerPresenceCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _togglePassengerPresenceCommand.execute(
        routeId,
        userId,
        isPresent,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ========================================================
  //   MÉTODO GENÉRICO DE OBSERVAÇÃO DE COMANDOS
  // ========================================================
  void _observeCommand<T>(
    RouteCommandSignalMixin<T> command, {
    required void Function(T data) onSuccess,
    void Function(String err)? onFailure,
  }) {
    effect(() {
      if (command.isExecuting.value) return;
      if (!command.hasResult.value) return;

      final err = command.error.value;
      final data = command.data.value;

      untracked(() {
        if (err != null) {
          state.setMessage(err);
          if (onFailure != null) onFailure(err);
        } else {
          state.clearMessage();
          onSuccess(data as T);
        }
      });
    });
  }

  // ========================================================
  //   OBSERVERS ESPECÍFICOS
  // ========================================================
  void _observeFetchAllRoutes() {
    _observeCommand<List<RouteModel>>(
      _fetchAllRoutesCommand,
      onSuccess: (routes) {
        state.setRoutes(routes);
      },
    );
  }

  void _observeFetchRoutesByCompany() {
    _observeCommand<List<RouteModel>>(
      _fetchRoutesByCompanyCommand,
      onSuccess: (routes) {
        state.setCompanyRoutes(routes);
      },
    );
  }

  void _observeDeleteRoute() {
    _observeCommand<void>(
      _deleteRouteCommand,
      onSuccess: (_) {
        state.clearMessage();
      },
    );
  }

  void _observeRequestToJoinRoute() {
    _observeCommand<void>(
      _requestToJoinRouteCommand,
      onSuccess: (_) {
        final routeId = _requestToJoinRouteCommand.lastRouteId;
        final userId = _requestToJoinRouteCommand.lastUserId;
        if (routeId == null || userId == null) return;
        final target = _findRouteInLists(routeId);
        if (target != null) {
          final updatedPending = <String>{
            ...target.pendingPassengerIds,
            userId,
          }.toList();
          state.upsertRoute(
            target.copyWith(pendingPassengerIds: updatedPending),
          );
        }
      },
    );
  }

  void _observeCancelJoinRequest() {
    _observeCommand<void>(
      _cancelJoinRequestCommand,
      onSuccess: (_) {
        final routeId = _cancelJoinRequestCommand.lastRouteId;
        final userId = _cancelJoinRequestCommand.lastUserId;
        if (routeId == null || userId == null) return;
        final target = _findRouteInLists(routeId);
        if (target != null) {
          final updatedPending = target.pendingPassengerIds
              .where((id) => id != userId)
              .toList();
          state.upsertRoute(
            target.copyWith(pendingPassengerIds: updatedPending),
          );
        }
      },
    );
  }

  void _observeApprovePassengerInRoute() {
    _observeCommand<void>(
      _approvePassengerInRouteCommand,
      onSuccess: (_) {
        final routeId = _approvePassengerInRouteCommand.lastRouteId;
        final userId = _approvePassengerInRouteCommand.lastUserId;
        if (routeId == null || userId == null) return;
        final target = _findRouteInLists(routeId);
        if (target != null) {
          final updatedPending = target.pendingPassengerIds
              .where((id) => id != userId)
              .toList();
          final updatedPassengers = <String>{
            ...target.passengerIds,
            userId,
          }.toList();
          state.upsertRoute(
            target.copyWith(
              pendingPassengerIds: updatedPending,
              passengerIds: updatedPassengers,
            ),
          );
        }
      },
    );
  }

  void _observeRemovePassengerFromRoute() {
    _observeCommand<void>(
      _removePassengerFromRouteCommand,
      onSuccess: (_) {
        final routeId = _removePassengerFromRouteCommand.lastRouteId;
        final userId = _removePassengerFromRouteCommand.lastUserId;
        if (routeId == null || userId == null) return;
        final target = _findRouteInLists(routeId);
        if (target != null) {
          state.upsertRoute(
            target.copyWith(
              pendingPassengerIds: target.pendingPassengerIds
                  .where((id) => id != userId)
                  .toList(),
              passengerIds: target.passengerIds
                  .where((id) => id != userId)
                  .toList(),
              confirmedPassengerIds: target.confirmedPassengerIds
                  .where((id) => id != userId)
                  .toList(),
            ),
          );
        }
      },
    );
  }

  void _observeTogglePassengerPresence() {
    _observeCommand<void>(
      _togglePassengerPresenceCommand,
      onSuccess: (_) {
        final routeId = _togglePassengerPresenceCommand.lastRouteId;
        final userId = _togglePassengerPresenceCommand.lastUserId;
        final isPresent = _togglePassengerPresenceCommand.lastIsPresent;
        if (routeId == null || userId == null || isPresent == null) return;
        final target = _findRouteInLists(routeId);
        if (target != null) {
          final updatedConfirmed = isPresent
              ? <String>{...target.confirmedPassengerIds, userId}.toList()
              : target.confirmedPassengerIds
                    .where((id) => id != userId)
                    .toList();
          state.upsertRoute(
            target.copyWith(confirmedPassengerIds: updatedConfirmed),
          );
        }
      },
    );
  }
}