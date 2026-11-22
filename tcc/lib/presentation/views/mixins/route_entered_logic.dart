import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/company_routes.dart';
import '../../../core/routes/home_routes.dart';
import '../../../core/routes/route_operation_routes.dart';
import '../../../domain/models/boarding_entity.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/route_entity.dart';
import '../../../domain/models/trip_entity.dart';
import '../../../domain/models/user_entity.dart';
import '../../../domain/models/vehicle_entity.dart';
import '../../controllers/boarding/boarding_list_viewmodel.dart';
import '../../controllers/boarding/boarding_viewmodel.dart';
import '../../controllers/company/company_list_viewmodel.dart';
import '../../controllers/route/route_viewmodel.dart';
import '../../controllers/trip/trip_list_viewmodel.dart';
import '../../controllers/trip/trip_viewmodel.dart';
import '../../controllers/user/user_viewmodel.dart';
import '../../widgets/calendar/route_schedule_resolver.dart';
import '../application/routes/route_entered_view.dart';

mixin RouteEnteredMixin on State<RouteEnteredView> {
  late final RouteViewModel routeViewModel;
  late final BoardingViewModel boardingViewModel;
  late final BoardingListViewModel boardingListViewModel;
  late final TripViewModel tripViewModel;
  late final TripListViewModel tripListViewModel;
  late final CompanyListViewModel companyListViewModel;
  late final UserViewModel userViewModel;

  final isLoading = signal<bool>(true);
  final isActionExecuting = signal<bool>(false);
  final isStartingRoute = signal<bool>(false);
  final startingRouteMessage = signal<String>('Iniciando rota...');
  final selectedDirection = signal<TripDirection>(TripDirection.outbound);
  final liveNotificationBanner = signal<String?>(null);

  StreamSubscription<Position>? _driverPositionSub;
  EffectCleanup? _tripMonitorCleanup;
  bool _hasNotifiedStartInSession = false;
  final Set<int> _notifiedThresholdsInSession = {};

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  RouteModel get currentRoute {
    final loaded = routeViewModel.state.route.value;
    if (loaded != null && loaded.id == widget.route.id) return loaded;
    return widget.route;
  }

  CompanyModel? get currentCompany => widget.company ?? currentRoute.company;

  String get routeIdStr => currentRoute.id.toString();

  String get currentUserId {
    final loggedUser = userViewModel.state.user.value;
    final cleanCpf = _cleanDigits(loggedUser?.cpf ?? '');
    if (cleanCpf.isNotEmpty) return cleanCpf;
    if (loggedUser != null && loggedUser.uid.trim().isNotEmpty) {
      return loggedUser.uid.trim();
    }
    return '';
  }

  Set<String> _allCurrentUserIdentifiers() {
    final ids = <String>{};
    final loggedUser = userViewModel.state.user.value;

    if (loggedUser != null) {
      if (loggedUser.uid.trim().isNotEmpty) ids.add(loggedUser.uid.trim());
      final cpf = loggedUser.cpf ?? '';
      if (cpf.trim().isNotEmpty) {
        ids.add(cpf.trim());
        final cleaned = _cleanDigits(cpf);
        if (cleaned.isNotEmpty) ids.add(cleaned);
      }
      if (loggedUser.email.trim().isNotEmpty) {
        ids.add(loggedUser.email.trim().toLowerCase());
      }
    }
    return ids;
  }

  bool _matchesUser(String? rawTarget, Set<String> userIds) {
    if (rawTarget == null) return false;
    final trimmed = rawTarget.trim();
    if (trimmed.isEmpty) return false;
    final cleaned = _cleanDigits(trimmed);
    return userIds.contains(trimmed) ||
        userIds.contains(trimmed.toLowerCase()) ||
        (cleaned.length == 11 && userIds.contains(cleaned));
  }

  bool get hasValidCnh {
    final cnh = userViewModel.state.user.value?.driverLicense;
    return cnh != null && cnh.trim().isNotEmpty;
  }

  bool get isStaffRole {
    final badge = (widget.roleBadge ?? '').trim().toLowerCase();

    if (badge == 'passageiro') return false;

    if (['motorista', 'gerente', 'ceo', 'equipe'].contains(badge)) {
      return true;
    }

    final userIds = _allCurrentUserIdentifiers();
    if (_matchesUser(currentRoute.driverId, userIds)) return true;

    final comp = currentCompany;
    if (comp != null) {
      if (_matchesUser(comp.ownerId, userIds)) return true;
      if (comp.memberIds.any((id) => _matchesUser(id, userIds))) return true;
    }

    final cleanCnpj = _cleanDigits(currentRoute.companyCnpj);
    if (cleanCnpj.isNotEmpty) {
      final isOwned = companyListViewModel.state.ownedCompanies.value.any(
        (c) => _cleanDigits(c.cnpj) == cleanCnpj,
      );
      final isMember = companyListViewModel.state.memberCompanies.value.any(
        (c) => _cleanDigits(c.cnpj) == cleanCnpj,
      );
      if (isOwned || isMember) return true;
    }

    return false;
  }

  bool get canDriveRoute => isStaffRole && hasValidCnh;

  bool get isPassengerInRoute {
    final userIds = _allCurrentUserIdentifiers();
    if (currentRoute.passengerIds.any((id) => _matchesUser(id, userIds))) {
      return true;
    }
    return !isStaffRole;
  }

  /// Determina automaticamente o sentido (Ida/Volta) e horário mais próximos do relógio atual.
  ({TripDirection direction, String? slotTime, DateTime scheduledDateTime})
  resolveClosestScheduleNow() {
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final resolved = RouteScheduleResolver.resolve(currentRoute);

    TripDirection bestDirection = TripDirection.outbound;
    ScheduleSlot? bestSlot;
    int bestDiff = 1 << 30;

    for (final s in resolved.outboundSlots) {
      final diff = (s.minutesFromMidnight - nowMin).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestDirection = TripDirection.outbound;
        bestSlot = s;
      }
    }

    for (final s in resolved.returnSlots) {
      final diff = (s.minutesFromMidnight - nowMin).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        bestDirection = TripDirection.returnTrip;
        bestSlot = s;
      }
    }

    final scheduledDateTime = bestSlot != null
        ? DateTime(
            now.year,
            now.month,
            now.day,
            bestSlot.minutesFromMidnight ~/ 60,
            bestSlot.minutesFromMidnight % 60,
          )
        : now;

    return (
      direction: bestDirection,
      slotTime: bestSlot?.time,
      scheduledDateTime: scheduledDateTime,
    );
  }

  String get closestScheduleLabel {
    final closest = resolveClosestScheduleNow();
    final dirLabel =
        closest.direction == TripDirection.outbound ? 'Ida' : 'Volta';
    final cleanTime = closest.slotTime?.replaceAll('~', '').trim();
    return cleanTime != null && cleanTime.isNotEmpty
        ? '$dirLabel • $cleanTime'
        : dirLabel;
  }

  /// Todas as viagens ativas (em andamento ou embarcando) nesta rota agora.
  List<TripModel> get activeTripsForRoute {
    final byId = <String, TripModel>{};

    for (final t in tripListViewModel.state.routeTrips.value) {
      if (t.routeId == routeIdStr &&
          (t.status == TripStatus.inProgress ||
              t.status == TripStatus.boarding)) {
        byId[t.id] = t;
      }
    }

    final watched = tripViewModel.state.activeTrip.value;
    if (watched != null &&
        watched.routeId == routeIdStr &&
        (watched.status == TripStatus.inProgress ||
            watched.status == TripStatus.boarding)) {
      byId[watched.id] = watched;
    }

    final list = byId.values.toList()
      ..sort((a, b) => a.tripGroupIndex.compareTo(b.tripGroupIndex));
    return list;
  }

  /// Viagem ativa conduzida especificamente pela conta logada.
  TripModel? get myActiveTrip {
    if (!isStaffRole) return null;
    final userIds = _allCurrentUserIdentifiers();
    for (final trip in activeTripsForRoute) {
      if (_matchesUser(trip.driverId, userIds)) return trip;
    }
    return null;
  }

  /// IDs dos veículos já ocupados por viagens ativas desta rota.
  Set<String> get activeVehicleIds => activeTripsForRoute
      .map((t) => t.vehicleId.trim())
      .where((id) => id.isNotEmpty)
      .toSet();

  Set<String> _assignedPassengerKeysInActiveTrips() {
    final assigned = <String>{};
    for (final trip in activeTripsForRoute) {
      for (final rawId in trip.assignedPassengerIds) {
        final trimmed = rawId.trim();
        if (trimmed.isNotEmpty) assigned.add(trimmed);
        final cleaned = _cleanDigits(trimmed);
        if (cleaned.length == 11) assigned.add(cleaned);
      }
      for (final stop in trip.stops) {
        final trimmed = stop.passengerId.trim();
        if (trimmed.isNotEmpty) assigned.add(trimmed);
        final cleaned = _cleanDigits(trimmed);
        if (cleaned.length == 11) assigned.add(cleaned);
      }
    }
    return assigned;
  }

  bool _isPassengerAlreadyAssigned(String rawId, Set<String> assignedKeys) {
    final trimmed = rawId.trim();
    if (assignedKeys.contains(trimmed)) return true;
    final cleaned = _cleanDigits(trimmed);
    return cleaned.length == 11 && assignedKeys.contains(cleaned);
  }

  /// Passageiros confirmados no turno atual que ainda não couberam nos veículos ativos.
  List<TripStopPoint> get unassignedStopsForClosestSchedule {
    final closest = resolveClosestScheduleNow();
    final allStops = _buildOptimizedStopsFromTodayBoardings(
      startLat: currentRoute.origin.latitude,
      startLng: currentRoute.origin.longitude,
      directionOverride: closest.direction,
      targetSlotTime: closest.slotTime,
    );

    final assignedKeys = _assignedPassengerKeysInActiveTrips();
    if (assignedKeys.isEmpty) return allStops;

    return allStops
        .where((s) => !_isPassengerAlreadyAssigned(s.passengerId, assignedKeys))
        .toList();
  }

  /// Indica se há passageiros excedendo a capacidade dos veículos atualmente em rota.
  bool get needsExtraVehicleTrip {
    final activeTrips = activeTripsForRoute;
    if (activeTrips.isEmpty) return false;

    final remaining = unassignedStopsForClosestSchedule.length;
    if (remaining == 0) return false;

    final totalCapacity = activeTrips.fold<int>(
      0,
      (sum, t) => sum + t.vehicleCapacity,
    );
    final totalAssigned = activeTrips.fold<int>(
      0,
      (sum, t) =>
          sum + math.max(t.passengerCount, t.assignedPassengerIds.length),
    );

    return (totalAssigned + remaining) > totalCapacity ||
        activeTrips.every((t) => t.isFull);
  }

  TripModel? get currentActiveTrip {
    final activeTrips = activeTripsForRoute;
    if (activeTrips.isEmpty) return null;

    if (isStaffRole) {
      return myActiveTrip ?? activeTrips.first;
    }

    final userIds = _allCurrentUserIdentifiers();
    for (final trip in activeTrips) {
      final assignedHere =
          trip.assignedPassengerIds.any((id) => _matchesUser(id, userIds)) ||
          trip.stops.any((s) => _matchesUser(s.passengerId, userIds));
      if (assignedHere) return trip;
    }

    return activeTrips.first;
  }

  bool get isRouteActiveNow =>
      currentRoute.isTripActive || activeTripsForRoute.isNotEmpty;

  TripStopPoint? get currentUserStop {
    final trip = currentActiveTrip;
    if (trip == null) return null;
    final userIds = _allCurrentUserIdentifiers();
    for (final stop in trip.stops) {
      if (_matchesUser(stop.passengerId, userIds)) return stop;
    }
    return null;
  }

  /// Libera a avaliação da empresa após o passageiro concluir sua primeira viagem.
  bool get hasCompletedFirstTrip {
    if (isStaffRole) return false;

    final current = boardingViewModel.state.currentBoarding.value;
    if (current != null &&
        current.present &&
        current.attendanceStatus == BoardingAttendanceStatus.boarded) {
      return true;
    }

    final history = boardingViewModel.state.calendarMap.value.values;
    if (history.any(
      (b) =>
          b.present && b.attendanceStatus == BoardingAttendanceStatus.boarded,
    )) {
      return true;
    }

    final userIds = _allCurrentUserIdentifiers();
    for (final trip in tripListViewModel.state.routeTrips.value) {
      if (trip.routeId != routeIdStr) continue;
      final inTrip =
          trip.assignedPassengerIds.any((id) => _matchesUser(id, userIds)) ||
          trip.stops.any((s) => _matchesUser(s.passengerId, userIds));
      if (!inTrip) continue;

      if (trip.status == TripStatus.completed) return true;
      if (trip.stops.any(
        (s) => _matchesUser(s.passengerId, userIds) && s.isCompleted,
      )) {
        return true;
      }
    }

    return false;
  }

  List<TripStopPoint> get optimizedStopsForCurrentState {
    final active = currentActiveTrip;
    final boardings = boardingListViewModel.state.routeBoardings.value;
    final readyUserIds = boardings
        .where((b) => b.present && b.isReadyForBoarding)
        .map(
          (b) => _cleanDigits(b.userId).isNotEmpty
              ? _cleanDigits(b.userId)
              : b.userId.trim(),
        )
        .toSet();

    if (active != null && active.stops.isNotEmpty) {
      final refLat = active.driverLatitude ?? currentRoute.origin.latitude;
      final refLng = active.driverLongitude ?? currentRoute.origin.longitude;

      final enriched = active.stops.map((stop) {
        final cleanId = _cleanDigits(stop.passengerId);
        final isReady =
            stop.isPassengerReady ||
            readyUserIds.contains(stop.passengerId.trim()) ||
            (cleanId.isNotEmpty && readyUserIds.contains(cleanId));
        return stop.copyWith(isPassengerReady: isReady);
      }).toList();

      return _sortStopsOptimally(
        stops: enriched,
        startLat: refLat,
        startLng: refLng,
      );
    }

    final closest = resolveClosestScheduleNow();
    return _buildOptimizedStopsFromTodayBoardings(
      startLat: currentRoute.origin.latitude,
      startLng: currentRoute.origin.longitude,
      directionOverride: closest.direction,
      targetSlotTime: closest.slotTime,
    );
  }

  @override
  void initState() {
    super.initState();
    routeViewModel = injector.get<RouteViewModel>();
    boardingViewModel = injector.get<BoardingViewModel>();
    boardingListViewModel = injector.get<BoardingListViewModel>();
    tripViewModel = injector.get<TripViewModel>();
    tripListViewModel = injector.get<TripListViewModel>();
    companyListViewModel = injector.get<CompanyListViewModel>();
    userViewModel = injector.get<UserViewModel>();

    selectedDirection.value = resolveClosestScheduleNow().direction;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupRealtimeNotificationsMonitor();
      loadInitialData();
    });
  }

  @override
  void dispose() {
    _tripMonitorCleanup?.call();
    _driverPositionSub?.cancel();
    boardingListViewModel.commands.stopWatchingRouteBoardings();
    boardingViewModel.commands.stopWatchingPassengerBoarding();
    tripListViewModel.commands.stopWatchingActiveTrips();
    tripViewModel.commands.stopWatchingTrip();
    isLoading.dispose();
    isActionExecuting.dispose();
    isStartingRoute.dispose();
    startingRouteMessage.dispose();
    selectedDirection.dispose();
    liveNotificationBanner.dispose();
    super.dispose();
  }

  Future<void> loadInitialData() async {
    if (!mounted) return;
    isLoading.value = true;
    try {
      if (userViewModel.state.user.value == null) {
        await userViewModel.commands.fetchUser();
      }

      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);

      await routeViewModel.commands.fetchRouteById(
        currentRoute.id,
        loadMembers: true,
      );

      selectedDirection.value = resolveClosestScheduleNow().direction;

      final uid = currentUserId;
      if (uid.isNotEmpty) {
        if (!isStaffRole) {
          await boardingViewModel.commands.loadUserHistory(
            routeId: routeIdStr,
            userId: uid,
            startDate: DateTime(2024, 1, 1),
            endDate: normalizedToday,
          );
        }

        await boardingViewModel.commands.loadDailyBoarding(
          routeId: routeIdStr,
          userId: uid,
          date: normalizedToday,
        );
        boardingViewModel.commands.watchPassengerBoarding(
          routeId: routeIdStr,
          userId: uid,
          date: normalizedToday,
        );
      }

      await boardingListViewModel.commands.fetchByRouteAndDate(
        routeId: routeIdStr,
        date: normalizedToday,
      );
      boardingListViewModel.commands.watchRouteBoardingsByDate(
        routeId: routeIdStr,
        date: normalizedToday,
      );

      await tripListViewModel.commands.fetchTripsByRoute(
        routeId: routeIdStr,
        date: normalizedToday,
      );
      tripListViewModel.commands.watchActiveTripsByRoute(routeIdStr);

      final active = currentActiveTrip;
      if (active != null) {
        tripViewModel.commands.startWatchingTrip(active.id);
      }
    } finally {
      if (mounted) {
        isLoading.value = false;
      }
    }
  }

  void _setupRealtimeNotificationsMonitor() {
    _tripMonitorCleanup?.call();
    _tripMonitorCleanup = effect(() {
      if (!mounted) return;
      final trip = currentActiveTrip;
      final routeActive = currentRoute.isTripActive || trip != null;
      final boarding = boardingViewModel.state.currentBoarding.value;

      if (trip != null && tripViewModel.state.activeTrip.value?.id != trip.id) {
        untracked(() {
          tripViewModel.commands.startWatchingTrip(trip.id);
        });
      }

      if (routeActive && !_hasNotifiedStartInSession) {
        _hasNotifiedStartInSession = true;
        final alreadyNotifiedInDb = boarding?.wasTripStartNotified ?? false;

        if (!alreadyNotifiedInDb && !isStaffRole) {
          const msg =
              'O motorista iniciou a rota! Sinalize "Estou pronto" quando estiver no ponto.';
          liveNotificationBanner.value = msg;
          untracked(() {
            _showSnackBar(msg);
            if (boarding != null) {
              final updated = boarding.copyWith(wasTripStartNotified: true);
              boardingViewModel.state.currentBoarding.value = updated;
              boardingViewModel.state.upsertInHistory(updated);
              try {
                boardingViewModel.registerBoardingNotificationCommand.execute(
                  boardingId: boarding.id,
                );
              } catch (_) {}
            }
          });
        }
      }

      if (trip != null && !isStaffRole) {
        final myStop = currentUserStop;
        int? etaMinutes = myStop?.estimatedMinutesRemaining;

        if (etaMinutes == null &&
            trip.driverLatitude != null &&
            trip.driverLongitude != null) {
          final stopLat =
              myStop?.latitude ??
              userViewModel.state.user.value?.boardingPoint?.latitude;
          final stopLng =
              myStop?.longitude ??
              userViewModel.state.user.value?.boardingPoint?.longitude;

          if (stopLat != null && stopLng != null) {
            final distKm = _calculateDistanceKm(
              trip.driverLatitude!,
              trip.driverLongitude!,
              stopLat,
              stopLng,
            );
            etaMinutes = math.max(1, ((distKm / 35.0) * 60).round());
          }
        }

        if (etaMinutes != null) {
          const thresholds = [15, 10, 5, 2];
          for (final t in thresholds) {
            if (etaMinutes <= t && !_notifiedThresholdsInSession.contains(t)) {
              _notifiedThresholdsInSession.add(t);
              final msg = etaMinutes <= 2
                  ? 'O motorista está muito próximo do seu ponto (~$etaMinutes min)!'
                  : 'Motorista a caminho: chegada estimada em ~$etaMinutes min.';
              liveNotificationBanner.value = msg;
              untracked(() {
                _showSnackBar(msg);
                if (boarding != null) {
                  try {
                    boardingViewModel.registerBoardingNotificationCommand
                        .execute(
                          boardingId: boarding.id,
                          etaThresholdMinutes: t,
                        );
                  } catch (_) {}
                }
              });
              break;
            }
          }
        }
      }
    });
  }

  UserModel? _findPassengerProfile(String rawUserId) {
    final passengers = routeViewModel.state.passengers.value;
    final cleanTarget = _cleanDigits(rawUserId);

    for (final p in passengers) {
      final pCleanCpf = _cleanDigits(p.cpf ?? '');
      if (p.uid.trim() == rawUserId.trim() ||
          (cleanTarget.length == 11 && pCleanCpf == cleanTarget) ||
          p.email.trim().toLowerCase() == rawUserId.trim().toLowerCase()) {
        return p;
      }
    }
    return null;
  }

  List<TripStopPoint> _buildOptimizedStopsFromTodayBoardings({
    required double startLat,
    required double startLng,
    TripDirection? directionOverride,
    String? targetSlotTime,
  }) {
    final closest = resolveClosestScheduleNow();
    final effectiveDirection = directionOverride ?? closest.direction;
    final isOutbound = effectiveDirection == TripDirection.outbound;
    final resolved = RouteScheduleResolver.resolve(currentRoute);
    final slots = isOutbound ? resolved.outboundSlots : resolved.returnSlots;

    final effectiveSlot = targetSlotTime ?? closest.slotTime;

    final allTodayBoardings = boardingListViewModel.state.routeBoardings.value;
    final confirmedBoardings = isOutbound
        ? boardingListViewModel.state.confirmedOutboundList.value
        : boardingListViewModel.state.confirmedReturnList.value;

    final passengers = routeViewModel.state.passengers.value;
    final rawStops = <TripStopPoint>[];
    final addedIds = <String>{};

    final explicitUserIds = allTodayBoardings
        .map(
          (b) => _cleanDigits(b.userId).isNotEmpty
              ? _cleanDigits(b.userId)
              : b.userId.trim(),
        )
        .toSet();

    for (final b in confirmedBoardings) {
      final chosenSlot = isOutbound
          ? (b.selectedDepartureTime?.trim().isNotEmpty == true
                ? b.selectedDepartureTime!.trim()
                : (slots.isNotEmpty ? slots.first.time : null))
          : (b.selectedReturnTime?.trim().isNotEmpty == true
                ? b.selectedReturnTime!.trim()
                : resolved.defaultReturnForOutbound(b.selectedDepartureTime));

      if (effectiveSlot != null &&
          chosenSlot != null &&
          chosenSlot != effectiveSlot) {
        continue;
      }

      final profile = _findPassengerProfile(b.userId);
      final geo = isOutbound
          ? (profile?.boardingPoint ?? currentRoute.origin)
          : (profile?.disembarkationPoint ??
                profile?.boardingPoint ??
                currentRoute.destination);

      final key = _cleanDigits(b.userId).isNotEmpty
          ? _cleanDigits(b.userId)
          : b.userId.trim();
      if (addedIds.contains(key)) continue;
      addedIds.add(key);

      rawStops.add(
        TripStopPoint(
          passengerId: b.userId,
          passengerName: profile?.name ?? 'Passageiro',
          passengerPhotoUrl: profile?.photoUrl,
          latitude: geo.latitude,
          longitude: geo.longitude,
          orderIndex: 0,
          isPassengerReady: b.isReadyForBoarding,
          isCompleted: b.attendanceStatus == BoardingAttendanceStatus.boarded,
        ),
      );
    }

    if (allTodayBoardings.isEmpty && passengers.isNotEmpty) {
      for (final p in passengers) {
        final id = (p.cpf != null && p.cpf!.trim().isNotEmpty)
            ? _cleanDigits(p.cpf!)
            : p.uid;
        if (addedIds.contains(id) || explicitUserIds.contains(id)) continue;
        addedIds.add(id);

        final geo = isOutbound
            ? (p.boardingPoint ?? currentRoute.origin)
            : (p.disembarkationPoint ??
                  p.boardingPoint ??
                  currentRoute.destination);

        rawStops.add(
          TripStopPoint(
            passengerId: id,
            passengerName: p.name,
            passengerPhotoUrl: p.photoUrl,
            latitude: geo.latitude,
            longitude: geo.longitude,
            orderIndex: 0,
            isPassengerReady: false,
            isCompleted: false,
          ),
        );
      }
    }

    return _sortStopsOptimally(
      stops: rawStops,
      startLat: startLat,
      startLng: startLng,
    );
  }

  List<TripStopPoint> _sortStopsOptimally({
    required List<TripStopPoint> stops,
    required double startLat,
    required double startLng,
  }) {
    if (stops.isEmpty) return const [];

    final completed = stops.where((s) => s.isCompleted).toList();
    final pendingReady = stops
        .where((s) => !s.isCompleted && s.isPassengerReady)
        .toList();
    final pendingOthers = stops
        .where((s) => !s.isCompleted && !s.isPassengerReady)
        .toList();

    final ordered = <TripStopPoint>[];
    double curLat = startLat;
    double curLng = startLng;

    void consumePool(List<TripStopPoint> pool) {
      while (pool.isNotEmpty) {
        int bestIdx = 0;
        double bestDist = double.infinity;

        for (int i = 0; i < pool.length; i++) {
          final candidate = pool[i];
          final d = _calculateDistanceKm(
            curLat,
            curLng,
            candidate.latitude,
            candidate.longitude,
          );
          if (d < bestDist) {
            bestDist = d;
            bestIdx = i;
          }
        }

        final chosen = pool.removeAt(bestIdx);
        curLat = chosen.latitude;
        curLng = chosen.longitude;
        final eta = math.max(1, ((bestDist / 35.0) * 60).round());

        ordered.add(
          chosen.copyWith(
            orderIndex: ordered.length + 1,
            estimatedMinutesRemaining: eta,
          ),
        );
      }
    }

    consumePool(pendingReady);
    consumePool(pendingOthers);
    for (final c in completed) {
      ordered.add(c.copyWith(orderIndex: ordered.length + 1));
    }

    return ordered;
  }

  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Future<void> togglePassengerReady() async {
    final uid = currentUserId;
    if (uid.isEmpty || isStaffRole) return;

    isActionExecuting.value = true;
    try {
      final now = DateTime.now();
      final normalizedToday = DateTime(now.year, now.month, now.day);

      var boarding = boardingViewModel.state.currentBoarding.value;
      boarding ??= await boardingViewModel.commands.loadDailyBoarding(
        routeId: routeIdStr,
        userId: uid,
        date: normalizedToday,
      );

      if (boarding == null) return;

      final nextReady = !boarding.isReadyForBoarding;
      final ok = await boardingViewModel.commands.toggleReadyForBoarding(
        boardingId: boarding.id,
        isReady: nextReady,
      );

      final active = currentActiveTrip;
      if (active != null) {
        await tripViewModel.commands.setPassengerReadyAtStop(
          tripId: active.id,
          passengerId: uid,
          isReady: nextReady,
        );
      }

      if (ok) {
        _showSnackBar(
          nextReady
              ? 'Status "Estou pronto" ativado!'
              : 'Status "Estou pronto" desativado.',
        );
      }
    } finally {
      if (mounted) {
        isActionExecuting.value = false;
      }
    }
  }

  Future<Position?> _tryGetCurrentPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  /// Abre a tela de veículos em modo de seleção antes de iniciar a rota ou o transporte extra.
  Future<void> selectVehicleAndStartTrip(BuildContext context) async {
    if (!canDriveRoute || isActionExecuting.value) return;

    final selectedVehicle = await context.pushNamed<VehicleModel>(
      CompanyRouteNames.companyVehicles,
      extra: {
        'company': currentCompany,
        'companyCnpj': currentRoute.companyCnpj,
        'canManage': false,
        'isSelectionMode': true,
        'unavailableVehicleIds': activeVehicleIds,
      },
    );

    if (selectedVehicle == null || !mounted) return;
    await startOptimizedRouteTrip(selectedVehicle);
  }

  Future<void> startOptimizedRouteTrip(VehicleModel selectedVehicle) async {
    if (!canDriveRoute || isActionExecuting.value) return;

    isActionExecuting.value = true;
    startingRouteMessage.value = 'Obtendo sua localização...';
    isStartingRoute.value = true;

    try {
      final pos = await _tryGetCurrentPosition();
      final startLat = pos?.latitude ?? currentRoute.origin.latitude;
      final startLng = pos?.longitude ?? currentRoute.origin.longitude;

      if (mounted) {
        startingRouteMessage.value = 'Organizando paradas e passageiros...';
      }

      final closest = resolveClosestScheduleNow();
      selectedDirection.value = closest.direction;

      final allStops = _buildOptimizedStopsFromTodayBoardings(
        startLat: startLat,
        startLng: startLng,
        directionOverride: closest.direction,
        targetSlotTime: closest.slotTime,
      );

      final assignedKeys = _assignedPassengerKeysInActiveTrips();
      final remainingStops = assignedKeys.isEmpty
          ? allStops
          : allStops
              .where(
                (s) => !_isPassengerAlreadyAssigned(s.passengerId, assignedKeys),
              )
              .toList();

      final capacity = math.max(1, selectedVehicle.capacity);
      final stopsForThisVehicle = remainingStops.take(capacity).toList();
      final reindexedStops = List.generate(
        stopsForThisVehicle.length,
        (idx) => stopsForThisVehicle[idx].copyWith(orderIndex: idx + 1),
      );

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final driverId = currentUserId;
      final nextGroupIndex = activeTripsForRoute.length + 1;

      final newTrip = TripModel(
        id: 'trip_${currentRoute.id}_${nextGroupIndex}_${now.millisecondsSinceEpoch}',
        routeId: routeIdStr,
        companyCnpj: currentRoute.companyCnpj,
        vehicleId: selectedVehicle.id,
        driverId: driverId,
        date: todayDate,
        departureTime: closest.scheduledDateTime,
        status: TripStatus.inProgress,
        passengerCount: reindexedStops.length,
        direction: closest.direction,
        tripGroupIndex: nextGroupIndex,
        vehicleCapacity: capacity,
        assignedPassengerIds: reindexedStops.map((s) => s.passengerId).toList(),
        driverLatitude: startLat,
        driverLongitude: startLng,
        isSharingLocation: true,
        stops: reindexedStops,
      );

      if (mounted) {
        startingRouteMessage.value =
            'Iniciando viagem e notificando passageiros...';
      }

      final created = await tripViewModel.commands.createTrip(newTrip);
      final active = created ?? newTrip;

      await tripViewModel.commands.startTrip(
        tripId: active.id,
        initialLatitude: startLat,
        initialLongitude: startLng,
      );
      tripViewModel.commands.startWatchingTrip(active.id);
      _startSharingDriverLocation(active.id);

      if (!currentRoute.isTripActive) {
        await routeViewModel.commands.startRouteTrip(currentRoute.id, driverId);
      }

      if (mounted) {
        startingRouteMessage.value = 'Sincronizando painel da rota...';
      }

      await routeViewModel.commands.fetchRouteById(
        currentRoute.id,
        loadMembers: true,
      );
      await tripListViewModel.commands.fetchTripsByRoute(
        routeId: routeIdStr,
        date: todayDate,
      );

      final dirLabel =
          closest.direction == TripDirection.outbound ? 'Ida' : 'Volta';
      final cleanTime = closest.slotTime?.replaceAll('~', '').trim();
      final scheduleText = (cleanTime != null && cleanTime.isNotEmpty)
          ? '$dirLabel, $cleanTime'
          : dirLabel;

      final leftoverCount = remainingStops.length - reindexedStops.length;
      if (leftoverCount > 0) {
        _showSnackBar(
          'Rota iniciada com o veículo:\n'
          '${selectedVehicle.displayTitle}\n'
          '$scheduleText\n'
          'Restam $leftoverCount passageiro(s) aguardando veículo extra.',
        );
      } else {
        _showSnackBar(
          'Rota iniciada com o veículo:\n'
          '${selectedVehicle.displayTitle}\n'
          '$scheduleText',
        );
      }
    } catch (e) {
      _showSnackBar('Erro ao iniciar a rota: $e', isError: true);
    } finally {
      if (mounted) {
        isStartingRoute.value = false;
        isActionExecuting.value = false;
      }
    }
  }

  void _startSharingDriverLocation(String tripId) {
    _driverPositionSub?.cancel();
    _driverPositionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          ),
        ).listen((pos) {
          final speedKmh = (pos.speed > 1.0)
              ? (pos.speed * 3.6).clamp(15.0, 90.0)
              : 35.0;
          tripViewModel.commands.updateDriverLocation(
            tripId: tripId,
            latitude: pos.latitude,
            longitude: pos.longitude,
            isSharingLocation: true,
            averageSpeedKmh: speedKmh,
          );
        });
  }

  Future<void> finishActiveRouteTrip() async {
    if (isActionExecuting.value) return;
    isActionExecuting.value = true;

    try {
      await _driverPositionSub?.cancel();
      _driverPositionSub = null;

      final ownTrip = myActiveTrip;
      final activeTrips = activeTripsForRoute;
      final remainingOtherTrips = ownTrip != null
          ? activeTrips.where((t) => t.id != ownTrip.id).toList()
          : const <TripModel>[];

      if (ownTrip != null) {
        await tripViewModel.commands.finishTrip(ownTrip.id);
      } else {
        for (final t in activeTrips) {
          await tripViewModel.commands.finishTrip(t.id);
        }
      }

      // Só desativa isTripActive da rota se não houver outro veículo ainda em andamento
      if (remainingOtherTrips.isEmpty) {
        await routeViewModel.commands.finishRouteTrip(currentRoute.id);
      }

      tripViewModel.commands.stopWatchingTrip();
      tripViewModel.state.activeTrip.value = null;

      final now = DateTime.now();
      final normalizedToday = DateTime(now.year, now.month, now.day);

      await routeViewModel.commands.fetchRouteById(
        currentRoute.id,
        loadMembers: true,
      );
      await tripListViewModel.commands.fetchTripsByRoute(
        routeId: routeIdStr,
        date: normalizedToday,
      );

      _hasNotifiedStartInSession = false;
      _notifiedThresholdsInSession.clear();
      liveNotificationBanner.value = null;

      _showSnackBar(
        remainingOtherTrips.isEmpty
            ? 'Rota finalizada!'
            : 'Sua viagem foi finalizada! Outro veículo ainda segue em rota.',
      );
    } catch (e) {
      _showSnackBar('Erro ao encerrar a rota: $e', isError: true);
    } finally {
      if (mounted) {
        isActionExecuting.value = false;
      }
    }
  }

  Future<void> toggleStopCompleted(TripStopPoint stop) async {
    final active = currentActiveTrip;
    if (active == null) return;

    await tripViewModel.commands.markStopCompleted(
      tripId: active.id,
      passengerId: stop.passengerId,
      isCompleted: !stop.isCompleted,
    );
  }

  Future<void> openLiveMap(BuildContext context, {bool? isDriver}) async {
    if (!isRouteActiveNow) {
      _showSnackBar(
        isStaffRole
            ? 'Nenhuma viagem está ativa nesta rota no momento. Inicie a rota antes de abrir o mapa em tempo real.'
            : 'Esta rota ainda não foi iniciada pelo motorista.',
        isError: true,
      );
      return;
    }

    final isDriverOfThisTrip =
        (isDriver ?? canDriveRoute) &&
        (myActiveTrip != null || activeTripsForRoute.isEmpty);

    await context.pushNamed(
      RouteOperationNames.driverLiveMap,
      extra: {
        'route': currentRoute,
        'company': currentCompany,
        'trip': currentActiveTrip,
        'stops': optimizedStopsForCurrentState,
        'isDriver': isDriverOfThisTrip,
      },
    );
    if (mounted) {
      await loadInitialData();
    }
  }

  Future<void> openAttendanceCalendar(BuildContext context) async {
    await context.pushNamed(
      RouteOperationNames.routeCalendar,
      extra: {
        'route': currentRoute,
        'company': currentCompany,
        'isStaff': isStaffRole,
      },
    );
    if (mounted) {
      await loadInitialData();
    }
  }

  Future<void> openCompanyReviews(BuildContext context) async {
    final company = currentCompany;
    if (company == null) return;

    await context.pushNamed(
      HomeRouteNames.companyReviews,
      extra: company,
    );
    if (mounted) {
      await loadInitialData();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          backgroundColor: isError
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
}