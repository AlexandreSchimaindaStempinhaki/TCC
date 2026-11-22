import 'package:flutter/material.dart';
import 'package:tcc/presentation/widgets/account/account_option.dart';

import 'day_attendance_status.dart';

class CalendarActionsCard extends StatelessWidget {
  final bool isStaff;
  final String formattedDate;
  final DayAttendanceDraft selectedDraft;
  final VoidCallback onOpenDaySchedule;
  final VoidCallback onOpenDefaultSchedule;

  const CalendarActionsCard({
    super.key,
    required this.isStaff,
    required this.formattedDate,
    required this.selectedDraft,
    required this.onOpenDaySchedule,
    required this.onOpenDefaultSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final status = selectedDraft.status;

    final hasLegs =
        !isStaff &&
        (status == DayAttendanceStatus.both ||
            status == DayAttendanceStatus.outboundOnly ||
            status == DayAttendanceStatus.returnOnly);

    final hasOutbound =
        status == DayAttendanceStatus.both ||
        status == DayAttendanceStatus.outboundOnly;
    final hasReturn =
        status == DayAttendanceStatus.both ||
        status == DayAttendanceStatus.returnOnly;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: calendarCardDecoration(theme),
      child: Column(
        children: [
          // ================= 1. PROGRAMAÇÃO (ACCOUNT OPTION) =================
          AccountOption(
            icon: isStaff
                ? Icons.groups_outlined
                : Icons.calendar_month_outlined,
            title: isStaff
                ? 'Confirmados - $formattedDate'
                : 'Programação - $formattedDate',
            trailing: (!isStaff && status != DayAttendanceStatus.none)
                ? Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: status.color(colorScheme),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            onTap: onOpenDaySchedule,
          ),

          // ================= DETALHES DE IDA E VOLTA =================
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onOpenDaySchedule,
                child: hasLegs
                    ? _ScheduleItineraryBox(
                        hasOutbound: hasOutbound,
                        hasReturn: hasReturn,
                        departureTime: selectedDraft.departureTime,
                        returnTime: selectedDraft.returnTime,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF232732)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          isStaff
                              ? 'Toque para ver os passageiros confirmados por horário'
                              : (status == DayAttendanceStatus.absent
                                    ? 'Você não utilizará o transporte nesta data'
                                    : 'Toque para definir os horários de ida e volta'),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // ================= 2. PADRÃO DA SEMANA (ACCOUNT OPTION) =================
          if (!isStaff) ...[
            const SizedBox(height: 14),
            AccountOption(
              icon: Icons.event_repeat_rounded,
              title: 'Definir todos os dias da semana',
              trailing: const SizedBox.shrink(),
              onTap: onOpenDefaultSchedule,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleItineraryBox extends StatelessWidget {
  final bool hasOutbound;
  final bool hasReturn;
  final String? departureTime;
  final String? returnTime;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ScheduleItineraryBox({
    required this.hasOutbound,
    required this.hasReturn,
    required this.departureTime,
    required this.returnTime,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6);
    final lineColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFD1D5DB);
    final activeIconColor = colorScheme.onSurface;
    final mutedIconColor = isDark
        ? const Color(0xFF4B5563)
        : const Color(0xFFB8BEC8);

    final cleanDeparture = departureTime?.replaceAll('~', '').trim();
    final cleanReturn = returnTime?.replaceAll('~', '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trilho vertical com ícones brancos no tema escuro / escuros no claro
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_circle_right_outlined,
                    size: 20,
                    color: hasOutbound ? activeIconColor : mutedIconColor,
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
                  Icon(
                    Icons.arrow_circle_left_outlined,
                    size: 20,
                    color: hasReturn ? activeIconColor : mutedIconColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Detalhes de cada trecho com maior distância entre Ida e Volta
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ItineraryLegRow(
                    label: 'Ida',
                    timeLabel: hasOutbound
                        ? (cleanDeparture != null && cleanDeparture.isNotEmpty
                              ? cleanDeparture
                              : 'Confirmada')
                        : 'Não selecionada',
                    isActive: hasOutbound,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 24),
                  _ItineraryLegRow(
                    label: 'Volta',
                    timeLabel: hasReturn
                        ? (cleanReturn != null && cleanReturn.isNotEmpty
                              ? cleanReturn
                              : 'Confirmada')
                        : 'Não selecionada',
                    isActive: hasReturn,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryLegRow extends StatelessWidget {
  final String label;
  final String timeLabel;
  final bool isActive;
  final ColorScheme colorScheme;

  const _ItineraryLegRow({
    required this.label,
    required this.timeLabel,
    required this.isActive,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          timeLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
