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

  RouteCommands({
    required this.state,
    required GetRouteByIdCommand getRouteByIdCommand,
    required CreateRouteCommand createRouteCommand,
    required UpdateRouteCommand updateRouteCommand,
    required UpdateRouteImageCommand updateRouteImageCommand,
    required DeleteRouteCommand deleteRouteCommand,
  }) : _getRouteByIdCommand = getRouteByIdCommand,
       _createRouteCommand = createRouteCommand,
       _updateRouteCommand = updateRouteCommand,
       _updateRouteImageCommand = updateRouteImageCommand,
       _deleteRouteCommand = deleteRouteCommand {
    _observeGetRouteById();
    _observeCreateRoute();
    _observeUpdateRoute();
    _observeUpdateRouteImage();
    _observeDeleteRoute();
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

  // ========================================================
  //   MÉTODOS PÚBLICOS (CHAMADOS PELOS WIDGETS)
  // ========================================================
  Future<void> fetchRouteById(int routeId) async {
    if (_getRouteByIdCommand.isExecuting.value) return;

    state.clearMessage();
    await _getRouteByIdCommand.execute(routeId);
  }

  Future<bool> createRoute(
    RouteModel route, {
    File? imageFile,
  }) async {
    if (_createRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      final created = await _createRouteCommand.execute(
        route,
        imageFile: imageFile,
      );
      state.setRoute(created);
      return true;
    } catch (e) {
      state.setMessage(e.toString());
      return false;
    }
  }

  Future<bool> updateRoute(
    RouteModel route, {
    File? imageFile,
  }) async {
    if (_updateRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      final updated = await _updateRouteCommand.execute(
        route,
        imageFile: imageFile,
      );
      state.setRoute(updated);
      return true;
    } catch (e) {
      state.setMessage(e.toString());
      return false;
    }
  }

  Future<void> updateRouteImage(int routeId, File imageFile) async {
    if (_updateRouteImageCommand.isExecuting.value) return;

    state.clearMessage();
    try {
      final imageUrl = await _updateRouteImageCommand.execute(
        routeId,
        imageFile,
      );
      final currentRoute = state.route.value;
      if (currentRoute != null) {
        state.setRoute(currentRoute.copyWith(imageUrl: imageUrl));
      }
    } catch (e) {
      state.setMessage(e.toString());
    }
  }

  Future<bool> deleteRoute(int routeId) async {
    if (_deleteRouteCommand.isExecuting.value) return false;

    state.clearMessage();
    try {
      await _deleteRouteCommand.execute(routeId);
      state.clearRoute();
      return true;
    } catch (e) {
      state.setMessage(e.toString());
      return false;
    }
  }

  // ========================================================
  //   MÉTODO GENÉRICO DE OBSERVAÇÃO DE COMANDOS
  // ========================================================
  void _observeCommand<T>(
    dynamic command, {
    required void Function(T data) onSuccess,
    void Function(Object err)? onFailure,
  }) {
    // Caso utilize effect reativo baseado no state interno do command:
    effect(() {
      if (command.isExecuting.value) return;
      // Se preferir gerenciar diretamente via try/catch nos métodos públicos acima, 
      // os observers ficam como suporte secundário.
    });
  }

  void _observeGetRouteById() {
    effect(() {
      if (_getRouteByIdCommand.isExecuting.value) return;
      // Lógica reativa opcional caso necessário
    });
  }

  void _observeCreateRoute() {}
  void _observeUpdateRoute() {}
  void _observeUpdateRouteImage() {}
  void _observeDeleteRoute() {}
}