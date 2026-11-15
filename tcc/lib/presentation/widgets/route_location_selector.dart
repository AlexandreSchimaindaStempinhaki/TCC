import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'account_option.dart';
import 'animated_three_dots.dart';
import 'location_card.dart';

class RouteLocationSelector extends StatelessWidget {
  final String label;
  final GeoPoint? geoPoint;
  final bool isLoadingGps;
  final VoidCallback onViewOnMap;
  final VoidCallback onGetGps;
  final VoidCallback onPickOnMap;

  const RouteLocationSelector({
    super.key,
    required this.label,
    required this.geoPoint,
    required this.isLoadingGps,
    required this.onViewOnMap,
    required this.onGetGps,
    required this.onPickOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Parte superior com os dados da localização registrada
              LocationCard(
                geoPoint: geoPoint,
                onViewOnMap: onViewOnMap,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              // Ações diretas sem título de seção
              AccountOption(
                icon: Icons.my_location_rounded,
                title: 'Pegar Localização Atual (GPS)',
                trailing: isLoadingGps
                    ? AnimatedThreeDots(color: colorScheme.surfaceTint)
                    : const Icon(Icons.chevron_right_rounded),
                onTap: onGetGps,
              ),
              const SizedBox(height: 8),
              AccountOption(
                icon: Icons.map_outlined,
                title: 'Escolher no Mapa',
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onPickOnMap,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}