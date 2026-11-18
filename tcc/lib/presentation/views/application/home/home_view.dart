import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/company_route_card.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../controllers/route/route_list_viewmodel.dart';
import '../../../widgets/animated_three_dots.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final RouteListViewModel _routeListViewModel;

  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final Signal<String> _searchQuery = signal('');

  static const String _fallbackRouteImage =
      'https://ifpr.edu.br/paranagua/wp-content/uploads/sites/20/2021/08/241126748_1632298510296715_3679175102561492871_n.jpg';

  final List _categories = [
    {'label': 'Todas', 'icon': Icons.directions_bus_rounded},
    {'label': 'Universitários', 'icon': Icons.school_rounded},
    {'label': 'Empresas', 'icon': Icons.business_center_rounded},
    {'label': 'Escolares', 'icon': Icons.family_restroom_rounded},
    {'label': 'Próximas', 'icon': Icons.near_me_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _routeListViewModel = injector.get<RouteListViewModel>();
    _routeListViewModel.commands.fetchAllRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    super.dispose();
  }

  String _normalizeText(String input) {
    const withAccents = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
    var result = input.trim().toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  String _formatShift(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';

    if (dt.hour >= 5 && dt.hour < 12) return 'Manhã ($timeStr)';
    if (dt.hour >= 12 && dt.hour < 18) return 'Tarde ($timeStr)';
    if (dt.hour >= 18) return 'Noite ($timeStr)';
    return 'Madrugada ($timeStr)';
  }

  Map<String, dynamic> _mapRouteToCardData(
    RouteModel route, {
    required bool isFavorite,
  }) {
    final companyName =
        (route.company?.name != null && route.company!.name.trim().isNotEmpty)
        ? route.company!.name
        : 'Empresa (${route.companyCnpj})';

    final originText =
        (route.originName != null && route.originName!.trim().isNotEmpty)
        ? route.originName!
        : 'Lat: ${route.origin.latitude.toStringAsFixed(4)}, Lng: ${route.origin.longitude.toStringAsFixed(4)}';

    final destinationText =
        (route.destinationName != null &&
            route.destinationName!.trim().isNotEmpty)
        ? route.destinationName!
        : 'Lat: ${route.destination.latitude.toStringAsFixed(4)}, Lng: ${route.destination.longitude.toStringAsFixed(4)}';

    final imageUrl =
        (route.imageUrl != null && route.imageUrl!.trim().isNotEmpty)
        ? route.imageUrl!
        : (route.company?.logoUrl != null &&
              route.company!.logoUrl!.trim().isNotEmpty)
        ? route.company!.logoUrl!
        : _fallbackRouteImage;

    final sortedSchedules = List<DateTime>.from(route.schedules)
      ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );

    final shifts = sortedSchedules.map(_formatShift).toList();

    final passengerCount = route.passengerIds.length;
    final vacanciesText = passengerCount == 0
        ? 'Vagas abertas'
        : '$passengerCount ${passengerCount == 1 ? 'passageiro inscrito' : 'passageiros inscritos'}';

    return {
      'id': route.id,
      'routeModel': route,
      'company': route.company,
      'companyCnpj': route.companyCnpj,
      'companyName': companyName,
      'origin': originText,
      'destination': destinationText,
      'startLatitude': route.origin.latitude,
      'startLongitude': route.origin.longitude,
      'endLatitude': route.destination.latitude,
      'endLongitude': route.destination.longitude,
      'operatingDays': route.operatingDaysLabel,
      'shifts': shifts,
      'isHomePickup': true,
      'vacancies': vacanciesText,
      'rating': 5.0,
      'isFavorite': isFavorite,
      'image': imageUrl,
    };
  }

  List<RouteModel> _filterRoutes(List<RouteModel> allRoutes, String rawQuery) {
    final query = _normalizeText(rawQuery);

    return allRoutes.where((route) {
      final destination = _normalizeText(route.destinationName ?? '');
      final origin = _normalizeText(route.originName ?? '');
      final company = _normalizeText(route.company?.name ?? '');

      final matchesSearch =
          query.isEmpty ||
          destination.contains(query) ||
          origin.contains(query) ||
          company.contains(query);

      if (!matchesSearch) return false;

      switch (_selectedCategoryIndex) {
        case 1: // Universitários
          return destination.contains('ifpr') ||
              destination.contains('ufpr') ||
              destination.contains('faculdade') ||
              destination.contains('universi') ||
              destination.contains('campus') ||
              company.contains('universi') ||
              company.contains('estudantil');
        case 2: // Empresas
          return destination.contains('industrial') ||
              destination.contains('empresa') ||
              destination.contains('porto') ||
              destination.contains('centro') ||
              company.contains('corp') ||
              company.contains('fretamento');
        case 3: // Escolares
          return destination.contains('escola') ||
              destination.contains('colegio') ||
              company.contains('escolar');
        default:
          return true;
      }
    }).toList();
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
            // BARRA DE PESQUISA POR DESTINO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.dividerColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? 0.3 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Watch((context) {
                  final hasSearchText = _searchQuery.value.trim().isNotEmpty;

                  return TextField(
                    controller: _searchController,
                    onChanged: (value) => _searchQuery.value = value,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Buscar por destino da rota...',
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
                      suffixIcon: hasSearchText
                          ? IconButton(
                              tooltip: 'Limpar busca',
                              icon: Icon(
                                Icons.close_rounded,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery.value = '';
                                FocusScope.of(context).unfocus();
                              },
                            )
                          : Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  color: colorScheme.onSurface,
                                  size: 16,
                                ),
                                tooltip: 'Atualizar rotas',
                                onPressed: () => _routeListViewModel.commands
                                    .fetchAllRoutes(),
                              ),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // CATEGORIAS
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

            // LISTA REATIVA DE ROTAS REAIS
            Expanded(
              child: Watch((context) {
                final isLoading =
                    _routeListViewModel.fetchAllRoutesCommand.isExecuting.value;
                final allRoutes = _routeListViewModel.state.routes.value;
                final query = _searchQuery.value;
                final favIds =
                    _routeListViewModel.state.favoriteRouteIds.value;

                final filteredRoutes = _filterRoutes(allRoutes, query);

                if (isLoading && allRoutes.isEmpty) {
                  return Center(
                    child: AnimatedThreeDots(color: colorScheme.primary),
                  );
                }

                if (filteredRoutes.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        _routeListViewModel.commands.fetchAllRoutes(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(32, 80, 32, 100),
                      children: [
                        Icon(
                          Icons.directions_bus_outlined,
                          size: 56,
                          color: colorScheme.secondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.trim().isNotEmpty
                              ? 'Nenhuma rota encontrada para "${query.trim()}"'
                              : 'Nenhuma rota cadastrada no momento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          query.trim().isNotEmpty
                              ? 'Tente pesquisar por outro nome de destino.'
                              : '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      _routeListViewModel.commands.fetchAllRoutes(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                    itemCount: filteredRoutes.length,
                    itemBuilder: (context, index) {
                      final routeModel = filteredRoutes[index];

                      return Watch((context) {
                        final isFav = favIds.contains(routeModel.id) ||
                            _routeListViewModel.state.isFavorite(
                              routeModel.id,
                            );
                        final routeCardData = _mapRouteToCardData(
                          routeModel,
                          isFavorite: isFav,
                        );

                        return CompanyRouteCard(
                          key: ValueKey('route_${routeModel.id}_fav_$isFav'),
                          route: routeCardData,
                          onTap: () {
                            context.pushNamed(
                              IndigoRouteNames.routeDetails,
                              extra: routeCardData,
                            );
                          },
                          onFavoriteTap: () {
                            _routeListViewModel.state.toggleFavorite(
                              routeModel.id,
                            );
                            setState(() {});
                          },
                        );
                      });
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 5),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}