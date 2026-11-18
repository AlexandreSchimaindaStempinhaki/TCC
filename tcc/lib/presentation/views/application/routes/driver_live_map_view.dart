import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../../domain/models/trip_entity.dart';
import '../../../controllers/trip/trip_viewmodel.dart';

class DriverLiveMapView extends StatefulWidget {
  final RouteModel route;
  final CompanyModel? company;
  final TripModel? trip;
  final List<TripStopPoint> stops;

  const DriverLiveMapView({
    super.key,
    required this.route,
    this.company,
    this.trip,
    this.stops = const [],
  });

  @override
  State<DriverLiveMapView> createState() => _DriverLiveMapViewState();
}

class _DriverLiveMapViewState extends State<DriverLiveMapView> {
  late final TripViewModel _tripViewModel;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tripViewModel = injector.get<TripViewModel>();
    if (widget.trip != null) {
      _tripViewModel.commands.startWatchingTrip(widget.trip!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final liveTrip = _tripViewModel.state.activeTrip.value ?? widget.trip;
      final stops = (liveTrip != null && liveTrip.stops.isNotEmpty)
          ? liveTrip.stops
          : widget.stops;

      final originLatLng = LatLng(
        widget.route.origin.latitude,
        widget.route.origin.longitude,
      );
      final destLatLng = LatLng(
        widget.route.destination.latitude,
        widget.route.destination.longitude,
      );

      final driverLatLng = (liveTrip?.driverLatitude != null &&
              liveTrip?.driverLongitude != null)
          ? LatLng(liveTrip!.driverLatitude!, liveTrip.driverLongitude!)
          : originLatLng;

      final polylinePoints = <LatLng>[
        driverLatLng,
        ...stops
            .where((s) => !s.isCompleted)
            .map((s) => LatLng(s.latitude, s.longitude)),
        destLatLng,
      ];

      return Scaffold(
        appBar: AppBar(
          backgroundColor: theme.cardColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Motorista em Tempo Real',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: driverLatLng,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.indigo.tcc',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.5,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Paradas dos passageiros
                    ...stops.map(
                      (s) => Marker(
                        point: LatLng(s.latitude, s.longitude),
                        width: 42,
                        height: 42,
                        child: CircleAvatar(
                          backgroundColor: s.isPassengerReady
                              ? const Color(0xFF16A34A)
                              : colorScheme.primary,
                          child: Text(
                            '${s.orderIndex}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Destino final
                    Marker(
                      point: destLatLng,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.flag_circle_rounded,
                        size: 38,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    // Posição atual do motorista
                    Marker(
                      point: driverLatLng,
                      width: 52,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF16A34A),
                      child: Icon(
                        Icons.sensors_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rastreamento Ativo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${stops.where((s) => s.isPassengerReady).length} passageiros prontos • ${stops.length} paradas no trajeto',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Centralizar no motorista',
                      icon: Icon(
                        Icons.my_location_rounded,
                        color: colorScheme.primary,
                      ),
                      onPressed: () {
                        _mapController.move(driverLatLng, 15.0);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}