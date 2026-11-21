import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../domain/models/boarding_entity.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/route_entity.dart';
import '../../../domain/models/trip_entity.dart';
import '../../../domain/models/user_entity.dart';
import '../../controllers/boarding/boarding_list_viewmodel.dart';
import '../../controllers/boarding/boarding_viewmodel.dart';
import '../../controllers/company/company_list_viewmodel.dart';
import '../../controllers/route/route_viewmodel.dart';
import '../../controllers/trip/trip_list_viewmodel.dart';
import '../../controllers/trip/trip_viewmodel.dart';
import '../../controllers/user/user_viewmodel.dart';
import '../application/routes/route_entered_view.dart';
import '../../widgets/calendar/route_schedule_resolver.dart';

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
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Set<String> _allCurrentUserIdentifiers() {
    final ids = <String>{};
    final authUser = FirebaseAuth.instance.currentUser;
    final loggedUser = userViewModel.state.user.value;

    if (authUser != null) {
      if (authUser.uid.trim().isNotEmpty) ids.add(authUser.uid.trim());
      if (authUser.email != null && authUser.email!.trim().isNotEmpty) {
        ids.add(authUser.email!.trim().toLowerCase());
      }
    }
    if (loggedUser != null) {
      if (loggedUser.uid.trim().isNotEmpty) ids.add(loggedUser.uid.trim());
      final cpf = loggedUser.cpf ?? '';
      if (cpf.trim().isNotEmpty) {
        ids.add(cpf.trim());
        ids.add(_cleanDigits(cpf));
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
        (cleaned.isNotEmpty && userIds.contains(cleaned));
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

  TripModel? get currentActiveTrip {
    final watched = tripViewModel.state.activeTrip.value;
    if (watched != null &&
        watched.routeId == routeIdStr &&
        (watched.status == TripStatus.inProgress ||
            watched.status == TripStatus.boarding)) {
      return watched;
    }

    for (final t in tripListViewModel.state.routeTrips.value) {
      if (t.routeId == routeIdStr &&
          (t.status == TripStatus.inProgress ||
              t.status == TripStatus.boarding)) {
        return t;
      }
    }
    return null;
  }

  bool get isRouteActiveNow =>
      currentRoute.isTripActive || currentActiveTrip != null;

  TripStopPoint? get currentUserStop {
    final trip = currentActiveTrip;
    if (trip == null) return null;
    final userIds = _allCurrentUserIdentifiers();
    for (final stop in trip.stops) {
      if (_matchesUser(stop.passengerId, userIds)) return stop;
    }
    return null;
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

    return _buildOptimizedStopsFromTodayBoardings(
      startLat: currentRoute.origin.latitude,
      startLng: currentRoute.origin.longitude,
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

    // Adiado para após o primeiro frame para evitar acesso ao ScaffoldMessenger no initState
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

      final uid = currentUserId;
      if (uid.isNotEmpty) {
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
          (cleanTarget.isNotEmpty && pCleanCpf == cleanTarget) ||
          p.email.trim().toLowerCase() == rawUserId.trim().toLowerCase()) {
        return p;
      }
    }
    return null;
  }

  /// Determina automaticamente o horário mais próximo da viagem atual (Ida ou Volta)
  /// e inclui somente passageiros com presença ativa para esse trecho/horário no Firestore.
  List<TripStopPoint> _buildOptimizedStopsFromTodayBoardings({
    required double startLat,
    required double startLng,
    String? targetSlotTime,
  }) {
    final isOutbound = selectedDirection.value == TripDirection.outbound;
    final resolved = RouteScheduleResolver.resolve(currentRoute);
    final slots = isOutbound ? resolved.outboundSlots : resolved.returnSlots;

    String? effectiveSlot = targetSlotTime;
    if (effectiveSlot == null && slots.isNotEmpty) {
      final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
      effectiveSlot = slots.first.time;
      int bestDiff = 10000;
      for (final s in slots) {
        final diff = (s.minutesFromMidnight - nowMin).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          effectiveSlot = s.time;
        }
      }
    }

    final allTodayBoardings = boardingListViewModel.state.routeBoardings.value;
    final confirmedBoardings = isOutbound
        ? boardingListViewModel.state.confirmedOutboundList.value
        : boardingListViewModel.state.confirmedReturnList.value;

    final passengers = routeViewModel.state.passengers.value;
    final rawStops = <TripStopPoint>[];
    final addedIds = <String>{};

    // IDs de passageiros que já registraram decisão explícita hoje no Firestore
    // (impede que alguém que cancelou a volta às 13:00 volte a entrar por fallback)
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

      // Se o passageiro mudou a volta para outro horário (ex.: 18:30), não entra na rota das 13:15
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

  Future<void> startOptimizedRouteTrip() async {
    if (!canDriveRoute || isActionExecuting.value) return;

    isActionExecuting.value = true;
    try {
      final pos = await _tryGetCurrentPosition();
      final startLat = pos?.latitude ?? currentRoute.origin.latitude;
      final startLng = pos?.longitude ?? currentRoute.origin.longitude;

      final stops = _buildOptimizedStopsFromTodayBoardings(
        startLat: startLat,
        startLng: startLng,
      );

      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final driverId = currentUserId;

      final baseTrip = TripModel(
        id: 'trip_${currentRoute.id}_${now.millisecondsSinceEpoch}',
        routeId: routeIdStr,
        companyCnpj: currentRoute.companyCnpj,
        vehicleId: 'default_vehicle',
        driverId: driverId,
        date: todayDate,
        departureTime: now,
        status: TripStatus.inProgress,
        passengerCount: stops.length,
        direction: selectedDirection.value,
        tripGroupIndex: 1,
        vehicleCapacity: 15,
        assignedPassengerIds: stops.map((s) => s.passengerId).toList(),
        driverLatitude: startLat,
        driverLongitude: startLng,
        isSharingLocation: true,
        stops: stops,
      );

      TripModel? active;
      final scaled = await tripViewModel.commands.generateScaledTrips(
        baseTrip: baseTrip,
        confirmedStops: stops,
      );

      if (scaled.isNotEmpty) {
        active = scaled.first;
      } else {
        active = await tripViewModel.commands.createTrip(baseTrip);
      }

      if (active != null) {
        await tripViewModel.commands.startTrip(
          tripId: active.id,
          initialLatitude: startLat,
          initialLongitude: startLng,
        );
        tripViewModel.commands.startWatchingTrip(active.id);
        _startSharingDriverLocation(active.id);
      }

      await routeViewModel.commands.startRouteTrip(currentRoute.id, driverId);
      await routeViewModel.commands.fetchRouteById(
        currentRoute.id,
        loadMembers: true,
      );
      await tripListViewModel.commands.fetchTripsByRoute(
        routeId: routeIdStr,
        date: todayDate,
      );

      _showSnackBar('Rota iniciada com sucesso!');
    } catch (e) {
      _showSnackBar('Erro ao iniciar a rota: $e', isError: true);
    } finally {
      if (mounted) {
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

      // Encerra TODAS as viagens ativas/embarcando vinculadas a esta rota
      final activeTripIds = <String>{};
      final watched = tripViewModel.state.activeTrip.value;
      if (watched != null &&
          watched.routeId == routeIdStr &&
          (watched.status == TripStatus.inProgress ||
              watched.status == TripStatus.boarding)) {
        activeTripIds.add(watched.id);
      }

      for (final t in tripListViewModel.state.routeTrips.value) {
        if (t.routeId == routeIdStr &&
            (t.status == TripStatus.inProgress ||
                t.status == TripStatus.boarding)) {
          activeTripIds.add(t.id);
        }
      }

      for (final tripId in activeTripIds) {
        await tripViewModel.commands.finishTrip(tripId);
      }

      // Desativa isTripActive da rota no Firestore
      await routeViewModel.commands.finishRouteTrip(currentRoute.id);

      // Para o watcher da viagem encerrada e limpa referência ativa em memória
      tripViewModel.commands.stopWatchingTrip();
      tripViewModel.state.activeTrip.value = null;

      final now = DateTime.now();
      final normalizedToday = DateTime(now.year, now.month, now.day);

      // Recarrega rota e lista de viagens com a data normalizada
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

      _showSnackBar('Rota finalizada!');
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
    await context.pushNamed(
      IndigoRouteNames.driverLiveMap,
      extra: {
        'route': currentRoute,
        'company': currentCompany,
        'trip': currentActiveTrip,
        'stops': optimizedStopsForCurrentState,
        'isDriver': isDriver ?? canDriveRoute,
      },
    );
    if (mounted) {
      await loadInitialData();
    }
  }

  Future<void> openAttendanceCalendar(BuildContext context) async {
    await context.pushNamed(
      IndigoRouteNames.routeCalendar,
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
