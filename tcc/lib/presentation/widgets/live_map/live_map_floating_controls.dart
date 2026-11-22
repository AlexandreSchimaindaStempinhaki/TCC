import 'package:flutter/material.dart';

import 'live_map_marker_factory.dart';

class DriverMapFloatingControls extends StatelessWidget {
  final int speedKmh;
  final bool followDriver;
  final String bottomPillLabel;
  final VoidCallback onRecenter;

  const DriverMapFloatingControls({
    super.key,
    required this.speedKmh,
    required this.followDriver,
    required this.bottomPillLabel,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final speedBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final speedBorder = isDark ? Colors.white : const Color(0xFFE2E8F0);
    final speedText = isDark ? Colors.white : const Color(0xFF0F172A);
    final speedSubText = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: speedBg,
                shape: BoxShape.circle,
                border: Border.all(color: speedBorder, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$speedKmh',
                    style: TextStyle(
                      color: speedText,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'km/h',
                    style: TextStyle(
                      color: speedSubText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRecenter,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: followDriver
                      ? LiveMapMarkerFactory.waitingAmber
                      : LiveMapMarkerFactory.appBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white : Colors.white,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: LiveMapMarkerFactory.appBlue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.28 : 0.16),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            bottomPillLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class PassengerRecenterButton extends StatelessWidget {
  final bool followDriver;
  final VoidCallback onPressed;

  const PassengerRecenterButton({
    super.key,
    required this.followDriver,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton(
      heroTag: 'center_bus_btn',
      backgroundColor: theme.cardColor,
      elevation: 4,
      onPressed: onPressed,
      child: Icon(
        Icons.directions_bus_rounded,
        color: followDriver
            ? LiveMapMarkerFactory.readyGreen
            : LiveMapMarkerFactory.appBlue,
      ),
    );
  }
}