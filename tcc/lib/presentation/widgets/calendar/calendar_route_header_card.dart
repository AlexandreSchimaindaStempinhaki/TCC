import 'dart:io';

import 'package:flutter/material.dart';

import 'day_attendance_status.dart';

class CalendarRouteHeaderCard extends StatelessWidget {
  final String imageUrl;
  final String companyName;
  final String originText;
  final String destinationText;
  final String operatingDaysText;

  const CalendarRouteHeaderCard({
    super.key,
    required this.imageUrl,
    required this.companyName,
    required this.originText,
    required this.destinationText,
    required this.operatingDaysText,
  });

  Widget _buildRouteThumb(ColorScheme colorScheme) {
    Widget fallback() => Container(
          color: colorScheme.primary,
          alignment: Alignment.center,
          child: const Icon(
            Icons.directions_bus_rounded,
            size: 24,
            color: Colors.white,
          ),
        );

    if (imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 52, height: 52, child: fallback()),
      );
    }

    final img =
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'))
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              )
            : Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: 52, height: 52, child: img),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: calendarCardDecoration(theme),
      child: Row(
        children: [
          _buildRouteThumb(colorScheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$originText → $destinationText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    operatingDaysText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}