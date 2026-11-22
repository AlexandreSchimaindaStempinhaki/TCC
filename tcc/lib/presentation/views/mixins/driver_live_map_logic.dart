import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/models/trip_entity.dart';
import '../../controllers/trip/trip_viewmodel.dart';
import '../../widgets/live_map/live_map_bottom_sheet.dart';
import '../../widgets/live_map/live_map_marker_factory.dart';
import '../../widgets/live_map/live_map_navigation_engine.dart';
import '../../widgets/live_map/live_map_routing_service.dart';
import '../application/routes/driver_live_map_view.dart';

mixin DriverLiveMapMixin on State<DriverLiveMapView> {
  final LiveMapRoutingService _routingService = LiveMapRoutingService();

  late final TripViewModel tripViewModel;
  GoogleMapController? mapController;

  final isInitialLoading = signal<bool>(true);
  final initialLoadingMessage = signal<String>('Preparando navegação...');

  bool _hasInitialLocation = false;
  bool _hasInitialRoute = false;
  Timer? _initialLoadingTimeout;

  StreamSubscription<Position>? _gpsSubscription;
  DateTime? _lastFirebaseLocationPush;
  LatLng? _lastPushedPosition;

  LatLng? liveGpsDriverPosition;
  bool followDriver = true;
  bool isStopsExpanded = false;
  String? selectedPassengerId;

  final Map<String, int> _roadEtaByPassengerId = {};
  final Map<String, String> resolvedAddressByPassengerId = {};
  List<String> _googleOptimizedOrderIds = const [];

  List<NavStep> _navSteps = const [];
  int _currentStepIndex = 0;
  List<TripStopPoint> _lastPendingStops = const [];
  LatLng? _lastDestination;

  LatLng? _lastDriverPos;
  DateTime? _lastDriverTimestamp;
  double currentSpeedKmh = 0;
  double currentBearing = 0;

  List<LatLng> roadPolylinePoints = const [];
  double? roadTotalDistanceMeters;
  int? roadTotalDurationMinutes;
  double? nextManeuverDistanceMeters;
  String? nextRoadName;
  String? thenRoadName;
  String? currentRoadName;
  IconData nextManeuverIcon = Icons.straight_rounded;
  IconData? thenManeuverIcon;

  bool _isFetchingRoute = false;
  LatLng? _lastRoutedOrigin;
  String? _lastStopsSignature;
  DateTime? _lastRouteFetchTime;

  bool? _iconsPreparedForDark;
  BitmapDescriptor? driverArrowIcon;
  BitmapDescriptor? busVehicleIcon;
  BitmapDescriptor? destIcon;
  BitmapDescriptor? anonReadyIcon;
  BitmapDescriptor? anonWaitingIcon;
  BitmapDescriptor? anonCompletedIcon;

  final Map<String, BitmapDescriptor> driverStopCardsCache = {};
  final Set<String> _loadingStopCardKeys = {};

  @override
  void initState() {
    super.initState();
    tripViewModel = injector.get<TripViewModel>();
    _routingService.loadApiKey();

    _hasInitialLocation = !widget.isDriver;
    initialLoadingMessage.value = widget.isDriver
        ? 'Obtendo sua localização...'
        : 'Carregando trajeto em tempo real...';
    _startInitialLoadingGuard();

    if (widget.trip != null && widget.trip!.id.trim().isNotEmpty) {
      tripViewModel.commands.startWatchingTrip(widget.trip!.id);
    }

    if (widget.isDriver) {
      _startDriverGpsTracking();
    }
  }

  @override
  void dispose() {
    _initialLoadingTimeout?.cancel();
    isInitialLoading.dispose();
    initialLoadingMessage.dispose();
    _gpsSubscription?.cancel();
    if (widget.trip != null && widget.trip!.id.trim().isNotEmpty) {
      tripViewModel.commands.stopWatchingTrip();
    }
    mapController?.dispose();
    super.dispose();
  }

  void _startInitialLoadingGuard() {
    _initialLoadingTimeout?.cancel();
    _initialLoadingTimeout = Timer(const Duration(seconds: 7), () {
      if (mounted && isInitialLoading.value) {
        isInitialLoading.value = false;
      }
    });
  }

  void _markInitialLocationReady() {
    if (_hasInitialLocation) return;
    _hasInitialLocation = true;
    if (isInitialLoading.value) {
      initialLoadingMessage.value = 'Calculando melhor rota...';
    }
    _tryFinishInitialLoading();
  }

  void _tryFinishInitialLoading() {
    if (!mounted || !isInitialLoading.value) return;
    if (_hasInitialLocation && _hasInitialRoute) {
      _initialLoadingTimeout?.cancel();
      isInitialLoading.value = false;
    }
  }

  String get destinationLabel =>
      (widget.route.destinationName?.trim().isNotEmpty == true)
          ? widget.route.destinationName!.trim()
          : 'Destino da Rota';

  Future<void> _startDriverGpsTracking() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _markInitialLocationReady();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _markInitialLocationReady();
        return;
      }

      _handleDriverGpsUpdate(await Geolocator.getCurrentPosition());
      _markInitialLocationReady();

      _gpsSubscription?.cancel();
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 4,
        ),
      ).listen(_handleDriverGpsUpdate);
    } catch (e) {
      debugPrint('Erro ao iniciar rastreamento GPS do motorista: $e');
      _markInitialLocationReady();
    }
  }

  void _handleDriverGpsUpdate(Position pos) {
    if (!mounted) return;
    final newPos = LatLng(pos.latitude, pos.longitude);
    final double speedKmh = (pos.speed.isFinite && pos.speed >= 0)
        ? (pos.speed * 3.6).clamp(0.0, 150.0).toDouble()
        : currentSpeedKmh;
    final double heading =
        (pos.heading.isFinite && pos.heading >= 0 && pos.speed > 1.0)
            ? pos.heading.toDouble()
            : currentBearing;

    setState(() {
      liveGpsDriverPosition = newPos;
      currentSpeedKmh = speedKmh;
      currentBearing = heading;
    });

    _updateTurnByTurnProgress(newPos);
    if (followDriver) animateCameraToDriver(newPos, currentBearing);
    _pushDriverLocationToFirebase(newPos, speedKmh);
  }

  Future<void> _pushDriverLocationToFirebase(
    LatLng pos,
    double speedKmh,
  ) async {
    final activeTrip = tripViewModel.state.activeTrip.value ?? widget.trip;
    if (activeTrip == null || activeTrip.id.trim().isEmpty) return;

    final now = DateTime.now();
    final elapsedOk = _lastFirebaseLocationPush == null ||
        now.difference(_lastFirebaseLocationPush!).inSeconds >= 5;
    final movedOk = _lastPushedPosition == null ||
        LiveMapNavigationEngine.distanceMeters(_lastPushedPosition!, pos) >=
            12.0;

    if (!elapsedOk && !movedOk) return;

    _lastFirebaseLocationPush = now;
    _lastPushedPosition = pos;

    await tripViewModel.commands.updateDriverLocation(
      tripId: activeTrip.id,
      latitude: pos.latitude,
      longitude: pos.longitude,
      isSharingLocation: true,
      averageSpeedKmh: speedKmh > 5 ? speedKmh : 35.0,
    );
  }

  Future<void> ensureBaseIconsForTheme(bool isDark) async {
    if (_iconsPreparedForDark == isDark) return;
    _iconsPreparedForDark = isDark;

    final dest = await LiveMapMarkerFactory.createDestinationIcon();
    if (widget.isDriver) {
      final arrow = await LiveMapMarkerFactory.createDriverArrowIcon();
      if (!mounted) return;
      setState(() {
        driverArrowIcon = arrow;
        destIcon = dest;
      });
    } else {
      final bus = await LiveMapMarkerFactory.createBusVehicleIcon();
      final ready = await LiveMapMarkerFactory.createAnonymousStopIcon(
        isReady: true,
        isCompleted: false,
        isDark: isDark,
      );
      final waiting = await LiveMapMarkerFactory.createAnonymousStopIcon(
        isReady: false,
        isCompleted: false,
        isDark: isDark,
      );
      final completed = await LiveMapMarkerFactory.createAnonymousStopIcon(
        isReady: false,
        isCompleted: true,
        isDark: isDark,
      );
      if (!mounted) return;
      setState(() {
        busVehicleIcon = bus;
        anonReadyIcon = ready;
        anonWaitingIcon = waiting;
        anonCompletedIcon = completed;
        destIcon = dest;
      });
    }
  }

  BitmapDescriptor? anonymousIconForStop(TripStopPoint stop) {
    if (stop.isCompleted) return anonCompletedIcon;
    return stop.isPassengerReady ? anonReadyIcon : anonWaitingIcon;
  }

  List<TripStopPoint> resolveOrderedStops(
    List<TripStopPoint> rawStops,
    LatLng startPoint,
  ) {
    return LiveMapNavigationEngine.orderStops(
      rawStops: rawStops,
      startPoint: startPoint,
      googleOptimizedOrderIds: _googleOptimizedOrderIds,
      etaByPassengerId: _roadEtaByPassengerId,
      addressByPassengerId: resolvedAddressByPassengerId,
    );
  }

  String stopCardCacheKey(TripStopPoint stop, bool isDark) =>
      '${isDark ? 'd' : 'l'}_${stop.passengerId}_${stop.orderIndex}_${stop.isPassengerReady}_${stop.isCompleted}_${stop.estimatedMinutesRemaining ?? -1}_${stop.passengerPhotoUrl ?? ''}';

  Future<void> ensureDriverStopCards(
    List<TripStopPoint> stops, {
    required bool isDark,
  }) async {
    if (!widget.isDriver) return;

    for (final stop in stops) {
      final key = stopCardCacheKey(stop, isDark);
      if (driverStopCardsCache.containsKey(key) ||
          _loadingStopCardKeys.contains(key)) {
        continue;
      }
      _loadingStopCardKeys.add(key);
      LiveMapMarkerFactory.createPassengerMapCardIcon(stop, isDark: isDark)
          .then((descriptor) {
        _loadingStopCardKeys.remove(key);
        if (!mounted) return;
        setState(() => driverStopCardsCache[key] = descriptor);
      }).catchError((_) {
        _loadingStopCardKeys.remove(key);
      });
    }
  }

  Future<void> maybeFetchRoadRoute(
    LatLng driverPos,
    List<TripStopPoint> pendingStops,
    LatLng destination, {
    bool force = false,
  }) async {
    _lastPendingStops = pendingStops;
    _lastDestination = destination;
    if (_isFetchingRoute) return;

    final stopsSig = pendingStops
        .map(
          (s) =>
              '${s.passengerId}:${s.isPassengerReady ? 1 : 0}:${s.latitude.toStringAsFixed(4)},${s.longitude.toStringAsFixed(4)}',
        )
        .join('|');

    final now = DateTime.now();
    final stopsChanged = stopsSig != _lastStopsSignature;
    final movedFarEnough = _lastRoutedOrigin == null ||
        LiveMapNavigationEngine.distanceMeters(_lastRoutedOrigin!, driverPos) >=
            (_navSteps.isNotEmpty ? 150.0 : 40.0);
    final cooldownPassed = _lastRouteFetchTime == null ||
        now.difference(_lastRouteFetchTime!).inSeconds >=
            (_navSteps.isNotEmpty ? 30 : 10);

    if (!force && !stopsChanged && !(movedFarEnough && cooldownPassed)) {
      if (_hasInitialLocation &&
          !_hasInitialRoute &&
          _lastRouteFetchTime != null) {
        _hasInitialRoute = true;
        _tryFinishInitialLoading();
      }
      return;
    }

    _isFetchingRoute = true;
    _lastRoutedOrigin = driverPos;
    _lastStopsSignature = stopsSig;
    _lastRouteFetchTime = now;

    try {
      final result = await _routingService.fetchBestRoute(
        driverPos: driverPos,
        pendingStops: pendingStops,
        destination: destination,
        destinationLabel: destinationLabel,
      );
      if (result == null || !mounted) return;

      setState(() {
        if (result.polylinePoints.length >= 2) {
          roadPolylinePoints = result.polylinePoints;
          if (currentBearing == 0) {
            currentBearing = LiveMapNavigationEngine.calculateBearing(
              result.polylinePoints[0],
              result.polylinePoints[1],
            );
          }
        }
        _navSteps = result.navSteps;
        _currentStepIndex = 0;
        if (result.totalDistanceMeters != null) {
          roadTotalDistanceMeters = result.totalDistanceMeters;
        }
        if (result.totalDurationMinutes != null) {
          roadTotalDurationMinutes = result.totalDurationMinutes;
        }
        if (result.optimizedOrderIds.isNotEmpty) {
          _googleOptimizedOrderIds = result.optimizedOrderIds;
        }
        _roadEtaByPassengerId
          ..clear()
          ..addAll(result.etaByPassengerId);
        resolvedAddressByPassengerId.addAll(result.addressByPassengerId);
      });

      _updateTurnByTurnProgress(driverPos, forceUiSync: true);
    } catch (e) {
      debugPrint('Erro ao calcular rota: $e');
    } finally {
      _isFetchingRoute = false;
      if (_hasInitialLocation && !_hasInitialRoute) {
        _hasInitialRoute = true;
        _tryFinishInitialLoading();
      }
    }
  }

  void _updateTurnByTurnProgress(
    LatLng driverPos, {
    bool forceUiSync = false,
  }) {
    final snap = LiveMapNavigationEngine.evaluateTurnByTurn(
      driverPos: driverPos,
      navSteps: _navSteps,
      currentStepIndex: _currentStepIndex,
    );
    if (snap == null || !mounted) return;

    // Recálculo automático fora de rota (> 55m da via traçada)
    if (widget.isDriver &&
        snap.distanceToPathMeters > 55.0 &&
        _lastDestination != null &&
        !_isFetchingRoute) {
      final canReroute = _lastRouteFetchTime == null ||
          DateTime.now().difference(_lastRouteFetchTime!).inSeconds >= 6;
      if (canReroute) {
        maybeFetchRoadRoute(
          driverPos,
          _lastPendingStops,
          _lastDestination!,
          force: true,
        );
      }
    }

    final bool significantChange = forceUiSync ||
        snap.stepIndex != _currentStepIndex ||
        nextRoadName != snap.bannerTitle ||
        thenRoadName != snap.thenTitle ||
        currentRoadName != snap.currentStreet ||
        nextManeuverIcon != snap.bannerIcon ||
        thenManeuverIcon != snap.thenIcon ||
        nextManeuverDistanceMeters == null ||
        (snap.nextManeuverDistanceMeters - nextManeuverDistanceMeters!).abs() >=
            5.0;

    if (!significantChange) return;

    setState(() {
      _currentStepIndex = snap.stepIndex;
      nextManeuverDistanceMeters = snap.nextManeuverDistanceMeters;
      nextRoadName = snap.bannerTitle;
      nextManeuverIcon = snap.bannerIcon;
      thenRoadName = snap.thenTitle;
      thenManeuverIcon = snap.thenIcon;
      currentRoadName = snap.currentStreet;
      roadTotalDistanceMeters = snap.remainingTotalMeters;
      roadTotalDurationMinutes = snap.remainingMinutes;
    });
  }

  Future<String?> _resolveStopAddress(TripStopPoint stop) async {
    if (stop.passengerAddress?.trim().isNotEmpty == true) {
      return stop.passengerAddress!.trim();
    }
    final cached = resolvedAddressByPassengerId[stop.passengerId];
    if (cached != null && cached.trim().isNotEmpty) return cached;

    final fetched = await _routingService.reverseGeocode(
      LatLng(stop.latitude, stop.longitude),
    );
    if (fetched != null && mounted) {
      setState(() => resolvedAddressByPassengerId[stop.passengerId] = fetched);
    }
    return fetched;
  }

  Future<void> showPassengerAddressModal(
    BuildContext context,
    TripStopPoint stop,
  ) async {
    if (!widget.isDriver) return;

    setState(() => selectedPassengerId = stop.passengerId);
    final existing = (stop.passengerAddress?.trim().isNotEmpty == true)
        ? stop.passengerAddress!.trim()
        : resolvedAddressByPassengerId[stop.passengerId];
    final addressFuture =
        existing != null ? Future.value(existing) : _resolveStopAddress(stop);
    final activeTrip = tripViewModel.state.activeTrip.value ?? widget.trip;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return FutureBuilder<String?>(
          future: addressFuture,
          initialData: existing,
          builder: (context, snapshot) {
            return PassengerAddressDetailSheet(
              stop: stop,
              fullAddress: snapshot.data,
              isLoadingAddress:
                  snapshot.connectionState == ConnectionState.waiting,
              onCenterOnMap: () => focusOnStop(stop),
              onToggleCompleted:
                  activeTrip != null && activeTrip.id.trim().isNotEmpty
                      ? (completed) async {
                          await tripViewModel.commands.markStopCompleted(
                            tripId: activeTrip.id,
                            passengerId: stop.passengerId,
                            isCompleted: completed,
                          );
                        }
                      : null,
            );
          },
        );
      },
    );
  }

  void syncDriverMotion(LatLng driverPos, LatLng lookAheadPoint) {
    final now = DateTime.now();
    final bearingToAhead =
        LiveMapNavigationEngine.calculateBearing(driverPos, lookAheadPoint);

    if (_lastDriverPos != null && _lastDriverTimestamp != null) {
      final double movedMeters =
          LiveMapNavigationEngine.distanceMeters(_lastDriverPos!, driverPos);
      final double elapsedSeconds =
          now.difference(_lastDriverTimestamp!).inMilliseconds / 1000.0;

      if (movedMeters >= 2.0 && elapsedSeconds >= 0.8) {
        if (!widget.isDriver) {
          currentSpeedKmh = ((movedMeters / elapsedSeconds) * 3.6)
              .clamp(0.0, 140.0)
              .toDouble();
          currentBearing = LiveMapNavigationEngine.calculateBearing(
            _lastDriverPos!,
            driverPos,
          );
        }
        _lastDriverPos = driverPos;
        _lastDriverTimestamp = now;
        _updateTurnByTurnProgress(driverPos);
        if (followDriver) animateCameraToDriver(driverPos, currentBearing);
      } else if (currentBearing == 0) {
        currentBearing = bearingToAhead;
      }
    } else {
      _lastDriverPos = driverPos;
      _lastDriverTimestamp = now;
      currentBearing = bearingToAhead;
    }
  }

  Future<void> animateCameraToDriver(LatLng target, double bearing) async {
    if (mapController == null) return;
    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: widget.isDriver ? 17.2 : 15.2,
          tilt: widget.isDriver ? 60.0 : 0.0,
          bearing: widget.isDriver ? bearing : 0.0,
        ),
      ),
    );
  }

  Future<void> focusOnStop(TripStopPoint stop) async {
    if (mapController == null) return;
    setState(() {
      followDriver = false;
      selectedPassengerId = stop.passengerId;
    });
    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(stop.latitude, stop.longitude),
          zoom: 17.4,
          tilt: widget.isDriver ? 48.0 : 0.0,
          bearing: 0.0,
        ),
      ),
    );
  }

  Future<void> fitOverviewBounds(List<LatLng> points) async {
    if (mapController == null || points.length < 2) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    setState(() => followDriver = false);
    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }
}