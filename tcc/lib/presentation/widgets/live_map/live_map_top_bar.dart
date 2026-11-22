import 'package:flutter/material.dart';

import 'live_map_marker_factory.dart';

class DriverNavigationBanner extends StatelessWidget {
  final IconData maneuverIcon;
  final String distanceLabel;
  final String nextBannerTitle;
  final String? thenBannerTitle;
  final IconData? thenManeuverIcon;
  final VoidCallback onBack;

  const DriverNavigationBanner({
    super.key,
    required this.maneuverIcon,
    required this.distanceLabel,
    required this.nextBannerTitle,
    this.thenBannerTitle,
    this.thenManeuverIcon,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bannerBg = isDark ? const Color(0xFF0B1120) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final streetText =
        isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
    final dividerColor =
        isDark ? Colors.white.withOpacity(0.14) : const Color(0xFFE2E8F0);
    final iconBoxBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    final iconColor =
        isDark ? Colors.white : LiveMapMarkerFactory.appBlueDark;

    final thenBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final thenLabelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final thenBorderColor =
        isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1);

    final hasThen =
        thenBannerTitle != null && thenBannerTitle!.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bannerBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: primaryText,
                        ),
                        onPressed: onBack,
                      ),
                      Expanded(
                        child: Text(
                          'Navegação da Rota',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: iconBoxBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          maneuverIcon,
                          color: iconColor,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              distanceLabel,
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextBannerTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: streetText,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasThen)
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: thenBg,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              border: Border(
                left: BorderSide(color: thenBorderColor),
                right: BorderSide(color: thenBorderColor),
                bottom: BorderSide(color: thenBorderColor),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.28 : 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Depois',
                  style: TextStyle(
                    color: thenLabelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  thenManeuverIcon ?? Icons.straight_rounded,
                  size: 18,
                  color: primaryText,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    thenBannerTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PassengerTrackingHeader extends StatelessWidget {
  final String companyName;
  final String destinationLabel;
  final VoidCallback onBack;

  const PassengerTrackingHeader({
    super.key,
    required this.companyName,
    required this.destinationLabel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onSurface,
              ),
              onPressed: onBack,
            ),
            const SizedBox(width: 6),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: LiveMapMarkerFactory.readyGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Localização do Motorista',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$companyName • $destinationLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}