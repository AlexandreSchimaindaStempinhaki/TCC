import 'package:flutter/material.dart';

class RouteItineraryCard extends StatelessWidget {
  final String origin;
  final String destination;
  final String operatingDays;
  final List<String> shifts;

  const RouteItineraryCard({
    super.key,
    required this.origin,
    required this.destination,
    required this.operatingDays,
    required this.shifts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          _buildTimelineItem(
            title: 'Origem',
            subtitle: origin,
            isFirst: true,
            colorScheme: colorScheme,
          ),
          _buildTimelineItem(
            title: 'Destino',
            subtitle: destination,
            isLast: true,
            colorScheme: colorScheme,
          ),
          Divider(height: 24, color: theme.dividerColor),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                operatingDays,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: shifts.map((shift) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    shift,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Icon(
              isFirst
                  ? Icons.radio_button_checked_rounded
                  : Icons.location_on_rounded,
              size: 16,
              color: isFirst ? colorScheme.primary : Colors.redAccent,
            ),
            if (!isLast)
              Container(
                height: 24,
                width: 2,
                color: colorScheme.secondary.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}