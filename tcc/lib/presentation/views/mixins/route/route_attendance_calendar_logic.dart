import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/route_operation_routes.dart';
import '../../../../domain/models/boarding_entity.dart';
import '../../../controllers/boarding/boarding_state_viewmodel.dart';
import '../../../controllers/boarding/boarding_viewmodel.dart';
import '../../../controllers/user/user_viewmodel.dart';
import '../../../widgets/calendar/day_attendance_status.dart';
import '../../../widgets/calendar/route_schedule_resolver.dart';
import '../../application/routes/route_attendance_calendar_view.dart';

mixin RouteAttendanceCalendarMixin on State<RouteAttendanceCalendarView> {
  static const Map<int, String> _monthNames = {
    // Opcional: 1: 'Janeiro', ...
  };

  late final BoardingViewModel boardingViewModel;
  late final UserViewModel userViewModel;
  late final ResolvedRouteSchedules resolvedSchedules;

  late final Signal<DateTime> focusedMonth;
  late final Signal<DateTime> selectedDate;
  late final Signal<bool> isInitialLoading;

  @override
  void initState() {
    super.initState();
    boardingViewModel = injector.get<BoardingViewModel>();
    userViewModel = injector.get<UserViewModel>();
    resolvedSchedules = RouteScheduleResolver.resolve(widget.route);

    final initialDate = resolvedSchedules.nextOperatingDate(DateTime.now());
    focusedMonth = signal(DateTime(initialDate.year, initialDate.month));
    selectedDate = signal(initialDate);
    isInitialLoading = signal(true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadInitialData();
    });
  }

  @override
  void dispose() {
    focusedMonth.dispose();
    selectedDate.dispose();
    isInitialLoading.dispose();
    super.dispose();
  }

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String get routeIdStr => widget.route.id.toString();

  String get currentUserId {
    final loggedUser = userViewModel.state.user.value;
    final cleanCpf = _cleanDigits(loggedUser?.cpf ?? '');
    if (cleanCpf.isNotEmpty) return cleanCpf;
    if (loggedUser != null && loggedUser.uid.trim().isNotEmpty) {
      return loggedUser.uid.trim();
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  DateTime normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool isOperatingDay(DateTime date) => resolvedSchedules.isOperatingDay(date);

  String dateKey(DateTime dt) => BoardingState.formatDateKey(dt);

  String formatDateBr(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  String monthHeaderLabel(BuildContext context, DateTime dt) {
    final custom = _monthNames[dt.month]?.trim();
    if (custom != null && custom.isNotEmpty) {
      return '$custom${dt.year}';
    }
    final formatted = MaterialLocalizations.of(context).formatMonthYear(dt);
    if (formatted.isEmpty) {
      final m = dt.month.toString().padLeft(2, '0');
      return '$m/${dt.year}';
    }
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  DayAttendanceDraft resolveDisplayDraft(
    DateTime date,
    Map<String, BoardingModel> savedMap,
  ) {
    if (!isOperatingDay(date)) {
      return const DayAttendanceDraft(status: DayAttendanceStatus.none);
    }

    final saved = savedMap[dateKey(date)];
    if (saved == null) {
      return const DayAttendanceDraft(status: DayAttendanceStatus.none);
    }

    late final DayAttendanceStatus status;
    if (!saved.present ||
        saved.attendanceStatus == BoardingAttendanceStatus.declined) {
      status = DayAttendanceStatus.absent;
    } else if (saved.willGoOutbound && saved.willGoReturn) {
      status = DayAttendanceStatus.both;
    } else if (saved.willGoOutbound && !saved.willGoReturn) {
      status = DayAttendanceStatus.outboundOnly;
    } else if (!saved.willGoOutbound && saved.willGoReturn) {
      status = DayAttendanceStatus.returnOnly;
    } else {
      status = DayAttendanceStatus.absent;
    }

    final defaultOut = resolvedSchedules.outboundSlots.isNotEmpty
        ? resolvedSchedules.outboundSlots.first.time
        : null;

    final dep =
        (status == DayAttendanceStatus.both ||
            status == DayAttendanceStatus.outboundOnly)
        ? (saved.selectedDepartureTime?.trim().isNotEmpty == true
              ? saved.selectedDepartureTime!.trim()
              : defaultOut)
        : null;

    final ret =
        (status == DayAttendanceStatus.both ||
            status == DayAttendanceStatus.returnOnly)
        ? (saved.selectedReturnTime?.trim().isNotEmpty == true
              ? saved.selectedReturnTime!.trim()
              : resolvedSchedules.defaultReturnForOutbound(dep))
        : null;

    return DayAttendanceDraft(
      status: status,
      departureTime: dep,
      returnTime: ret,
    );
  }

  DayAttendanceStatus resolveDisplayStatus(
    DateTime date,
    Map<String, BoardingModel> savedMap,
  ) {
    return resolveDisplayDraft(date, savedMap).status;
  }

  Future<void> loadInitialData() async {
    isInitialLoading.value = true;
    try {
      if (userViewModel.state.user.value == null) {
        await userViewModel.commands.fetchUser();
      }
      await loadMonthAttendance();
    } finally {
      if (mounted) isInitialLoading.value = false;
    }
  }

  Future<void> loadMonthAttendance() async {
    if (widget.isStaff) return;

    final uid = currentUserId;
    if (uid.isEmpty) return;

    final focused = focusedMonth.value;
    await boardingViewModel.commands.loadUserHistory(
      routeId: routeIdStr,
      userId: uid,
      startDate: DateTime(focused.year, focused.month, 1),
      endDate: DateTime(focused.year, focused.month + 1, 0),
    );
  }

  void changeMonth(int delta) {
    final current = focusedMonth.value;
    focusedMonth.value = DateTime(current.year, current.month + delta);
    loadMonthAttendance();
  }

  void selectDate(DateTime date) {
    final normalized = normalizeDate(date);
    if (!isOperatingDay(normalized)) return;

    selectedDate.value = normalized;
    boardingViewModel.state.selectedDate.value = normalized;
  }

  Future<void> openSelectedDaySchedule() async {
    final target = normalizeDate(selectedDate.value);
    if (!isOperatingDay(target)) return;

    await context.pushNamed(
      RouteOperationNames.routeDaySchedule,
      extra: {
        'route': widget.route,
        'company': widget.company,
        'selectedDate': target,
        'isStaff': widget.isStaff,
        'isDefaultPattern': false,
      },
    );

    if (!mounted) return;
    await loadMonthAttendance();
  }

  String _formatShortDayMonth(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  bool isAttendanceFulfilled(
    DateTime date,
    Map<String, BoardingModel> savedMap,
  ) {
    if (!isOperatingDay(date)) return false;
    final saved = savedMap[dateKey(date)];
    if (saved == null) return false;
    return saved.present &&
        saved.attendanceStatus == BoardingAttendanceStatus.boarded;
  }

  Future<void> openDefaultSchedule() async {
    if (widget.isStaff) return;

    final selected = normalizeDate(selectedDate.value);
    final today = normalizeDate(DateTime.now());
    final weekStart = selected.subtract(Duration(days: selected.weekday - 1));

    final operatingDaysInWeek = <DateTime>[];
    bool hasRemainingDay = false;

    for (int i = 0; i < 7; i++) {
      final candidate = weekStart.add(Duration(days: i));
      if (!isOperatingDay(candidate)) continue;
      operatingDaysInWeek.add(candidate);
      if (!candidate.isBefore(today)) {
        hasRemainingDay = true;
      }
    }

    if (!hasRemainingDay) {
      _showSnackBar(
        'Não há dias úteis restantes nessa semana. Selecione uma semana atual ou futura.',
        isError: true,
      );
      return;
    }

    final firstOp = operatingDaysInWeek.first;
    final lastOp = operatingDaysInWeek.last;
    final weekLabel = firstOp == lastOp
        ? _formatShortDayMonth(firstOp)
        : '${_formatShortDayMonth(firstOp)} a ${_formatShortDayMonth(lastOp)}';

    await context.pushNamed(
      RouteOperationNames.routeDaySchedule,
      extra: {
        'route': widget.route,
        'company': widget.company,
        'selectedDate': selected,
        'isStaff': false,
        'isDefaultPattern': true,
        'monthLabel': weekLabel,
      },
    );

    if (!mounted) return;
    await loadMonthAttendance();
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