import '../../../domain/models/vehicle_entity.dart';
import 'vehicle_viewmodel.dart';

class VehicleViewModelCommands {
  final VehicleViewModel _viewModel;

  VehicleViewModelCommands(this._viewModel);

  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final vehicle = await _viewModel.getVehicleByIdCommand.execute(vehicleId);
      if (vehicle != null) {
        _viewModel.state.selectedVehicle.value = vehicle;
      }
      return vehicle;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao buscar veículo: $e';
      return null;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<VehicleModel?> createVehicle(VehicleModel vehicle) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final created = await _viewModel.createVehicleCommand.execute(vehicle);
      _viewModel.state.selectedVehicle.value = created;
      return created;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao cadastrar veículo: $e';
      return null;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<VehicleModel?> updateVehicle(VehicleModel vehicle) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final updated = await _viewModel.updateVehicleCommand.execute(vehicle);
      if (_viewModel.state.selectedVehicle.value?.id == updated.id) {
        _viewModel.state.selectedVehicle.value = updated;
      }
      return updated;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao atualizar veículo: $e';
      return null;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<bool> toggleVehicleStatus({
    required String vehicleId,
    required bool isActive,
  }) async {
    _viewModel.state.clearMessage();
    try {
      await _viewModel.toggleVehicleStatusCommand.execute(
        vehicleId: vehicleId,
        isActive: isActive,
      );
      final current = _viewModel.state.selectedVehicle.value;
      if (current != null && current.id == vehicleId) {
        _viewModel.state.selectedVehicle.value = current.copyWith(
          isActive: isActive,
        );
      }
      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao alterar status do veículo: $e';
      return false;
    }
  }

  Future<bool> assignDriver({
    required String vehicleId,
    String? driverId,
  }) async {
    _viewModel.state.clearMessage();
    try {
      await _viewModel.assignVehicleDriverCommand.execute(
        vehicleId: vehicleId,
        driverId: driverId,
      );
      final current = _viewModel.state.selectedVehicle.value;
      if (current != null && current.id == vehicleId) {
        _viewModel.state.selectedVehicle.value = current.copyWith(
          defaultDriverId: driverId,
        );
      }
      return true;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao vincular motorista ao veículo: $e';
      return false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      await _viewModel.deleteVehicleCommand.execute(vehicleId);
      if (_viewModel.state.selectedVehicle.value?.id == vehicleId) {
        _viewModel.state.selectedVehicle.value = null;
      }
      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao excluir veículo: $e';
      return false;
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }
}