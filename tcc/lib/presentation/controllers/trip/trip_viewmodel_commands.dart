import 'dart:async';
import '../../../domain/models/trip_entity.dart';
import 'trip_viewmodel.dart';

class TripViewModelCommands {
  final TripViewModel _viewModel;
  StreamSubscription<TripModel?>? _tripSubscription;

  TripViewModelCommands(this._viewModel);

  Future<TripModel?> getTripById(String tripId) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final trip = await _viewModel.getTripByIdCommand.execute(tripId);
      _viewModel.state.setActiveTrip(trip);
      return trip;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao carregar viagem: $e';
      return null;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  void startWatchingTrip(String tripId) {
    _tripSubscription?.cancel();
    _tripSubscription = _viewModel.watchTripByIdCommand.execute(tripId).listen(
      (trip) {
        _viewModel.state.setActiveTrip(trip);
      },
      onError: (e) {
        _viewModel.state.message.value =
            'Erro no acompanhamento em tempo real: $e';
      },
    );
  }

  void stopWatchingTrip() {
    _tripSubscription?.cancel();
    _tripSubscription = null;
  }

  Future<TripModel?> createTrip(TripModel trip) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final created = await _viewModel.createTripCommand.execute(trip);
      _viewModel.state.setActiveTrip(created);
      return created;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao criar viagem: $e';
      return null;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<List<TripModel>> generateScaledTrips({
    required TripModel baseTrip,
    required List<TripStopPoint> confirmedStops,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final generated = await _viewModel.generateScaledTripsCommand.execute(
        baseTrip: baseTrip,
        confirmedStops: confirmedStops,
      );
      if (generated.isNotEmpty) {
        _viewModel.state.setActiveTrip(generated.first);
      }
      return generated;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao escalonar viagens por lotação: $e';
      return const [];
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<bool> startTrip({
    required String tripId,
    double? initialLatitude,
    double? initialLongitude,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final started = await _viewModel.startTripCommand.execute(
        tripId: tripId,
        initialLatitude: initialLatitude,
        initialLongitude: initialLongitude,
      );
      _viewModel.state.setActiveTrip(started);
      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao iniciar viagem: $e';
      return false;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<bool> finishTrip(String tripId) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final finished = await _viewModel.finishTripCommand.execute(tripId);
      _viewModel.state.setActiveTrip(finished);
      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao finalizar viagem: $e';
      return false;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<bool> cancelTrip(String tripId) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final cancelled = await _viewModel.cancelTripCommand.execute(tripId);
      _viewModel.state.setActiveTrip(cancelled);
      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao cancelar viagem: $e';
      return false;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<void> updateDriverLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    bool isSharingLocation = true,
    double averageSpeedKmh = 35.0,
  }) async {
    try {
      final updated = await _viewModel.updateDriverLocationCommand.execute(
        tripId: tripId,
        latitude: latitude,
        longitude: longitude,
        isSharingLocation: isSharingLocation,
        averageSpeedKmh: averageSpeedKmh,
      );
      _viewModel.state.setActiveTrip(updated);
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao atualizar localização: $e';
    }
  }

  Future<bool> markStopCompleted({
    required String tripId,
    required String passengerId,
    required bool isCompleted,
  }) async {
    _viewModel.state.clearMessage();
    try {
      final updated = await _viewModel.markStopCompletedCommand.execute(
        tripId: tripId,
        passengerId: passengerId,
        isCompleted: isCompleted,
      );
      _viewModel.state.setActiveTrip(updated);
      return true;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao atualizar ponto de parada: $e';
      return false;
    }
  }

  Future<bool> setPassengerReadyAtStop({
    required String tripId,
    required String passengerId,
    required bool isReady,
  }) async {
    _viewModel.state.clearMessage();
    try {
      final updated = await _viewModel.setPassengerReadyAtStopCommand.execute(
        tripId: tripId,
        passengerId: passengerId,
        isReady: isReady,
      );
      _viewModel.state.setActiveTrip(updated);
      return true;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao sinalizar prontidão no ponto: $e';
      return false;
    }
  }

  Future<bool> deleteTrip(String tripId) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      await _viewModel.deleteTripCommand.execute(tripId);
      if (_viewModel.state.activeTrip.value?.id == tripId) {
        _viewModel.state.setActiveTrip(null);
      }
      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao excluir viagem: $e';
      return false;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }
}