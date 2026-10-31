import 'package:flutter/material.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';

class SavedView extends StatefulWidget {
  const SavedView({super.key});

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView> {
  // Dados mockados de rotas salvas e status de solicitações
  final List _savedRoutes = [
    {
      'id': '1',
      'companyName': 'Associação Estudantil Litoral',
      'origin': 'Pontal do Sul',
      'destination': 'Campus IFPR / UFPR',
      'status': 'Solicitação Pendente',
      'statusColor': const Color(0xFFD97706), // Laranja (Em análise)
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
      'statusColor': const Color(0xFF166534), // Verde (Disponível)
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
            // Cabeçalho da Tela
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

            // Conteúdo ou Estado Vazio
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
                        return _buildSavedCard(route);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSavedCard(Map<String, dynamic> route) {
    final isHomePickup = route['isHomePickup'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    route['image'] as String,
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de Status da Solicitação/Vaga
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (route['statusColor'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          route['status'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: route['statusColor'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        route['companyName'] as String,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${route['origin']} ➔${route['destination']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _savedRoutes.removeWhere((item) => item['id'] == route['id']);
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isHomePickup ? Icons.home_rounded : Icons.location_on_rounded,
                      size: 14,
                      color: const Color(0xFF1E3A8A),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHomePickup ? 'Coleta em Casa' : 'Ponto Próximo',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Ver Detalhes ➔',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}