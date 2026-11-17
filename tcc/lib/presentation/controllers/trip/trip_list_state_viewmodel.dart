import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/trip_entity.dart';

class TripListState {
  final routeTrips = signal<List<TripModel>>([]);
  final driverTrips = signal<List<TripModel>>([]);
  final companyTrips = signal<List<TripModel>>([]);
  final selectedDate = signal<DateTime>(DateTime.now());
  final isLoading = signal<bool>(false);
  final message = signal<String?>(null);

  late final outboundTrips = computed(
    () => routeTrips.value
        .where((t) => t.direction == TripDirection.outbound)
        .toList(),
  );

  late final returnTrips = computed(
    () => routeTrips.value
        .where((t) => t.direction == TripDirection.returnTrip)
        .toList(),
  );

  late final activeRouteTrips = computed(
    () => routeTrips.value
        .where(
          (t) =>
              t.status == TripStatus.inProgress ||
              t.status == TripStatus.boarding,
        )
        .toList(),
  );

  /// Localiza em qual viagem (Van 1 ou Van 2) o passageiro foi alocado
  TripModel? findTripForPassenger(String passengerId) {
    final trimmed = passengerId.trim();
    if (trimmed.isEmpty) return routeTrips.value.firstOrNull;

    for (final trip in routeTrips.value) {
      if (trip.assignedPassengerIds.contains(trimmed) ||
          trip.stops.any((s) => s.passengerId.trim() == trimmed)) {
        return trip;
      }
    }
    return routeTrips.value.firstOrNull;
  }

  void clearMessage() => message.value = null;
}