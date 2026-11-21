import 'package:flutter/material.dart';
import 'package:tcc/presentation/widgets/account_option.dart';

import '../animated_three_dots.dart';
import 'day_attendance_modals.dart';
import 'day_attendance_status.dart';
import 'route_schedule_resolver.dart';
import 'staff_day_attendance_panel.dart';

class DayAttendancePanelCard extends StatelessWidget {
  final bool isStaff;
  final bool isDefaultPattern;
  final String? patternMonthLabel;
  final bool preserveCustomizedDays;
  final ValueChanged<bool>? onPreserveCustomizedDaysChanged;
  final DateTime selectedDate;
  final String formattedDate;
  final DayAttendanceDraft selectedDraft;
  final ResolvedRouteSchedules schedules;
  final bool isSaving;
  final bool isLoadingStaff;
  final int outboundCount;
  final int returnCount;
  final int absentCount;
  final bool staffViewingReturn;
  final String? staffSelectedSlotTime;
  final Map<String, int> staffSlotCounts;
  final List<StaffPassengerSlotEntry> staffSlotPassengers;
  final ValueChanged<DayAttendanceStatus> onSelectStatus;
  final ValueChanged<String> onSelectDepartureTime;
  final ValueChanged<String> onSelectReturnTime;
  final VoidCallback onCancelReturnNow;
  final VoidCallback onSave;
  final ValueChanged<bool> onStaffDirectionChanged;
  final ValueChanged<String?> onStaffSlotSelected;

  const DayAttendancePanelCard({
    super.key,
    required this.isStaff,
    this.isDefaultPattern = false,
    this.patternMonthLabel,
    this.preserveCustomizedDays = true,
    this.onPreserveCustomizedDaysChanged,
    required this.selectedDate,
    required this.formattedDate,
    required this.selectedDraft,
    required this.schedules,
    required this.isSaving,
    required this.isLoadingStaff,
    required this.outboundCount,
    required this.returnCount,
    required this.absentCount,
    required this.staffViewingReturn,
    required this.staffSelectedSlotTime,
    required this.staffSlotCounts,
    required this.staffSlotPassengers,
    required this.onSelectStatus,
    required this.onSelectDepartureTime,
    required this.onSelectReturnTime,
    required this.onCancelReturnNow,
    required this.onSave,
    required this.onStaffDirectionChanged,
    required this.onStaffSlotSelected,
  });

  Widget _trailingValue(String text, ColorScheme cs, {bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: bold ? 14 : 13.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: bold ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isStaff) {
      return StaffDayAttendancePanel(
        formattedDate: formattedDate,
        schedules: schedules,
        isLoadingStaff: isLoadingStaff,
        outboundCount: outboundCount,
        returnCount: returnCount,
        absentCount: absentCount,
        staffViewingReturn: staffViewingReturn,
        staffSelectedSlotTime: staffSelectedSlotTime,
        staffSlotCounts: staffSlotCounts,
        staffSlotPassengers: staffSlotPassengers,
        onStaffDirectionChanged: onStaffDirectionChanged,
        onStaffSlotSelected: onStaffSlotSelected,
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final status = selectedDraft.status;

    final needsOutbound = status == DayAttendanceStatus.both ||
        status == DayAttendanceStatus.outboundOnly;
    final needsReturn = status == DayAttendanceStatus.both ||
        status == DayAttendanceStatus.returnOnly;

    final availableReturns = needsOutbound
        ? schedules.validReturnsForOutbound(selectedDraft.departureTime)
        : schedules.returnSlots;

    final headerTitle = isDefaultPattern
        ? (patternMonthLabel != null
            ? 'Semana - $patternMonthLabel'
            : 'Padrão da Semana')
        : 'Programação - $formattedDate';

    final cleanDeparture =
        selectedDraft.departureTime?.replaceAll('~', '').trim() ?? 'Selecionar';
    final cleanReturn =
        selectedDraft.returnTime?.replaceAll('~', '').trim() ?? 'Selecionar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  headerTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (status != DayAttendanceStatus.none) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: status.color(cs),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              AccountOption(
                icon: Icons.swap_horiz_rounded,
                title: 'Presença',
                trailing: _trailingValue(
                  status == DayAttendanceStatus.none
                      ? 'Selecionar'
                      : status.label,
                  cs,
                ),
                onTap: () => DayAttendanceModals.showPresence(
                  context,
                  currentStatus: status,
                  onSelected: onSelectStatus,
                ),
              ),
              if (needsOutbound && schedules.outboundSlots.isNotEmpty) ...[
                const SizedBox(height: 8),
                AccountOption(
                  icon: Icons.arrow_circle_right_outlined,
                  title: 'Horário de Ida',
                  trailing: _trailingValue(cleanDeparture, cs, bold: true),
                  onTap: () => DayAttendanceModals.showSchedule(
                    context,
                    title: 'Horário de Ida',
                    slots: schedules.outboundSlots,
                    selectedTime: selectedDraft.departureTime,
                    isOutbound: true,
                    isDefaultPattern: isDefaultPattern,
                    selectedDate: selectedDate,
                    onSelected: onSelectDepartureTime,
                  ),
                ),
              ],
              if (needsReturn && availableReturns.isNotEmpty) ...[
                const SizedBox(height: 8),
                AccountOption(
                  icon: Icons.arrow_circle_left_outlined,
                  title: 'Horário de Volta',
                  trailing: _trailingValue(cleanReturn, cs, bold: true),
                  onTap: () => DayAttendanceModals.showSchedule(
                    context,
                    title: 'Horário de Volta',
                    slots: availableReturns,
                    selectedTime: selectedDraft.returnTime,
                    isOutbound: false,
                    isDefaultPattern: isDefaultPattern,
                    selectedDate: selectedDate,
                    onSelected: onSelectReturnTime,
                  ),
                ),
              ],
              if (isDefaultPattern) ...[
                const SizedBox(height: 8),
                AccountOption(
                  icon: Icons.shield_outlined,
                  title: 'Manter dias já alterados',
                  trailing: Switch(
                    value: preserveCustomizedDays,
                    activeColor: cs.primary,
                    onChanged: onPreserveCustomizedDaysChanged,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (!isDefaultPattern && needsReturn) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSaving ? null : onCancelReturnNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cancelar apenas a volta',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isSaving
                ? const AnimatedThreeDots(color: Colors.white)
                : Text(
                    isDefaultPattern
                        ? 'Aplicar Padrão nessa Semana'
                        : 'Salvar Presença',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}