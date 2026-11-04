import 'package:flutter/material.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';
import 'package:tcc/presentation/widgets/company_route_card.dart';
import '../../../core/routes/indigo_routes.dart';
import 'package:go_router/go_router.dart';

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

  final List _availableRoutes = [
    {
      'companyName': 'Associação Estudantil Litoral',
      'origin': 'Pontal do Sul (R. Barão do Rio Branco, nº 450)',
      'destination': 'Campus IFPR Paranaguá / UFPR Litoral',
      'operatingDays': 'Segunda a Sexta-feira',
      'shifts': ['Manhã (06:30)', 'Tarde (12:15)', 'Noite (18:10)'],
      'isHomePickup': true,
      'vacancies': '5 vagas restantes',
      'rating': 4.9,
      'isFavorite': false,
      'image': 'https://ifpr.edu.br/paranagua/wp-content/uploads/sites/20/2021/08/241126748_1632298510296715_3679175102561492871_n.jpg',
    },
    {
      'companyName': 'Expresso Fretamentos Corp',
      'origin': 'Bairro Santa Rosa (Ponto Central da Praça)',
      'destination': 'Distrito Industrial Paranaguá (Polos A e B)',
      'operatingDays': 'Segunda a Sábado',
      'shifts': ['Turno 1 (05:40)', 'Turno 2 (13:30)', 'Turno 3 (21:40)'],
      'isHomePickup': false,
      'vacancies': 'Vagas abertas para colaboradores',
      'rating': 4.8,
      'isFavorite': false,
      'image': 'https://upload.wikimedia.org/wikipedia/commons/7/7d/UFPR_vista_frontal.jpg?utm_source=pt.wikipedia.org&utm_campaign=index&utm_content=original',
    },
    {
      'companyName': 'Viação Universitária Índigo',
      'origin': 'Praia de Leste (Av. Barão do Rio Branco)',
      'destination': 'UFPR - Centro Politécnico Curitiba',
      'operatingDays': 'Segunda, Quarta e Sexta',
      'shifts': ['Manhã (06:00)', 'Noite (17:30)'],
      'isHomePickup': false,
      'vacancies': 'Cadastro reserva',
      'rating': 4.95,
      'isFavorite': true,
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTCVHV0baSZSxF8qkOJYHX9fKyMuQWhWskNurlEjKM3KnsEtUszJ_ThetA&s=10',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.dividerColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Buscar empresa, bairro de origem ou destino...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                      child: Icon(
                        Icons.search_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.tune_rounded,
                          color: colorScheme.onSurface,
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
                                ? colorScheme.primary
                                : colorScheme.secondary.withOpacity(0.7),
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
                                  ? colorScheme.primary
                                  : colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 2.5,
                            width: 24,
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                itemCount: _availableRoutes.length,
                itemBuilder: (context, index) {
                  final route = _availableRoutes[index];
                  return CompanyRouteCard(
                    route: route,
                    onTap: () {
                      context.pushNamed(
                        IndigoRouteNames.routeDetails,
                        extra: route,
                      );
                    },
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