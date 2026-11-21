import 'package:flutter/material.dart';

import '../animated_three_dots.dart';
import 'day_attendance_status.dart';
import 'route_schedule_resolver.dart';

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
  final bool hasUnsavedChange;
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
    required this.hasUnsavedChange,
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

  Color _darkenSolid(Color color, [double amount = 0.12]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Widget _buildSlotsGrid({
    required List<ScheduleSlot> slots,
    required Widget Function(ScheduleSlot slot) itemBuilder,
  }) {
    if (slots.length == 1) return itemBuilder(slots.first);

    final rows = <Widget>[];
    for (int i = 0; i < slots.length; i += 2) {
      final first = slots[i];
      final second = (i + 1 < slots.length) ? slots[i + 1] : null;

      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: itemBuilder(first)),
              const SizedBox(width: 10),
              Expanded(
                child: second != null
                    ? itemBuilder(second)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: calendarCardDecoration(theme),
      child: isStaff
          ? _buildStaffSummary(theme, colorScheme, isDark)
          : _buildPassengerControls(theme, colorScheme, isDark),
    );
  }

  Widget _buildPassengerControls(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final status = selectedDraft.status;
    final badgeColor = status.color(colorScheme);
    final needsOutbound = status == DayAttendanceStatus.both ||
        status == DayAttendanceStatus.outboundOnly;
    final needsReturn = status == DayAttendanceStatus.both ||
        status == DayAttendanceStatus.returnOnly;

    final availableReturns = needsOutbound
        ? schedules.validReturnsForOutbound(selectedDraft.departureTime)
        : schedules.returnSlots;

    final headerTitle = isDefaultPattern
        ? (patternMonthLabel != null
            ? 'Semana • $patternMonthLabel'
            : 'Padrão da Semana')
        : 'Programação • $formattedDate';

    final headerSubtitle = isDefaultPattern
        ? 'Aplicado aos dias úteis restantes dessa semana; você pode alterar dias específicos'
        : (hasUnsavedChange
            ? 'Alteração pendente — toque em salvar abaixo'
            : 'Escolha os trechos e combine os horários como preferir');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headerTitle,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    headerSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnsavedChange
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: hasUnsavedChange
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (status != DayAttendanceStatus.none) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Divider(color: theme.dividerColor.withOpacity(0.5), height: 1),
        const SizedBox(height: 14),

        // Grade 2x2 fosca de modalidade
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatusGridOption(
                  title: 'Ida e Volta',
                  subtitle: 'Combine qualquer turno',
                  icon: Icons.swap_horiz_rounded,
                  accentColor: const Color(0xFF16A34A),
                  iconBoxColor: status == DayAttendanceStatus.both
                      ? _darkenSolid(const Color(0xFF16A34A))
                      : const Color(0xFF16A34A),
                  isSelected: status == DayAttendanceStatus.both,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onTap: () => onSelectStatus(DayAttendanceStatus.both),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusGridOption(
                  title: 'Somente Ida',
                  subtitle: 'Não retorno na van',
                  icon: Icons.arrow_forward_rounded,
                  accentColor: colorScheme.primary,
                  iconBoxColor: status == DayAttendanceStatus.outboundOnly
                      ? _darkenSolid(colorScheme.primary)
                      : colorScheme.primary,
                  isSelected: status == DayAttendanceStatus.outboundOnly,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onTap: () => onSelectStatus(DayAttendanceStatus.outboundOnly),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatusGridOption(
                  title: 'Somente Volta',
                  subtitle: 'Apenas retorno',
                  icon: Icons.arrow_back_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  iconBoxColor: status == DayAttendanceStatus.returnOnly
                      ? _darkenSolid(const Color(0xFFF59E0B))
                      : const Color(0xFFF59E0B),
                  isSelected: status == DayAttendanceStatus.returnOnly,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onTap: () => onSelectStatus(DayAttendanceStatus.returnOnly),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatusGridOption(
                  title: 'Ausente',
                  subtitle: isDefaultPattern
                      ? 'Marcar como ausente'
                      : 'Não vou neste dia',
                  icon: Icons.event_busy_rounded,
                  accentColor: const Color(0xFFDC2626),
                  iconBoxColor: status == DayAttendanceStatus.absent
                      ? _darkenSolid(const Color(0xFFDC2626))
                      : const Color(0xFFDC2626),
                  isSelected: status == DayAttendanceStatus.absent,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onTap: () => onSelectStatus(DayAttendanceStatus.absent),
                ),
              ),
            ],
          ),
        ),

        // ================= HORÁRIO DE IDA =================
        if (needsOutbound && schedules.outboundSlots.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ScheduleSectionHeader(
            title: isDefaultPattern ? 'Horário padrão de Ida' : 'Horário de Ida',
            subtitle: 'Selecione sua saída',
            accentColor: colorScheme.primary,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
          _buildSlotsGrid(
            slots: schedules.outboundSlots,
            itemBuilder: (slot) {
              final selected = selectedDraft.departureTime == slot.time;
              final passed = !isDefaultPattern &&
                  RouteScheduleResolver.hasSlotPassedForDate(
                    slot.time,
                    selectedDate,
                  );
              return _ScheduleSlotCard(
                badgeLabel: '${slot.index}ª IDA',
                timeText: slot.displayTime,
                footerText: passed ? 'Já passou' : 'Saída programada',
                accentColor: colorScheme.primary,
                badgeColor: selected
                    ? _darkenSolid(colorScheme.primary)
                    : colorScheme.primary,
                isSelected: selected,
                isPassed: passed,
                isDark: isDark,
                colorScheme: colorScheme,
                onTap: () => onSelectDepartureTime(slot.time),
              );
            },
          ),
        ],

        // ================= HORÁRIO DE VOLTA =================
        if (needsReturn && availableReturns.isNotEmpty) ...[
          const SizedBox(height: 18),
          _ScheduleSectionHeader(
            title: isDefaultPattern
                ? 'Horário padrão de Volta'
                : 'Horário de Volta',
            subtitle: 'Previsão aproximada',
            accentColor: const Color(0xFFF59E0B),
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 10),
          _buildSlotsGrid(
            slots: availableReturns,
            itemBuilder: (slot) {
              final selected = selectedDraft.returnTime == slot.time;
              final passed = !isDefaultPattern &&
                  RouteScheduleResolver.hasSlotPassedForDate(
                    slot.time,
                    selectedDate,
                  );
              return _ScheduleSlotCard(
                badgeLabel: '${slot.index}ª VOLTA',
                timeText: slot.displayTime,
                footerText: passed ? 'Já passou' : 'Retorno previsto',
                accentColor: const Color(0xFFF59E0B),
                badgeColor: selected
                    ? _darkenSolid(const Color(0xFFF59E0B))
                    : const Color(0xFFF59E0B),
                isSelected: selected,
                isPassed: passed,
                isDark: isDark,
                colorScheme: colorScheme,
                onTap: () => onSelectReturnTime(slot.time),
              );
            },
          ),

          if (!isDefaultPattern) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
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
                  'Não volto mais (cancelar volta)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],

        // Opção de preservar dias já alterados (apenas no modo padrão semanal)
        if (isDefaultPattern) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: colorScheme.primary,
              title: Text(
                'Manter dias já alterados',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Não substitui exceções já salvas nessa semana',
                style: TextStyle(
                  fontSize: 11.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              value: preserveCustomizedDays,
              onChanged: onPreserveCustomizedDaysChanged,
            ),
          ),
        ],

        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox.shrink()
                : const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
            label: isSaving
                ? const AnimatedThreeDots(color: Colors.white)
                : Text(
                    isDefaultPattern
                        ? 'Aplicar Padrão nessa Semana'
                        : 'Salvar Presença do Dia',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffSummary(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final activeSlots =
        staffViewingReturn ? schedules.returnSlots : schedules.outboundSlots;
    final activeAccent =
        staffViewingReturn ? const Color(0xFFF59E0B) : colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmados ao vivo • $formattedDate',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Atualizado em tempo real conforme os passageiros alteram horários',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Divider(color: theme.dividerColor.withOpacity(0.5), height: 1),
        const SizedBox(height: 14),
        if (isLoadingStaff)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: AnimatedThreeDots(color: colorScheme.onSurface),
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _StaffMetricChip(
                  label: 'Ida',
                  value: '$outboundCount',
                  icon: Icons.arrow_forward_rounded,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StaffMetricChip(
                  label: 'Volta',
                  value: '$returnCount',
                  icon: Icons.arrow_back_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StaffMetricChip(
                  label: 'Ausentes',
                  value: '$absentCount',
                  icon: Icons.event_busy_rounded,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DirectionToggleBtn(
                  label: 'Trecho de Ida',
                  icon: Icons.arrow_forward_rounded,
                  activeColor: colorScheme.primary,
                  isSelected: !staffViewingReturn,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onTap: () => onStaffDirectionChanged(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DirectionToggleBtn(
                  label: 'Trecho de Volta',
                  icon: Icons.arrow_back_rounded,
                  activeColor: const Color(0xFFF59E0B),
                  isSelected: staffViewingReturn,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onTap: () => onStaffDirectionChanged(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSlotsGrid(
            slots: activeSlots,
            itemBuilder: (slot) {
              final count = staffSlotCounts[slot.time] ?? 0;
              final isSelected = staffSelectedSlotTime == slot.time;
              return _ScheduleSlotCard(
                badgeLabel:
                    '${slot.index}ª ${staffViewingReturn ? 'VOLTA' : 'IDA'}',
                timeText: slot.displayTime,
                footerText:
                    '$count ${count == 1 ? 'confirmado' : 'confirmados'}',
                accentColor: activeAccent,
                badgeColor:
                    isSelected ? _darkenSolid(activeAccent) : activeAccent,
                isSelected: isSelected,
                isPassed: false,
                isDark: isDark,
                colorScheme: colorScheme,
                onTap: () => onStaffSlotSelected(slot.time),
              );
            },
          ),
          const SizedBox(height: 14),
          if (staffSlotPassengers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF232732)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Nenhum passageiro confirmado para este horário.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staffSlotPassengers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final entry = staffSlotPassengers[index];
                final badgeColor =
                    entry.isReady ? const Color(0xFF16A34A) : activeAccent;
                final badgeText = entry.isReady
                    ? 'Pronto'
                    : (staffViewingReturn
                        ? 'Volta ~${entry.returnTime ?? '--'}'
                        : 'Ida ${entry.departureTime ?? '--'}');

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF232732)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.passengerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${entry.willGoOutbound ? 'Ida ${entry.departureTime ?? '--'}' : 'Sem ida'} • ${entry.willGoReturn ? 'Volta ~${entry.returnTime ?? '--'}' : 'Sem volta'}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

class _ScheduleSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final ColorScheme colorScheme;

  const _ScheduleSectionHeader({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ScheduleSlotCard extends StatelessWidget {
  final String badgeLabel;
  final String timeText;
  final String footerText;
  final Color accentColor;
  final Color badgeColor;
  final bool isSelected;
  final bool isPassed;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ScheduleSlotCard({
    required this.badgeLabel,
    required this.timeText,
    required this.footerText,
    required this.accentColor,
    required this.badgeColor,
    required this.isSelected,
    required this.isPassed,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedBg =
        isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6);
    final unselectedBorder =
        isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : unselectedBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : unselectedBorder,
              width: isSelected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: isSelected ? Colors.white : accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                footerText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isPassed ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isPassed
                          ? const Color(0xFFDC2626)
                          : colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectionToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _DirectionToggleBtn({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? activeColor
        : (isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusGridOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color iconBoxColor;
  final bool isSelected;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _StatusGridOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.iconBoxColor,
    required this.isSelected,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedBg =
        isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6);
    final unselectedBorder =
        isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : unselectedBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : unselectedBorder,
              width: isSelected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconBoxColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 19, color: Colors.white),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 19,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isSelected
                      ? Colors.white
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaffMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StaffMetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}