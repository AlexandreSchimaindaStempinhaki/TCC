import 'package:flutter/material.dart';

class SavedRouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const SavedRouteCard({
    super.key,
    required this.route,
    required this.onTap,
    required this.onFavoriteTap,
  });

  Color _resolveSolidBadgeColor(
    String status,
    dynamic customColor,
    ColorScheme colorScheme,
  ) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('pendente')) {
      return const Color(0xFFD97706);
    }
    if (normalized.contains('vinculado') || normalized.contains('aprovado')) {
      return const Color(0xFF15803D);
    }
    if (normalized.contains('favorit')) {
      return const Color(0xFF2563EB);
    }
    if (customColor is Color) {
      return customColor.withOpacity(1.0);
    }
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final inverseColor = colorScheme.onSurface;

    final String status = route['status']?.toString() ?? 'Favoritada';
    final Color badgeColor = _resolveSolidBadgeColor(
      status,
      route['statusColor'],
      colorScheme,
    );

    final bool isFavorite = (route['isFavorite'] as bool?) ?? true;
    final String operatingDays =
        route['operatingDays']?.toString() ?? 'Segunda a Sexta';
    final String origin = route['origin']?.toString() ?? 'Origem';
    final String destination = route['destination']?.toString() ?? 'Destino';
    final String companyName =
        route['companyName']?.toString() ?? 'Empresa de Transporte';
    final String imageUrl = route['image']?.toString() ?? '';

    final Color cardBorderColor = isDark
        ? inverseColor.withOpacity(0.24)
        : inverseColor.withOpacity(0.16);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cardBorderColor,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 104,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: inverseColor.withOpacity(0.08),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.directions_bus_rounded,
                                    color: inverseColor,
                                    size: 34,
                                  ),
                                ),
                              )
                            : Container(
                                color: inverseColor.withOpacity(0.08),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.directions_bus_rounded,
                                  color: inverseColor,
                                  size: 34,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 118),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  tooltip: isFavorite
                                      ? 'Remover dos favoritos'
                                      : 'Adicionar aos favoritos',
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                      color: isFavorite
                                        ? Colors.redAccent
                                        : colorScheme.secondary,
                                    size: 22,
                                  ),
                                  onPressed: onFavoriteTap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: inverseColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.radio_button_checked_rounded,
                                size: 13,
                                color: inverseColor,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _AdaptiveSingleLineText(
                                  text: origin,
                                  maxFontSize: 12.5,
                                  minFontSize: 9.0,
                                  style: TextStyle(
                                    color: inverseColor.withOpacity(0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 5.8,
                              top: 2,
                              bottom: 2,
                            ),
                            child: Container(
                              height: 6,
                              width: 1.5,
                              color: inverseColor.withOpacity(0.35),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: inverseColor,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _AdaptiveSingleLineText(
                                  text: destination,
                                  maxFontSize: 12.5,
                                  minFontSize: 9.0,
                                  style: TextStyle(
                                    color: inverseColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1.2,
                color: cardBorderColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              operatingDays,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          'Ver Detalhes',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: inverseColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: inverseColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveSingleLineText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double maxFontSize;
  final double minFontSize;

  const _AdaptiveSingleLineText({
    required this.text,
    required this.style,
    this.maxFontSize = 12.5,
    this.minFontSize = 9.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= 0) {
          return Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(fontSize: maxFontSize),
          );
        }

        double chosenSize = maxFontSize;
        final textDirection = Directionality.of(context);

        while (chosenSize > minFontSize) {
          final painter = TextPainter(
            text: TextSpan(
              text: text,
              style: style.copyWith(fontSize: chosenSize),
            ),
            maxLines: 1,
            textDirection: textDirection,
          )..layout(maxWidth: double.infinity);

          if (painter.width <= constraints.maxWidth) {
            break;
          }
          chosenSize -= 0.5;
        }

        return Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(fontSize: chosenSize),
        );
      },
    );
  }
}