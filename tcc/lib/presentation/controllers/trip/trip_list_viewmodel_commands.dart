import 'dart:async';
import '../../../domain/models/trip_entity.dart';
import 'trip_list_viewmodel.dart';

class TripListViewModelCommands {
  final TripListViewModel _viewModel;
  StreamSubscription<List<TripModel>>? _activeRouteTripsSub;

  TripListViewModelCommands(this._viewModel);

  Future<void> fetchTripsByRoute({
    required String routeId,
    DateTime? date,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      if (date != null) _viewModel.state.selectedDate.value = date;
      final trips = await _viewModel.fetchTripsByRouteCommand.execute(
        routeId: routeId,
        date: date,
      );
      _viewModel.state.routeTrips.value = trips;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao buscar viagens da rota: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<void> fetchTripsByDriver({
    required String driverId,
    DateTime? date,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final trips = await _viewModel.fetchTripsByDriverCommand.execute(
        driverId: driverId,
        date: date,
      );
      _viewModel.state.driverTrips.value = trips;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao buscar viagens do motorista: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<void> fetchTripsByCompany({
    required String companyCnpj,
    DateTime? date,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final trips = await _viewModel.fetchTripsByCompanyCommand.execute(
        companyCnpj: companyCnpj,
        date: date,
      );
      _viewModel.state.companyTrips.value = trips;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao buscar viagens da empresa: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  void watchActiveTripsByRoute(String routeId) {
    _activeRouteTripsSub?.cancel();
    _activeRouteTripsSub = _viewModel.watchActiveTripsByRouteCommand
        .execute(routeId)
        .listen((trips) {
      _viewModel.state.routeTrips.value = trips;
    });
  }

  void stopWatchingActiveTrips() {
    _activeRouteTripsSub?.cancel();
    _activeRouteTripsSub = null;
  }
}