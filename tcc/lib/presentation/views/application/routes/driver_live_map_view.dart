import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/feedback/animated_three_dots.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../../domain/models/trip_entity.dart';
import '../../../widgets/feedback/indigo_splash_loader.dart';
import '../../../widgets/live_map/live_map_bottom_sheet.dart';
import '../../../widgets/live_map/live_map_floating_controls.dart';
import '../../../widgets/live_map/live_map_marker_factory.dart';
import '../../../widgets/live_map/live_map_navigation_engine.dart';
import '../../../widgets/live_map/live_map_top_bar.dart';
import '../../mixins/route/driver_live_map_logic.dart';

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
  Set<Marker> _buildMarkers({
    required BuildContext context,
    required List<TripStopPoint> stops,
    required LatLng driverLatLng,
    required LatLng destLatLng,
    required bool isDark,
  }) {
    final isDriver = widget.isDriver;

    return {
      ...stops.map((s) {
        if (isDriver) {
          final key = stopCardCacheKey(s, isDark);
          return Marker(
            markerId: MarkerId('stop_${s.passengerId}_${s.orderIndex}'),
            position: LatLng(s.latitude, s.longitude),
            anchor: const Offset(0.5, 1.0),
            zIndexInt: s.passengerId == selectedPassengerId ? 9 : 5,
            icon:
                driverStopCardsCache[key] ??
                BitmapDescriptor.defaultMarkerWithHue(
                  s.isCompleted
                      ? BitmapDescriptor.hueAzure
                      : (s.isPassengerReady
                            ? BitmapDescriptor.hueGreen
                            : BitmapDescriptor.hueOrange),
                ),
            onTap: () {
              focusOnStop(s);
              showPassengerAddressModal(context, s);
            },
          );
        }

        final anonymousTitle = s.isCompleted
            ? 'Embarque concluído'
            : (s.isPassengerReady
                  ? 'Passageiro pronto'
                  : 'Passageiro aguardando');

        return Marker(
          markerId: MarkerId('anon_stop_${s.orderIndex}'),
          position: LatLng(s.latitude, s.longitude),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
          icon:
              anonymousIconForStop(s) ??
              BitmapDescriptor.defaultMarkerWithHue(
                s.isCompleted
                    ? BitmapDescriptor.hueAzure
                    : (s.isPassengerReady
                          ? BitmapDescriptor.hueGreen
                          : BitmapDescriptor.hueOrange),
              ),
          infoWindow: InfoWindow(title: anonymousTitle),
        );
      }),
      Marker(
        markerId: const MarkerId('destination'),
        position: destLatLng,
        zIndexInt: 4,
        icon:
            destIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: destinationLabel),
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
  }

  Set<Polyline> _buildPolylines(List<LatLng> points, bool isDriver) {
    return {
      Polyline(
        polylineId: const PolylineId('route_outline'),
        points: points,
        width: isDriver ? 12 : 9,
        color: LiveMapMarkerFactory.appBlueDark,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
      Polyline(
        polylineId: const PolylineId('route_core'),
        points: points,
        width: isDriver ? 7 : 5,
        color: LiveMapMarkerFactory.appBlue,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isDriver = widget.isDriver;

    ensureBaseIconsForTheme(isDark);

    return Watch((context) {
      final liveTrip = tripViewModel.state.activeTrip.value ?? widget.trip;

      final originLatLng = LatLng(
        widget.route.origin.latitude,
        widget.route.origin.longitude,
      );
      final destLatLng = LatLng(
        widget.route.destination.latitude,
        widget.route.destination.longitude,
      );

      final firebaseDriverLatLng =
          (liveTrip?.driverLatitude != null &&
              liveTrip?.driverLongitude != null)
          ? LatLng(liveTrip!.driverLatitude!, liveTrip.driverLongitude!)
          : null;

      final driverLatLng = isDriver
          ? (liveGpsDriverPosition ?? firebaseDriverLatLng ?? originLatLng)
          : (firebaseDriverLatLng ?? originLatLng);

      final rawStops = (liveTrip != null && liveTrip.stops.isNotEmpty)
          ? liveTrip.stops
          : widget.stops;
      final stops = resolveOrderedStops(rawStops, driverLatLng);

      if (isDriver) ensureDriverStopCards(stops, isDark: isDark);

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
      final lookAheadPoint = activePolyline.length >= 2
          ? activePolyline[1]
          : nextTargetLatLng;

      final bannerDistanceMeters =
          nextManeuverDistanceMeters ??
          LiveMapNavigationEngine.distanceMeters(
            driverLatLng,
            nextTargetLatLng,
          );
      final totalRemainingMeters =
          roadTotalDistanceMeters ??
          LiveMapNavigationEngine.polylineLengthMeters(fallbackPoints);
      final estimatedMinutes =
          roadTotalDurationMinutes ??
          nextStop?.estimatedMinutesRemaining ??
          ((totalRemainingMeters / 1000) / 38 * 60).ceil().clamp(1, 999);

      final companyName = (widget.company?.name.trim().isNotEmpty == true)
          ? widget.company!.name.trim()
          : 'Transporte';

      final nextBannerTitle =
          nextRoadName ??
          (nextStop != null
              ? '${LiveMapMarkerFactory.firstName(nextStop.passengerName)} (Parada #${nextStop.orderIndex})'
              : destinationLabel);

      final bottomPillLabel =
          currentRoadName ??
          (nextStop != null
              ? 'Próxima parada: ${LiveMapMarkerFactory.firstName(nextStop.passengerName)}'
              : destinationLabel);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        syncDriverMotion(driverLatLng, lookAheadPoint);
        maybeFetchRoadRoute(driverLatLng, pendingStops, destLatLng);
      });

      final initialBearing = isDriver
          ? LiveMapNavigationEngine.calculateBearing(
              driverLatLng,
              lookAheadPoint,
            )
          : 0.0;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            GoogleMap(
              key: ValueKey('live_map_${isDark ? 'dark' : 'light'}'),
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: driverLatLng,
                zoom: isDriver ? 16.2 : 14.8,
                tilt: isDriver ? 60.0 : 0.0,
                bearing: initialBearing,
              ),
              style: isDark ? LiveMapMarkerFactory.darkMapStyle : null,
              buildingsEnabled: isDriver,
              tiltGesturesEnabled: isDriver,
              rotateGesturesEnabled: isDriver,
              compassEnabled: false,
              zoomControlsEnabled: false,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + (isDriver ? 168 : 82),
                bottom: (isDriver && isStopsExpanded) ? 330 : 134,
              ),
              markers: _buildMarkers(
                context: context,
                stops: stops,
                driverLatLng: driverLatLng,
                destLatLng: destLatLng,
                isDark: isDark,
              ),
              polylines: _buildPolylines(activePolyline, isDriver),
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
                    animateCameraToDriver(driverLatLng, initialBearing);
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
                  distanceLabel: LiveMapNavigationEngine.formatDistance(
                    bannerDistanceMeters,
                  ),
                  nextBannerTitle: nextBannerTitle,
                  thenBannerTitle: thenRoadName,
                  thenManeuverIcon: thenManeuverIcon,
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
                  destinationLabel: destinationLabel,
                  onBack: () {
                    if (context.canPop()) context.pop();
                  },
                ),
              ),
            if (isDriver)
              Positioned(
                left: 16,
                right: 16,
                bottom: isStopsExpanded ? 320 : 114,
                child: DriverMapFloatingControls(
                  speedKmh: currentSpeedKmh.round(),
                  followDriver: followDriver,
                  bottomPillLabel: bottomPillLabel,
                  onRecenter: () {
                    setState(() {
                      followDriver = true;
                      selectedPassengerId = null;
                    });
                    animateCameraToDriver(driverLatLng, initialBearing);
                  },
                ),
              )
            else
              Positioned(
                right: 16,
                bottom: 132,
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
                arrivalClock: LiveMapNavigationEngine.formatArrivalClock(
                  estimatedMinutes,
                ),
                estimatedMinutes: estimatedMinutes,
                remainingDistanceLabel: LiveMapNavigationEngine.formatDistance(
                  totalRemainingMeters,
                ),
                stops: stops,
                selectedPassengerId: selectedPassengerId,
                resolvedAddresses: resolvedAddressByPassengerId,
                onOverview: () => fitOverviewBounds(activePolyline),
                onToggleExpand: () {
                  setState(() => isStopsExpanded = !isStopsExpanded);
                },
                onTapStop: focusOnStop,
                onOpenStopAddress: isDriver
                    ? (stop) => showPassengerAddressModal(context, stop)
                    : null,
              ),
            ),
            Watch((context) {
              final loading = isInitialLoading.value;
              final statusText = initialLoadingMessage.value;

              return IgnorePointer(
                ignoring: !loading,
                child: AnimatedOpacity(
                  opacity: loading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: theme.scaffoldBackgroundColor,
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IndigoSplashLoader(
                              isLoading: loading,
                              duration: const Duration(milliseconds: 3500),
                              message: statusText,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
