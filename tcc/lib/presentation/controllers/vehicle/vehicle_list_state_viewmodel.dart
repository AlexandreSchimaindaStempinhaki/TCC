import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/vehicle_entity.dart';

class VehicleListState {
  final companyVehicles = signal<List<VehicleModel>>([]);
  final driverVehicles = signal<List<VehicleModel>>([]);
  final searchQuery = signal<String>('');
  final isLoading = signal<bool>(false);
  final message = signal<String?>(null);

  late final activeVehicles = computed(
    () => companyVehicles.value.where((v) => v.isActive).toList(),
  );

  late final inactiveVehicles = computed(
    () => companyVehicles.value.where((v) => !v.isActive).toList(),
  );

  late final totalFleetCapacity = computed(
    () => activeVehicles.value.fold<int>(0, (sum, v) => sum + v.capacity),
  );

  late final filteredVehicles = computed(() {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return companyVehicles.value;

    return companyVehicles.value.where((v) {
      return v.plate.toLowerCase().contains(query) ||
          v.model.toLowerCase().contains(query) ||
          v.brand.toLowerCase().contains(query) ||
          (v.color?.toLowerCase().contains(query) ?? false);
    }).toList();
  });

  int calculateRequiredTripsCount({
    required int confirmedPassengersCount,
    VehicleModel? preferredVehicle,
  }) {
    if (confirmedPassengersCount <= 0) return 1;
    final targetVehicle = preferredVehicle ?? activeVehicles.value.firstOrNull;
    final capacity = (targetVehicle?.capacity ?? 15) > 0
        ? targetVehicle!.capacity
        : 15;
    return (confirmedPassengersCount / capacity).ceil();
  }

  void upsertVehicleInList(VehicleModel vehicle) {
    final list = companyVehicles.value;
    final exists = list.any((v) => v.id == vehicle.id);
    if (exists) {
      companyVehicles.value = list
          .map((v) => v.id == vehicle.id ? vehicle : v)
          .toList();
    } else {
      companyVehicles.value = [...list, vehicle];
    }
  }

  void removeVehicleFromList(String vehicleId) {
    companyVehicles.value = companyVehicles.value
        .where((v) => v.id != vehicleId)
        .toList();
    driverVehicles.value = driverVehicles.value
        .where((v) => v.id != vehicleId)
        .toList();
  }

  void clearMessage() => message.value = null;
}