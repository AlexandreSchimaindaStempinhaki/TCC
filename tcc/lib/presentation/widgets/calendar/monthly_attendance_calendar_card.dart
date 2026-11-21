import 'package:flutter/material.dart';

import 'day_attendance_status.dart';

class MonthlyAttendanceCalendarCard extends StatelessWidget {
  static const List<String> _weekInitials = [
    'D',
    'S',
    'T',
    'Q',
    'Q',
    'S',
    'S',
  ];

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final String monthLabel;
  final bool showLegend;
  final bool Function(DateTime date) isDayEnabled;
  final DayAttendanceStatus Function(DateTime date) statusBuilder;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  const MonthlyAttendanceCalendarCard({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.today,
    required this.monthLabel,
    required this.showLegend,
    required this.isDayEnabled,
    required this.statusBuilder,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leadingEmptySlots = firstDayOfMonth.weekday % 7;
    final totalCells = leadingEmptySlots + daysInMonth;

    final disabledBg =
        isDark ? const Color(0xFF1A1D24) : const Color(0xFFF3F4F6);
    final disabledTextColor =
        isDark ? const Color(0xFF4B5563) : const Color(0xFFB8BEC8);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: calendarCardDecoration(theme),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MonthNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPreviousMonth,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
              Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              _MonthNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextMonth,
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(_weekInitials.length, (i) {
              // Mapeia índice da coluna (0=Dom, 1=Seg..6=Sáb) para DateTime.weekday (7=Dom, 1=Seg..6=Sáb)
              final weekday = i == 0 ? DateTime.sunday : i;
              final sampleDate = DateTime(2026, 11, 22 + i); // 22/11/2026 é domingo
              final columnEnabled = isDayEnabled(sampleDate);
              assert(sampleDate.weekday == weekday);

              return Expanded(
                child: Center(
                  child: Text(
                    _weekInitials[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: columnEnabled
                          ? colorScheme.onSurfaceVariant
                          : disabledTextColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 5,
              childAspectRatio: 0.96,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptySlots) return const SizedBox.shrink();

              final dayNumber = index - leadingEmptySlots + 1;
              final cellDate = DateTime(
                focusedMonth.year,
                focusedMonth.month,
                dayNumber,
              );
              final enabled = isDayEnabled(cellDate);
              final isSelected = enabled && cellDate == selectedDate;
              final isToday = cellDate == today;
              final status =
                  enabled ? statusBuilder(cellDate) : DayAttendanceStatus.none;
              final dotColor = status.color(colorScheme);

              if (!enabled) {
                return Container(
                  decoration: BoxDecoration(
                    color: disabledBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: disabledTextColor,
                      ),
                    ),
                  ),
                );
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelectDate(cellDate),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : (status != DayAttendanceStatus.none
                              ? dotColor.withOpacity(isDark ? 0.20 : 0.13)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(color: colorScheme.primary, width: 1.6)
                          : (status != DayAttendanceStatus.none && !isSelected
                              ? Border.all(
                                  color: dotColor.withOpacity(0.35),
                                  width: 1,
                                )
                              : null),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: status == DayAttendanceStatus.none ? 0 : 14,
                          height: 3.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: status == DayAttendanceStatus.none
                                ? Colors.transparent
                                : (isSelected ? Colors.white : dotColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (showLegend) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(isDark ? 0.05 : 0.035),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _LegendItem(
                    'Ida e Volta',
                    const Color(0xFF16A34A),
                    colorScheme,
                  ),
                  _LegendItem('Só Ida', colorScheme.primary, colorScheme),
                  _LegendItem('Só Volta', const Color(0xFFF59E0B), colorScheme),
                  _LegendItem('Ausente', const Color(0xFFDC2626), colorScheme),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final ColorScheme colorScheme;

  const _LegendItem(this.label, this.color, this.colorScheme);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final ColorScheme colorScheme;

  const _MonthNavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: colorScheme.onSurface, size: 22),
        ),
      ),
    );
  }
}