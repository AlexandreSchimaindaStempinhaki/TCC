import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../domain/models/trip_entity.dart';

class NavStep {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String instruction;
  final String? roadName;
  final IconData maneuverIcon;
  final int legIndex;
  final String? legEndLabel;
  final bool isStopArrival;

  const NavStep({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.instruction,
    this.roadName,
    required this.maneuverIcon,
    required this.legIndex,
    this.legEndLabel,
    this.isStopArrival = false,
  });
}

class ComputedRouteResult {
  final List<LatLng> polylinePoints;
  final List<NavStep> navSteps;
  final List<String> optimizedOrderIds;
  final Map<String, int> etaByPassengerId;
  final Map<String, String> addressByPassengerId;
  final double? totalDistanceMeters;
  final int? totalDurationMinutes;

  const ComputedRouteResult({
    required this.polylinePoints,
    required this.navSteps,
    required this.optimizedOrderIds,
    required this.etaByPassengerId,
    required this.addressByPassengerId,
    this.totalDistanceMeters,
    this.totalDurationMinutes,
  });
}

class TurnByTurnSnapshot {
  final int stepIndex;
  final double distanceToPathMeters;
  final double nextManeuverDistanceMeters;
  final String bannerTitle;
  final IconData bannerIcon;
  final String? thenTitle;
  final IconData? thenIcon;
  final String? currentStreet;
  final double remainingTotalMeters;
  final int remainingMinutes;

  const TurnByTurnSnapshot({
    required this.stepIndex,
    required this.distanceToPathMeters,
    required this.nextManeuverDistanceMeters,
    required this.bannerTitle,
    required this.bannerIcon,
    this.thenTitle,
    this.thenIcon,
    this.currentStreet,
    required this.remainingTotalMeters,
    required this.remainingMinutes,
  });
}

class _StepProjection {
  final double distanceToPathMeters;
  final double remainingStepMeters;

  const _StepProjection({
    required this.distanceToPathMeters,
    required this.remainingStepMeters,
  });
}

class LiveMapNavigationEngine {
  LiveMapNavigationEngine._();

  static double distanceMeters(LatLng a, LatLng b) {
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

  static double calculateBearing(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_radToDeg(math.atan2(y, x)) + 360) % 360;
  }

