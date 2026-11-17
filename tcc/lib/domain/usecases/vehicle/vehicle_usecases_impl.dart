import '../../../data/repositories/vehicle/i_vehicle_repository.dart';
import '../../models/vehicle_entity.dart';
import 'i_vehicle_usecases.dart';

class FetchCompanyVehiclesUseCaseImpl implements IFetchCompanyVehiclesUseCase {
  final IVehicleRepository _repository;
  FetchCompanyVehiclesUseCaseImpl(this._repository);

  @override
  Future<List<VehicleModel>> call(String companyCnpj) =>
      _repository.fetchVehiclesByCompany(companyCnpj);
}

class GetVehicleByIdUseCaseImpl implements IGetVehicleByIdUseCase {
  final IVehicleRepository _repository;
  GetVehicleByIdUseCaseImpl(this._repository);

  @override
  Future<VehicleModel?> call(String vehicleId) =>
      _repository.getVehicleById(vehicleId);
}

class FetchDriverVehiclesUseCaseImpl implements IFetchDriverVehiclesUseCase {
  final IVehicleRepository _repository;
  FetchDriverVehiclesUseCaseImpl(this._repository);

  @override
  Future<List<VehicleModel>> call({
    required String companyCnpj,
    required String driverId,
  }) =>
      _repository.fetchVehiclesByDriver(
        companyCnpj: companyCnpj,
        driverId: driverId,
      );
}

class CreateVehicleUseCaseImpl implements ICreateVehicleUseCase {
  final IVehicleRepository _repository;
  CreateVehicleUseCaseImpl(this._repository);

  @override
  Future<VehicleModel> call(VehicleModel vehicle) {
    if (vehicle.plate.trim().isEmpty) {
      throw Exception('A placa do veículo é obrigatória.');
    }
    if (vehicle.model.trim().isEmpty || vehicle.brand.trim().isEmpty) {
      throw Exception('Informe a marca e o modelo do veículo.');
    }
    if (vehicle.capacity <= 0) {
      throw Exception('A capacidade do veículo deve ser maior que zero.');
    }
    return _repository.createVehicle(vehicle);
  }
}

class UpdateVehicleUseCaseImpl implements IUpdateVehicleUseCase {
  final IVehicleRepository _repository;
  UpdateVehicleUseCaseImpl(this._repository);

  @override
  Future<VehicleModel> call(VehicleModel vehicle) {
    if (vehicle.capacity <= 0) {
      throw Exception('A capacidade do veículo deve ser maior que zero.');
    }
    return _repository.updateVehicle(vehicle);
  }
}

class ToggleVehicleStatusUseCaseImpl implements IToggleVehicleStatusUseCase {
  final IVehicleRepository _repository;
  ToggleVehicleStatusUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required String vehicleId,
    required bool isActive,
  }) =>
      _repository.toggleVehicleActiveStatus(
        vehicleId: vehicleId,
        isActive: isActive,
      );
}

class AssignVehicleDriverUseCaseImpl implements IAssignVehicleDriverUseCase {
  final IVehicleRepository _repository;
  AssignVehicleDriverUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required String vehicleId,
    String? driverId,
  }) =>
      _repository.assignDefaultDriver(
        vehicleId: vehicleId,
        driverId: driverId,
      );
}

class DeleteVehicleUseCaseImpl implements IDeleteVehicleUseCase {
  final IVehicleRepository _repository;
  DeleteVehicleUseCaseImpl(this._repository);

  @override
  Future<void> call(String vehicleId) => _repository.deleteVehicle(vehicleId);
}