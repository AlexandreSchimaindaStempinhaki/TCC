import 'vehicle_list_viewmodel.dart';

class VehicleListViewModelCommands {
  final VehicleListViewModel _viewModel;

  VehicleListViewModelCommands(this._viewModel);

  Future<void> fetchVehiclesByCompany(String companyCnpj) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final result = await _viewModel.fetchCompanyVehiclesCommand.execute(
        companyCnpj,
      );
      _viewModel.state.companyVehicles.value = result;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao carregar frota da empresa: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }

  Future<void> fetchVehiclesByDriver({
    required String companyCnpj,
    required String driverId,
  }) async {
    _viewModel.state.clearMessage();
    _viewModel.state.isLoading.value = true;
    try {
      final result = await _viewModel.fetchDriverVehiclesCommand.execute(
        companyCnpj: companyCnpj,
        driverId: driverId,
      );
      _viewModel.state.driverVehicles.value = result;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao carregar veículos do motorista: $e';
    } finally {
      _viewModel.state.isLoading.value = false;
    }
  }
}