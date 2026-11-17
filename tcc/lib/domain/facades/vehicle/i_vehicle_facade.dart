import '../../models/vehicle_entity.dart';

abstract class IVehicleFacade {
  Future<List<VehicleModel>> fetchCompanyVehicles(String companyCnpj);
  Future<VehicleModel?> getVehicleById(String vehicleId);
  Future<List<VehicleModel>> fetchDriverVehicles({
    required String companyCnpj,
    required String driverId,
  });
  Future<VehicleModel> createVehicle(VehicleModel vehicle);
  Future<VehicleModel> updateVehicle(VehicleModel vehicle);
  Future<void> toggleVehicleStatus({
    required String vehicleId,
    required bool isActive,
  });
  Future<void> assignDriver({
    required String vehicleId,
    String? driverId,
  });
  Future<void> deleteVehicle(String vehicleId);
}