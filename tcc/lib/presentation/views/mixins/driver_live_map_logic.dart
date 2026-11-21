import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/di/dependency_injection.dart';
import '../../../domain/models/trip_entity.dart';
import '../../controllers/trip/trip_viewmodel.dart';
import '../../widgets/live_map/live_map_marker_factory.dart';
import '../application/routes/driver_live_map_view.dart';

mixin DriverLiveMapMixin on State<DriverLiveMapView> {
  // Troque para false quando quiser usar exclusivamente as paradas reais do Firestore.
  static const bool useMockDemoData = true;

  late final TripViewModel tripViewModel;
  GoogleMapController? mapController;

  bool followDriver = true;
  bool isStopsExpanded = false;
  String? selectedPassengerId;

  List<TripStopPoint> mockStops = const [];
  LatLng? mockDriverPosition;
  bool mockRoadStopsReady = false;
  final Map<String, int> _roadEtaByPassengerId = {};

  LatLng? _lastDriverPos;
  DateTime? _lastDriverTimestamp;
  double currentSpeedKmh = 42;
  double currentBearing = 0;

  List<LatLng> roadPolylinePoints = const [];
  double? roadTotalDistanceMeters;
  int? roadTotalDurationMinutes;
  double? nextManeuverDistanceMeters;
  String? nextRoadName;
  String? currentRoadName;
  IconData nextManeuverIcon = Icons.straight_rounded;

  bool _isFetchingRoute = false;
  LatLng? _lastRoutedOrigin;
  String? _lastStopsSignature;
  DateTime? _lastRouteFetchTime;

  BitmapDescriptor? driverArrowIcon;
  BitmapDescriptor? busVehicleIcon;
  BitmapDescriptor? destIcon;
  BitmapDescriptor? anonymousStopIcon;
  final Map<String, BitmapDescriptor> driverStopCardsCache = {};
  final Set<String> _loadingStopCardKeys = {};

  @override
  void initState() {
    super.initState();
    tripViewModel = injector.get<TripViewModel>();
    if (!useMockDemoData && widget.trip != null) {
      tripViewModel.commands.startWatchingTrip(widget.trip!.id);
    }
    _prepareBaseIcons();
    if (useMockDemoData) {
      _bootstrapMockStopsOnRealRoad();
    }
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  (LatLng origin, LatLng dest) resolveDemoAnchors() {
    final routeOrigin = LatLng(
      widget.route.origin.latitude,
      widget.route.origin.longitude,
    );
    final routeDest = LatLng(
      widget.route.destination.latitude,
      widget.route.destination.longitude,
    );

    final validCoords = routeOrigin.latitude.abs() > 0.1 &&
        routeDest.latitude.abs() > 0.1 &&
        distanceMeters(routeOrigin, routeDest) >= 800;

    if (validCoords) return (routeOrigin, routeDest);

    return (
      const LatLng(-25.67258, -48.45815),
      const LatLng(-25.57545, -48.35692),
    );
  }

  LatLng _pointAlongPolyline(
    List<LatLng> points,
    List<double> cumulativeMeters,
    double fraction,
  ) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1 || cumulativeMeters.last <= 0) return points.first;

    final targetDist = cumulativeMeters.last * fraction.clamp(0.0, 1.0);
    for (int i = 0; i < points.length - 1; i++) {
      final startDist = cumulativeMeters[i];
      final endDist = cumulativeMeters[i + 1];
      if (targetDist <= endDist || i == points.length - 2) {
        final segLen = endDist - startDist;
        final t = segLen <= 0
            ? 0.0
            : ((targetDist - startDist) / segLen).clamp(0.0, 1.0);
        return LatLng(
          points[i].latitude + (points[i + 1].latitude - points[i].latitude) * t,
          points[i].longitude +
              (points[i + 1].longitude - points[i].longitude) * t,
        );
      }
    }
    return points.last;
  }

  Future<void> _bootstrapMockStopsOnRealRoad() async {
    final (origin, dest) = resolveDemoAnchors();
    List<LatLng> baseRoadPoints = [origin, dest];

    try {
      final coordsParam =
          '${origin.longitude.toStringAsFixed(6)},${origin.latitude.toStringAsFixed(6)};'
          '${dest.longitude.toStringAsFixed(6)},${dest.latitude.toStringAsFixed(6)}';

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordsParam'
        '?overview=full&geometries=geojson&continue_straight=true',
      );

      final response = await http
          .get(uri, headers: const {'User-Agent': 'IndigoTransportApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok') {
          final routes = data['routes'] as List<dynamic>?;
          if (routes != null && routes.isNotEmpty) {
            final primary = routes.first as Map<String, dynamic>;
            final geometry = primary['geometry'] as Map<String, dynamic>?;
            final rawCoords =
                geometry?['coordinates'] as List<dynamic>? ?? const [];
            final parsed = rawCoords.map((pair) {
              final list = pair as List<dynamic>;
              return LatLng(
                (list[1] as num).toDouble(),
                (list[0] as num).toDouble(),
              );
            }).toList();
            if (parsed.length >= 2) baseRoadPoints = parsed;
          }
        }
      }
    } catch (_) {}

    final cumulative = <double>[0.0];
    for (int i = 1; i < baseRoadPoints.length; i++) {
      cumulative.add(
        cumulative.last +
            distanceMeters(baseRoadPoints[i - 1], baseRoadPoints[i]),
      );
    }

    final pBoarded = _pointAlongPolyline(baseRoadPoints, cumulative, 0.08);
    final driverPos = _pointAlongPolyline(baseRoadPoints, cumulative, 0.18);
    final driverAhead = _pointAlongPolyline(baseRoadPoints, cumulative, 0.21);
    final pStop1 = _pointAlongPolyline(baseRoadPoints, cumulative, 0.34);
    final pStop2 = _pointAlongPolyline(baseRoadPoints, cumulative, 0.52);
    final pStop3 = _pointAlongPolyline(baseRoadPoints, cumulative, 0.70);
    final pStop4 = _pointAlongPolyline(baseRoadPoints, cumulative, 0.86);

    final rawStops = <TripStopPoint>[
      TripStopPoint(
        passengerId: 'mock_alexandre',
        passengerName: 'Alexandre Schimainda Stempinhaki',
        passengerPhotoUrl:
            'https://res.cloudinary.com/db37erprw/image/upload/v1795057188/medanncv6wfo8ejp2vii.jpg',
        latitude: pStop1.latitude,
        longitude: pStop1.longitude,
        orderIndex: 1,
        isPassengerReady: true,
        isCompleted: false,
      ),
      TripStopPoint(
        passengerId: 'mock_amanda',
        passengerName: 'Amanda Patrícia dos Santos',
        passengerPhotoUrl:
            'https://i.pinimg.com/736x/73/13/ed/7313ed61381ee09ee2713e51580da033.jpg',
        latitude: pStop2.latitude,
        longitude: pStop2.longitude,
        orderIndex: 2,
        isPassengerReady: true,
        isCompleted: false,
      ),
      TripStopPoint(
        passengerId: 'mock_leonardo',
        passengerName: 'Leonardo Vinicius Nogueira',
        passengerPhotoUrl:
            'https://i.pinimg.com/236x/9a/55/be/9a55bec64e4e3ae3f93a723cb27b8bf2.jpg',
        latitude: pStop3.latitude,
        longitude: pStop3.longitude,
        orderIndex: 3,
        isPassengerReady: false,
        isCompleted: false,
      ),
      TripStopPoint(
        passengerId: 'mock_camila',
        passengerName: 'Camila Almeida',
        passengerPhotoUrl: 'https://randomuser.me/api/portraits/women/22.jpg',
        latitude: pStop4.latitude,
        longitude: pStop4.longitude,
        orderIndex: 4,
        isPassengerReady: false,
        isCompleted: false,
      ),
      TripStopPoint(
        passengerId: 'mock_beatriz',
        passengerName: 'Beatriz Ferreira',
        passengerPhotoUrl: 'https://randomuser.me/api/portraits/women/68.jpg',
        latitude: pBoarded.latitude,
        longitude: pBoarded.longitude,
        orderIndex: 5,
        isPassengerReady: true,
        isCompleted: true,
      ),
    ];

    final optimized = optimizeStopsOrder(rawStops, driverPos);
    final initialBearing = calculateBearing(driverPos, driverAhead);

    if (!mounted) return;
    setState(() {
      mockDriverPosition = driverPos;
      mockStops = optimized;
      mockRoadStopsReady = true;
      currentBearing = initialBearing;
    });

    final pending = optimized.where((s) => !s.isCompleted).toList();
    await maybeFetchRoadRoute(driverPos, pending, dest, force: true);

    if (!mounted) return;
    if (widget.isDriver && followDriver) {
      await animateCameraToDriver(driverPos, currentBearing);
    } else if (!widget.isDriver && roadPolylinePoints.length >= 2) {
      await fitOverviewBounds(roadPolylinePoints);
    }
  }

  List<TripStopPoint> optimizeStopsOrder(
    List<TripStopPoint> stops,
    LatLng startPoint,
  ) {
    if (stops.isEmpty) return const [];

    final completed = stops.where((s) => s.isCompleted).toList();
    final pendingReady =
        stops.where((s) => !s.isCompleted && s.isPassengerReady).toList();
    final pendingWaiting =
        stops.where((s) => !s.isCompleted && !s.isPassengerReady).toList();

    final ordered = <TripStopPoint>[];
    LatLng cursor = startPoint;
    int cumulativeMinutes = 0;

    void consumeNearest(List<TripStopPoint> pool) {
      while (pool.isNotEmpty) {
        int bestIndex = 0;
        double bestDist = double.infinity;

        for (int i = 0; i < pool.length; i++) {
          final d = distanceMeters(
            cursor,
            LatLng(pool[i].latitude, pool[i].longitude),
          );
          if (d < bestDist) {
            bestDist = d;
            bestIndex = i;
          }
        }

        final chosen = pool.removeAt(bestIndex);
        cursor = LatLng(chosen.latitude, chosen.longitude);
        final legMin = math.max(1, ((bestDist / 1000.0) / 38.0 * 60).round());
        cumulativeMinutes += legMin;

        ordered.add(
          TripStopPoint(
            passengerId: chosen.passengerId,
            passengerName: chosen.passengerName,
            passengerPhotoUrl: chosen.passengerPhotoUrl,
            latitude: chosen.latitude,
            longitude: chosen.longitude,
            orderIndex: ordered.length + 1,
            isPassengerReady: chosen.isPassengerReady,
            isCompleted: false,
            estimatedMinutesRemaining:
                _roadEtaByPassengerId[chosen.passengerId] ?? cumulativeMinutes,
          ),
        );
      }
    }

    consumeNearest(pendingReady);
    consumeNearest(pendingWaiting);

    for (final done in completed) {
      ordered.add(
        TripStopPoint(
          passengerId: done.passengerId,
          passengerName: done.passengerName,
          passengerPhotoUrl: done.passengerPhotoUrl,
          latitude: done.latitude,
          longitude: done.longitude,
          orderIndex: ordered.length + 1,
          isPassengerReady: done.isPassengerReady,
          isCompleted: true,
        ),
      );
    }

    return ordered;
  }

  Future<void> _prepareBaseIcons() async {
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
      final anon = await LiveMapMarkerFactory.createAnonymousStopIcon();
      if (!mounted) return;
      setState(() {
        busVehicleIcon = bus;
        anonymousStopIcon = anon;
        destIcon = dest;
      });
    }
  }

  String stopCardCacheKey(TripStopPoint stop) =>
      '${stop.passengerId}_${stop.orderIndex}_${stop.isPassengerReady}_${stop.isCompleted}_${stop.estimatedMinutesRemaining ?? -1}_${stop.passengerPhotoUrl ?? ''}';

  Future<void> ensureDriverStopCards(List<TripStopPoint> stops) async {
    if (!widget.isDriver) return;

    for (final stop in stops) {
      final key = stopCardCacheKey(stop);
      if (driverStopCardsCache.containsKey(key) ||
          _loadingStopCardKeys.contains(key)) {
        continue;
      }
      _loadingStopCardKeys.add(key);
      LiveMapMarkerFactory.createPassengerMapCardIcon(stop).then((descriptor) {
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
    if (_isFetchingRoute) return;

    final stopsSig = pendingStops
        .map(
          (s) =>
              '${s.passengerId}:${s.orderIndex}:${s.latitude.toStringAsFixed(4)},${s.longitude.toStringAsFixed(4)}',
        )
        .join('|');

    final now = DateTime.now();
    final stopsChanged = stopsSig != _lastStopsSignature;
    final movedFarEnough = _lastRoutedOrigin == null ||
        distanceMeters(_lastRoutedOrigin!, driverPos) >= 35.0;
    final cooldownPassed = _lastRouteFetchTime == null ||
        now.difference(_lastRouteFetchTime!).inSeconds >= 8;

    if (!force && !stopsChanged && !(movedFarEnough && cooldownPassed)) return;

    _isFetchingRoute = true;
    _lastRoutedOrigin = driverPos;
    _lastStopsSignature = stopsSig;
    _lastRouteFetchTime = now;

    try {
      final waypoints = <LatLng>[
        driverPos,
        ...pendingStops.map((s) => LatLng(s.latitude, s.longitude)),
        destination,
      ];

      final coordsParam = waypoints
          .map(
            (p) =>
                '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}',
          )
          .join(';');

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordsParam'
        '?overview=full&geometries=geojson&steps=true&continue_straight=true',
      );

      final response = await http
          .get(uri, headers: const {'User-Agent': 'IndigoTransportApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') return;

      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return;

      final primaryRoute = routes.first as Map<String, dynamic>;
      final geometry = primaryRoute['geometry'] as Map<String, dynamic>?;
      final rawCoords = geometry?['coordinates'] as List<dynamic>? ?? const [];

      final parsedPoints = rawCoords.map((pair) {
        final list = pair as List<dynamic>;
        return LatLng(
          (list[1] as num).toDouble(),
          (list[0] as num).toDouble(),
        );
      }).toList();

      final totalMeters = (primaryRoute['distance'] as num?)?.toDouble();
      final totalSeconds = (primaryRoute['duration'] as num?)?.toDouble();

      String? currentVia;
      String? nextVia;
      double? nextStepDist;
      IconData maneuverIcon = Icons.straight_rounded;
      final computedEtas = <String, int>{};

      final legs = primaryRoute['legs'] as List<dynamic>?;
      if (legs != null && legs.isNotEmpty) {
        double cumulativeSeconds = 0;
        for (int i = 0; i < pendingStops.length && i < legs.length; i++) {
          final leg = legs[i] as Map<String, dynamic>;
          cumulativeSeconds += (leg['duration'] as num?)?.toDouble() ?? 0;
          computedEtas[pendingStops[i].passengerId] =
              (cumulativeSeconds / 60).ceil().clamp(1, 999);
        }

        final firstLeg = legs.first as Map<String, dynamic>;
        final steps = firstLeg['steps'] as List<dynamic>?;
        if (steps != null && steps.isNotEmpty) {
          final currentStep = steps.first as Map<String, dynamic>;
          currentVia = _extractRoadLabel(currentStep);
          nextStepDist = (currentStep['distance'] as num?)?.toDouble();

          final targetStep = (steps.length > 1
              ? steps[1]
              : steps.first) as Map<String, dynamic>;

          nextVia = _extractRoadLabel(targetStep) ?? currentVia;
          final maneuver = targetStep['maneuver'] as Map<String, dynamic>?;
          maneuverIcon = _resolveManeuverIcon(
            maneuver?['type'] as String?,
            maneuver?['modifier'] as String?,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        if (parsedPoints.length >= 2) {
          roadPolylinePoints = parsedPoints;
          currentBearing = calculateBearing(parsedPoints[0], parsedPoints[1]);
        }
        roadTotalDistanceMeters = totalMeters;
        if (totalSeconds != null) {
          roadTotalDurationMinutes = (totalSeconds / 60).ceil().clamp(1, 999);
        }
        _roadEtaByPassengerId
          ..clear()
          ..addAll(computedEtas);

        if (useMockDemoData) {
          mockStops = mockStops.map((s) {
            final eta = _roadEtaByPassengerId[s.passengerId];
            if (eta == null || s.isCompleted) return s;
            return TripStopPoint(
              passengerId: s.passengerId,
              passengerName: s.passengerName,
              passengerPhotoUrl: s.passengerPhotoUrl,
              latitude: s.latitude,
              longitude: s.longitude,
              orderIndex: s.orderIndex,
              isPassengerReady: s.isPassengerReady,
              isCompleted: s.isCompleted,
              estimatedMinutesRemaining: eta,
            );
          }).toList();
        }

        currentRoadName = currentVia;
        nextRoadName = nextVia;
        nextManeuverDistanceMeters = nextStepDist;
        nextManeuverIcon = maneuverIcon;
      });
    } catch (_) {
    } finally {
      _isFetchingRoute = false;
    }
  }

  String? _extractRoadLabel(Map<String, dynamic> step) {
    final ref = (step['ref'] as String?)?.trim();
    final name = (step['name'] as String?)?.trim();
    if (ref != null && ref.isNotEmpty && name != null && name.isNotEmpty) {
      return name.contains(ref) ? name : '$ref • $name';
    }
    if (ref != null && ref.isNotEmpty) return ref;
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  IconData _resolveManeuverIcon(String? type, String? modifier) {
    if (type == 'arrive') return Icons.flag_rounded;
    if (type == 'roundabout' || type == 'rotary') {
      return Icons.roundabout_right_rounded;
    }
    switch (modifier) {
      case 'left':
        return Icons.turn_left_rounded;
      case 'slight left':
        return Icons.turn_slight_left_rounded;
      case 'sharp left':
        return Icons.turn_sharp_left_rounded;
      case 'right':
        return Icons.turn_right_rounded;
      case 'slight right':
        return Icons.turn_slight_right_rounded;
      case 'sharp right':
        return Icons.turn_sharp_right_rounded;
      case 'uturn':
        return Icons.u_turn_left_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  double distanceMeters(LatLng a, LatLng b) {
    const double earthRadius = 6371000;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earthRadius * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  double calculateBearing(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_radToDeg(math.atan2(y, x)) + 360) % 360;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _radToDeg(double rad) => rad * (180.0 / math.pi);

  String formatDistance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';

  String formatArrivalClock(int minutesFromNow) {
    final eta = DateTime.now().add(Duration(minutes: minutesFromNow));
    return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
  }

  void syncDriverMotion(LatLng driverPos, LatLng lookAheadPoint) {
    final now = DateTime.now();
    final bearingToAhead = calculateBearing(driverPos, lookAheadPoint);

    if (_lastDriverPos != null && _lastDriverTimestamp != null) {
      final movedMeters = distanceMeters(_lastDriverPos!, driverPos);
      final elapsedSeconds =
          now.difference(_lastDriverTimestamp!).inMilliseconds / 1000.0;

      if (movedMeters >= 2.0 && elapsedSeconds >= 0.8) {
        currentSpeedKmh = ((movedMeters / elapsedSeconds) * 3.6).clamp(0, 140);
        currentBearing = calculateBearing(_lastDriverPos!, driverPos);
        _lastDriverPos = driverPos;
        _lastDriverTimestamp = now;

        if (followDriver) {
          animateCameraToDriver(driverPos, currentBearing);
        }
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
          zoom: widget.isDriver ? 17.2 : 15.4,
          tilt: widget.isDriver ? 60.0 : 25.0,
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
          tilt: widget.isDriver ? 48.0 : 25.0,
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