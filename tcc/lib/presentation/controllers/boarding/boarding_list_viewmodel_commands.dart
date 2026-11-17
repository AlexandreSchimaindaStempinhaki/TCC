import 'dart:async';
import '../../../domain/models/boarding_entity.dart';
import 'boarding_list_viewmodel.dart';

class BoardingListViewModelCommands {
  final BoardingListViewModel _viewModel;
  StreamSubscription<List<BoardingModel>>? _routeBoardingsSub;

  BoardingListViewModelCommands(this._viewModel);

  Future<void> fetchByRouteAndDate({
    required String routeId,
    required DateTime date,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    _viewModel.state.selectedDate.value = date;
    try {
      final result = await _viewModel.fetchBoardingsByRouteAndDateCommand
          .execute(routeId: routeId, date: date);
      _viewModel.state.routeBoardings.value = result;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao carregar lista de presença da rota: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<void> fetchByTrip(String tripId) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final result = await _viewModel.fetchBoardingsByTripCommand.execute(
        tripId,
      );
      _viewModel.state.tripBoardings.value = result;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao carregar embarques da viagem: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  void watchRouteBoardingsByDate({
    required String routeId,
    required DateTime date,
  }) {
    _routeBoardingsSub?.cancel();
    _viewModel.state.selectedDate.value = date;
    _routeBoardingsSub = _viewModel.watchRouteBoardingsByDateCommand
        .execute(routeId: routeId, date: date)
        .listen((list) {
      _viewModel.state.routeBoardings.value = list;
    });
  }

  void stopWatchingRouteBoardings() {
    _routeBoardingsSub?.cancel();
    _routeBoardingsSub = null;
  }

  Future<bool> markPassengerOutcome({
    required String boardingId,
    required BoardingAttendanceStatus status,
  }) async {
    _viewModel.state.clearMessage();
    try {
      final updated = await _viewModel.markBoardingOutcomeCommand.execute(
        boardingId: boardingId,
        status: status,
      );
      _viewModel.state.routeBoardings.value = _viewModel
          .state.routeBoardings.value
          .map((b) => b.id == boardingId ? updated : b)
          .toList();
      return true;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao atualizar embarque do passageiro: $e';
      return false;
    }
  }
}