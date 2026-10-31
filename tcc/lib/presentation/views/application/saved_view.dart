import 'package:flutter/material.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';
import 'package:tcc/presentation/widgets/saved_route_card.dart';

class SavedView extends StatefulWidget {
  const SavedView({super.key});

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView> {
  final List _savedRoutes = [
    {
      'id': '1',
      'companyName': 'Associação Estudantil Litoral',
      'origin': 'Pontal do Sul',
      'destination': 'Campus IFPR / UFPR',
      'status': 'Solicitação Pendente',
      'statusColor': const Color(0xFFD97706), // Apenas a cor do texto (Laranja)
      'isHomePickup': true,
      'rating': 4.9,
      'image': 'https://images.unsplash.com/photo-1541829070764-84a7d30dd3f3?q=80&w=800&auto=format&fit=crop',
    },
    {
      'id': '2',
      'companyName': 'Viação Universitária Índigo',
      'origin': 'Praia de Leste',
      'destination': 'UFPR - Centro Politécnico',
      'status': 'Vagas Abertas',
      'statusColor': const Color(0xFF15803D), // Apenas a cor do texto (Verde)
      'isHomePickup': false,
      'rating': 4.95,
      'image': 'https://images.unsplash.com/photo-1562774053-701939374585?q=80&w=800&auto=format&fit=crop',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rotas Salvas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Linhas favoritadas e solicitações de vínculo',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _savedRoutes.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma rota salva no momento.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _savedRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _savedRoutes[index];
                        return SavedRouteCard(
                          route: route,
                          onTap: () {
                            // Abrir detalhes da rota salva
                          },
                          onFavoriteTap: () {
                            setState(() {
                              _savedRoutes.removeWhere((item) => item['id'] == route['id']);
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}