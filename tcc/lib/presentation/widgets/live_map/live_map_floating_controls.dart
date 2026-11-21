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
                color: const Color(0xFF1F2937),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'km/h',
                    style: TextStyle(
                      color: Colors.white70,
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
                      ? const Color(0xFFF59E0B)
                      : LiveMapMarkerFactory.appBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
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
                color: Colors.black.withOpacity(0.28),
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
            ? const Color(0xFF16A34A)
            : LiveMapMarkerFactory.appBlue,
      ),
    );
  }
}