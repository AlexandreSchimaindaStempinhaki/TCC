import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final Map<String, String> resolvedAddresses;
  final VoidCallback onOverview;
  final VoidCallback onToggleExpand;
  final ValueChanged<TripStopPoint> onTapStop;
  final ValueChanged<TripStopPoint>? onOpenStopAddress;

  const LiveMapBottomSheet({
    super.key,
    required this.isDriver,
    required this.isExpanded,
    required this.arrivalClock,
    required this.estimatedMinutes,
    required this.remainingDistanceLabel,
    required this.stops,
    required this.selectedPassengerId,
    this.resolvedAddresses = const {},
    required this.onOverview,
    required this.onToggleExpand,
    required this.onTapStop,
    this.onOpenStopAddress,
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

  Widget _buildLegendChip(
    BuildContext context, {
    required Color color,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.14),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
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
                  if (!isDriver && stops.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildLegendChip(
                          context,
                          color: LiveMapMarkerFactory.readyGreen,
                          label: 'Pronto',
                        ),
                        _buildLegendChip(
                          context,
                          color: LiveMapMarkerFactory.waitingAmber,
                          label: 'Aguardando',
                        ),
                        _buildLegendChip(
                          context,
                          color: LiveMapMarkerFactory.completedSlate,
                          label: 'Embarcado',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isDriver && isExpanded) ...[
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
              SizedBox(
                height: 220,
                child: stops.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma parada registrada nesta viagem.',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13.5,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        itemCount: stops.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = stops[index];
                          final statusText =
                              LiveMapMarkerFactory.statusLabelForStop(s);
                          final statusColor =
                              LiveMapMarkerFactory.statusColorForStop(s);
                          final isSelected =
                              s.passengerId == selectedPassengerId;
                          final address = (s.passengerAddress?.trim().isNotEmpty ==
                                  true)
                              ? s.passengerAddress!.trim()
                              : resolvedAddresses[s.passengerId];

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
                                  _buildPassengerAvatar(
                                    s,
                                    accentColor: statusColor,
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            color:
                                                colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (address != null &&
                                            address.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: colorScheme
                                                  .onSurfaceVariant
                                                  .withOpacity(0.9),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (onOpenStopAddress != null)
                                    IconButton(
                                      tooltip: 'Ver endereço completo',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => onOpenStopAddress!(s),
                                      icon: Icon(
                                        Icons.location_on_outlined,
                                        size: 20,
                                        color: LiveMapMarkerFactory.appBlue,
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

/// Modal exibido exclusivamente para o motorista com o endereço completo do passageiro
/// e ação rápida de confirmação de embarque.
class PassengerAddressDetailSheet extends StatelessWidget {
  final TripStopPoint stop;
  final String? fullAddress;
  final bool isLoadingAddress;
  final VoidCallback onCenterOnMap;
  final Future<void> Function(bool isCompleted)? onToggleCompleted;

  const PassengerAddressDetailSheet({
    super.key,
    required this.stop,
    required this.fullAddress,
    required this.isLoadingAddress,
    required this.onCenterOnMap,
    this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = LiveMapMarkerFactory.statusColorForStop(stop);
    final statusLabel = LiveMapMarkerFactory.statusLabelForStop(stop);

    final displayAddress = (fullAddress != null && fullAddress!.trim().isNotEmpty)
        ? fullAddress!.trim()
        : 'Lat ${stop.latitude.toStringAsFixed(5)}, Lng ${stop.longitude.toStringAsFixed(5)}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor,
                  backgroundImage: (stop.passengerPhotoUrl != null &&
                          stop.passengerPhotoUrl!.startsWith('http'))
                      ? NetworkImage(stop.passengerPhotoUrl!)
                      : null,
                  child: (stop.passengerPhotoUrl == null ||
                          !stop.passengerPhotoUrl!.startsWith('http'))
                      ? Text(
                          LiveMapMarkerFactory.initialsFromName(
                            stop.passengerName,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.passengerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Parada #${stop.orderIndex}${!stop.isCompleted && stop.estimatedMinutesRemaining != null ? ' • Chegada em ~${stop.estimatedMinutesRemaining} min' : ''}',
                        style: TextStyle(
                          fontSize: 12.5,
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
                    statusLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2430)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: LiveMapMarkerFactory.appBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Endereço completo de embarque',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: displayAddress),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Endereço copiado.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 15,
                                color: LiveMapMarkerFactory.appBlue,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Copiar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: LiveMapMarkerFactory.appBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isLoadingAddress &&
                      (fullAddress == null || fullAddress!.trim().isEmpty))
                    Text(
                      'Buscando endereço completo...',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    SelectableText(
                      displayAddress,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCenterOnMap();
                    },
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Ver no mapa'),
                  ),
                ),
                if (onToggleCompleted != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: stop.isCompleted
                            ? LiveMapMarkerFactory.waitingAmber
                            : LiveMapMarkerFactory.readyGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await onToggleCompleted!(!stop.isCompleted);
                      },
                      icon: Icon(
                        stop.isCompleted
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      label: Text(
                        stop.isCompleted ? 'Desfazer' : 'Embarcou',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}