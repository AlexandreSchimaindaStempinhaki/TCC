import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  int _selectedShiftIndex = 0; // 0: Manhã (07:00), 1: Noite (18:00)

  // Controle de dias da semana selecionados (Seg a Sex)
  final Map<String, bool> _activeDays = {
    'Seg': true,
    'Ter': true,
    'Qua': true,
    'Qui': true,
    'Sex': false,
  };

  // Coordenadas mock do motorista e da sua parada
  final LatLng _driverPosition = const LatLng(-25.5450, -48.5900);
  final LatLng _userPickupPosition = const LatLng(-25.5188, -48.5496);

  @override
  Widget build(BuildContext context) {
    final routeName = widget.route['routeName'] as String? ?? 'Detalhes da Rota';
    final driverName = widget.route['driverName'] as String? ?? 'Motorista';
    final vehicleInfo = widget.route['vehicleInfo'] as String? ?? 'Veículo';
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
            // 1. RASTREAMENTO AO VIVO E ESTIMATIVA DE CHEGADA (ETA)
            const Text(
              'Localização em Tempo Real',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _driverPosition,
                        zoom: 13,
                      ),
                      zoomControlsEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('driver'),
                          position: _driverPosition,
                          infoWindow: InfoWindow(title: 'Motorista: $driverName'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                        Marker(
                          markerId: const MarkerId('user'),
                          position: _userPickupPosition,
                          infoWindow: const InfoWindow(title: 'Sua Parada'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      },
                    ),

                    // Badge de ETA sobreposto no mapa
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Chegada em ~$eta min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Card do Motorista
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.person_outline, color: Color(0xFF1E3A8A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          vehicleInfo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. CONFIRMAÇÃO DE EMBARQUE DIÁRIO ("ESTOU PRONTO")
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
                              ? 'O motorista foi notificado que você está no ponto.'
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
                    onChanged: (val) {
                      setState(() {
                        _isReadyForPickup = val;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. CALENDÁRIO DE DIAS E HORÁRIOS DA SEMANA
            const Text(
              'Programação Semanal e Turnos',
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecione o Turno:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Seletor de Turnos
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Manhã (07:00)')),
                          selected: _selectedShiftIndex == 0,
                          selectedColor: const Color(0xFF1E3A8A),
                          labelStyle: TextStyle(
                            color: _selectedShiftIndex == 0
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedShiftIndex = 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Noite (18:00)')),
                          selected: _selectedShiftIndex == 1,
                          selectedColor: const Color(0xFF1E3A8A),
                          labelStyle: TextStyle(
                            color: _selectedShiftIndex == 1
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedShiftIndex = 1);
                          },
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  const Text(
                    'Dias que você utilizará esta linha:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Calendário semanal em chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _activeDays.keys.map((day) {
                      final isActive = _activeDays[day]!;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeDays[day] = !_activeDays[day]!;
                          });
                        },
                        child: Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Icon(
                                isActive
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 14,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}