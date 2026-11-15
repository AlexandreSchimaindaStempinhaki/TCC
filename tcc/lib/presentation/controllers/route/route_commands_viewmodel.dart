import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/route_entity.dart';
import '../../commands/route_commands.dart';
import 'route_state_viewmodel.dart';

class RouteCommands {
  final RouteState state;
  final GetRouteByIdCommand _getRouteByIdCommand;
  final CreateRouteCommand _createRouteCommand;
  final UpdateRouteCommand _updateRouteCommand;
  final UpdateRouteImageCommand _updateRouteImageCommand;
  final DeleteRouteCommand _deleteRouteCommand;

  final RequestToJoinRouteCommand _requestToJoinRouteCommand;
  final CancelJoinRequestCommand _cancelJoinRequestCommand;
  final ApprovePassengerInRouteCommand _approvePassengerInRouteCommand;
  final RemovePassengerFromRouteCommand _removePassengerFromRouteCommand;
  final FetchRouteUsersByIdsCommand _fetchRouteUsersByIdsCommand;

  final AssignDriverToRouteCommand _assignDriverToRouteCommand;
  final TogglePassengerPresenceCommand _togglePassengerPresenceCommand;
  final StartRouteTripCommand _startRouteTripCommand;
  final FinishRouteTripCommand _finishRouteTripCommand;

  RouteCommands({
    required this.state,
    required GetRouteByIdCommand getRouteByIdCommand,
    required CreateRouteCommand createRouteCommand,
    required UpdateRouteCommand updateRouteCommand,
    required UpdateRouteImageCommand updateRouteImageCommand,
    required DeleteRouteCommand deleteRouteCommand,
    required RequestToJoinRouteCommand requestToJoinRouteCommand,
    required CancelJoinRequestCommand cancelJoinRequestCommand,
    required ApprovePassengerInRouteCommand approvePassengerInRouteCommand,
    required RemovePassengerFromRouteCommand removePassengerFromRouteCommand,
    required FetchRouteUsersByIdsCommand fetchRouteUsersByIdsCommand,
    required AssignDriverToRouteCommand assignDriverToRouteCommand,
    required TogglePassengerPresenceCommand togglePassengerPresenceCommand,
    required StartRouteTripCommand startRouteTripCommand,
    required FinishRouteTripCommand finishRouteTripCommand,
  }) : _getRouteByIdCommand = getRouteByIdCommand,
       _createRouteCommand = createRouteCommand,
       _updateRouteCommand = updateRouteCommand,
       _updateRouteImageCommand = updateRouteImageCommand,
       _deleteRouteCommand = deleteRouteCommand,
       _requestToJoinRouteCommand = requestToJoinRouteCommand,
       _cancelJoinRequestCommand = cancelJoinRequestCommand,
       _approvePassengerInRouteCommand = approvePassengerInRouteCommand,
       _removePassengerFromRouteCommand = removePassengerFromRouteCommand,
       _fetchRouteUsersByIdsCommand = fetchRouteUsersByIdsCommand,
       _assignDriverToRouteCommand = assignDriverToRouteCommand,
       _togglePassengerPresenceCommand = togglePassengerPresenceCommand,
       _startRouteTripCommand = startRouteTripCommand,
       _finishRouteTripCommand = finishRouteTripCommand {
    _observeGetRouteById();
    _observeCreateRoute();
    _observeUpdateRoute();
    _observeUpdateRouteImage();
    _observeDeleteRoute();
    _observeRequestToJoinRoute();
    _observeCancelJoinRequest();
    _observeApprovePassengerInRoute();
    _observeRemovePassengerFromRoute();
    _observeAssignDriverToRoute();
    _observeTogglePassengerPresence();
    _observeStartRouteTrip();
    _observeFinishRouteTrip();
  }

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  bool _matchesUserId(String rawId, String? userCpf, String? userEmail) {
    final cpf = userCpf ?? '';
    final email = userEmail ?? '';
    final cleanRaw = _cleanDigits(rawId);
    final cleanCpf = _cleanDigits(cpf);
    if (cleanRaw.isNotEmpty && cleanRaw == cleanCpf) return true;
    return rawId.trim().toLowerCase() == email.trim().toLowerCase() ||
        (cpf.isNotEmpty && rawId.trim() == cpf.trim());
  }

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  GetRouteByIdCommand get getRouteByIdCommand => _getRouteByIdCommand;
  CreateRouteCommand get createRouteCommand => _createRouteCommand;
  UpdateRouteCommand get updateRouteCommand => _updateRouteCommand;
  UpdateRouteImageCommand get updateRouteImageCommand =>
      _updateRouteImageCommand;
  DeleteRouteCommand get deleteRouteCommand => _deleteRouteCommand;

