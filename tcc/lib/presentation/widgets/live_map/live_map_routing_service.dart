import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/trip_entity.dart';
import 'live_map_marker_factory.dart';
import 'live_map_navigation_engine.dart';

class LiveMapRoutingService {
  static const MethodChannel _mapsConfigChannel =
      MethodChannel('indigo/maps_config');

  String? _apiKey;

  Future<String?> loadApiKey() async {
    if (_apiKey != null && _apiKey!.isNotEmpty) return _apiKey;

    const envKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (envKey.isNotEmpty) {
      _apiKey = envKey;
      return _apiKey;
    }

    try {
      final manifestKey =
          await _mapsConfigChannel.invokeMethod<String>('getApiKey');
      if (manifestKey != null && manifestKey.trim().isNotEmpty) {
        _apiKey = manifestKey.trim();
      }
    } catch (e) {
      debugPrint('Nao foi possivel ler GOOGLE_MAPS_API_KEY do Manifest: $e');
    }
    return _apiKey;
  }

  Future<ComputedRouteResult?> fetchBestRoute({
    required LatLng driverPos,
    required List<TripStopPoint> pendingStops,
    required LatLng destination,
    required String destinationLabel,
  }) async {
    final apiKey = await loadApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      final googleResult = await _fetchGoogleWithReadyPriority(
        driverPos: driverPos,
        pendingStops: pendingStops,
        destination: destination,
        destinationLabel: destinationLabel,
        apiKey: apiKey,
      );
      if (googleResult != null) return googleResult;
    }

