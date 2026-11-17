import '../../domain/facades/vehicle/i_vehicle_facade.dart';
import '../../domain/models/vehicle_entity.dart';

class FetchCompanyVehiclesCommand {
  final IVehicleFacade _facade;
  FetchCompanyVehiclesCommand(this._facade);

  Future<List<VehicleModel>> execute(String companyCnpj) =>
      _facade.fetchCompanyVehicles(companyCnpj);
}

class GetVehicleByIdCommand {
  final IVehicleFacade _facade;
  GetVehicleByIdCommand(this._facade);

  Future<VehicleModel?> execute(String vehicleId) =>
      _facade.getVehicleById(vehicleId);
}

class FetchDriverVehiclesCommand {
  final IVehicleFacade _facade;
  FetchDriverVehiclesCommand(this._facade);

  Future<List<VehicleModel>> execute({
    required String companyCnpj,
    required String driverId,
  }) =>
      _facade.fetchDriverVehicles(
        companyCnpj: companyCnpj,
        driverId: driverId,
      );
}

class CreateVehicleCommand {
  final IVehicleFacade _facade;
  CreateVehicleCommand(this._facade);

  Future<VehicleModel> execute(VehicleModel vehicle) =>
      _facade.createVehicle(vehicle);
}

class UpdateVehicleCommand {
  final IVehicleFacade _facade;
  UpdateVehicleCommand(this._facade);

  Future<VehicleModel> execute(VehicleModel vehicle) =>
      _facade.updateVehicle(vehicle);
}

class ToggleVehicleStatusCommand {
  final IVehicleFacade _facade;
  ToggleVehicleStatusCommand(this._facade);

  Future<void> execute({
    required String vehicleId,
    required bool isActive,
  }) =>
      _facade.toggleVehicleStatus(
        vehicleId: vehicleId,
        isActive: isActive,
      );
}

class AssignVehicleDriverCommand {
  final IVehicleFacade _facade;
  AssignVehicleDriverCommand(this._facade);

  Future<void> execute({
    required String vehicleId,
    String? driverId,
  }) =>
      _facade.assignDriver(
        vehicleId: vehicleId,
        driverId: driverId,
      );
}

class DeleteVehicleCommand {
  final IVehicleFacade _facade;
  DeleteVehicleCommand(this._facade);

  Future<void> execute(String vehicleId) => _facade.deleteVehicle(vehicleId);
}