import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/route/i_route_facade.dart';
import '../../commands/route_commands.dart';
import 'route_list_commands_viewmodel.dart';
import 'route_list_state_viewmodel.dart';

class RouteListViewModel {
  final IRouteUseCaseFacade _facade;

  late final RouteListState _state;
  late final RouteListCommands _commands;
  late final Signal<bool> _loading;

  RouteListState get state => _state;
  RouteListCommands get commands => _commands;
  ReadonlySignal<bool> get loading => _loading.readonly();

  RouteListViewModel(this._facade) {
    _state = RouteListState();

    _commands = RouteListCommands(
      state: _state,
      fetchAllRoutesCommand: FetchAllRoutesCommand(_facade),
      fetchRoutesByCompanyCommand: FetchRoutesByCompanyCommand(_facade),
      deleteRouteCommand: DeleteRouteCommand(_facade),
    );

    _loading = signal(false);
  }

  // --- Comandos expostos diretamente para conveniência na UI ---
  FetchAllRoutesCommand get fetchAllRoutesCommand =>
      _commands.fetchAllRoutesCommand;
  FetchRoutesByCompanyCommand get fetchRoutesByCompanyCommand =>
      _commands.fetchRoutesByCompanyCommand;
  DeleteRouteCommand get deleteRouteCommand => _commands.deleteRouteCommand;
}