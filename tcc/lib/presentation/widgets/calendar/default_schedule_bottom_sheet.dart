import 'package:flutter/material.dart';

import 'day_attendance_status.dart';
import 'route_schedule_resolver.dart';

class DefaultScheduleConfig {
  final DayAttendanceStatus status;
  final String? departureTime;
  final String? returnTime;
  final bool preserveCustomizedDays;

  const DefaultScheduleConfig({
    required this.status,
    required this.departureTime,
    required this.returnTime,
    required this.preserveCustomizedDays,
  });
}

class DefaultScheduleBottomSheet extends StatefulWidget {
  final String monthLabel;
  final ResolvedRouteSchedules schedules;
  final DayAttendanceDraft? initialDraft;

  const DefaultScheduleBottomSheet({
    super.key,
    required this.monthLabel,
    required this.schedules,
    this.initialDraft,
  });

  static Future<DefaultScheduleConfig?> show(
    BuildContext context, {
    required String monthLabel,
    required ResolvedRouteSchedules schedules,
    DayAttendanceDraft? initialDraft,
  }) {
    return showModalBottomSheet<DefaultScheduleConfig>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DefaultScheduleBottomSheet(
        monthLabel: monthLabel,
        schedules: schedules,
        initialDraft: initialDraft,
      ),
    );
  }

  @override
  State<DefaultScheduleBottomSheet> createState() =>
      _DefaultScheduleBottomSheetState();
}

class _DefaultScheduleBottomSheetState
    extends State<DefaultScheduleBottomSheet> {
  late DayAttendanceStatus _status;
  String? _departureTime;
  String? _returnTime;
  bool _preserveCustomizedDays = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDraft;
    if (initial != null &&
        initial.status != DayAttendanceStatus.none &&
        initial.status != DayAttendanceStatus.absent) {
      _status = initial.status;
    } else {
      _status = DayAttendanceStatus.both;
    }

    _departureTime = initial?.departureTime ??
        (widget.schedules.outboundSlots.isNotEmpty
            ? widget.schedules.outboundSlots.first.time
            : null);

    _returnTime = initial?.returnTime ??
        widget.schedules.defaultReturnForOutbound(_departureTime);
  }

  Color _darkenSolid(Color color, [double amount = 0.12]) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  void _selectStatus(DayAttendanceStatus next) {
    setState(() {
      _status = next;
      if (next == DayAttendanceStatus.both ||
          next == DayAttendanceStatus.outboundOnly) {
        _departureTime ??= widget.schedules.outboundSlots.isNotEmpty
            ? widget.schedules.outboundSlots.first.time
            : null;
      }
      if (next == DayAttendanceStatus.both) {
        final validReturns =
            widget.schedules.validReturnsForOutbound(_departureTime);
        final keep = _returnTime != null &&
            validReturns.any((s) => s.time == _returnTime);
        if (!keep) {
          _returnTime =
              widget.schedules.defaultReturnForOutbound(_departureTime);
        }
      } else if (next == DayAttendanceStatus.returnOnly) {
        _returnTime ??= widget.schedules.returnSlots.isNotEmpty
            ? widget.schedules.returnSlots.first.time
            : null;
      }
    });
  }

  void _selectDeparture(String time) {
    setState(() {
      _departureTime = time;
      if (_status == DayAttendanceStatus.both) {
        final validReturns = widget.schedules.validReturnsForOutbound(time);
        final keep = _returnTime != null &&
            validReturns.any((s) => s.time == _returnTime);
        if (!keep) {
          _returnTime = widget.schedules.defaultReturnForOutbound(time);
        }
      }
    });
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

    final needsOutbound = _status == DayAttendanceStatus.both ||
        _status == DayAttendanceStatus.outboundOnly;
    final needsReturn = _status == DayAttendanceStatus.both ||
        _status == DayAttendanceStatus.returnOnly;

    final availableReturns = needsOutbound
        ? widget.schedules.validReturnsForOutbound(_departureTime)
        : widget.schedules.returnSlots;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Padrão de ${widget.monthLabel}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Aplica nos dias úteis restantes deste mês. Você continua livre para alterar qualquer dia específico depois.',
              style: TextStyle(
                fontSize: 12.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Modalidades padrão
            Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    label: 'Ida e Volta',
                    accentColor: const Color(0xFF16A34A),
                    isSelected: _status == DayAttendanceStatus.both,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onTap: () => _selectStatus(DayAttendanceStatus.both),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    label: 'Só Ida',
                    accentColor: colorScheme.primary,
                    isSelected: _status == DayAttendanceStatus.outboundOnly,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onTap: () => _selectStatus(DayAttendanceStatus.outboundOnly),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeChip(
                    label: 'Só Volta',
                    accentColor: const Color(0xFFF59E0B),
                    isSelected: _status == DayAttendanceStatus.returnOnly,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onTap: () => _selectStatus(DayAttendanceStatus.returnOnly),
                  ),
                ),
              ],
            ),

            // Horários de ida
            if (needsOutbound && widget.schedules.outboundSlots.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Horário padrão de Ida',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              _buildSlotsGrid(
                slots: widget.schedules.outboundSlots,
                itemBuilder: (slot) {
                  final selected = _departureTime == slot.time;
                  return _DefaultSlotCard(
                    badgeLabel: '${slot.index}ª IDA',
                    timeText: slot.displayTime,
                    accentColor: colorScheme.primary,
                    badgeColor: selected
                        ? _darkenSolid(colorScheme.primary)
                        : colorScheme.primary,
                    isSelected: selected,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onTap: () => _selectDeparture(slot.time),
                  );
                },
              ),
            ],

            // Horários de volta
            if (needsReturn && availableReturns.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Horário padrão de Volta (aprox.)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              _buildSlotsGrid(
                slots: availableReturns,
                itemBuilder: (slot) {
                  final selected = _returnTime == slot.time;
                  return _DefaultSlotCard(
                    badgeLabel: '${slot.index}ª VOLTA',
                    timeText: slot.displayTime,
                    accentColor: const Color(0xFFF59E0B),
                    badgeColor: selected
                        ? _darkenSolid(const Color(0xFFF59E0B))
                        : const Color(0xFFF59E0B),
                    isSelected: selected,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onTap: () => setState(() => _returnTime = slot.time),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF232732)
                    : const Color(0xFFF3F4F6),
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
                  'Não sobrescreve exceções que você já salvou',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _preserveCustomizedDays,
                onChanged: (v) => setState(() => _preserveCustomizedDays = v),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(
                    DefaultScheduleConfig(
                      status: _status,
                      departureTime: needsOutbound ? _departureTime : null,
                      returnTime: needsReturn ? _returnTime : null,
                      preserveCustomizedDays: _preserveCustomizedDays,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Aplicar Padrão nos Dias Úteis',
                  style: TextStyle(
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
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final Color accentColor;
  final bool isSelected;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.accentColor,
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
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : unselectedBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : unselectedBorder,
              width: isSelected ? 1.6 : 1.1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultSlotCard extends StatelessWidget {
  final String badgeLabel;
  final String timeText;
  final Color accentColor;
  final Color badgeColor;
  final bool isSelected;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _DefaultSlotCard({
    required this.badgeLabel,
    required this.timeText,
    required this.accentColor,
    required this.badgeColor,
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
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
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
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}