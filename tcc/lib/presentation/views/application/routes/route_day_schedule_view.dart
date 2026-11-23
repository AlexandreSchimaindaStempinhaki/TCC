import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../widgets/feedback/animated_three_dots.dart';
import '../../../widgets/calendar/day_attendance_panel_card.dart';
import '../../mixins/routes/route_day_schedule_logic.dart';

class RouteDayScheduleView extends StatefulWidget {
  final RouteModel route;
  final CompanyModel? company;
  final DateTime selectedDate;
  final bool isStaff;
  final bool isDefaultPattern;
  final String? monthLabel;

  const RouteDayScheduleView({
    super.key,
    required this.route,
    this.company,
    required this.selectedDate,
    this.isStaff = false,
    this.isDefaultPattern = false,
    this.monthLabel,
  });

  @override
  State<RouteDayScheduleView> createState() => _RouteDayScheduleViewState();
}

class _RouteDayScheduleViewState extends State<RouteDayScheduleView>
    with RouteDayScheduleMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      final savedMap = boardingViewModel.state.calendarMap.value;
      final override = draftOverride.value;
      final selectedDraft = resolveCurrentDraft(savedMap, override);

      final routeBoardings = boardingListViewModel.state.routeBoardings.value;
      final outboundCount =
          boardingListViewModel.state.confirmedOutboundList.value.length;
      final returnCount =
          boardingListViewModel.state.confirmedReturnList.value.length;
      final absentCount = routeBoardings
          .where((b) => !b.present || (!b.willGoOutbound && !b.willGoReturn))
          .length;

      final viewingReturn = staffViewingReturn.value;
      final selectedSlot = staffSelectedSlotTime.value;
      final slotCounts = buildStaffCountsBySlot(isReturn: viewingReturn);
      final slotPassengers = buildStaffPassengersForSelectedSlot();
      final isStaffView = widget.isStaff && !widget.isDefaultPattern;

      final appBarTitle = widget.isDefaultPattern
          ? 'Padrão da Semana'
          : (widget.isStaff ? 'Confirmados do Dia' : 'Programação do Dia');

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
            appBarTitle,
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
                onRefresh: loadDayData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  child: DayAttendancePanelCard(
                    isStaff: isStaffView,
                    isDefaultPattern: widget.isDefaultPattern,
                    patternMonthLabel: widget.monthLabel ?? formattedWeekRange,
                    preserveCustomizedDays: preserveCustomizedDays.value,
                    onPreserveCustomizedDaysChanged: setPreserveCustomizedDays,
                    selectedDate: targetDate,
                    formattedDate: formattedDateBr,
                    selectedDraft: selectedDraft,
                    schedules: resolvedSchedules,
                    isSaving: isSaving.value,
                    isLoadingStaff: isLoadingStaffDay.value,
                    outboundCount: outboundCount,
                    returnCount: returnCount,
                    absentCount: absentCount,
                    staffViewingReturn: viewingReturn,
                    staffSelectedSlotTime: selectedSlot,
                    staffSlotCounts: slotCounts,
                    staffSlotPassengers: slotPassengers,
                    onSelectStatus: selectStatus,
                    onSelectDepartureTime: selectDepartureTime,
                    onSelectReturnTime: selectReturnTime,
                    onCancelReturnNow: cancelReturnNow,
                    onSave: saveDay,
                    onStaffDirectionChanged: setStaffDirection,
                    onStaffSlotSelected: setStaffSlotTime,
                  ),
                ),
              ),
      );
    });
  }
}