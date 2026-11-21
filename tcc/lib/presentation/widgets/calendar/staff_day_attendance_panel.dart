import 'package:flutter/material.dart';

import '../animated_three_dots.dart';
import 'day_attendance_status.dart';
import 'route_schedule_resolver.dart';

class StaffDayAttendancePanel extends StatelessWidget {
  final String formattedDate;
  final ResolvedRouteSchedules schedules;
  final bool isLoadingStaff;
  final int outboundCount;
  final int returnCount;
  final int absentCount;
  final bool staffViewingReturn;
  final String? staffSelectedSlotTime;
  final Map<String, int> staffSlotCounts;
  final List<StaffPassengerSlotEntry> staffSlotPassengers;
  final ValueChanged<bool> onStaffDirectionChanged;
  final ValueChanged<String?> onStaffSlotSelected;

  const StaffDayAttendancePanel({
    super.key,
    required this.formattedDate,
    required this.schedules,
    required this.isLoadingStaff,
    required this.outboundCount,
    required this.returnCount,
    required this.absentCount,
    required this.staffViewingReturn,
    required this.staffSelectedSlotTime,
    required this.staffSlotCounts,
    required this.staffSlotPassengers,
    required this.onStaffDirectionChanged,
    required this.onStaffSlotSelected,
  });

  BoxDecoration _cardDecoration(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.22 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final activeSlots =
        staffViewingReturn ? schedules.returnSlots : schedules.outboundSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
          child: Text(
            'Confirmados - $formattedDate',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),
        if (isLoadingStaff)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(child: AnimatedThreeDots(color: cs.onSurface)),
          )
        else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: _cardDecoration(theme),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem('Ida', '$outboundCount', cs.primary, cs),
                ),
                _vDivider(theme),
                Expanded(
                  child: _StatItem(
                    'Volta',
                    '$returnCount',
                    const Color(0xFFF59E0B),
                    cs,
                  ),
                ),
                _vDivider(theme),
                Expanded(
                  child: _StatItem(
                    'Ausentes',
                    '$absentCount',
                    const Color(0xFFDC2626),
                    cs,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Filtrar por Horário', cs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(theme),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DirectionTab(
                        label: 'Ida',
                        icon: Icons.arrow_circle_right_outlined,
                        isSelected: !staffViewingReturn,
                        isDark: isDark,
                        colorScheme: cs,
                        onTap: () => onStaffDirectionChanged(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DirectionTab(
                        label: 'Volta',
                        icon: Icons.arrow_circle_left_outlined,
                        isSelected: staffViewingReturn,
                        isDark: isDark,
                        colorScheme: cs,
                        onTap: () => onStaffDirectionChanged(true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activeSlots.map((slot) {
                    final count = staffSlotCounts[slot.time] ?? 0;
                    final isSelected = staffSelectedSlotTime == slot.time;
                    return Material(
                      color: isSelected
                          ? cs.primary
                          : (isDark
                              ? const Color(0xFF232732)
                              : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onStaffSlotSelected(slot.time),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            '${slot.index}ª ${staffViewingReturn ? 'volta' : 'ida'} • ${slot.time} ($count)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Passageiros (${staffSlotPassengers.length})', cs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: _cardDecoration(theme),
            child: staffSlotPassengers.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Text(
                      'Nenhum passageiro confirmado para este horário.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: staffSlotPassengers.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withOpacity(0.4),
                    ),
                    itemBuilder: (_, index) {
                      final entry = staffSlotPassengers[index];
                      final dep = entry.departureTime?.replaceAll('~', '').trim();
                      final ret = entry.returnTime?.replaceAll('~', '').trim();
                      final subtitle =
                          '${entry.willGoOutbound ? 'Ida ${dep ?? '--'}' : 'Sem ida'}  •  ${entry.willGoReturn ? 'Volta ${ret ?? '--'}' : 'Sem volta'}';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 22,
                              color: cs.onSurface,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.passengerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (entry.isReady) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Pronto',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _vDivider(ThemeData theme) => Container(
        width: 1,
        height: 34,
        color: theme.dividerColor.withOpacity(0.5),
      );
}

class _DirectionTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _DirectionTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? colorScheme.primary
        : (isDark ? const Color(0xFF232732) : const Color(0xFFF3F4F6));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;
  final ColorScheme colorScheme;

  const _StatItem(this.label, this.value, this.dotColor, this.colorScheme);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}