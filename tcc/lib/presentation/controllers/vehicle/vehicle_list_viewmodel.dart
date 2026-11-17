import '../../../domain/facades/vehicle/i_vehicle_facade.dart';
import '../../commands/vehicle_commands.dart';
import 'vehicle_list_state_viewmodel.dart';
import 'vehicle_list_viewmodel_commands.dart';

class VehicleListViewModel {
  final IVehicleFacade _facade;

  late final VehicleListState state;
  late final VehicleListViewModelCommands commands;

  late final FetchCompanyVehiclesCommand fetchCompanyVehiclesCommand;
  late final FetchDriverVehiclesCommand fetchDriverVehiclesCommand;

  VehicleListViewModel(this._facade) {
    state = VehicleListState();
    fetchCompanyVehiclesCommand = FetchCompanyVehiclesCommand(_facade);
    fetchDriverVehiclesCommand = FetchDriverVehiclesCommand(_facade);
    commands = VehicleListViewModelCommands(this);
  }
}