  RequestToJoinRouteCommand get requestToJoinRouteCommand =>
      _requestToJoinRouteCommand;
  CancelJoinRequestCommand get cancelJoinRequestCommand =>
      _cancelJoinRequestCommand;
  ApprovePassengerInRouteCommand get approvePassengerInRouteCommand =>
      _approvePassengerInRouteCommand;
  RemovePassengerFromRouteCommand get removePassengerFromRouteCommand =>
      _removePassengerFromRouteCommand;
  FetchRouteUsersByIdsCommand get fetchRouteUsersByIdsCommand =>
      _fetchRouteUsersByIdsCommand;

  AssignDriverToRouteCommand get assignDriverToRouteCommand =>
      _assignDriverToRouteCommand;
  TogglePassengerPresenceCommand get togglePassengerPresenceCommand =>
      _togglePassengerPresenceCommand;
  StartRouteTripCommand get startRouteTripCommand => _startRouteTripCommand;
  FinishRouteTripCommand get finishRouteTripCommand => _finishRouteTripCommand;

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<RouteModel?> fetchRouteById(
    int routeId, {
    bool loadMembers = true,
  }) async {
    if (_getRouteByIdCommand.isExecuting.value) return state.route.value;

    state.clearMessage();
    try {
      final fetched = await _getRouteByIdCommand.execute(routeId);
      if (fetched != null && loadMembers) {
        await loadRouteMembersDetails(fetched);
      }
      return fetched;
    } catch (_) {
      return null;
    }
  }

