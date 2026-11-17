import '../../../domain/models/vehicle_entity.dart';

abstract class IVehicleService {
  Future<List<VehicleModel>> fetchVehiclesByCompany(String companyCnpj);
  Future<VehicleModel?> getVehicleById(String vehicleId);
  Future<List<VehicleModel>> fetchVehiclesByDriver({
    required String companyCnpj,
    required String driverId,
  });
  Future<VehicleModel> createVehicle(VehicleModel vehicle);
  Future<VehicleModel> updateVehicle(VehicleModel vehicle);
  Future<void> toggleVehicleActiveStatus({
    required String vehicleId,
    required bool isActive,
  });
  Future<void> assignDefaultDriver({
    required String vehicleId,
    String? driverId,
  });
  Future<void> deleteVehicle(String vehicleId);
}