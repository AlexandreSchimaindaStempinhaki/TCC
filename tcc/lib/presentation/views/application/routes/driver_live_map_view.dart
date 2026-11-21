import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../../domain/models/trip_entity.dart';
import '../../../widgets/live_map/live_map_bottom_sheet.dart';
import '../../../widgets/live_map/live_map_floating_controls.dart';
import '../../../widgets/live_map/live_map_marker_factory.dart';
import '../../../widgets/live_map/live_map_top_bar.dart';
import '../../mixins/driver_live_map_logic.dart';

class DriverLiveMapView extends StatefulWidget {
  final RouteModel route;
  final CompanyModel? company;
  final TripModel? trip;
  final List<TripStopPoint> stops;
  final bool isDriver;

  const DriverLiveMapView({
    super.key,
    required this.route,
    this.company,
    this.trip,
    this.stops = const [],
    this.isDriver = false,
  });

  @override
  State<DriverLiveMapView> createState() => _DriverLiveMapViewState();
}

class _DriverLiveMapViewState extends State<DriverLiveMapView>
    with DriverLiveMapMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDriver = widget.isDriver;

    return Watch((context) {
      final liveTrip = DriverLiveMapMixin.useMockDemoData
          ? null
          : (tripViewModel.state.activeTrip.value ?? widget.trip);

      final (demoOrigin, demoDest) = resolveDemoAnchors();

      final originLatLng = DriverLiveMapMixin.useMockDemoData
          ? demoOrigin
          : LatLng(widget.route.origin.latitude, widget.route.origin.longitude);

      final destLatLng = DriverLiveMapMixin.useMockDemoData
          ? demoDest
          : LatLng(
              widget.route.destination.latitude,
              widget.route.destination.longitude,
            );

      final driverLatLng = DriverLiveMapMixin.useMockDemoData
          ? (mockDriverPosition ?? originLatLng)
          : ((liveTrip?.driverLatitude != null &&
                  liveTrip?.driverLongitude != null)
              ? LatLng(liveTrip!.driverLatitude!, liveTrip.driverLongitude!)
              : originLatLng);

      final stops = DriverLiveMapMixin.useMockDemoData
          ? mockStops
          : optimizeStopsOrder(
              (liveTrip != null && liveTrip.stops.isNotEmpty)
                  ? liveTrip.stops
                  : widget.stops,
              driverLatLng,
            );

      if (isDriver) ensureDriverStopCards(stops);

      final pendingStops = stops.where((s) => !s.isCompleted).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      final nextStop = pendingStops.isNotEmpty ? pendingStops.first : null;
      final nextTargetLatLng = nextStop != null
          ? LatLng(nextStop.latitude, nextStop.longitude)
          : destLatLng;

      final fallbackPoints = <LatLng>[
        driverLatLng,
        ...pendingStops.map((s) => LatLng(s.latitude, s.longitude)),
        destLatLng,
      ];

      final activePolyline = roadPolylinePoints.length >= 2
          ? roadPolylinePoints
          : fallbackPoints;

      final lookAheadPoint =
          activePolyline.length >= 2 ? activePolyline[1] : nextTargetLatLng;

      final bannerDistanceMeters = nextManeuverDistanceMeters ??
          distanceMeters(driverLatLng, nextTargetLatLng);

      double fallbackTotalMeters = 0;
      for (int i = 0; i < fallbackPoints.length - 1; i++) {
        fallbackTotalMeters +=
            distanceMeters(fallbackPoints[i], fallbackPoints[i + 1]);
      }

      final totalRemainingMeters =
          roadTotalDistanceMeters ?? fallbackTotalMeters;

      final estimatedMinutes = roadTotalDurationMinutes ??
          nextStop?.estimatedMinutesRemaining ??
          ((totalRemainingMeters / 1000) / 38 * 60).ceil().clamp(1, 999);

      final destLabel = (widget.route.destinationName?.trim().isNotEmpty == true)
          ? widget.route.destinationName!.trim()
          : 'Campus Central • Destino';

      final companyName = (widget.company?.name.trim().isNotEmpty == true)
          ? widget.company!.name.trim()
          : 'Transportes Costa';

      final nextBannerTitle = nextRoadName != null
          ? '» $nextRoadName'
          : (nextStop != null
              ? '» ${LiveMapMarkerFactory.firstName(nextStop.passengerName)} (Parada #${nextStop.orderIndex})'
              : '» $destLabel');

      final bottomPillLabel = currentRoadName ??
          (nextStop != null
              ? 'Próxima parada: ${LiveMapMarkerFactory.firstName(nextStop.passengerName)}'
              : destLabel);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        syncDriverMotion(driverLatLng, lookAheadPoint);
        if (!DriverLiveMapMixin.useMockDemoData || mockRoadStopsReady) {
          maybeFetchRoadRoute(driverLatLng, pendingStops, destLatLng);
        }
      });

      final markers = <Marker>{
        ...stops.map((s) {
          if (isDriver) {
            final key = stopCardCacheKey(s);
            return Marker(
              markerId: MarkerId('stop_${s.passengerId}_${s.orderIndex}'),
              position: LatLng(s.latitude, s.longitude),
              anchor: const Offset(0.5, 1.0),
              zIndexInt: s.passengerId == selectedPassengerId ? 9 : 5,
              icon: driverStopCardsCache[key] ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    s.isCompleted
                        ? BitmapDescriptor.hueAzure
                        : (s.isPassengerReady
                            ? BitmapDescriptor.hueGreen
                            : BitmapDescriptor.hueOrange),
                  ),
              onTap: () => focusOnStop(s),
            );
          }

          return Marker(
            markerId: MarkerId('anon_stop_${s.orderIndex}'),
            position: LatLng(s.latitude, s.longitude),
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 3,
            consumeTapEvents: true,
            icon: anonymousStopIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
          );
        }),
        Marker(
          markerId: const MarkerId('destination'),
          position: destLatLng,
          zIndexInt: 4,
          icon: destIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: destLabel),
        ),
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLatLng,
          rotation: isDriver ? currentBearing : 0.0,
          flat: isDriver,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 10,
          icon: isDriver
              ? (driverArrowIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ))
              : (busVehicleIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  )),
          infoWindow: isDriver
              ? InfoWindow.noText
              : const InfoWindow(title: 'Motorista em deslocamento'),
        ),
      };

      final polylines = <Polyline>{
        Polyline(
          polylineId: const PolylineId('route_outline'),
          points: activePolyline,
          width: isDriver ? 12 : 9,
          color: LiveMapMarkerFactory.appBlueDark,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
        Polyline(
          polylineId: const PolylineId('route_core'),
          points: activePolyline,
          width: isDriver ? 7 : 5,
          color: LiveMapMarkerFactory.appBlue,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };

      return Scaffold(
        backgroundColor: isDriver ? Colors.black : theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: driverLatLng,
                zoom: isDriver ? 15.8 : 14.8,
                tilt: isDriver ? 60.0 : 25.0,
                bearing: isDriver
                    ? calculateBearing(driverLatLng, lookAheadPoint)
                    : 0.0,
              ),
              style: isDark ? LiveMapMarkerFactory.darkMapStyle : null,
              buildingsEnabled: true,
              tiltGesturesEnabled: isDriver,
              rotateGesturesEnabled: isDriver,
              compassEnabled: false,
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + (isDriver ? 138 : 82),
                bottom: (isDriver && isStopsExpanded) ? 310 : 124,
              ),
              markers: markers,
              polylines: polylines,
              onTap: (_) {
                if (selectedPassengerId != null) {
                  setState(() => selectedPassengerId = null);
                }
              },
              onMapCreated: (controller) {
                mapController = controller;
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (!mounted) return;
                  if (isDriver) {
                    animateCameraToDriver(
                      driverLatLng,
                      calculateBearing(driverLatLng, lookAheadPoint),
                    );
                  } else if (activePolyline.length >= 2) {
                    fitOverviewBounds(activePolyline);
                  }
                });
              },
            ),
            if (isDriver)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DriverNavigationBanner(
                  maneuverIcon: nextManeuverIcon,
                  distanceLabel: formatDistance(bannerDistanceMeters),
                  nextBannerTitle: nextBannerTitle,
                  onBack: () {
                    if (context.canPop()) context.pop();
                  },
                ),
              )
            else
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                child: PassengerTrackingHeader(
                  companyName: companyName,
                  destinationLabel: destLabel,
                  onBack: () {
                    if (context.canPop()) context.pop();
                  },
                ),
              ),
            if (isDriver)
              Positioned(
                left: 16,
                right: 16,
                bottom: isStopsExpanded ? 298 : 114,
                child: DriverMapFloatingControls(
                  speedKmh: currentSpeedKmh.round(),
                  followDriver: followDriver,
                  bottomPillLabel: bottomPillLabel,
                  onRecenter: () {
                    setState(() {
                      followDriver = true;
                      selectedPassengerId = null;
                    });
                    animateCameraToDriver(
                      driverLatLng,
                      calculateBearing(driverLatLng, lookAheadPoint),
                    );
                  },
                ),
              )
            else
              Positioned(
                right: 16,
                bottom: 118,
                child: PassengerRecenterButton(
                  followDriver: followDriver,
                  onPressed: () {
                    setState(() => followDriver = true);
                    animateCameraToDriver(driverLatLng, 0.0);
                  },
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LiveMapBottomSheet(
                isDriver: isDriver,
                isExpanded: isStopsExpanded,
                arrivalClock: formatArrivalClock(estimatedMinutes),
                estimatedMinutes: estimatedMinutes,
                remainingDistanceLabel: formatDistance(totalRemainingMeters),
                stops: stops,
                selectedPassengerId: selectedPassengerId,
                onOverview: () => fitOverviewBounds(activePolyline),
                onToggleExpand: () {
                  setState(() => isStopsExpanded = !isStopsExpanded);
                },
                onTapStop: focusOnStop,
              ),
            ),
          ],
        ),
      );
    });
  }
}