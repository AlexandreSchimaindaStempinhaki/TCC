import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/models/vehicle_entity.dart';

class CompanyVehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final String? companyLogoUrl;
  final VoidCallback onTap;

  const CompanyVehicleCard({
    super.key,
    required this.vehicle,
    this.companyLogoUrl,
    required this.onTap,
  });

  String _formatPlate(String raw) {
    final clean = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.length == 7) {
      return '${clean.substring(0, 3)}-${clean.substring(3)}';
    }
    return raw.toUpperCase();
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

    final photo =
        (vehicle.photoUrl != null && vehicle.photoUrl!.trim().isNotEmpty)
            ? vehicle.photoUrl!.trim()
            : (companyLogoUrl != null && companyLogoUrl!.trim().isNotEmpty)
                ? companyLogoUrl!.trim()
                : '';

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
            color: Colors.black.withOpacity(
              isDark ? 0.3 : 0.04,
            ),
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
            // Imagem do veículo com efeito blur no fundo e contain na frente
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: photo.isEmpty
                    ? Container(
                        color: colorScheme.primary.withOpacity(0.08),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.directions_bus_rounded,
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
                              photo,
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
                            photo,
                            colorScheme,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vehicle.model,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: vehicle.isActive
                              ? colorScheme.primary.withOpacity(0.12)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vehicle.isActive ? 'Em rota' : 'Disponível',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: vehicle.isActive
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.pin_drop_rounded,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Placa: ${_formatPlate(vehicle.plate)}',
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