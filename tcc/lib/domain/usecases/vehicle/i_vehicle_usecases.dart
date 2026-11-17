import '../../models/vehicle_entity.dart';

abstract class IFetchCompanyVehiclesUseCase {
  Future<List<VehicleModel>> call(String companyCnpj);
}

abstract class IGetVehicleByIdUseCase {
  Future<VehicleModel?> call(String vehicleId);
}

abstract class IFetchDriverVehiclesUseCase {
  Future<List<VehicleModel>> call({
    required String companyCnpj,
    required String driverId,
  });
}

abstract class ICreateVehicleUseCase {
  Future<VehicleModel> call(VehicleModel vehicle);
}

abstract class IUpdateVehicleUseCase {
  Future<VehicleModel> call(VehicleModel vehicle);
}

abstract class IToggleVehicleStatusUseCase {
  Future<void> call({
    required String vehicleId,
    required bool isActive,
  });
}

abstract class IAssignVehicleDriverUseCase {
  Future<void> call({
    required String vehicleId,
    String? driverId,
  });
}

abstract class IDeleteVehicleUseCase {
  Future<void> call(String vehicleId);
}