import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../widgets/feedback/animated_three_dots.dart';
import '../../../widgets/calendar/calendar_actions_card.dart';
import '../../../widgets/calendar/calendar_route_header_card.dart';
import '../../../widgets/calendar/day_attendance_status.dart';
import '../../../widgets/calendar/monthly_attendance_calendar_card.dart';
import '../../mixins/route/route_attendance_calendar_logic.dart';

class RouteAttendanceCalendarView extends StatefulWidget {
  final RouteModel route;
  final CompanyModel? company;
  final bool isStaff;

  const RouteAttendanceCalendarView({
    super.key,
    required this.route,
    this.company,
    this.isStaff = false,
  });

  @override
  State<RouteAttendanceCalendarView> createState() =>
      _RouteAttendanceCalendarViewState();
}

class _RouteAttendanceCalendarViewState
    extends State<RouteAttendanceCalendarView>
    with RouteAttendanceCalendarMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final today = normalizeDate(DateTime.now());

    final route = widget.route;
    final company = widget.company;

    final imageUrl =
        (route.imageUrl != null && route.imageUrl!.trim().isNotEmpty)
        ? route.imageUrl!.trim()
        : ((company?.logoUrl != null && company!.logoUrl!.trim().isNotEmpty)
              ? company.logoUrl!.trim()
              : '');

    final companyName = (company?.name.trim().isNotEmpty == true)
        ? company!.name.trim()
        : 'Transporte Contratual';

    final originText =
        (route.originName != null && route.originName!.trim().isNotEmpty)
        ? route.originName!.trim()
        : 'Partida';

    final destinationText =
        (route.destinationName != null &&
            route.destinationName!.trim().isNotEmpty)
        ? route.destinationName!.trim()
        : 'Destino';

    return Watch((context) {
      final focused = focusedMonth.value;
      final selected = selectedDate.value;
      final savedMap = boardingViewModel.state.calendarMap.value;
      final selectedDraft = resolveDisplayDraft(selected, savedMap);

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
          title: Text(
            widget.isStaff ? 'Presenças da Rota' : 'Calendário de Presença',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: isInitialLoading.value
            ? Center(child: AnimatedThreeDots(color: colorScheme.onSurface))
            : RefreshIndicator(
                color: colorScheme.onSurface,
                onRefresh: loadMonthAttendance,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CalendarRouteHeaderCard(
                        imageUrl: imageUrl,
                        companyName: companyName,
                        originText: originText,
                        destinationText: destinationText,
                        operatingDaysText: route.operatingDaysLabel,
                      ),
                      const SizedBox(height: 16),
                      MonthlyAttendanceCalendarCard(
                        focusedMonth: focused,
                        selectedDate: selected,
                        today: today,
                        monthLabel: monthHeaderLabel(context, focused),
                        showLegend: !widget.isStaff,
                        isDayEnabled: isOperatingDay,
                        statusBuilder: (date) => widget.isStaff
                            ? DayAttendanceStatus.none
                            : resolveDisplayStatus(date, savedMap),
                        isCompletedBuilder: (date) => widget.isStaff
                            ? false
                            : isAttendanceFulfilled(date, savedMap),
                        onPreviousMonth: () => changeMonth(-1),
                        onNextMonth: () => changeMonth(1),
                        onSelectDate: selectDate,
                      ),
                      const SizedBox(height: 16),
                      CalendarActionsCard(
                        isStaff: widget.isStaff,
                        formattedDate: formatDateBr(selected),
                        selectedDraft: selectedDraft,
                        onOpenDaySchedule: openSelectedDaySchedule,
                        onOpenDefaultSchedule: openDefaultSchedule,
                      ),
                    ],
                  ),
                ),
              ),
      );
    });
  }
}
