import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
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

class _DriverLiveMapViewState extends State<DriverLiveMapView> {
  // Troque para false quando quiser usar exclusivamente as paradas reais do Firestore.
  static const bool _useMockDemoData = true;

  // Azul padrão do app
  static const Color _appBlue = Color(0xFF3B82F6);
  static const Color _appBlueDark = Color(0xFF1E3A8A);

  late final TripViewModel _tripViewModel;
  GoogleMapController? _mapController;

  bool _followDriver = true;
  bool _isStopsExpanded = false;
  String? _selectedPassengerId;

  // Dados fictícios posicionados sobre a rua real entre partida e destino
  List<TripStopPoint> _mockStops = const [];
  LatLng? _mockDriverPosition;
  bool _mockRoadStopsReady = false;
  final Map<String, int> _roadEtaByPassengerId = {};

  LatLng? _lastDriverPos;
  DateTime? _lastDriverTimestamp;
  double _currentSpeedKmh = 42;
  double _currentBearing = 0;

  // ==================== ROTA VIÁRIA OTIMIZADA (HTTP / OSRM) ====================
  List<LatLng> _roadPolylinePoints = const [];
  double? _roadTotalDistanceMeters;
  int? _roadTotalDurationMinutes;
  double? _nextManeuverDistanceMeters;
  String? _nextRoadName;
  String? _currentRoadName;
  IconData _nextManeuverIcon = Icons.straight_rounded;

  bool _isFetchingRoute = false;
  LatLng? _lastRoutedOrigin;
  String? _lastStopsSignature;
  DateTime? _lastRouteFetchTime;

