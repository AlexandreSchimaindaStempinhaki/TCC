import 'dart:io';

import 'package:flutter/material.dart';

import '../../../domain/models/trip_entity.dart';
import 'live_map_marker_factory.dart';

class LiveMapBottomSheet extends StatelessWidget {
  final bool isDriver;
  final bool isExpanded;
  final String arrivalClock;
  final int estimatedMinutes;
  final String remainingDistanceLabel;
  final List<TripStopPoint> stops;
  final String? selectedPassengerId;
  final VoidCallback onOverview;
  final VoidCallback onToggleExpand;
  final ValueChanged<TripStopPoint> onTapStop;

  const LiveMapBottomSheet({
    super.key,
    required this.isDriver,
    required this.isExpanded,
    required this.arrivalClock,
    required this.estimatedMinutes,
    required this.remainingDistanceLabel,
    required this.stops,
    required this.selectedPassengerId,
    required this.onOverview,
    required this.onToggleExpand,
    required this.onTapStop,
  });

  Widget _buildPassengerAvatar(
    TripStopPoint stop, {
    required Color accentColor,
  }) {
    final photo = stop.passengerPhotoUrl?.trim() ?? '';
    ImageProvider? provider;
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      provider = NetworkImage(photo);
    } else if (photo.startsWith('assets/')) {
      provider = AssetImage(photo);
    } else if (photo.isNotEmpty) {
      final file = File(photo);
      if (file.existsSync()) provider = FileImage(file);
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentColor, width: 2.2),
      ),
      child: CircleAvatar(
        radius: 19,
        backgroundColor: accentColor,
        backgroundImage: provider,
        child: provider == null
            ? Text(
                LiveMapMarkerFactory.initialsFromName(stop.passengerName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Ver todos os pontos da rota',
                    onPressed: onOverview,
                    icon: Icon(
                      Icons.alt_route_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isDriver)
                          Text(
                            'Previsão de chegada',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          arrivalClock,
                          style: TextStyle(
                            fontSize: isDriver ? 25 : 22,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$estimatedMinutes min  •  $remainingDistanceLabel',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDriver)
                    IconButton(
                      tooltip: 'Ver passageiros da rota',
                      onPressed: onToggleExpand,
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: colorScheme.onSurface,
                        size: 30,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            if (isDriver && isExpanded) ...[
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
              SizedBox(
                height: 195,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  itemCount: stops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = stops[index];
                    final statusText = s.isCompleted
                        ? 'Embarcado'
                        : (s.isPassengerReady ? 'Pronto' : 'Aguardando');
                    final statusColor = s.isCompleted
                        ? const Color(0xFF64748B)
                        : (s.isPassengerReady
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFF59E0B));
                    final isSelected = s.passengerId == selectedPassengerId;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onTapStop(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF232732)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? statusColor
                                : (isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFD1D5DB)),
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildPassengerAvatar(s, accentColor: statusColor),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.passengerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Parada #${s.orderIndex}${!s.isCompleted && s.estimatedMinutesRemaining != null ? ' • ~${s.estimatedMinutesRemaining} min' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                statusText,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}