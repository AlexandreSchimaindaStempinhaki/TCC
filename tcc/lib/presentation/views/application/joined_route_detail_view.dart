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

  // Coordenadas fictícias do motorista e parada do usuário
  final LatLng _driverPosition = const LatLng(-25.5450, -48.5900);
  final LatLng _userPickupPosition = const LatLng(-25.5188, -48.5496);

  // Pop-up de Reconfirmação de Embarque
  Future<void> _handlePickupToggle(bool newValue) async {
    if (newValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirmar Presença',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Você confirma que estará no ponto de embarque no horário agendado de hoje?',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
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
    final routeName = widget.route['routeName'] as String? ?? 'Detalhes da Rota';
    final driverName = widget.route['driverName'] as String? ?? 'Carlos Andrade';
    final vehicleInfo = widget.route['vehicleInfo'] as String? ?? 'Mercedes-Benz Sprinter';
    final eta = widget.route['etaMinutes'] ?? 12;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          routeName,
          style: const TextStyle(
            color: Color(0xFF0F172A),
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
            // 1. COMPONENTE DE RASTREAMENTO DO MAPA + MOTORISTA + ETA
            LiveRouteTrackingCard(
              driverName: driverName,
              vehicleInfo: vehicleInfo,
              etaMinutes: eta,
              driverPosition: _driverPosition,
              userPickupPosition: _userPickupPosition,
            ),

            const SizedBox(height: 24),

            // 2. CARD DE CONFIRMAÇÃO COM RECONFIRMAÇÃO EM POP-UP
            const Text(
              'Confirmação para Hoje',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isReadyForPickup
                    ? const Color(0xFFF0FDF4)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isReadyForPickup
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFF1F5F9),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isReadyForPickup
                        ? Icons.check_circle_rounded
                        : Icons.do_not_disturb_on_outlined,
                    color: _isReadyForPickup
                        ? const Color(0xFF166534)
                        : const Color(0xFF64748B),
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
                                ? const Color(0xFF14532D)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isReadyForPickup
                              ? 'O motorista foi notificado da sua presença.'
                              : 'Avisar o motorista se você vai embarcar na corrida de hoje.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isReadyForPickup,
                    activeColor: const Color(0xFF1E3A8A),
                    onChanged: (val) => _handlePickupToggle(val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. COMPONENTE DE PROGRAMAÇÃO MENSAL
            const Text(
              'Programação Mensal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
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