  // ==================== ÍCONES CUSTOMIZADOS ====================
  BitmapDescriptor? _driverArrowIcon;
  BitmapDescriptor? _busVehicleIcon;
  BitmapDescriptor? _destIcon;
  BitmapDescriptor? _anonymousStopIcon;
  final Map<String, BitmapDescriptor> _driverStopCardsCache = {};
  final Set<String> _loadingStopCardKeys = {};

  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2230"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#94a3b8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1d2230"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c3548"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#374151"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#475569"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0f172a"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#16302b"}]},
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]}
]
''';

  @override
  void initState() {
    super.initState();
    _tripViewModel = injector.get<TripViewModel>();
    if (!_useMockDemoData && widget.trip != null) {
      _tripViewModel.commands.startWatchingTrip(widget.trip!.id);
    }
    _prepareBaseIcons();
    if (_useMockDemoData) {
      _bootstrapMockStopsOnRealRoad();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ==================== POSICIONAMENTO NA RUA REAL ENTRE PARTIDA E DESTINO ====================

  (LatLng origin, LatLng dest) _resolveDemoAnchors() {
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
        _distanceMeters(routeOrigin, routeDest) >= 800;

    if (validCoords) {
      return (routeOrigin, routeDest);
    }

    // Fallback sobre a Rodovia PR-412 (Pontal do Paraná)
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

    final clamped = fraction.clamp(0.0, 1.0);
    final targetDist = cumulativeMeters.last * clamped;

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

  /// Consulta a rota real entre partida e destino no OSRM e posiciona o motorista
  /// e todos os passageiros diretamente sobre a pista real.
  Future<void> _bootstrapMockStopsOnRealRoad() async {
    final (origin, dest) = _resolveDemoAnchors();
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
          .get(
            uri,
            headers: const {'User-Agent': 'IndigoTransportApp/1.0'},
          )
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

            if (parsed.length >= 2) {
              baseRoadPoints = parsed;
            }
          }
        }
      }
    } catch (_) {
      // Fallback seguro caso esteja offline
    }

    final cumulative = <double>[0.0];
    for (int i = 1; i < baseRoadPoints.length; i++) {
      cumulative.add(
        cumulative.last +
            _distanceMeters(baseRoadPoints[i - 1], baseRoadPoints[i]),
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
        passengerPhotoUrl: 'https://res.cloudinary.com/db37erprw/image/upload/v1795057188/medanncv6wfo8ejp2vii.jpg',
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

    final optimized = _optimizeStopsOrder(rawStops, driverPos);
    final initialBearing = _calculateBearing(driverPos, driverAhead);

    if (!mounted) return;
    setState(() {
      _mockDriverPosition = driverPos;
      _mockStops = optimized;
      _mockRoadStopsReady = true;
      _currentBearing = initialBearing;
    });

    final pending = optimized.where((s) => !s.isCompleted).toList();
    await _maybeFetchRoadRoute(driverPos, pending, dest, force: true);

    if (!mounted) return;
    if (widget.isDriver && _followDriver) {
      await _animateCameraToDriver(driverPos, _currentBearing);
    } else if (!widget.isDriver && _roadPolylinePoints.length >= 2) {
      await _fitOverviewBounds(_roadPolylinePoints);
    }
  }

  List<TripStopPoint> _optimizeStopsOrder(
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
          final d = _distanceMeters(
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
    final dest = await _createDestinationIcon();
    if (widget.isDriver) {
      final arrow = await _createDriverArrowIcon();
      if (!mounted) return;
      setState(() {
        _driverArrowIcon = arrow;
        _destIcon = dest;
      });
    } else {
      final bus = await _createBusVehicleIcon();
      final anonStop = await _createAnonymousStopIcon();
      if (!mounted) return;
      setState(() {
        _busVehicleIcon = bus;
        _anonymousStopIcon = anonStop;
        _destIcon = dest;
      });
    }
  }

  String _stopCardCacheKey(TripStopPoint stop) =>
      '${stop.passengerId}_${stop.orderIndex}_${stop.isPassengerReady}_${stop.isCompleted}_${stop.estimatedMinutesRemaining ?? -1}_${stop.passengerPhotoUrl ?? ''}';

  Future<void> _ensureDriverStopCards(List<TripStopPoint> stops) async {
    if (!widget.isDriver) return;

    for (final stop in stops) {
      final key = _stopCardCacheKey(stop);
      if (_driverStopCardsCache.containsKey(key) ||
          _loadingStopCardKeys.contains(key)) {
        continue;
      }
      _loadingStopCardKeys.add(key);
      _createPassengerMapCardIcon(stop).then((descriptor) {
        _loadingStopCardKeys.remove(key);
        if (!mounted) return;
        setState(() {
          _driverStopCardsCache[key] = descriptor;
        });
      }).catchError((_) {
        _loadingStopCardKeys.remove(key);
      });
    }
  }

  // ==================== ROTEAMENTO POR RODOVIAS VIA HTTP (OSRM) ====================

  Future<void> _maybeFetchRoadRoute(
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
        _distanceMeters(_lastRoutedOrigin!, driverPos) >= 35.0;
    final cooldownPassed = _lastRouteFetchTime == null ||
        now.difference(_lastRouteFetchTime!).inSeconds >= 8;

    if (!force && !stopsChanged && !(movedFarEnough && cooldownPassed)) {
      return;
    }

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
          .get(
            uri,
            headers: const {'User-Agent': 'IndigoTransportApp/1.0'},
          )
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
        final lng = (list[0] as num).toDouble();
        final lat = (list[1] as num).toDouble();
        return LatLng(lat, lng);
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
          _roadPolylinePoints = parsedPoints;
          _currentBearing = _calculateBearing(parsedPoints[0], parsedPoints[1]);
        }
        _roadTotalDistanceMeters = totalMeters;
        if (totalSeconds != null) {
          _roadTotalDurationMinutes = (totalSeconds / 60).ceil().clamp(1, 999);
        }
        _roadEtaByPassengerId
          ..clear()
          ..addAll(computedEtas);

        if (_useMockDemoData) {
          _mockStops = _mockStops.map((s) {
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

        _currentRoadName = currentVia;
        _nextRoadName = nextVia;
        _nextManeuverDistanceMeters = nextStepDist;
        _nextManeuverIcon = maneuverIcon;
      });
    } catch (_) {
      // Mantém os pontos disponíveis
    } finally {
      _isFetchingRoute = false;
    }
  }

  String? _extractRoadLabel(Map<String, dynamic> step) {
    final ref = (step['ref'] as String?)?.trim();
    final name = (step['name'] as String?)?.trim();
    if (ref != null && ref.isNotEmpty && name != null && name.isNotEmpty) {
      if (name.contains(ref)) return name;
      return '$ref • $name';
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

  // ==================== FOTOS + CARDS EM CANVAS NO MAPA ====================

  Future<ui.Image?> _loadUiImage(String? rawUrl) async {
    final url = rawUrl?.trim();
    if (url == null || url.isEmpty) return null;

    try {
      Uint8List? bytes;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          bytes = res.bodyBytes;
        }
      } else if (url.startsWith('assets/')) {
        final data = await rootBundle.load(url);
        bytes = data.buffer.asUint8List();
      } else {
        final file = File(url);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }
      if (bytes == null || bytes.isEmpty) return null;

      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 104,
        targetHeight: 104,
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  String _initialsFromName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Passageiro';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// Card flutuante no mapa EXCLUSIVO do motorista:
  /// foto circular, ordem da parada, primeiro nome e badge 100% fosco (Pronto / Aguardando / Embarcado).
  Future<BitmapDescriptor> _createPassengerMapCardIcon(
    TripStopPoint stop,
  ) async {
    const double width = 316;
    const double height = 122;
    const double cardHeight = 92;

    final avatarImage = await _loadUiImage(stop.passengerPhotoUrl);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final accentColor = stop.isCompleted
        ? const Color(0xFF64748B)
        : (stop.isPassengerReady
            ? const Color(0xFF16A34A)
            : const Color(0xFFF59E0B));

    final statusWord = stop.isCompleted
        ? 'Embarcado'
        : (stop.isPassengerReady ? 'Pronto' : 'Aguardando');

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 6, width - 16, cardHeight),
      const Radius.circular(24),
    );

    canvas.drawShadow(
      Path()..addRRect(cardRect),
      Colors.black.withOpacity(0.55),
      9,
      true,
    );

    canvas.drawRRect(cardRect, Paint()..color = const Color(0xFF111827));
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    final pointerPath = Path()
      ..moveTo(width / 2 - 14, 6 + cardHeight - 2)
      ..lineTo(width / 2 + 14, 6 + cardHeight - 2)
      ..lineTo(width / 2, height - 4)
      ..close();
    canvas.drawPath(pointerPath, Paint()..color = accentColor);

    const avatarCenter = Offset(54, 52);
    const double avatarRadius = 29;

    canvas.drawCircle(
      avatarCenter,
      avatarRadius + 3.5,
      Paint()..color = accentColor,
    );

    final avatarOval = Rect.fromCircle(
      center: avatarCenter,
      radius: avatarRadius,
    );

    if (avatarImage != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(avatarOval));
      final srcSize = math.min(avatarImage.width, avatarImage.height).toDouble();
      final srcLeft = (avatarImage.width - srcSize) / 2;
      final srcTop = (avatarImage.height - srcSize) / 2;
      canvas.drawImageRect(
        avatarImage,
        Rect.fromLTWH(srcLeft, srcTop, srcSize, srcSize),
        avatarOval,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
      avatarImage.dispose();
    } else {
      canvas.drawCircle(
        avatarCenter,
        avatarRadius,
        Paint()..color = accentColor,
      );
      final initialsPainter = TextPainter(
        text: TextSpan(
          text: _initialsFromName(stop.passengerName),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      initialsPainter.paint(
        canvas,
        Offset(
          avatarCenter.dx - initialsPainter.width / 2,
          avatarCenter.dy - initialsPainter.height / 2,
        ),
      );
    }

    // Badge da ordem no canto inferior direito do avatar
    const badgeCenter = Offset(77, 75);
    canvas.drawCircle(badgeCenter, 13.5, Paint()..color = const Color(0xFF111827));
    canvas.drawCircle(badgeCenter, 11, Paint()..color = accentColor);
    final orderPainter = TextPainter(
      text: TextSpan(
        text: stop.isCompleted ? '✓' : '${stop.orderIndex}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    orderPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - orderPainter.width / 2,
        badgeCenter.dy - orderPainter.height / 2,
      ),
    );

    // Primeiro nome
    final namePainter = TextPainter(
      text: TextSpan(
        text: _firstName(stop.passengerName),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 118);
    namePainter.paint(canvas, const Offset(98, 17));

    // Pill 100% fosca (sem opacity) para Pronto / Aguardando / Embarcado
    final statusPainter = TextPainter(
      text: TextSpan(
        text: statusWord,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    const double pillLeft = 98;
    const double pillTop = 51;
    const double pillPadX = 11;
    const double pillHeight = 29;
    final double pillWidth = statusPainter.width + (pillPadX * 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pillLeft, pillTop, pillWidth, pillHeight),
        const Radius.circular(10),
      ),
      Paint()..color = accentColor,
    );

    statusPainter.paint(
      canvas,
      Offset(
        pillLeft + pillPadX,
        pillTop + (pillHeight - statusPainter.height) / 2,
      ),
    );

    if (!stop.isCompleted && stop.estimatedMinutesRemaining != null) {
      final etaLeft = pillLeft + pillWidth + 8;
      final remainingWidth = (width - 18) - etaLeft;
      if (remainingWidth >= 34) {
        final etaPainter = TextPainter(
          text: TextSpan(
            text: '${stop.estimatedMinutesRemaining} min',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: remainingWidth);

        etaPainter.paint(
          canvas,
          Offset(
            etaLeft,
            pillTop + (pillHeight - etaPainter.height) / 2,
          ),
        );
      }
    }

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 170,
      height: 66,
    );
  }

  /// Marcador anônimo (visualização de não-motorista): sem foto, sem nome e sem status.
  Future<BitmapDescriptor> _createAnonymousStopIcon() async {
    const double size = 64;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    canvas.drawCircle(center, 22, Paint()..color = Colors.white);
    canvas.drawCircle(center, 16, Paint()..color = _appBlue);
    canvas.drawCircle(center, 6, Paint()..color = Colors.white);

    final image = await recorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 24,
      height: 24,
    );
  }

  Future<BitmapDescriptor> _createDriverArrowIcon() async {
    const double size = 140;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      58,
      Paint()..color = _appBlue.withOpacity(0.24),
    );

    final arrowPath = Path()
      ..moveTo(size * 0.50, size * 0.16)
      ..lineTo(size * 0.80, size * 0.78)
      ..lineTo(size * 0.50, size * 0.65)
      ..lineTo(size * 0.20, size * 0.78)
      ..close();

    canvas.drawShadow(arrowPath, Colors.black.withOpacity(0.45), 8, true);

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = _appBlue
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round,
    );

    final image = await recorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 52,
      height: 52,
    );
  }

  Future<BitmapDescriptor> _createBusVehicleIcon() async {
    const double size = 128;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    canvas.drawCircle(
      center,
      58,
      Paint()..color = const Color(0xFF16A34A).withOpacity(0.20),
    );
    canvas.drawCircle(center, 44, Paint()..color = Colors.white);
    canvas.drawCircle(center, 37, Paint()..color = const Color(0xFF16A34A));

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.directions_bus_rounded.codePoint),
        style: TextStyle(
          fontSize: 44,
          fontFamily: Icons.directions_bus_rounded.fontFamily,
          package: Icons.directions_bus_rounded.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 48,
      height: 48,
    );
  }

  Future<BitmapDescriptor> _createDestinationIcon() async {
    const double size = 104;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    canvas.drawCircle(center, 44, Paint()..color = Colors.white);
    canvas.drawCircle(center, 37, Paint()..color = const Color(0xFFDC2626));

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'FIM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 40,
      height: 40,
    );
  }

  // ==================== CÁLCULOS GEOGRÁFICOS ====================

  double _distanceMeters(LatLng a, LatLng b) {
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

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = _radToDeg(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _radToDeg(double rad) => rad * (180.0 / math.pi);

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatArrivalClock(int minutesFromNow) {
    final eta = DateTime.now().add(Duration(minutes: minutesFromNow));
    final h = eta.hour.toString().padLeft(2, '0');
    final m = eta.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ==================== CÂMERA ====================

  void _syncDriverMotion(LatLng driverPos, LatLng lookAheadPoint) {
    final now = DateTime.now();
    final bearingToAhead = _calculateBearing(driverPos, lookAheadPoint);

    if (_lastDriverPos != null && _lastDriverTimestamp != null) {
      final movedMeters = _distanceMeters(_lastDriverPos!, driverPos);
      final elapsedSeconds =
          now.difference(_lastDriverTimestamp!).inMilliseconds / 1000.0;

      if (movedMeters >= 2.0 && elapsedSeconds >= 0.8) {
        final kmh = (movedMeters / elapsedSeconds) * 3.6;
        _currentSpeedKmh = kmh.clamp(0, 140);
        _currentBearing = _calculateBearing(_lastDriverPos!, driverPos);
        _lastDriverPos = driverPos;
        _lastDriverTimestamp = now;

        if (_followDriver) {
          _animateCameraToDriver(driverPos, _currentBearing);
        }
      } else if (_currentBearing == 0) {
        _currentBearing = bearingToAhead;
      }
    } else {
      _lastDriverPos = driverPos;
      _lastDriverTimestamp = now;
      _currentBearing = bearingToAhead;
    }
  }

  Future<void> _animateCameraToDriver(LatLng target, double bearing) async {
    if (_mapController == null) return;
    if (widget.isDriver) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 17.2,
            tilt: 60.0,
            bearing: bearing,
          ),
        ),
      );
    } else {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 15.4,
            tilt: 25.0,
            bearing: 0.0,
          ),
        ),
      );
    }
  }

  Future<void> _focusOnStop(TripStopPoint stop) async {
    if (_mapController == null) return;
    setState(() {
      _followDriver = false;
      _selectedPassengerId = stop.passengerId;
    });
    await _mapController!.animateCamera(
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

  Future<void> _fitOverviewBounds(List<LatLng> points) async {
    if (_mapController == null || points.length < 2) return;
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

    setState(() => _followDriver = false);
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  Widget _buildPassengerAvatar(
    TripStopPoint stop, {
    required double radius,
    required Color accentColor,
  }) {
    final photo = stop.passengerPhotoUrl?.trim() ?? '';
    ImageProvider? provider;
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      provider = NetworkImage(photo);
    } else if (photo.startsWith('assets/')) {
      provider = AssetImage(photo);
    } else if (photo.isNotEmpty) {
      final file = File(photo);
      if (file.existsSync()) {
        provider = FileImage(file);
      }
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor, width: 2.2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: accentColor,
        backgroundImage: provider,
        child: provider == null
            ? Text(
                _initialsFromName(stop.passengerName),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.68,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isDriver = widget.isDriver;

    return Watch((context) {
      final liveTrip = _useMockDemoData
          ? null
          : (_tripViewModel.state.activeTrip.value ?? widget.trip);

      final (demoOrigin, demoDest) = _resolveDemoAnchors();

      final originLatLng = _useMockDemoData
          ? demoOrigin
          : LatLng(
              widget.route.origin.latitude,
              widget.route.origin.longitude,
            );

      final destLatLng = _useMockDemoData
          ? demoDest
          : LatLng(
              widget.route.destination.latitude,
              widget.route.destination.longitude,
            );

      final driverLatLng = _useMockDemoData
          ? (_mockDriverPosition ?? originLatLng)
          : ((liveTrip?.driverLatitude != null &&
                  liveTrip?.driverLongitude != null)
              ? LatLng(liveTrip!.driverLatitude!, liveTrip.driverLongitude!)
              : originLatLng);

      final stops = _useMockDemoData
          ? _mockStops
          : _optimizeStopsOrder(
              (liveTrip != null && liveTrip.stops.isNotEmpty)
                  ? liveTrip.stops
                  : widget.stops,
              driverLatLng,
            );

      if (isDriver) {
        _ensureDriverStopCards(stops);
      }

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

      final activePolyline = _roadPolylinePoints.length >= 2
          ? _roadPolylinePoints
          : fallbackPoints;

      final lookAheadPoint = activePolyline.length >= 2
          ? activePolyline[1]
          : nextTargetLatLng;

      final bannerDistanceMeters = _nextManeuverDistanceMeters ??
          _distanceMeters(driverLatLng, nextTargetLatLng);

      double fallbackTotalMeters = 0;
      for (int i = 0; i < fallbackPoints.length - 1; i++) {
        fallbackTotalMeters +=
            _distanceMeters(fallbackPoints[i], fallbackPoints[i + 1]);
      }

      final totalRemainingMeters =
          _roadTotalDistanceMeters ?? fallbackTotalMeters;

      final estimatedMinutes = _roadTotalDurationMinutes ??
          nextStop?.estimatedMinutesRemaining ??
          ((totalRemainingMeters / 1000) / 38 * 60).ceil().clamp(1, 999);

      final destLabel = (widget.route.destinationName != null &&
              widget.route.destinationName!.trim().isNotEmpty)
          ? widget.route.destinationName!.trim()
          : 'Campus Central • Destino';

      final companyName = (widget.company?.name.trim().isNotEmpty == true)
          ? widget.company!.name.trim()
          : 'Transportes Costa';

      final nextBannerTitle = _nextRoadName != null
          ? '» $_nextRoadName'
          : (nextStop != null
              ? '» ${_firstName(nextStop.passengerName)} (Parada #${nextStop.orderIndex})'
              : '» $destLabel');

      final bottomPillLabel = _currentRoadName ??
          (nextStop != null
              ? 'Próxima parada: ${_firstName(nextStop.passengerName)}'
              : destLabel);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncDriverMotion(driverLatLng, lookAheadPoint);
        if (!_useMockDemoData || _mockRoadStopsReady) {
          _maybeFetchRoadRoute(driverLatLng, pendingStops, destLatLng);
        }
      });

      final markers = <Marker>{
        ...stops.map((s) {
          if (isDriver) {
            final key = _stopCardCacheKey(s);
            return Marker(
              markerId: MarkerId('stop_${s.passengerId}_${s.orderIndex}'),
              position: LatLng(s.latitude, s.longitude),
              anchor: const Offset(0.5, 1.0),
              zIndexInt: s.passengerId == _selectedPassengerId ? 9 : 5,
              icon: _driverStopCardsCache[key] ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    s.isCompleted
                        ? BitmapDescriptor.hueAzure
                        : (s.isPassengerReady
                            ? BitmapDescriptor.hueGreen
                            : BitmapDescriptor.hueOrange),
                  ),
              onTap: () => _focusOnStop(s),
            );
          }

          // Modo não-motorista: ponto anônimo sem foto, sem nome e sem toque
          return Marker(
            markerId: MarkerId('anon_stop_${s.orderIndex}'),
            position: LatLng(s.latitude, s.longitude),
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 3,
            consumeTapEvents: true,
            icon: _anonymousStopIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
          );
        }),

        // Destino final
        Marker(
          markerId: const MarkerId('destination'),
          position: destLatLng,
          zIndexInt: 4,
          icon: _destIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: destLabel),
        ),

        // Posição do veículo
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLatLng,
          rotation: isDriver ? _currentBearing : 0.0,
          flat: isDriver,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 10,
          icon: isDriver
              ? (_driverArrowIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ))
              : (_busVehicleIcon ??
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
          color: _appBlueDark,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
        Polyline(
          polylineId: const PolylineId('route_core'),
          points: activePolyline,
          width: isDriver ? 7 : 5,
          color: _appBlue,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };

      return Scaffold(
        backgroundColor: isDriver ? Colors.black : theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // ================= 1. GOOGLE MAPS 3D =================
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: driverLatLng,
                zoom: isDriver ? 15.8 : 14.8,
                tilt: isDriver ? 60.0 : 25.0,
                bearing: isDriver
                    ? _calculateBearing(driverLatLng, lookAheadPoint)
                    : 0.0,
              ),
              style: isDark ? _darkMapStyle : null,
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
                bottom: (isDriver && _isStopsExpanded) ? 310 : 124,
              ),
              markers: markers,
              polylines: polylines,
              onTap: (_) {
                if (_selectedPassengerId != null) {
                  setState(() => _selectedPassengerId = null);
                }
              },
              onMapCreated: (controller) {
                _mapController = controller;
                Future.delayed(const Duration(milliseconds: 350), () {
                  if (!mounted) return;
                  if (isDriver) {
                    _animateCameraToDriver(
                      driverLatLng,
                      _calculateBearing(driverLatLng, lookAheadPoint),
                    );
                  } else if (activePolyline.length >= 2) {
                    _fitOverviewBounds(activePolyline);
                  }
                });
              },
            ),

            // ================= 2. TOPO =================
            if (isDriver)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: const Color(0xFF0A0C10),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  if (context.canPop()) context.pop();
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Mapa da Rota',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.white24,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                          child: Row(
                            children: [
                              Icon(
                                _nextManeuverIcon,
                                color: Colors.white,
                                size: 44,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatDistance(bannerDistanceMeters),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w800,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nextBannerTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF93C5FD),
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Positioned(
                top: 0,
                left: 16,
                right: 16,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 34,
                            minHeight: 34,
                          ),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: colorScheme.onSurface,
                          ),
                          onPressed: () {
                            if (context.canPop()) context.pop();
                          },
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Localização do Motorista',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '$companyName • $destLabel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ================= 3. CONTROLES FLUTUANTES SOBRE O MAPA =================
            if (isDriver)
              Positioned(
                left: 16,
                right: 16,
                bottom: _isStopsExpanded ? 298 : 114,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Velocímetro circular
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${_currentSpeedKmh.round()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                'km/h',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Botão direito: Recentralizar 3D
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _followDriver = true;
                              _selectedPassengerId = null;
                            });
                            _animateCameraToDriver(
                              driverLatLng,
                              _calculateBearing(driverLatLng, lookAheadPoint),
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _followDriver
                                  ? const Color(0xFFF59E0B)
                                  : _appBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.navigation_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Pílula azul padrão do app
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _appBlue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        bottomPillLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Positioned(
                right: 16,
                bottom: 118,
                child: FloatingActionButton(
                  heroTag: 'center_bus_btn',
                  backgroundColor: theme.cardColor,
                  elevation: 4,
                  onPressed: () {
                    setState(() => _followDriver = true);
                    _animateCameraToDriver(driverLatLng, 0.0);
                  },
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: _followDriver ? const Color(0xFF16A34A) : _appBlue,
                  ),
                ),
              ),

            // ================= 4. PAINEL INFERIOR =================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Ver todos os pontos da rota',
                              onPressed: () =>
                                  _fitOverviewBounds(activePolyline),
                              icon: Icon(
                                Icons.alt_route_rounded,
                                color: colorScheme.onSurfaceVariant,
                                size: 26,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isDriver)
                                    Text(
                                      'Previsão de chegada',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  Text(
                                    _formatArrivalClock(estimatedMinutes),
                                    style: TextStyle(
                                      fontSize: isDriver ? 25 : 22,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                      height: 1.08,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$estimatedMinutes min  •  ${_formatDistance(totalRemainingMeters)}',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isDriver)
                              IconButton(
                                tooltip: 'Ver passageiros da rota',
                                onPressed: () {
                                  setState(() {
                                    _isStopsExpanded = !_isStopsExpanded;
                                  });
                                },
                                icon: Icon(
                                  _isStopsExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: colorScheme.onSurface,
                                  size: 30,
                                ),
                              )
                            else
                              const SizedBox(width: 48),
                          ],
                        ),
                      ),

                      // Lista expansível de passageiros (EXCLUSIVA DO MOTORISTA)
                      if (isDriver && _isStopsExpanded) ...[
                        Divider(
                          height: 1,
                          color: theme.dividerColor.withOpacity(0.5),
                        ),
                        SizedBox(
                          height: 195,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                            itemCount: stops.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final s = stops[index];
                              final statusText = s.isCompleted
                                  ? 'Embarcado'
                                  : (s.isPassengerReady
                                      ? 'Pronto'
                                      : 'Aguardando');
                              final statusColor = s.isCompleted
                                  ? const Color(0xFF64748B)
                                  : (s.isPassengerReady
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFF59E0B));
                              final isSelected =
                                  s.passengerId == _selectedPassengerId;

                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _focusOnStop(s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF232732)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? statusColor
                                          : (isDark
                                              ? const Color(0xFF374151)
                                              : const Color(0xFFD1D5DB)),
                                      width: isSelected ? 1.8 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _buildPassengerAvatar(
                                        s,
                                        radius: 19,
                                        accentColor: statusColor,
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s.passengerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Parada #${s.orderIndex}${!s.isCompleted && s.estimatedMinutesRemaining != null ? ' • ~${s.estimatedMinutesRemaining} min' : ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}