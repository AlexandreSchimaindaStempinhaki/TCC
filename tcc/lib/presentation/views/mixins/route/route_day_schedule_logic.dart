import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../domain/models/boarding_entity.dart';
import '../../../../domain/models/user_entity.dart';
import '../../../controllers/boarding/boarding_list_viewmodel.dart';
import '../../../controllers/boarding/boarding_state_viewmodel.dart';
import '../../../controllers/boarding/boarding_viewmodel.dart';
import '../../../controllers/route/route_viewmodel.dart';
import '../../../controllers/user/user_viewmodel.dart';
import '../../../widgets/calendar/day_attendance_status.dart';
import '../../../widgets/calendar/route_schedule_resolver.dart';
import '../../application/routes/route_day_schedule_view.dart';

mixin RouteDayScheduleMixin on State<RouteDayScheduleView> {
  late final BoardingViewModel boardingViewModel;
  late final BoardingListViewModel boardingListViewModel;
  late final RouteViewModel routeViewModel;
  late final UserViewModel userViewModel;
  late final ResolvedRouteSchedules resolvedSchedules;

  late final DateTime targetDate;
  late final Signal<DayAttendanceDraft?> draftOverride;
  late final Signal<bool> preserveCustomizedDays;
  late final Signal<bool> isInitialLoading;
  late final Signal<bool> isSaving;
  late final Signal<bool> isLoadingStaffDay;
  late final Signal<bool> staffViewingReturn;
  late final Signal<String?> staffSelectedSlotTime;

  late final Signal extraUsersById;
  final Set<String> _requestedUserIds = <String>{};
  VoidCallback? _boardingsUsersEffect;

  @override
  void initState() {
    super.initState();
    boardingViewModel = injector.get<BoardingViewModel>();
    boardingListViewModel = injector.get<BoardingListViewModel>();
    routeViewModel = injector.get<RouteViewModel>();
    userViewModel = injector.get<UserViewModel>();
    resolvedSchedules = RouteScheduleResolver.resolve(widget.route);

    targetDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
    );

    final defaultOut = resolvedSchedules.outboundSlots.isNotEmpty
        ? resolvedSchedules.outboundSlots.first.time
        : null;

    draftOverride = signal<DayAttendanceDraft?>(
      widget.isDefaultPattern
          ? DayAttendanceDraft(
              status: DayAttendanceStatus.both,
              departureTime: defaultOut,
              returnTime: resolvedSchedules.defaultReturnForOutbound(defaultOut),
            )
          : null,
    );

    preserveCustomizedDays = signal<bool>(true);
    isInitialLoading = signal(true);
    isSaving = signal(false);
    isLoadingStaffDay = signal(false);
    extraUsersById = signal({});

    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    final lastOutMin = resolvedSchedules.outboundSlots.isNotEmpty
        ? resolvedSchedules.outboundSlots.last.minutesFromMidnight
        : 11 * 60;
    final startOnReturn = nowMin >= lastOutMin;
    staffViewingReturn = signal(startOnReturn);
    staffSelectedSlotTime = signal(
      _pickUpcomingSlotTime(isReturn: startOnReturn),
    );

    if (widget.isStaff && !widget.isDefaultPattern) {
      _boardingsUsersEffect = effect(() {
        final boardings = boardingListViewModel.state.routeBoardings.value;
        if (boardings.isEmpty) return;
        untracked(() => _fetchMissingBoardingUsers(boardings));
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadDayData();
    });
  }

  @override
  void dispose() {
    _boardingsUsersEffect?.call();
    boardingViewModel.commands.stopWatchingPassengerBoarding();
    boardingListViewModel.commands.stopWatchingRouteBoardings();
    draftOverride.dispose();
    preserveCustomizedDays.dispose();
    isInitialLoading.dispose();
    isSaving.dispose();
    isLoadingStaffDay.dispose();
    staffViewingReturn.dispose();
    staffSelectedSlotTime.dispose();
    extraUsersById.dispose();
    super.dispose();
  }

  String? _pickUpcomingSlotTime({required bool isReturn}) {
    final slots = isReturn
        ? resolvedSchedules.returnSlots
        : resolvedSchedules.outboundSlots;
    if (slots.isEmpty) return null;
    final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final s in slots) {
      if (s.minutesFromMidnight >= nowMin - 15) return s.time;
    }
    return slots.first.time;
  }

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String get routeIdStr => widget.route.id.toString();

  String get dateKey => BoardingState.formatDateKey(targetDate);

  String get formattedDateBr {
    final d = targetDate.day.toString().padLeft(2, '0');
    final m = targetDate.month.toString().padLeft(2, '0');
    return '$d/$m/${targetDate.year}';
  }

  (DateTime start, DateTime end) get weekBounds {
    final start = targetDate.subtract(Duration(days: targetDate.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return (start, end);
  }

  String get formattedWeekRange {
    final (start, _) = weekBounds;
    final operating = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      if (resolvedSchedules.isOperatingDay(d)) operating.add(d);
    }
    if (operating.isEmpty) return formattedDateBr;
    String fmt(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    return operating.first == operating.last
        ? fmt(operating.first)
        : '${fmt(operating.first)} a ${fmt(operating.last)}';
  }

  String get currentUserId {
    final loggedUser = userViewModel.state.user.value;
    final cleanCpf = _cleanDigits(loggedUser?.cpf ?? '');
    if (cleanCpf.isNotEmpty) return cleanCpf;
    if (loggedUser != null && loggedUser.uid.trim().isNotEmpty) {
      return loggedUser.uid.trim();
    }
    return '';
  }

  DayAttendanceStatus _statusFromBoarding(BoardingModel boarding) {
    if (!boarding.present ||
        boarding.attendanceStatus == BoardingAttendanceStatus.declined) {
      return DayAttendanceStatus.absent;
    }
    if (boarding.willGoOutbound && boarding.willGoReturn) {
      return DayAttendanceStatus.both;
    }
    if (boarding.willGoOutbound && !boarding.willGoReturn) {
      return DayAttendanceStatus.outboundOnly;
    }
    if (!boarding.willGoOutbound && boarding.willGoReturn) {
      return DayAttendanceStatus.returnOnly;
    }
    return DayAttendanceStatus.absent;
  }

  DayAttendanceDraft resolveCurrentDraft(
    Map<String, BoardingModel> savedMap,
    DayAttendanceDraft? override,
  ) {
    if (override != null) return override;
    if (widget.isDefaultPattern) {
      return const DayAttendanceDraft(status: DayAttendanceStatus.none);
    }

    final saved = savedMap[dateKey];
    if (saved != null) {
      final status = _statusFromBoarding(saved);
      final defaultOut = resolvedSchedules.outboundSlots.isNotEmpty
          ? resolvedSchedules.outboundSlots.first.time
          : null;
      final outTime = (status == DayAttendanceStatus.both ||
              status == DayAttendanceStatus.outboundOnly)
          ? (saved.selectedDepartureTime?.trim().isNotEmpty == true
              ? saved.selectedDepartureTime!.trim()
              : defaultOut)
          : null;

      final retTime = (status == DayAttendanceStatus.both ||
              status == DayAttendanceStatus.returnOnly)
          ? (saved.selectedReturnTime?.trim().isNotEmpty == true
              ? saved.selectedReturnTime!.trim()
              : resolvedSchedules.defaultReturnForOutbound(outTime))
          : null;

      return DayAttendanceDraft(
        status: status,
        departureTime: outTime,
        returnTime: retTime,
      );
    }

    return const DayAttendanceDraft(status: DayAttendanceStatus.none);
  }

  Future<void> loadDayData() async {
    isInitialLoading.value = true;
    try {
      if (userViewModel.state.user.value == null) {
        await userViewModel.commands.fetchUser();
      }

      if (widget.isStaff && !widget.isDefaultPattern) {
        isLoadingStaffDay.value = true;
        try {
          await routeViewModel.commands.fetchRouteById(
            widget.route.id,
            loadMembers: true,
          );
          if (routeViewModel.state.passengers.value.isEmpty &&
              widget.route.passengerIds.isNotEmpty) {
            await routeViewModel.commands.loadRouteMembersDetails(widget.route);
          }
          await boardingListViewModel.commands.fetchByRouteAndDate(
            routeId: routeIdStr,
            date: targetDate,
          );
          await _fetchMissingBoardingUsers(
            boardingListViewModel.state.routeBoardings.value,
          );
          boardingListViewModel.commands.watchRouteBoardingsByDate(
            routeId: routeIdStr,
            date: targetDate,
          );
        } finally {
          if (mounted) isLoadingStaffDay.value = false;
        }
      } else {
        final uid = currentUserId;
        if (uid.isEmpty) return;

        if (widget.isDefaultPattern) {
          final (weekStart, weekEnd) = weekBounds;
          await boardingViewModel.commands.loadUserHistory(
            routeId: routeIdStr,
            userId: uid,
            startDate: weekStart,
            endDate: weekEnd,
          );
        } else {
          boardingViewModel.state.selectedDate.value = targetDate;
          boardingViewModel.commands.watchPassengerBoarding(
            routeId: routeIdStr,
            userId: uid,
            date: targetDate,
          );
        }
      }
    } finally {
      if (mounted) isInitialLoading.value = false;
    }
  }

  void setPreserveCustomizedDays(bool value) {
    preserveCustomizedDays.value = value;
  }

  void selectStatus(DayAttendanceStatus status) {
    final current = resolveCurrentDraft(
      boardingViewModel.state.calendarMap.value,
      draftOverride.value,
    );

    final defaultOut = current.departureTime ??
        (resolvedSchedules.outboundSlots.isNotEmpty
            ? resolvedSchedules.outboundSlots.first.time
            : null);

    switch (status) {
      case DayAttendanceStatus.both:
        final validReturns = resolvedSchedules.validReturnsForOutbound(defaultOut);
        final keepReturn = current.returnTime != null &&
            validReturns.any((r) => r.time == current.returnTime);
        draftOverride.value = DayAttendanceDraft(
          status: DayAttendanceStatus.both,
          departureTime: defaultOut,
          returnTime: keepReturn
              ? current.returnTime
              : resolvedSchedules.defaultReturnForOutbound(defaultOut),
        );
        break;
      case DayAttendanceStatus.outboundOnly:
        draftOverride.value = DayAttendanceDraft(
          status: DayAttendanceStatus.outboundOnly,
          departureTime: defaultOut,
          returnTime: null,
        );
        break;
      case DayAttendanceStatus.returnOnly:
        final defaultRet = current.returnTime ??
            (resolvedSchedules.returnSlots.isNotEmpty
                ? resolvedSchedules.returnSlots.first.time
                : null);
        draftOverride.value = DayAttendanceDraft(
          status: DayAttendanceStatus.returnOnly,
          departureTime: null,
          returnTime: defaultRet,
        );
        break;
      case DayAttendanceStatus.absent:
        draftOverride.value = const DayAttendanceDraft(
          status: DayAttendanceStatus.absent,
          departureTime: null,
          returnTime: null,
        );
        break;
      case DayAttendanceStatus.none:
        draftOverride.value = null;
        break;
    }
  }

  void selectDepartureTime(String time) {
    final current = resolveCurrentDraft(
      boardingViewModel.state.calendarMap.value,
      draftOverride.value,
    );

    final nextStatus = current.status == DayAttendanceStatus.none ||
            current.status == DayAttendanceStatus.absent ||
            current.status == DayAttendanceStatus.returnOnly
        ? DayAttendanceStatus.both
        : current.status;

    String? nextReturn = current.returnTime;
    if (nextStatus == DayAttendanceStatus.both) {
      final validReturns = resolvedSchedules.validReturnsForOutbound(time);
      final stillValid =
          nextReturn != null && validReturns.any((s) => s.time == nextReturn);
      if (!stillValid) {
        nextReturn = resolvedSchedules.defaultReturnForOutbound(time);
      }
    } else {
      nextReturn = null;
    }

    draftOverride.value = DayAttendanceDraft(
      status: nextStatus,
      departureTime: time,
      returnTime: nextReturn,
    );
  }

  void selectReturnTime(String time) {
    final current = resolveCurrentDraft(
      boardingViewModel.state.calendarMap.value,
      draftOverride.value,
    );

    final nextStatus = current.status == DayAttendanceStatus.none ||
            current.status == DayAttendanceStatus.absent ||
            current.status == DayAttendanceStatus.outboundOnly
        ? (current.departureTime != null
            ? DayAttendanceStatus.both
            : DayAttendanceStatus.returnOnly)
        : current.status;

    draftOverride.value = DayAttendanceDraft(
      status: nextStatus,
      departureTime:
          nextStatus == DayAttendanceStatus.both ? current.departureTime : null,
      returnTime: time,
    );
  }

  Future<void> cancelReturnNow() async {
    if (widget.isDefaultPattern) return;

    final current = resolveCurrentDraft(
      boardingViewModel.state.calendarMap.value,
      draftOverride.value,
    );

    final hadOutbound = current.status == DayAttendanceStatus.both ||
        current.status == DayAttendanceStatus.outboundOnly;

    draftOverride.value = hadOutbound
        ? DayAttendanceDraft(
            status: DayAttendanceStatus.outboundOnly,
            departureTime: current.departureTime ??
                (resolvedSchedules.outboundSlots.isNotEmpty
                    ? resolvedSchedules.outboundSlots.first.time
                    : null),
            returnTime: null,
          )
        : const DayAttendanceDraft(
            status: DayAttendanceStatus.absent,
            departureTime: null,
            returnTime: null,
          );

    await saveDay();
  }

  Future<void> saveDay() async {
    if (isSaving.value) return;

    final uid = currentUserId;
    if (uid.isEmpty) {
      _showSnackBar(
        'Não foi possível identificar o usuário logado.',
        isError: true,
      );
      return;
    }

    final draft = resolveCurrentDraft(
      boardingViewModel.state.calendarMap.value,
      draftOverride.value,
    );

    if (draft.status == DayAttendanceStatus.none) {
      _showSnackBar(
        'Selecione uma opção de presença antes de salvar.',
        isError: true,
      );
      return;
    }

    final willGoOutbound = draft.status == DayAttendanceStatus.both ||
        draft.status == DayAttendanceStatus.outboundOnly;
    final willGoReturn = draft.status == DayAttendanceStatus.both ||
        draft.status == DayAttendanceStatus.returnOnly;

    final depTime = willGoOutbound
        ? (draft.departureTime ??
            (resolvedSchedules.outboundSlots.isNotEmpty
                ? resolvedSchedules.outboundSlots.first.time
                : null))
        : null;

    final retTime = willGoReturn
        ? (draft.returnTime ?? resolvedSchedules.defaultReturnForOutbound(depTime))
        : null;

    if (widget.isDefaultPattern) {
      await _applyDefaultPatternForWeek(
        uid: uid,
        willGoOutbound: willGoOutbound,
        willGoReturn: willGoReturn,
        depTime: depTime,
        retTime: retTime,
      );
      return;
    }

    isSaving.value = true;
    try {
      final ok = await boardingViewModel.commands.updateAttendance(
        routeId: routeIdStr,
        userId: uid,
        date: targetDate,
        willGoOutbound: willGoOutbound,
        willGoReturn: willGoReturn,
        selectedDepartureTime: depTime,
        selectedReturnTime: retTime,
      );

      if (!mounted) return;

      if (ok) {
        draftOverride.value = null;

        final detailParts = <String>[];
        if (willGoOutbound && depTime != null) detailParts.add('Ida $depTime');
        if (willGoReturn && retTime != null) detailParts.add('Volta $retTime');
        final suffix =
            detailParts.isNotEmpty ? ' (${detailParts.join(' • ')})' : '';

        _showSnackBar(
          'Presença de $formattedDateBr atualizada: ${draft.status.label}$suffix',
        );
        if (context.canPop()) context.pop();
      } else {
        final err = boardingViewModel.state.message.value ??
            'Não foi possível salvar sua presença.';
        _showSnackBar(err, isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar presença: $e', isError: true);
    } finally {
      if (mounted) isSaving.value = false;
    }
  }

  Future<void> _applyDefaultPatternForWeek({
    required String uid,
    required bool willGoOutbound,
    required bool willGoReturn,
    required String? depTime,
    required String? retTime,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final (weekStart, _) = weekBounds;
    final savedMap = boardingViewModel.state.calendarMap.value;
    final preserve = preserveCustomizedDays.value;

    final targetDates = <DateTime>[];
    for (int i = 0; i < 7; i++) {
      final candidate = weekStart.add(Duration(days: i));
      if (candidate.isBefore(today)) continue;
      if (!resolvedSchedules.isOperatingDay(candidate)) continue;
      if (preserve &&
          savedMap.containsKey(BoardingState.formatDateKey(candidate))) {
        continue;
      }
      targetDates.add(candidate);
    }

    if (targetDates.isEmpty) {
      _showSnackBar(
        'Todos os dias úteis restantes dessa semana já possuem programação. Desative "Manter dias já alterados" para substituir.',
        isError: true,
      );
      return;
    }

    isSaving.value = true;
    int updatedCount = 0;

    try {
      final results = await Future.wait(
        targetDates.map(
          (date) => boardingViewModel.commands.updateAttendance(
            routeId: routeIdStr,
            userId: uid,
            date: date,
            willGoOutbound: willGoOutbound,
            willGoReturn: willGoReturn,
            selectedDepartureTime: depTime,
            selectedReturnTime: retTime,
          ),
        ),
      );
      updatedCount = results.where((ok) => ok).length;

      if (!mounted) return;
      _showSnackBar(
        'Padrão aplicado em $updatedCount ${updatedCount == 1 ? 'dia útil' : 'dias úteis'} dessa semana!',
      );
      if (context.canPop()) context.pop();
    } catch (e) {
      _showSnackBar('Erro ao aplicar padrão: $e', isError: true);
    } finally {
      if (mounted) isSaving.value = false;
    }
  }

  void setStaffDirection(bool viewingReturn) {
    staffViewingReturn.value = viewingReturn;
    staffSelectedSlotTime.value = _pickUpcomingSlotTime(isReturn: viewingReturn);
  }

  void setStaffSlotTime(String? time) {
    staffSelectedSlotTime.value = time;
  }

  UserModel? _findLoadedUser(String rawUserId) {
    final target = rawUserId.trim();
    if (target.isEmpty) return null;

    final targetLower = target.toLowerCase();
    final cleanTarget = _cleanDigits(target);
    final looksLikeCpf = cleanTarget.length == 11;

    final extraMap = extraUsersById.value;
    if (extraMap.containsKey(target)) return extraMap[target];
    if (looksLikeCpf && extraMap.containsKey(cleanTarget)) {
      return extraMap[cleanTarget];
    }

    final candidates = <UserModel>[
      ...routeViewModel.state.passengers.value,
      ...extraMap.values,
      if (userViewModel.state.user.value != null)
        userViewModel.state.user.value!,
    ];

    for (final UserModel p in candidates) {
      final pUid = p.uid.trim();
      final pEmail = p.email.trim().toLowerCase();
      final pCleanCpf = _cleanDigits(p.cpf ?? '');

      if ((pUid.isNotEmpty && pUid == target) ||
          (looksLikeCpf && pCleanCpf.isNotEmpty && pCleanCpf == cleanTarget) ||
          (pEmail.isNotEmpty && pEmail == targetLower)) {
        return p;
      }
    }
    return null;
  }

  Future<void> _fetchMissingBoardingUsers(List<BoardingModel> boardings) async {
    if (routeViewModel.commands.fetchRouteUsersByIdsCommand.isExecuting.value) {
      return;
    }

    final missingIds = <String>[];
    for (final b in boardings) {
      final id = b.userId.trim();
      if (id.isEmpty || _requestedUserIds.contains(id)) continue;
      if (_findLoadedUser(id) != null) continue;
      missingIds.add(id);
    }

    if (missingIds.isEmpty) return;
    _requestedUserIds.addAll(missingIds);

    try {
      final fetched = await routeViewModel.commands.fetchRouteUsersByIdsCommand
          .execute(missingIds);

      if (!mounted || fetched.isEmpty) return;

      final updated = Map<String, UserModel>.from(extraUsersById.value);
      for (final user in fetched) {
        if (user.uid.trim().isNotEmpty) {
          updated[user.uid.trim()] = user;
        }
        final cleanCpf = _cleanDigits(user.cpf ?? '');
        if (cleanCpf.length == 11) {
          updated[cleanCpf] = user;
        }
        if (user.email.trim().isNotEmpty) {
          updated[user.email.trim().toLowerCase()] = user;
        }
      }
      extraUsersById.value = updated;
    } catch (_) {
      _requestedUserIds.removeAll(missingIds);
    }
  }

  Map<String, int> buildStaffCountsBySlot({required bool isReturn}) {
    final slots = isReturn
        ? resolvedSchedules.returnSlots
        : resolvedSchedules.outboundSlots;
    final counts = <String, int>{for (final s in slots) s.time: 0};

    final list = isReturn
        ? boardingListViewModel.state.confirmedReturnList.value
        : boardingListViewModel.state.confirmedOutboundList.value;

    final fallbackSlot = slots.isNotEmpty ? slots.first.time : null;

    for (final b in list) {
      final chosen = isReturn
          ? (b.selectedReturnTime?.trim().isNotEmpty == true
              ? b.selectedReturnTime!.trim()
              : resolvedSchedules
                  .defaultReturnForOutbound(b.selectedDepartureTime))
          : (b.selectedDepartureTime?.trim().isNotEmpty == true
              ? b.selectedDepartureTime!.trim()
              : fallbackSlot);

      if (chosen != null && counts.containsKey(chosen)) {
        counts[chosen] = counts[chosen]! + 1;
      } else if (fallbackSlot != null) {
        counts[fallbackSlot] = counts[fallbackSlot]! + 1;
      }
    }
    return counts;
  }

  List<StaffPassengerSlotEntry> buildStaffPassengersForSelectedSlot() {
    final isReturn = staffViewingReturn.value;
    final filterTime = staffSelectedSlotTime.value;
    final slots = isReturn
        ? resolvedSchedules.returnSlots
        : resolvedSchedules.outboundSlots;
    final fallbackSlot = slots.isNotEmpty ? slots.first.time : null;

    final list = isReturn
        ? boardingListViewModel.state.confirmedReturnList.value
        : boardingListViewModel.state.confirmedOutboundList.value;

    final entries = <StaffPassengerSlotEntry>[];
    for (final b in list) {
      final depTime = b.selectedDepartureTime?.trim().isNotEmpty == true
          ? b.selectedDepartureTime!.trim()
          : (resolvedSchedules.outboundSlots.isNotEmpty
              ? resolvedSchedules.outboundSlots.first.time
              : null);
      final retTime = b.selectedReturnTime?.trim().isNotEmpty == true
          ? b.selectedReturnTime!.trim()
          : resolvedSchedules.defaultReturnForOutbound(depTime);

      final effectiveSlot = (isReturn ? retTime : depTime) ?? fallbackSlot;
      if (filterTime != null && effectiveSlot != filterTime) continue;

      final user = _findLoadedUser(b.userId);
      final name = (user != null && user.name.trim().isNotEmpty)
          ? user.name.trim()
          : 'Passageiro';

      entries.add(
        StaffPassengerSlotEntry(
          passengerId: b.userId,
          passengerName: name,
          photoUrl: user?.photoUrl,
          userModel: user,
          departureTime: depTime,
          returnTime: retTime,
          willGoOutbound: b.willGoOutbound,
          willGoReturn: b.willGoReturn,
          isReady: b.isReadyForBoarding,
        ),
      );
    }

    entries.sort((a, b) => a.passengerName.compareTo(b.passengerName));
    return entries;
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}