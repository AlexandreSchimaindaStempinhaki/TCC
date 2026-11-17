import '../../../domain/facades/vehicle/i_vehicle_facade.dart';
import '../../commands/vehicle_commands.dart';
import 'vehicle_state_viewmodel.dart';
import 'vehicle_viewmodel_commands.dart';

class VehicleViewModel {
  final IVehicleFacade _facade;

  late final VehicleState state;
  late final VehicleViewModelCommands commands;

  late final GetVehicleByIdCommand getVehicleByIdCommand;
  late final CreateVehicleCommand createVehicleCommand;
  late final UpdateVehicleCommand updateVehicleCommand;
  late final ToggleVehicleStatusCommand toggleVehicleStatusCommand;
  late final AssignVehicleDriverCommand assignVehicleDriverCommand;
  late final DeleteVehicleCommand deleteVehicleCommand;

  VehicleViewModel(this._facade) {
    state = VehicleState();
    getVehicleByIdCommand = GetVehicleByIdCommand(_facade);
    createVehicleCommand = CreateVehicleCommand(_facade);
    updateVehicleCommand = UpdateVehicleCommand(_facade);
    toggleVehicleStatusCommand = ToggleVehicleStatusCommand(_facade);
    assignVehicleDriverCommand = AssignVehicleDriverCommand(_facade);
    deleteVehicleCommand = DeleteVehicleCommand(_facade);
    commands = VehicleViewModelCommands(this);
  }
}