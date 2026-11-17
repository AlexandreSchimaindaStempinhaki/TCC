import '../../../domain/models/vehicle_entity.dart';
import 'i_vehicle_repository.dart';
import '../../services/vehicle/i_vehicle_service.dart';

class VehicleRepositoryImpl implements IVehicleRepository {
  final IVehicleService _service;

  VehicleRepositoryImpl(this._service);

  @override
  Future<List<VehicleModel>> fetchVehiclesByCompany(String companyCnpj) =>
      _service.fetchVehiclesByCompany(companyCnpj);

  @override
  Future<VehicleModel?> getVehicleById(String vehicleId) =>
      _service.getVehicleById(vehicleId);

  @override
  Future<List<VehicleModel>> fetchVehiclesByDriver({
    required String companyCnpj,
    required String driverId,
  }) =>
      _service.fetchVehiclesByDriver(
        companyCnpj: companyCnpj,
        driverId: driverId,
      );

  @override
  Future<VehicleModel> createVehicle(VehicleModel vehicle) =>
      _service.createVehicle(vehicle);

  @override
  Future<VehicleModel> updateVehicle(VehicleModel vehicle) =>
      _service.updateVehicle(vehicle);

  @override
  Future<void> toggleVehicleActiveStatus({
    required String vehicleId,
    required bool isActive,
  }) =>
      _service.toggleVehicleActiveStatus(
        vehicleId: vehicleId,
        isActive: isActive,
      );

  @override
  Future<void> assignDefaultDriver({
    required String vehicleId,
    String? driverId,
  }) =>
      _service.assignDefaultDriver(
        vehicleId: vehicleId,
        driverId: driverId,
      );

  @override
  Future<void> deleteVehicle(String vehicleId) =>
      _service.deleteVehicle(vehicleId);
}