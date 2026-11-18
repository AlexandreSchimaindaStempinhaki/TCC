import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/models/company_entity.dart';
import '../../domain/models/route_entity.dart';

class MyRouteCard extends StatelessWidget {
  final RouteModel route;
  final CompanyModel? company;
  final String userRoleBadge;
  final VoidCallback onTap;

  const MyRouteCard({
    super.key,
    required this.route,
    this.company,
    required this.userRoleBadge,
    required this.onTap,
  });

  String _formatRouteTitle() {
    final orig = (route.originName ?? '').trim();
    final dest = (route.destinationName ?? '').trim();
    if (orig.isNotEmpty && dest.isNotEmpty) {
      return '$orig → $dest';
    }
    if (dest.isNotEmpty) return dest;
    if (orig.isNotEmpty) return orig;
    return 'Rota #${route.id}';
  }

  String _formatSchedules() {
    if (route.schedules.isEmpty) return 'Sem horário definido';
    final times = route.schedules.take(3).map((dt) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }).join(' • ');
    return '${route.operatingDaysLabel} ($times)';
  }

  Widget _buildRawImage(
    String imageUrl,
    ColorScheme colorScheme, {
    required BoxFit fit,
  }) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: colorScheme.primary.withOpacity(0.08),
          alignment: Alignment.center,
          child: Icon(
            Icons.directions_bus_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Image.file(
      File(imageUrl),
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.primary.withOpacity(0.08),
        alignment: Alignment.center,
        child: Icon(
          Icons.directions_bus_rounded,
          size: 48,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final resolvedCompany = company ?? route.company;

    final imageUrl =
        (route.imageUrl != null && route.imageUrl!.trim().isNotEmpty)
            ? route.imageUrl!.trim()
            : ((resolvedCompany?.logoUrl != null &&
                    resolvedCompany!.logoUrl!.trim().isNotEmpty)
                ? resolvedCompany.logoUrl!.trim()
                : '');

    final companyName = (resolvedCompany?.name.trim().isNotEmpty == true)
        ? resolvedCompany!.name.trim()
        : 'Transporte Contratual';

    final destinationText =
        (route.destinationName != null && route.destinationName!.trim().isNotEmpty)
            ? route.destinationName!.trim()
            : 'Destino definido no mapa';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? colorScheme.onSurface.withOpacity(0.24)
              : colorScheme.onSurface.withOpacity(0.16),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: SizedBox(
                    height: 155,
                    width: double.infinity,
                    child: imageUrl.isEmpty
                        ? Container(
                            color: colorScheme.primary.withOpacity(0.08),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.route_rounded,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 16,
                                  sigmaY: 16,
                                ),
                                child: _buildRawImage(
                                  imageUrl,
                                  colorScheme,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.25 : 0.12,
                                ),
                              ),
                              _buildRawImage(
                                imageUrl,
                                colorScheme,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                  ),
                ),
                if (route.isTripActive)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sensors_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Em viagem',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary, // Fundo totalmente preenchido
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userRoleBadge,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Texto branco contrastante
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatRouteTitle(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (resolvedCompany != null &&
                          resolvedCompany.ratingCount > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              resolvedCompany.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Destino: $destinationText',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatSchedules(),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Ver mais informações',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                    ],
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