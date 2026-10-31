import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/live_route_tracking_card.dart';
import '../../widgets/monthly_schedule_card.dart';

class JoinedRouteDetailView extends StatefulWidget {
  final Map<String, dynamic> route;

  const JoinedRouteDetailView({
    super.key,
    required this.route,
  });

  @override
  State<JoinedRouteDetailView> createState() => _JoinedRouteDetailViewState();
}

class _JoinedRouteDetailViewState extends State<JoinedRouteDetailView> {
  bool _isReadyForPickup = false;

  final LatLng _driverPosition = const LatLng(-25.5450, -48.5900);
  final LatLng _userPickupPosition = const LatLng(-25.5188, -48.5496);

  Future<void> _handlePickupToggle(bool newValue, ThemeData theme, ColorScheme colorScheme) async {
    if (newValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirmar Presença',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Você confirma que estará no ponto de embarque no horário agendado de hoje?',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.secondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Sim, estou pronto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => _isReadyForPickup = true);
      }
    } else {
      setState(() => _isReadyForPickup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final routeName = widget.route['routeName'] as String? ?? 'Detalhes da Rota';
    final driverName = widget.route['driverName'] as String? ?? 'Carlos Andrade';
    final vehicleInfo = widget.route['vehicleInfo'] as String? ?? 'Mercedes-Benz Sprinter';
    final eta = widget.route['etaMinutes'] ?? 12;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          routeName,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiveRouteTrackingCard(
              driverName: driverName,
              vehicleInfo: vehicleInfo,
              etaMinutes: eta,
              driverPosition: _driverPosition,
              userPickupPosition: _userPickupPosition,
            ),
            const SizedBox(height: 24),
            Text(
              'Confirmação para Hoje',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isReadyForPickup
                    ? (theme.brightness == Brightness.dark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isReadyForPickup
                      ? const Color(0xFFBBF7D0)
                      : theme.dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isReadyForPickup
                        ? Icons.check_circle_rounded
                        : Icons.do_not_disturb_on_outlined,
                    color: _isReadyForPickup
                        ? Colors.greenAccent
                        : colorScheme.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isReadyForPickup
                              ? 'Pronto para Embarque'
                              : 'Aguardando sua confirmação',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isReadyForPickup
                                ? Colors.white
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isReadyForPickup
                              ? 'O motorista foi notificado da sua presença.'
                              : 'Avisar o motorista se você vai embarcar na corrida de hoje.',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isReadyForPickup ? Colors.white70 : colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isReadyForPickup,
                    activeColor: colorScheme.primary,
                    onChanged: (val) => _handlePickupToggle(val, theme, colorScheme),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Programação Mensal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            const MonthlyScheduleCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}