  Future<bool> createRoute(RouteModel route, {File? imageFile}) async {
    if (_createRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _createRouteCommand.execute(route, imageFile: imageFile);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateRoute(RouteModel route, {File? imageFile}) async {
    if (_updateRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _updateRouteCommand.execute(route, imageFile: imageFile);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateRouteImage(int routeId, File imageFile) async {
    if (_updateRouteImageCommand.isExecuting.value) return;

    state.clearMessage();
    try {
      await _updateRouteImageCommand.execute(routeId, imageFile);
    } catch (_) {}
  }

  Future<bool> deleteRoute(int routeId) async {
    if (_deleteRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _deleteRouteCommand.execute(routeId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadRouteMembersDetails([RouteModel? targetRoute]) async {
    final current = targetRoute ?? state.route.value;
    if (current == null) return;

    try {
      if (current.passengerIds.isNotEmpty) {
        final approvedUsers = await _fetchRouteUsersByIdsCommand.execute(
          current.passengerIds,
        );
        state.setPassengers(approvedUsers);

        state.setConfirmedPassengers(
          approvedUsers
              .where(
                (u) => current.confirmedPassengerIds.any(
                  (id) => _matchesUserId(id, u.cpf, u.email),
                ),
              )
              .toList(),
        );
      } else {
        state.setPassengers([]);
        state.setConfirmedPassengers([]);
      }

      if (current.pendingPassengerIds.isNotEmpty) {
        final pendingUsers = await _fetchRouteUsersByIdsCommand.execute(
          current.pendingPassengerIds,
        );
        state.setPendingPassengers(pendingUsers);
      } else {
        state.setPendingPassengers([]);
      }

      if (current.driverId != null && current.driverId!.trim().isNotEmpty) {
        final drivers = await _fetchRouteUsersByIdsCommand.execute([
          current.driverId!,
        ]);
        state.setDriver(drivers.isNotEmpty ? drivers.first : null);
      } else {
        state.setDriver(null);
      }
    } catch (_) {}
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

  Future<bool> assignDriverToRoute(int routeId, String? driverId) async {
    if (_assignDriverToRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _assignDriverToRouteCommand.execute(routeId, driverId);
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
      await _togglePassengerPresenceCommand.execute(routeId, userId, isPresent);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startRouteTrip(int routeId, String driverId) async {
    if (_startRouteTripCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _startRouteTripCommand.execute(routeId, driverId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> finishRouteTrip(int routeId) async {
    if (_finishRouteTripCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _finishRouteTripCommand.execute(routeId);
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
  void _observeGetRouteById() {
    _observeCommand<RouteModel?>(
      _getRouteByIdCommand,
      onSuccess: (route) {
        state.setRoute(route);
      },
    );
  }

  void _observeCreateRoute() {
    _observeCommand<RouteModel>(
      _createRouteCommand,
      onSuccess: (createdRoute) {
        state.setRoute(createdRoute);
      },
    );
  }

  void _observeUpdateRoute() {
    _observeCommand<RouteModel>(
      _updateRouteCommand,
      onSuccess: (updatedRoute) {
        state.setRoute(updatedRoute);
      },
    );
  }

  void _observeUpdateRouteImage() {
    _observeCommand<String>(
      _updateRouteImageCommand,
      onSuccess: (imageUrl) {
        final currentRoute = state.route.value;
        if (currentRoute != null) {
          state.setRoute(currentRoute.copyWith(imageUrl: imageUrl));
        }
      },
    );
  }

  void _observeDeleteRoute() {
    _observeCommand<void>(
      _deleteRouteCommand,
      onSuccess: (_) {
        state.clearRoute();
      },
    );
  }

  void _observeRequestToJoinRoute() {
    _observeCommand<void>(
      _requestToJoinRouteCommand,
      onSuccess: (_) {
        final routeId = _requestToJoinRouteCommand.lastRouteId;
        final userId = _requestToJoinRouteCommand.lastUserId;
        final current = state.route.value;
        if (current != null &&
            routeId != null &&
            userId != null &&
            current.id == routeId) {
          final updatedRoute = current.copyWith(
            pendingPassengerIds: <String>{
              ...current.pendingPassengerIds,
              userId,
            }.toList(),
          );
          state.setRoute(updatedRoute);
          loadRouteMembersDetails(updatedRoute);
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
        final current = state.route.value;
        if (current != null &&
            routeId != null &&
            userId != null &&
            current.id == routeId) {
          final updatedRoute = current.copyWith(
            pendingPassengerIds: current.pendingPassengerIds
                .where((id) => id != userId)
                .toList(),
          );
          state.setRoute(updatedRoute);
          loadRouteMembersDetails(updatedRoute);
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
        final current = state.route.value;
        if (current != null &&
            routeId != null &&
            userId != null &&
            current.id == routeId) {
          final updatedRoute = current.copyWith(
            pendingPassengerIds: current.pendingPassengerIds
                .where((id) => id != userId)
                .toList(),
            passengerIds: <String>{...current.passengerIds, userId}.toList(),
          );
          state.setRoute(updatedRoute);
          loadRouteMembersDetails(updatedRoute);
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
        final current = state.route.value;
        if (current != null &&
            routeId != null &&
            userId != null &&
            current.id == routeId) {
          final updatedRoute = current.copyWith(
            pendingPassengerIds: current.pendingPassengerIds
                .where((id) => id != userId)
                .toList(),
            passengerIds: current.passengerIds
                .where((id) => id != userId)
                .toList(),
            confirmedPassengerIds: current.confirmedPassengerIds
                .where((id) => id != userId)
                .toList(),
          );
          state.setRoute(updatedRoute);
          loadRouteMembersDetails(updatedRoute);
        }
      },
    );
  }

  void _observeAssignDriverToRoute() {
    _observeCommand<void>(
      _assignDriverToRouteCommand,
      onSuccess: (_) {
        final routeId = _assignDriverToRouteCommand.lastRouteId;
        final driverId = _assignDriverToRouteCommand.lastDriverId;
        final current = state.route.value;
        if (current != null && routeId != null && current.id == routeId) {
          final updatedRoute = current.copyWith(driverId: driverId);
          state.setRoute(updatedRoute);
          loadRouteMembersDetails(updatedRoute);
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
        final current = state.route.value;
        if (current != null &&
            routeId != null &&
            userId != null &&
            isPresent != null &&
            current.id == routeId) {
          final updatedConfirmed = isPresent
              ? <String>{...current.confirmedPassengerIds, userId}.toList()
              : current.confirmedPassengerIds
                    .where((id) => id != userId)
                    .toList();
          final updatedRoute = current.copyWith(
            confirmedPassengerIds: updatedConfirmed,
          );
          state.setRoute(updatedRoute);
          state.setConfirmedPassengers(
            state.passengers.value
                .where(
                  (u) => updatedConfirmed.any(
                    (id) => _matchesUserId(id, u.cpf, u.email),
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  void _observeStartRouteTrip() {
    _observeCommand<RouteModel>(
      _startRouteTripCommand,
      onSuccess: (updatedRoute) {
        state.setRoute(updatedRoute);
      },
    );
  }

  void _observeFinishRouteTrip() {
    _observeCommand<RouteModel>(
      _finishRouteTripCommand,
      onSuccess: (updatedRoute) {
        state.setRoute(updatedRoute);
        state.setConfirmedPassengers([]);
      },
    );
  }
}