    return _fetchOsrmFallback(
      driverPos: driverPos,
      pendingStops: pendingStops,
      destination: destination,
      destinationLabel: destinationLabel,
    );
  }

  Future<String?> reverseGeocode(LatLng point) async {
    final apiKey = await loadApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        {
          'latlng': '${point.latitude},${point.longitude}',
          'language': 'pt-BR',
          'key': apiKey,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final formatted =
          (results.first as Map<String, dynamic>)['formatted_address']
              as String?;
      return formatted?.trim().isNotEmpty == true ? formatted!.trim() : null;
    } catch (_) {
      return null;
    }
  }

  Future<ComputedRouteResult?> _fetchGoogleWithReadyPriority({
    required LatLng driverPos,
    required List<TripStopPoint> pendingStops,
    required LatLng destination,
    required String destinationLabel,
    required String apiKey,
  }) async {
    final readyStops = pendingStops.where((s) => s.isPassengerReady).toList();
    final waitingStops =
        pendingStops.where((s) => !s.isPassengerReady).toList();

    List<TripStopPoint> orderedReady = readyStops;
    List<TripStopPoint> orderedWaiting = waitingStops;

    if (readyStops.isEmpty || waitingStops.isEmpty) {
      final singleGroup = readyStops.isNotEmpty ? readyStops : waitingStops;
      final data = await _callDirectionsApi(
        origin: driverPos,
        destination: destination,
        waypoints: singleGroup,
        optimizeWaypoints: singleGroup.length > 1,
        apiKey: apiKey,
      );
      final routes = data?['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final primary = routes.first as Map<String, dynamic>;
      final reordered = _applyWaypointOrder(
        singleGroup,
        primary['waypoint_order'] as List<dynamic>?,
      );
      return _parseGoogleRoute(primary, reordered, destinationLabel);
    }

    if (readyStops.length > 1) {
      final readyData = await _callDirectionsApi(
        origin: driverPos,
        destination: destination,
        waypoints: readyStops,
        optimizeWaypoints: true,
        apiKey: apiKey,
      );
      final readyRoutes = readyData?['routes'] as List<dynamic>?;
      if (readyRoutes != null && readyRoutes.isNotEmpty) {
        orderedReady = _applyWaypointOrder(
          readyStops,
          (readyRoutes.first as Map<String, dynamic>)['waypoint_order']
              as List<dynamic>?,
        );
      }
    }

    if (waitingStops.length > 1) {
      final lastReady = orderedReady.last;
      final waitingData = await _callDirectionsApi(
        origin: LatLng(lastReady.latitude, lastReady.longitude),
        destination: destination,
        waypoints: waitingStops,
        optimizeWaypoints: true,
        apiKey: apiKey,
      );
      final waitingRoutes = waitingData?['routes'] as List<dynamic>?;
      if (waitingRoutes != null && waitingRoutes.isNotEmpty) {
        orderedWaiting = _applyWaypointOrder(
          waitingStops,
          (waitingRoutes.first as Map<String, dynamic>)['waypoint_order']
              as List<dynamic>?,
        );
      }
    }

    final finalOrder = [...orderedReady, ...orderedWaiting];
    final unifiedData = await _callDirectionsApi(
      origin: driverPos,
      destination: destination,
      waypoints: finalOrder,
      optimizeWaypoints: false,
      apiKey: apiKey,
    );
    final routes = unifiedData?['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;

    return _parseGoogleRoute(
      routes.first as Map<String, dynamic>,
      finalOrder,
      destinationLabel,
    );
  }

  Future? _callDirectionsApi({
    required LatLng origin,
    required LatLng destination,
    required List<TripStopPoint> waypoints,
    required bool optimizeWaypoints,
    required String apiKey,
  }) async {
    final queryParams = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'language': 'pt-BR',
      'departure_time': 'now',
      'key': apiKey,
    };

    if (waypoints.isNotEmpty) {
      final serialized = waypoints
          .map(
            (w) =>
                '${w.latitude.toStringAsFixed(6)},${w.longitude.toStringAsFixed(6)}',
          )
          .join('|');
      queryParams['waypoints'] =
          optimizeWaypoints ? 'optimize:true|$serialized' : serialized;
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      queryParams,
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') {
      debugPrint(
        'Google Directions API: ${data['status']} (${data['error_message'] ?? ''})',
      );
      return null;
    }
    return data;
  }

  ComputedRouteResult _parseGoogleRoute(
    Map<String, dynamic> primaryRoute,
    List<TripStopPoint> orderedStops,
    String destinationLabel,
  ) {
    final legs = primaryRoute['legs'] as List<dynamic>? ?? const [];
    final detailedPoints = <LatLng>[];
    final navSteps = <NavStep>[];
    final etaByPassengerId = <String, int>{};
    final addressByPassengerId = <String, String>{};

    double totalMeters = 0;
    double totalSeconds = 0;
    double cumulativeSeconds = 0;

    for (int i = 0; i < legs.length; i++) {
      final leg = legs[i] as Map<String, dynamic>;
      final distVal =
          ((leg['distance'] as Map<String, dynamic>?)?['value'] as num?)
                  ?.toDouble() ??
              0;
      final durationMap = (leg['duration_in_traffic'] ?? leg['duration'])
          as Map<String, dynamic>?;
      final durVal = (durationMap?['value'] as num?)?.toDouble() ?? 0;

      totalMeters += distVal;
      totalSeconds += durVal;
      cumulativeSeconds += durVal;

      String legEndLabel = destinationLabel;
      bool isStopLeg = false;

      if (i < orderedStops.length) {
        final stop = orderedStops[i];
        isStopLeg = true;
        legEndLabel =
            'Parada #${i + 1} • ${LiveMapMarkerFactory.firstName(stop.passengerName)}';
        etaByPassengerId[stop.passengerId] =
            (cumulativeSeconds / 60).ceil().clamp(1, 999).toInt();
        final endAddress = (leg['end_address'] as String?)?.trim();
        if (endAddress != null && endAddress.isNotEmpty) {
          addressByPassengerId[stop.passengerId] = endAddress;
        }
      }

      final steps = leg['steps'] as List<dynamic>? ?? const [];
      for (final rawStep in steps) {
        final step = rawStep as Map<String, dynamic>;
        final poly = (step['polyline'] as Map<String, dynamic>?)?['points']
            as String?;
        final decoded = (poly != null && poly.isNotEmpty)
            ? _decodePolyline(poly)
            : _fallbackStepEndpoints(step);

        if (decoded.isEmpty) continue;

        if (detailedPoints.isNotEmpty) {
          detailedPoints.addAll(decoded.skip(1));
        } else {
          detailedPoints.addAll(decoded);
        }

        final rawHtml = step['html_instructions'] as String?;
        final maneuver = step['maneuver'] as String?;
        final street = _extractStreetFromHtml(rawHtml);

        navSteps.add(
          NavStep(
            points: decoded,
            distanceMeters:
                ((step['distance'] as Map<String, dynamic>?)?['value'] as num?)
                        ?.toDouble() ??
                    LiveMapNavigationEngine.polylineLengthMeters(decoded),
            durationSeconds:
                ((step['duration'] as Map<String, dynamic>?)?['value'] as num?)
                        ?.toDouble() ??
                    0,
            instruction: _formatGoogleInstruction(rawHtml, maneuver, street),
            roadName: street,
            maneuverIcon: _googleManeuverIcon(maneuver),
            legIndex: i,
            legEndLabel: legEndLabel,
            isStopArrival: isStopLeg,
          ),
        );
      }
    }

    if (detailedPoints.length < 2) {
      final overview = (primaryRoute['overview_polyline']
          as Map<String, dynamic>?)?['points'] as String?;
      if (overview != null && overview.isNotEmpty) {
        detailedPoints.addAll(_decodePolyline(overview));
      }
    }

    return ComputedRouteResult(
      polylinePoints: detailedPoints,
      navSteps: navSteps,
      optimizedOrderIds: orderedStops.map((s) => s.passengerId).toList(),
      etaByPassengerId: etaByPassengerId,
      addressByPassengerId: addressByPassengerId,
      totalDistanceMeters: totalMeters > 0 ? totalMeters : null,
      totalDurationMinutes: totalSeconds > 0
          ? (totalSeconds / 60).ceil().clamp(1, 999).toInt()
          : null,
    );
  }

  Future<ComputedRouteResult?> _fetchOsrmFallback({
    required LatLng driverPos,
    required List<TripStopPoint> pendingStops,
    required LatLng destination,
    required String destinationLabel,
  }) async {
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
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') return null;

    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;

    final primary = routes.first as Map<String, dynamic>;
    final rawCoords = ((primary['geometry'] as Map<String, dynamic>?)?[
            'coordinates'] as List<dynamic>?) ??
        const [];
    final parsedPoints = rawCoords.map((pair) {
      final list = pair as List<dynamic>;
      return LatLng((list[1] as num).toDouble(), (list[0] as num).toDouble());
    }).toList();

    final etaByPassengerId = <String, int>{};
    final navSteps = <NavStep>[];
    final legs = primary['legs'] as List<dynamic>? ?? const [];

    double cumulativeSeconds = 0;
    for (int i = 0; i < legs.length; i++) {
      final leg = legs[i] as Map<String, dynamic>;
      cumulativeSeconds += (leg['duration'] as num?)?.toDouble() ?? 0;

      String legEndLabel = destinationLabel;
      bool isStopLeg = false;
      if (i < pendingStops.length) {
        isStopLeg = true;
        final stop = pendingStops[i];
        legEndLabel =
            'Parada #${i + 1} • ${LiveMapMarkerFactory.firstName(stop.passengerName)}';
        etaByPassengerId[stop.passengerId] =
            (cumulativeSeconds / 60).ceil().clamp(1, 999).toInt();
      }

      final steps = leg['steps'] as List<dynamic>? ?? const [];
      for (final rawStep in steps) {
        final step = rawStep as Map<String, dynamic>;
        final coords = ((step['geometry'] as Map<String, dynamic>?)?[
                'coordinates'] as List<dynamic>?) ??
            const [];
        final stepPoints = coords.map((pair) {
          final list = pair as List<dynamic>;
          return LatLng(
            (list[1] as num).toDouble(),
            (list[0] as num).toDouble(),
          );
        }).toList();
        if (stepPoints.isEmpty) continue;

        final maneuver = step['maneuver'] as Map<String, dynamic>?;
        final type = maneuver?['type'] as String?;
        final modifier = maneuver?['modifier'] as String?;
        final road = _osrmRoadLabel(step);

        navSteps.add(
          NavStep(
            points: stepPoints,
            distanceMeters: (step['distance'] as num?)?.toDouble() ??
                LiveMapNavigationEngine.polylineLengthMeters(stepPoints),
            durationSeconds: (step['duration'] as num?)?.toDouble() ?? 0,
            instruction: _formatOsrmInstruction(type, modifier, road),
            roadName: road,
            maneuverIcon: _osrmManeuverIcon(type, modifier),
            legIndex: i,
            legEndLabel: legEndLabel,
            isStopArrival: isStopLeg,
          ),
        );
      }
    }

    final totalSeconds = (primary['duration'] as num?)?.toDouble();
    return ComputedRouteResult(
      polylinePoints: parsedPoints,
      navSteps: navSteps,
      optimizedOrderIds: const [],
      etaByPassengerId: etaByPassengerId,
      addressByPassengerId: const {},
      totalDistanceMeters: (primary['distance'] as num?)?.toDouble(),
      totalDurationMinutes: totalSeconds != null
          ? (totalSeconds / 60).ceil().clamp(1, 999).toInt()
          : null,
    );
  }

  List<TripStopPoint> _applyWaypointOrder(
    List<TripStopPoint> stops,
    List<dynamic>? orderRaw,
  ) {
    if (orderRaw == null || orderRaw.length != stops.length) return stops;
    final ordered = <TripStopPoint>[];
    for (final rawIdx in orderRaw) {
      final idx = (rawIdx as num).toInt();
      if (idx >= 0 && idx < stops.length) ordered.add(stops[idx]);
    }
    return ordered.length == stops.length ? ordered : stops;
  }

  List<LatLng> _fallbackStepEndpoints(Map<String, dynamic> step) {
    final pts = <LatLng>[];
    for (final key in const ['start_location', 'end_location']) {
      final loc = step[key] as Map<String, dynamic>?;
      if (loc != null) {
        pts.add(
          LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble()),
        );
      }
    }
    return pts;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  String? _cleanHtml(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'<div[^>]*>'), ' • ')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String? _extractStreetFromHtml(String? rawHtml) {
    if (rawHtml == null || rawHtml.trim().isEmpty) return null;
    final mainPart = rawHtml.split(RegExp(r'<div[^>]*>')).first;

    final prepMatch = RegExp(
      r'(?:\bna|\bno|\bpela|\bpelo|\bpara|\bpara a|\bpara o|\bem)\s*<b>([^<]+)</b>',
      caseSensitive: false,
    ).firstMatch(mainPart);
    if (prepMatch != null) {
      final candidate = _cleanHtml(prepMatch.group(1));
      if (candidate != null && candidate.length >= 2) return candidate;
    }

    const ignored = {
      'esquerda', 'direita', 'norte', 'sul', 'leste', 'oeste',
      'nordeste', 'noroeste', 'sudeste', 'sudoeste', 'frente', 'retorno',
    };
    final matches = RegExp(r'<b>([^<]+)</b>').allMatches(mainPart).toList();
    for (final m in matches.reversed) {
      final candidate = _cleanHtml(m.group(1));
      if (candidate != null &&
          candidate.length >= 2 &&
          !ignored.contains(candidate.toLowerCase())) {
        return candidate;
      }
    }
    return null;
  }

  String _formatGoogleInstruction(
    String? rawHtml,
    String? maneuver,
    String? street,
  ) {
    final action = _googleActionPt(maneuver);
    if (action != null && street != null && street.isNotEmpty) {
      return '$action • $street';
    }
    final cleaned = _cleanHtml(rawHtml?.split(RegExp(r'<div[^>]*>')).first);
    if (cleaned != null && cleaned.isNotEmpty) return cleaned;
    return street ?? action ?? 'Siga em frente';
  }

  String? _googleActionPt(String? maneuver) {
    const map = {
      'turn-left': 'Vire à esquerda',
      'turn-slight-left': 'Mantenha-se à esquerda',
      'turn-sharp-left': 'Curva acentuada à esquerda',
      'keep-left': 'Pegue a saída à esquerda',
      'fork-left': 'Pegue a saída à esquerda',
      'ramp-left': 'Pegue a saída à esquerda',
      'turn-right': 'Vire à direita',
      'turn-slight-right': 'Mantenha-se à direita',
      'turn-sharp-right': 'Curva acentuada à direita',
      'keep-right': 'Pegue a saída à direita',
      'fork-right': 'Pegue a saída à direita',
      'ramp-right': 'Pegue a saída à direita',
      'uturn-left': 'Faça o retorno',
      'uturn-right': 'Faça o retorno',
      'roundabout-left': 'Na rotatória, siga para',
      'roundabout-right': 'Na rotatória, siga para',
      'merge': 'Acesse',
      'straight': 'Siga em frente',
    };
    return map[maneuver];
  }

  IconData _googleManeuverIcon(String? maneuver) {
    switch (maneuver) {
      case 'turn-left':
      case 'fork-left':
      case 'ramp-left':
        return Icons.turn_left_rounded;
      case 'turn-slight-left':
      case 'keep-left':
        return Icons.turn_slight_left_rounded;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left_rounded;
      case 'turn-right':
      case 'fork-right':
      case 'ramp-right':
        return Icons.turn_right_rounded;
      case 'turn-slight-right':
      case 'keep-right':
        return Icons.turn_slight_right_rounded;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right_rounded;
      case 'uturn-left':
        return Icons.u_turn_left_rounded;
      case 'uturn-right':
        return Icons.u_turn_right_rounded;
      case 'roundabout-left':
        return Icons.roundabout_left_rounded;
      case 'roundabout-right':
        return Icons.roundabout_right_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  String? _osrmRoadLabel(Map<String, dynamic> step) {
    final ref = (step['ref'] as String?)?.trim();
    final name = (step['name'] as String?)?.trim();
    if (ref != null && ref.isNotEmpty && name != null && name.isNotEmpty) {
      return name.contains(ref) ? name : '$ref • $name';
    }
    if (ref != null && ref.isNotEmpty) return ref;
    return name != null && name.isNotEmpty ? name : null;
  }

  String _formatOsrmInstruction(String? type, String? modifier, String? road) {
    if (type == 'arrive') return road ?? 'Chegada';
    if (type == 'roundabout' || type == 'rotary') {
      return road != null ? 'Rotatória • $road' : 'Entre na rotatória';
    }
    const map = {
      'left': 'Vire à esquerda',
      'slight left': 'Mantenha-se à esquerda',
      'sharp left': 'Curva acentuada à esquerda',
      'right': 'Vire à direita',
      'slight right': 'Mantenha-se à direita',
      'sharp right': 'Curva acentuada à direita',
      'uturn': 'Faça o retorno',
    };
    final action = map[modifier] ?? 'Siga em frente';
    return road != null && road.isNotEmpty ? '$action • $road' : action;
  }

  IconData _osrmManeuverIcon(String? type, String? modifier) {
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
}