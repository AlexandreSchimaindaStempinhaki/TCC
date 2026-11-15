import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/route/i_route_facade.dart';
import '../../commands/route_commands.dart';
import 'route_commands_viewmodel.dart';
import 'route_state_viewmodel.dart';

class RouteViewModel {
  final IRouteUseCaseFacade _facade;

  late final RouteState _state;
  late final RouteCommands _commands;
  late final Signal<bool> _loading;

  RouteState get state => _state;
  RouteCommands get commands => _commands;
  ReadonlySignal<bool> get loading => _loading.readonly();

  RouteViewModel(this._facade) {
    _state = RouteState();

    _commands = RouteCommands(
      state: _state,
      getRouteByIdCommand: GetRouteByIdCommand(_facade),
      createRouteCommand: CreateRouteCommand(_facade),
      updateRouteCommand: UpdateRouteCommand(_facade),
      updateRouteImageCommand: UpdateRouteImageCommand(_facade),
      deleteRouteCommand: DeleteRouteCommand(_facade),
      requestToJoinRouteCommand: RequestToJoinRouteCommand(_facade),
      cancelJoinRequestCommand: CancelJoinRequestCommand(_facade),
      approvePassengerInRouteCommand: ApprovePassengerInRouteCommand(_facade),
      removePassengerFromRouteCommand: RemovePassengerFromRouteCommand(_facade),
      fetchRouteUsersByIdsCommand: FetchRouteUsersByIdsCommand(_facade),
      assignDriverToRouteCommand: AssignDriverToRouteCommand(_facade),
      togglePassengerPresenceCommand: TogglePassengerPresenceCommand(_facade),
      startRouteTripCommand: StartRouteTripCommand(_facade),
      finishRouteTripCommand: FinishRouteTripCommand(_facade),
    );

    _loading = signal(false);
  }

  // --- Comandos expostos diretamente para conveniência na UI ---
  GetRouteByIdCommand get getRouteByIdCommand => _commands.getRouteByIdCommand;
  CreateRouteCommand get createRouteCommand => _commands.createRouteCommand;
  UpdateRouteCommand get updateRouteCommand => _commands.updateRouteCommand;
  UpdateRouteImageCommand get updateRouteImageCommand =>
      _commands.updateRouteImageCommand;
  DeleteRouteCommand get deleteRouteCommand => _commands.deleteRouteCommand;

  RequestToJoinRouteCommand get requestToJoinRouteCommand =>
      _commands.requestToJoinRouteCommand;
  CancelJoinRequestCommand get cancelJoinRequestCommand =>
      _commands.cancelJoinRequestCommand;
  ApprovePassengerInRouteCommand get approvePassengerInRouteCommand =>
      _commands.approvePassengerInRouteCommand;
  RemovePassengerFromRouteCommand get removePassengerFromRouteCommand =>
      _commands.removePassengerFromRouteCommand;
  FetchRouteUsersByIdsCommand get fetchRouteUsersByIdsCommand =>
      _commands.fetchRouteUsersByIdsCommand;

  AssignDriverToRouteCommand get assignDriverToRouteCommand =>
      _commands.assignDriverToRouteCommand;
  TogglePassengerPresenceCommand get togglePassengerPresenceCommand =>
      _commands.togglePassengerPresenceCommand;
  StartRouteTripCommand get startRouteTripCommand =>
      _commands.startRouteTripCommand;
  FinishRouteTripCommand get finishRouteTripCommand =>
      _commands.finishRouteTripCommand;
}