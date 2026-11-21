import 'package:flutter/material.dart';

import 'day_attendance_status.dart';
import 'route_schedule_resolver.dart';

class DayAttendanceModals {
  DayAttendanceModals._();

  static Future<void> showPresence(
    BuildContext context, {
    required DayAttendanceStatus currentStatus,
    required ValueChanged<DayAttendanceStatus> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return _ModalSheetContainer(
          title: 'Selecionar Presença',
          isDark: isDark,
          children: [
            _ModalOptionTile(
              icon: Icons.swap_horiz_rounded,
              title: 'Ida e Volta',
              accentColor: const Color(0xFF16A34A),
              isSelected: currentStatus == DayAttendanceStatus.both,
              colorScheme: cs,
              onTap: () {
                onSelected(DayAttendanceStatus.both);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 6),
            _ModalOptionTile(
              icon: Icons.arrow_circle_right_outlined,
              title: 'Somente Ida',
              accentColor: cs.primary,
              isSelected: currentStatus == DayAttendanceStatus.outboundOnly,
              colorScheme: cs,
              onTap: () {
                onSelected(DayAttendanceStatus.outboundOnly);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 6),
            _ModalOptionTile(
              icon: Icons.arrow_circle_left_outlined,
              title: 'Somente Volta',
              accentColor: const Color(0xFFF59E0B),
              isSelected: currentStatus == DayAttendanceStatus.returnOnly,
              colorScheme: cs,
              onTap: () {
                onSelected(DayAttendanceStatus.returnOnly);
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: 6),
            _ModalOptionTile(
              icon: Icons.event_busy_outlined,
              title: 'Ausente',
              accentColor: const Color(0xFFDC2626),
              isSelected: currentStatus == DayAttendanceStatus.absent,
              colorScheme: cs,
              onTap: () {
                onSelected(DayAttendanceStatus.absent);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> showSchedule(
    BuildContext context, {
    required String title,
    required List<ScheduleSlot> slots,
    required String? selectedTime,
    required bool isOutbound,
    required bool isDefaultPattern,
    required DateTime selectedDate,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return _ModalSheetContainer(
          title: title,
          isDark: isDark,
          children: slots.map((slot) {
            final isSelected = selectedTime == slot.time;
            final passed = !isDefaultPattern &&
                RouteScheduleResolver.hasSlotPassedForDate(
                  slot.time,
                  selectedDate,
                );
            final label = isOutbound
                ? '${slot.index}ª ida - ${slot.time}'
                : '${slot.index}ª volta - ${slot.time}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ModalOptionTile(
                icon: Icons.schedule_rounded,
                title: label,
                subtitle: passed ? 'Já passou' : null,
                accentColor: cs.primary,
                isSelected: isSelected,
                colorScheme: cs,
                onTap: () {
                  onSelected(slot.time);
                  Navigator.of(ctx).pop();
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ModalSheetContainer extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;

  const _ModalSheetContainer({
    required this.title,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ModalOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ModalOptionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accentColor,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : colorScheme.onSurfaceVariant.withOpacity(0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}