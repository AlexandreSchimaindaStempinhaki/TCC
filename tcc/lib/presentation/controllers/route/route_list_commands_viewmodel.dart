import '../../commands/route_commands.dart';
import 'route_list_state_viewmodel.dart';

class RouteListCommands {
  final RouteListState state;
  final FetchAllRoutesCommand _fetchAllRoutesCommand;
  final FetchRoutesByCompanyCommand _fetchRoutesByCompanyCommand;
  final DeleteRouteCommand _deleteRouteCommand;

  RouteListCommands({
    required this.state,
    required FetchAllRoutesCommand fetchAllRoutesCommand,
    required FetchRoutesByCompanyCommand fetchRoutesByCompanyCommand,
    required DeleteRouteCommand deleteRouteCommand,
  })  : _fetchAllRoutesCommand = fetchAllRoutesCommand,
        _fetchRoutesByCompanyCommand = fetchRoutesByCompanyCommand,
        _deleteRouteCommand = deleteRouteCommand;

  // ========================================================
  //   GETTERS PARA WIDGETS USAREM DIRETAMENTE OS COMANDOS
  // ========================================================
  FetchAllRoutesCommand get fetchAllRoutesCommand => _fetchAllRoutesCommand;
  FetchRoutesByCompanyCommand get fetchRoutesByCompanyCommand =>
      _fetchRoutesByCompanyCommand;
  DeleteRouteCommand get deleteRouteCommand => _deleteRouteCommand;

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<void> fetchAllRoutes() async {
    if (_fetchAllRoutesCommand.isExecuting.value) return;

    state.clearMessage();
    try {
      final routes = await _fetchAllRoutesCommand.execute();
      state.setRoutes(routes);
    } catch (e) {
      state.setMessage(e.toString());
    }
  }

  Future<void> fetchRoutesByCompany(String companyCnpj) async {
    if (_fetchRoutesByCompanyCommand.isExecuting.value) return;

    state.clearMessage();
    try {
      final routes = await _fetchRoutesByCompanyCommand.execute(companyCnpj);
      state.setCompanyRoutes(routes);
    } catch (e) {
      state.setMessage(e.toString());
    }
  }

  Future<bool> deleteRouteFromList(int routeId) async {
    if (_deleteRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _deleteRouteCommand.execute(routeId);
      state.removeRouteById(routeId);
      return true;
    } catch (e) {
      state.setMessage(e.toString());
      return false;
    }
  }
}