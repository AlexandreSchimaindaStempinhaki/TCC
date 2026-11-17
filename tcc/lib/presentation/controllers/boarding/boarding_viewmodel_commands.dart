import 'dart:async';
import '../../../domain/models/boarding_entity.dart';
import 'boarding_viewmodel.dart';

class BoardingViewModelCommands {
  final BoardingViewModel _viewModel;
  StreamSubscription<BoardingModel?>? _passengerBoardingSub;

  BoardingViewModelCommands(this._viewModel);

  Future<BoardingModel?> loadDailyBoarding({
    required String routeId,
    required String userId,
    DateTime? date,
    String? tripId,
    String? defaultDepartureTime,
    String? defaultReturnTime,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    final targetDate = date ?? _viewModel.state.selectedDate.value;
    _viewModel.state.selectedDate.value = targetDate;

    try {
      final result = await _viewModel.getOrCreateDailyBoardingCommand.execute(
        routeId: routeId,
        userId: userId,
        date: targetDate,
        tripId: tripId,
        defaultDepartureTime: defaultDepartureTime,
        defaultReturnTime: defaultReturnTime,
      );
      _viewModel.state.currentBoarding.value = result;
      _viewModel.state.upsertInHistory(result);
      return result;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao carregar presença do dia: $e';
      return null;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<void> loadUserHistory({
    required String routeId,
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final history = await _viewModel.fetchUserBoardingHistoryCommand.execute(
        routeId: routeId,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      _viewModel.state.userHistory.value = history;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao carregar histórico do calendário: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  void watchPassengerBoarding({
    required String routeId,
    required String userId,
    required DateTime date,
  }) {
    _passengerBoardingSub?.cancel();
    _viewModel.state.selectedDate.value = date;
    _passengerBoardingSub = _viewModel.watchPassengerBoardingCommand
        .execute(routeId: routeId, userId: userId, date: date)
        .listen((boarding) {
      if (boarding != null) {
        _viewModel.state.currentBoarding.value = boarding;
        _viewModel.state.upsertInHistory(boarding);
      }
    });
  }

  void stopWatchingPassengerBoarding() {
    _passengerBoardingSub?.cancel();
    _passengerBoardingSub = null;
  }

  Future<bool> updateAttendance({
    required String routeId,
    required String userId,
    required DateTime date,
    required bool willGoOutbound,
    required bool willGoReturn,
    String? selectedDepartureTime,
    String? selectedReturnTime,
    String? tripId,
  }) async {
    _viewModel.state.clearMessage();
    try {
      final updated = await _viewModel.updateBoardingAttendanceCommand.execute(
        routeId: routeId,
        userId: userId,
        date: date,
        willGoOutbound: willGoOutbound,
        willGoReturn: willGoReturn,
        selectedDepartureTime: selectedDepartureTime,
        selectedReturnTime: selectedReturnTime,
        tripId: tripId,
      );
      _viewModel.state.currentBoarding.value = updated;
      _viewModel.state.upsertInHistory(updated);
      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao atualizar presença: $e';
      return false;
    }
  }

  Future<bool> toggleReadyForBoarding({
    required String boardingId,
    required bool isReady,
  }) async {
    _viewModel.state.clearMessage();
    try {
      final updated = await _viewModel.setReadyForBoardingCommand.execute(
        boardingId: boardingId,
        isReady: isReady,
      );
      _viewModel.state.currentBoarding.value = updated;
      _viewModel.state.upsertInHistory(updated);
      return true;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao sinalizar prontidão para o motorista: $e';
      return false;
    }
  }

  Future<bool> markBoardingOutcome({
    required String boardingId,
    required BoardingAttendanceStatus status,
  }) async {
    _viewModel.state.clearMessage();
    try {
      final updated = await _viewModel.markBoardingOutcomeCommand.execute(
        boardingId: boardingId,
        status: status,
      );
      if (_viewModel.state.currentBoarding.value?.id == boardingId) {
        _viewModel.state.currentBoarding.value = updated;
      }
      _viewModel.state.upsertInHistory(updated);
      return true;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao registrar status de embarque: $e';
      return false;
    }
  }
}