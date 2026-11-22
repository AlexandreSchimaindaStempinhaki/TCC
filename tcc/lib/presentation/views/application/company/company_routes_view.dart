import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/company/company_route_card.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/company_routes.dart';
import '../../../../core/routes/home_routes.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../controllers/company/company_viewmodel.dart'
    show CompanyViewModel;
import '../../../controllers/route/route_list_viewmodel.dart';
import '../../../widgets/feedback/animated_three_dots.dart';

class CompanyRoutesView extends StatefulWidget {
  final CompanyModel? company;

  const CompanyRoutesView({
    super.key,
    this.company,
  });

  @override
  State<CompanyRoutesView> createState() => _CompanyRoutesViewState();
}

class _CompanyRoutesViewState extends State<CompanyRoutesView> {
  late final RouteListViewModel _routeListViewModel;
  late final CompanyViewModel _companyViewModel;

  final TextEditingController _searchController = TextEditingController();
  final Signal<String> _searchQuery = signal('');
  final Signal<bool> _isInitialLoading = signal(true);

  static const String _fallbackRouteImage =
      'https://ifpr.edu.br/paranagua/wp-content/uploads/sites/20/2021/08/241126748_1632298510296715_3679175102561492871_n.jpg';

  CompanyModel? get _targetCompany =>
      widget.company ?? _companyViewModel.state.selectedCompany.value;

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    _routeListViewModel = injector.get<RouteListViewModel>();
    _companyViewModel = injector.get<CompanyViewModel>();
    _loadCompanyRoutes();
  }

  Future<void> _loadCompanyRoutes() async {
    _isInitialLoading.value = true;
    final rawCnpj = _cleanDigits(_targetCompany?.cnpj ?? '');

    if (rawCnpj.isNotEmpty) {
      await _routeListViewModel.commands.fetchRoutesByCompany(rawCnpj);
    } else {
      await _routeListViewModel.commands.fetchAllRoutes();
    }

    if (mounted) {
      _isInitialLoading.value = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    _isInitialLoading.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        CompanyRouteNames.companyHome,
        extra: _targetCompany,
      );
    }
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
    final effectiveCompany = route.company ?? _targetCompany;

    final companyName =
        (effectiveCompany?.name != null &&
            effectiveCompany!.name.trim().isNotEmpty)
        ? effectiveCompany.name
        : 'Empresa (${route.companyCnpj})';

    final originText =
        (route.originName != null && route.originName!.trim().isNotEmpty)
        ? route.originName!
        : 'Lat: ${route.origin.latitude.toStringAsFixed(4)}, Lng:${route.origin.longitude.toStringAsFixed(4)}';

    final destinationText =
        (route.destinationName != null &&
            route.destinationName!.trim().isNotEmpty)
        ? route.destinationName!
        : 'Lat: ${route.destination.latitude.toStringAsFixed(4)}, Lng:${route.destination.longitude.toStringAsFixed(4)}';

    final imageUrl =
        (route.imageUrl != null && route.imageUrl!.trim().isNotEmpty)
        ? route.imageUrl!
        : (effectiveCompany?.logoUrl != null &&
              effectiveCompany!.logoUrl!.trim().isNotEmpty)
        ? effectiveCompany.logoUrl!
        : _fallbackRouteImage;

    final sortedSchedules = List<DateTime>.from(route.schedules)
      ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );

    final shifts = sortedSchedules.map(_formatShift).toList();

    final passengerCount = route.passengerIds.length;
    final vacanciesText = passengerCount == 0
        ? 'Vagas abertas'
        : '$passengerCount${passengerCount == 1 ? 'passageiro inscrito' : 'passageiros inscritos'}';

    final ratingCount = effectiveCompany?.ratingCount ?? 0;
    final rawRating = effectiveCompany?.rating ?? 0.0;
    final hasRating = ratingCount > 0 && rawRating > 0;
    final ratingDisplay = hasRating
        ? rawRating.toStringAsFixed(1)
        : 'Sem avaliações';

    return {
      'id': route.id,
      'routeModel': route.copyWith(company: effectiveCompany),
      'company': effectiveCompany,
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
      'vacancies': vacanciesText,
      'rating': ratingDisplay,
      'ratingCount': ratingCount,
      'hasRating': hasRating,
      'isFavorite': isFavorite,
      'image': imageUrl,
    };
  }

  List<RouteModel> _filterCompanyRoutes(
    List<RouteModel> sourceRoutes,
    String rawQuery,
  ) {
    final query = _normalizeText(rawQuery);
    final targetCnpj = _cleanDigits(_targetCompany?.cnpj ?? '');

    return sourceRoutes.where((route) {
      if (targetCnpj.isNotEmpty &&
          _cleanDigits(route.companyCnpj) != targetCnpj) {
        return false;
      }

      if (query.isEmpty) return true;

      final destination = _normalizeText(route.destinationName ?? '');
      final origin = _normalizeText(route.originName ?? '');
      final days = _normalizeText(route.operatingDaysLabel);

      return destination.contains(query) ||
          origin.contains(query) ||
          days.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final company = _targetCompany;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => _handleBack(context),
          tooltip: 'Voltar',
        ),
        title: Column(
          children: [
            Text(
              'Rotas da Empresa',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (company != null && company.name.trim().isNotEmpty)
              Text(
                company.name,
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
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
                    hintText: 'Buscar por destino ou ponto de saída...',
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
                              onPressed: _loadCompanyRoutes,
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
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: Watch((context) {
              final companyRoutes =
                  _routeListViewModel.state.companyRoutes.value;
              final allRoutes = _routeListViewModel.state.routes.value;
              final sourceList = companyRoutes.isNotEmpty
                  ? companyRoutes
                  : allRoutes;

              final query = _searchQuery.value;
              final favIds = _routeListViewModel.state.favoriteRouteIds.value;
              final filteredRoutes = _filterCompanyRoutes(sourceList, query);

              if (_isInitialLoading.value && filteredRoutes.isEmpty) {
                return Center(
                  child: AnimatedThreeDots(color: colorScheme.primary),
                );
              }

              if (filteredRoutes.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _loadCompanyRoutes,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(32, 80, 32, 60),
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
                            : 'Esta empresa ainda não possui rotas cadastradas',
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
                            ? 'Tente pesquisar por outro destino ou ponto de partida.'
                            : 'Puxe para baixo para atualizar a lista.',
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
                onRefresh: _loadCompanyRoutes,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: filteredRoutes.length,
                  itemBuilder: (context, index) {
                    final routeModel = filteredRoutes[index];

                    return Watch((context) {
                      final isFav =
                          favIds.contains(routeModel.id) ||
                          _routeListViewModel.state.isFavorite(routeModel.id);

                      final routeCardData = _mapRouteToCardData(
                        routeModel,
                        isFavorite: isFav,
                      );

                      return CompanyRouteCard(
                        key: ValueKey(
                          'company_route_${routeModel.id}_fav_$isFav',
                        ),
                        route: routeCardData,
                        onTap: () async {
                          await context.pushNamed(
                            HomeRouteNames.routeDetails,
                            extra: routeCardData,
                          );
                          if (mounted) {
                            _loadCompanyRoutes();
                          }
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
        ],
      ),
    );
  }
}