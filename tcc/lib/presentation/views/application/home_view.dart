import 'package:flutter/material.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';
import 'package:tcc/presentation/widgets/company_route_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List _categories = [
    {'label': 'Todas', 'icon': Icons.directions_bus_rounded},
    {'label': 'Universitários', 'icon': Icons.school_rounded},
    {'label': 'Empresas', 'icon': Icons.business_center_rounded},
    {'label': 'Escolares', 'icon': Icons.family_restroom_rounded},
    {'label': 'Próximas', 'icon': Icons.near_me_rounded},
  ];

  // Dados com ponto de partida detalhado, destino, dias, turnos e modalidade de embarque
  final List _availableRoutes = [
    {
      'companyName': 'Associação Estudantil Litoral',
      'origin': 'Pontal do Sul (R. Barão do Rio Branco, nº 450)',
      'destination': 'Campus IFPR Paranaguá / UFPR Litoral',
      'operatingDays': 'Segunda a Sexta-feira',
      'shifts': ['Manhã (06:30)', 'Tarde (12:15)', 'Noite (18:10)'],
      'isHomePickup': true, // Pega em casa
      'vacancies': '5 vagas restantes',
      'rating': 4.9,
      'isFavorite': false,
      'image':
          'https://images.unsplash.com/photo-1541829070764-84a7d30dd3f3?q=80&w=800&auto=format&fit=crop',
    },
    {
      'companyName': 'Expresso Fretamentos Corp',
      'origin': 'Bairro Santa Rosa (Ponto Central da Praça)',
      'destination': 'Distrito Industrial Paranaguá (Polos A e B)',
      'operatingDays': 'Segunda a Sábado',
      'shifts': ['Turno 1 (05:40)', 'Turno 2 (13:30)', 'Turno 3 (21:40)'],
      'isHomePickup': false, // Ponto próximo
      'vacancies': 'Vagas abertas para colaboradores',
      'rating': 4.8,
      'isFavorite': false,
      'image':
          'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?q=80&w=800&auto=format&fit=crop',
    },
    {
      'companyName': 'Viação Universitária Índigo',
      'origin': 'Praia de Leste (Av. Barão do Rio Branco)',
      'destination': 'UFPR - Centro Politécnico Curitiba',
      'operatingDays': 'Segunda, Quarta e Sexta',
      'shifts': ['Manhã (06:00)', 'Noite (17:30)'],
      'isHomePickup': false, // Ponto próximo
      'vacancies': 'Cadastro reserva',
      'rating': 4.95,
      'isFavorite': true,
      'image':
          'https://images.unsplash.com/photo-1562774053-701939374585?q=80&w=800&auto=format&fit=crop',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // 1. BARRA DE BUSCA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar empresa, bairro de origem ou destino...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 12.0),
                      child: Icon(
                        Icons.search_rounded,
                        color: Color(0xFF1E3A8A),
                        size: 22,
                      ),
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF0F172A),
                          size: 16,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. CARROSSEL DE CATEGORIAS
            SizedBox(
              height: 78,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategoryIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            color: isSelected
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF94A3B8),
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2.5,
                            width: 24,
                            color: isSelected
                                ? const Color(0xFF1E3A8A)
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // 3. LISTA DE CARDS COMPONENTIZADOS
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                itemCount: _availableRoutes.length,
                itemBuilder: (context, index) {
                  final route = _availableRoutes[index];
                  return CompanyRouteCard(
                    route: route,
                    onTap: () => (),
                    onFavoriteTap: () {
                      setState(() {
                        route['isFavorite'] = !(route['isFavorite'] as bool);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}
