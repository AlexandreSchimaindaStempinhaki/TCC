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
}