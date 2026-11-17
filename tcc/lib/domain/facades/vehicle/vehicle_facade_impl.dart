import '../../models/vehicle_entity.dart';
import '../../usecases/vehicle/i_vehicle_usecases.dart';
import 'i_vehicle_facade.dart';

class VehicleFacadeImpl implements IVehicleFacade {
  final IFetchCompanyVehiclesUseCase _fetchCompanyVehiclesUseCase;
  final IGetVehicleByIdUseCase _getVehicleByIdUseCase;
  final IFetchDriverVehiclesUseCase _fetchDriverVehiclesUseCase;
  final ICreateVehicleUseCase _createVehicleUseCase;
  final IUpdateVehicleUseCase _updateVehicleUseCase;
  final IToggleVehicleStatusUseCase _toggleVehicleStatusUseCase;
  final IAssignVehicleDriverUseCase _assignVehicleDriverUseCase;
  final IDeleteVehicleUseCase _deleteVehicleUseCase;

  VehicleFacadeImpl(
    this._fetchCompanyVehiclesUseCase,
    this._getVehicleByIdUseCase,
    this._fetchDriverVehiclesUseCase,
    this._createVehicleUseCase,
    this._updateVehicleUseCase,
    this._toggleVehicleStatusUseCase,
    this._assignVehicleDriverUseCase,
    this._deleteVehicleUseCase,
  );

  @override
  Future<List<VehicleModel>> fetchCompanyVehicles(String companyCnpj) =>
      _fetchCompanyVehiclesUseCase(companyCnpj);

  @override
  Future<VehicleModel?> getVehicleById(String vehicleId) =>
      _getVehicleByIdUseCase(vehicleId);

  @override
  Future<List<VehicleModel>> fetchDriverVehicles({
    required String companyCnpj,
    required String driverId,
  }) =>
      _fetchDriverVehiclesUseCase(
        companyCnpj: companyCnpj,
        driverId: driverId,
      );

  @override
  Future<VehicleModel> createVehicle(VehicleModel vehicle) =>
      _createVehicleUseCase(vehicle);

  @override
  Future<VehicleModel> updateVehicle(VehicleModel vehicle) =>
      _updateVehicleUseCase(vehicle);

  @override
  Future<void> toggleVehicleStatus({
    required String vehicleId,
    required bool isActive,
  }) =>
      _toggleVehicleStatusUseCase(
        vehicleId: vehicleId,
        isActive: isActive,
      );

  @override
  Future<void> assignDriver({
    required String vehicleId,
    String? driverId,
  }) =>
      _assignVehicleDriverUseCase(
        vehicleId: vehicleId,
        driverId: driverId,
      );

  @override
  Future<void> deleteVehicle(String vehicleId) =>
      _deleteVehicleUseCase(vehicleId);
}