import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/vehicle_entity.dart';

class VehicleState {
  final selectedVehicle = signal<VehicleModel?>(null);
  final isLoading = signal<bool>(false);
  final message = signal<String?>(null);

  void setSelectedVehicle(VehicleModel? vehicle) =>
      selectedVehicle.value = vehicle;

  void clearMessage() => message.value = null;
}