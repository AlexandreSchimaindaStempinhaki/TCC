import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../widgets/nav_bar.dart';

class MyRoutesView extends StatelessWidget {
  const MyRoutesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: Text(
          'Minhas Rotas',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: myJoinedRoutes.isEmpty
          ? Center(
              child: Text(
                'Você ainda não possui vínculo com nenhuma rota.',
                style: TextStyle(color: colorScheme.secondary),
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
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['companyName'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              item['status'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['routeName'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Próxima viagem: ${item['nextTrip']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 20, color: theme.dividerColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gerenciar embarque e rastreamento',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: colorScheme.secondary,
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