  static double polylineLengthMeters(List<LatLng> points) {
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distanceMeters(points[i], points[i + 1]);
    }
    return total;
  }

  static String formatDistance(double meters) {
    if (meters < 50) return '${math.max(5, (meters / 5).round() * 5)} m';
    if (meters < 1000) return '${(meters / 10).round() * 10} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static String formatArrivalClock(int minutesFromNow) {
    final eta = DateTime.now().add(Duration(minutes: minutesFromNow));
    return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
  }

  /// Ordena: 1) Prontos (ordem do Google ou vizinho mais próximo), 2) Aguardando, 3) Embarcados.
  static List<TripStopPoint> orderStops({
    required List<TripStopPoint> rawStops,
    required LatLng startPoint,
    required List<String> googleOptimizedOrderIds,
    required Map<String, int> etaByPassengerId,
    required Map<String, String> addressByPassengerId,
  }) {
    if (rawStops.isEmpty) return const [];

    final completed = rawStops.where((s) => s.isCompleted).toList();
    final pendingReady =
        rawStops.where((s) => !s.isCompleted && s.isPassengerReady).toList();
    final pendingWaiting =
        rawStops.where((s) => !s.isCompleted && !s.isPassengerReady).toList();

    final ordered = <TripStopPoint>[];
    LatLng cursor = startPoint;
    int cumulativeMinutes = 0;

    void appendGroup(List<TripStopPoint> group) {
      if (group.isEmpty) return;

      final hasGoogleOrder =
          group.every((s) => googleOptimizedOrderIds.contains(s.passengerId));

      final List<TripStopPoint> sortedGroup;
      if (hasGoogleOrder) {
        sortedGroup = [...group]..sort(
            (a, b) => googleOptimizedOrderIds
                .indexOf(a.passengerId)
                .compareTo(googleOptimizedOrderIds.indexOf(b.passengerId)),
          );
      } else {
        final pool = [...group];
        sortedGroup = [];
        LatLng localCursor = cursor;
        while (pool.isNotEmpty) {
          int bestIdx = 0;
          double bestDist = double.infinity;
          for (int i = 0; i < pool.length; i++) {
            final d = distanceMeters(
              localCursor,
              LatLng(pool[i].latitude, pool[i].longitude),
            );
            if (d < bestDist) {
              bestDist = d;
              bestIdx = i;
            }
          }
          final chosen = pool.removeAt(bestIdx);
          localCursor = LatLng(chosen.latitude, chosen.longitude);
          sortedGroup.add(chosen);
        }
      }

      for (final stop in sortedGroup) {
        final legDist = distanceMeters(
          cursor,
          LatLng(stop.latitude, stop.longitude),
        );
        cursor = LatLng(stop.latitude, stop.longitude);
        cumulativeMinutes +=
            math.max(1, ((legDist / 1000.0) / 38.0 * 60).round());

        ordered.add(
          stop.copyWith(
            orderIndex: ordered.length + 1,
            passengerAddress:
                (stop.passengerAddress?.trim().isNotEmpty == true)
                    ? stop.passengerAddress
                    : addressByPassengerId[stop.passengerId],
            estimatedMinutesRemaining: etaByPassengerId[stop.passengerId] ??
                stop.estimatedMinutesRemaining ??
                cumulativeMinutes,
          ),
        );
      }
    }

    appendGroup(pendingReady);
    appendGroup(pendingWaiting);

    for (final done in completed) {
      ordered.add(
        done.copyWith(
          orderIndex: ordered.length + 1,
          passengerAddress: (done.passengerAddress?.trim().isNotEmpty == true)
              ? done.passengerAddress
              : addressByPassengerId[done.passengerId],
        ),
      );
    }

    return ordered;
  }

  static TurnByTurnSnapshot? evaluateTurnByTurn({
    required LatLng driverPos,
    required List<NavStep> navSteps,
    required int currentStepIndex,
  }) {
    if (navSteps.isEmpty) return null;

    int bestIdx = currentStepIndex.clamp(0, navSteps.length - 1).toInt();
    _StepProjection bestProj =
        _projectOntoPolyline(driverPos, navSteps[bestIdx].points);

    final int searchStart = math.max(0, currentStepIndex - 1);
    final int searchEnd = math.min(navSteps.length - 1, currentStepIndex + 6);

    for (int i = searchStart; i <= searchEnd; i++) {
      final proj = _projectOntoPolyline(driverPos, navSteps[i].points);
      final double adjustedDist =
          (i > currentStepIndex && bestProj.remainingStepMeters < 22.0)
              ? proj.distanceToPathMeters - 10.0
              : proj.distanceToPathMeters;
      if (adjustedDist < bestProj.distanceToPathMeters) {
        bestIdx = i;
        bestProj = proj;
      }
    }

    if (bestProj.distanceToPathMeters > 45.0) {
      for (int i = 0; i < navSteps.length; i++) {
        final proj = _projectOntoPolyline(driverPos, navSteps[i].points);
        if (proj.distanceToPathMeters < bestProj.distanceToPathMeters) {
          bestIdx = i;
          bestProj = proj;
        }
      }
    }

    if (bestProj.remainingStepMeters <= 14.0 &&
        bestIdx + 1 < navSteps.length) {
      final nextProj =
          _projectOntoPolyline(driverPos, navSteps[bestIdx + 1].points);
      if (nextProj.distanceToPathMeters <= 35.0) {
        bestIdx += 1;
        bestProj = nextProj;
      }
    }

    final currentStep = navSteps[bestIdx];
    final NavStep? upcomingStep =
        (bestIdx + 1 < navSteps.length) ? navSteps[bestIdx + 1] : null;
    final NavStep? afterStep =
        (bestIdx + 2 < navSteps.length) ? navSteps[bestIdx + 2] : null;

    final bool isEndingLeg =
        upcomingStep == null || upcomingStep.legIndex != currentStep.legIndex;

    final String bannerTitle;
    final IconData bannerIcon;
    String? thenTitle;
    IconData? thenIcon;

    if (isEndingLeg) {
      if (currentStep.isStopArrival && currentStep.legEndLabel != null) {
        bannerTitle = 'Chegando • ${currentStep.legEndLabel}';
        bannerIcon = Icons.person_pin_circle_rounded;
      } else {
        bannerTitle = 'Chegada • ${currentStep.legEndLabel ?? 'Destino'}';
        bannerIcon = Icons.flag_rounded;
      }
      if (upcomingStep != null) {
        thenTitle = upcomingStep.instruction;
        thenIcon = upcomingStep.maneuverIcon;
      }
    } else {
      bannerTitle = upcomingStep.instruction;
      bannerIcon = upcomingStep.maneuverIcon;

      if (afterStep != null && afterStep.legIndex == currentStep.legIndex) {
        thenTitle = afterStep.instruction;
        thenIcon = afterStep.maneuverIcon;
      } else {
        thenTitle =
            currentStep.isStopArrival && currentStep.legEndLabel != null
                ? 'Chegando • ${currentStep.legEndLabel}'
                : 'Chegada • ${currentStep.legEndLabel ?? 'Destino'}';
        thenIcon = currentStep.isStopArrival
            ? Icons.person_pin_circle_rounded
            : Icons.flag_rounded;
      }
    }

    final String? streetNow = currentStep.roadName ??
        (bestIdx > 0 ? navSteps[bestIdx - 1].roadName : null) ??
        currentStep.instruction;

    double remainingTotalMeters = bestProj.remainingStepMeters;
    double remainingTotalSeconds = currentStep.distanceMeters > 0
        ? currentStep.durationSeconds *
            (bestProj.remainingStepMeters / currentStep.distanceMeters)
                .clamp(0.0, 1.0)
                .toDouble()
        : 0.0;

    for (int i = bestIdx + 1; i < navSteps.length; i++) {
      remainingTotalMeters += navSteps[i].distanceMeters;
      remainingTotalSeconds += navSteps[i].durationSeconds;
    }

    final int remainingMinutes = remainingTotalSeconds > 0
        ? (remainingTotalSeconds / 60).ceil().clamp(1, 999).toInt()
        : ((remainingTotalMeters / 1000.0) / 38.0 * 60)
            .ceil()
            .clamp(1, 999)
            .toInt();

    return TurnByTurnSnapshot(
      stepIndex: bestIdx,
      distanceToPathMeters: bestProj.distanceToPathMeters,
      nextManeuverDistanceMeters: bestProj.remainingStepMeters,
      bannerTitle: bannerTitle,
      bannerIcon: bannerIcon,
      thenTitle: thenTitle,
      thenIcon: thenIcon,
      currentStreet: streetNow,
      remainingTotalMeters: remainingTotalMeters,
      remainingMinutes: remainingMinutes,
    );
  }

  static _StepProjection _projectOntoPolyline(
    LatLng point,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) {
      return const _StepProjection(
        distanceToPathMeters: double.infinity,
        remainingStepMeters: 0,
      );
    }
    if (polyline.length == 1) {
      final d = distanceMeters(point, polyline.first);
      return _StepProjection(
        distanceToPathMeters: d,
        remainingStepMeters: d,
      );
    }

    final segLengths = List<double>.filled(polyline.length - 1, 0);
    for (int i = 0; i < polyline.length - 1; i++) {
      segLengths[i] = distanceMeters(polyline[i], polyline[i + 1]);
    }
    final suffixDist = List<double>.filled(polyline.length, 0);
    for (int i = polyline.length - 2; i >= 0; i--) {
      suffixDist[i] = suffixDist[i + 1] + segLengths[i];
    }

    const double latScale = 111320.0;
    final double lngScale = 111320.0 * math.cos(_degToRad(point.latitude));

    double bestDist = double.infinity;
    double bestRemaining = suffixDist.first;

    for (int i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];

      final bx = (b.longitude - a.longitude) * lngScale;
      final by = (b.latitude - a.latitude) * latScale;
      final px = (point.longitude - a.longitude) * lngScale;
      final py = (point.latitude - a.latitude) * latScale;

      final abLenSq = (bx * bx) + (by * by);
      final double t = abLenSq <= 1e-6
          ? 0.0
          : (((px * bx) + (py * by)) / abLenSq).clamp(0.0, 1.0).toDouble();

      final dx = px - (bx * t);
      final dy = py - (by * t);
      final dist = math.sqrt((dx * dx) + (dy * dy));

      if (dist < bestDist) {
        bestDist = dist;
        bestRemaining = (segLengths[i] * (1.0 - t)) + suffixDist[i + 1];
      }
    }

    return _StepProjection(
      distanceToPathMeters: bestDist,
      remainingStepMeters: bestRemaining,
    );
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);
}