import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../widgets/nav_bar.dart';

class MyRoutesView extends StatelessWidget {
  const MyRoutesView({super.key});

  @override
  Widget build(BuildContext context) {
    final List myJoinedRoutes = [
      {
        'id': 'joined_1',
        'companyName': 'TransLitoral Executivo',
        'routeName': 'Linha Universitária - IFPR',
        'origin': 'Av. das Magnólias, 58',
        'destination': 'IFPR - Campus Paranaguá',
        'driverName': 'Sr. Carlos Andrade',
        'vehicleInfo': 'Mercedes-Benz Sprinter • ABC-1D23',
        'isHomePickup': true,
        'nextTrip': 'Hoje às 18:00',
        'status': 'Em Operação',
        'etaMinutes': 12,
      },
      {
        'id': 'joined_2',
        'companyName': 'Viação Índigo Urbano',
        'routeName': 'Rota Centro - Zona Sul',
        'origin': 'Rua das Palmeiras, 120',
        'destination': 'Terminal Central',
        'driverName': 'Dra. Márcia Santos',
        'vehicleInfo': 'Volare Fly 10 • XYZ-9876',
        'isHomePickup': false,
        'nextTrip': 'Amanhã às 07:00',
        'status': 'Programada',
        'etaMinutes': null,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Minhas Rotas',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: myJoinedRoutes.isEmpty
          ? const Center(
              child: Text(
                'Você ainda não possui vínculo com nenhuma rota.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: myJoinedRoutes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = myJoinedRoutes[index];
                return InkWell(
                  onTap: () {
                    context.pushNamed(
                      IndigoRouteNames.joinedRouteDetail,
                      extra: item,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['companyName'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['status'] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['routeName'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Próxima viagem: ${item['nextTrip']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gerenciar embarque e rastreamento',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}