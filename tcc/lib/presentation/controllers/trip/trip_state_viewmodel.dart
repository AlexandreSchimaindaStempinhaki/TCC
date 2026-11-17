import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/models/trip_entity.dart';

class TripState {
  final activeTrip = signal<TripModel?>(null);
  final isLoading = signal<bool>(false);
  final isSharingGps = signal<bool>(false);
  final message = signal<String?>(null);

  late final stops = computed(
    () => activeTrip.value?.stops ?? const <TripStopPoint>[],
  );

  late final pendingStops = computed(
    () => stops.value.where((s) => !s.isCompleted).toList(),
  );

  late final completedStops = computed(
    () => stops.value.where((s) => s.isCompleted).toList(),
  );

  late final readyPassengersCount = computed(
    () => stops.value.where((s) => s.isPassengerReady && !s.isCompleted).length,
  );

  late final nextStop = computed(
    () => pendingStops.value.firstOrNull,
  );

  /// Obtém os dados da parada e o tempo estimado (ETA) de um passageiro específico
  TripStopPoint? getStopForPassenger(String passengerId) {
    final trimmed = passengerId.trim();
    if (trimmed.isEmpty) return null;
    for (final stop in stops.value) {
      if (stop.passengerId.trim() == trimmed) return stop;
    }
    return null;
  }

  void setActiveTrip(TripModel? trip) {
    activeTrip.value = trip;
    isSharingGps.value = trip?.isSharingLocation ?? false;
  }

  void clearMessage() => message.value = null;
}