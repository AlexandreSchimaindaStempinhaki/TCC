import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/animated_three_dots.dart';
import 'package:tcc/presentation/widgets/nav_bar.dart';
import 'package:tcc/presentation/widgets/saved_route_card.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../controllers/route/route_list_viewmodel.dart';
import '../../../controllers/user/user_viewmodel.dart';

class SavedView extends StatefulWidget {
  const SavedView({super.key});

  @override
  State<SavedView> createState() => _SavedViewState();
}

class _SavedViewState extends State<SavedView> {
  late final RouteListViewModel _routeListViewModel;
  late final UserViewModel _userViewModel;

  static const String _fallbackRouteImage =
      'https://ifpr.edu.br/paranagua/wp-content/uploads/sites/20/2021/08/241126748_1632298510296715_3679175102561492871_n.jpg';

  @override
  void initState() {
    super.initState();
    _routeListViewModel = injector.get<RouteListViewModel>();
    _userViewModel = injector.get<UserViewModel>();

    if (_routeListViewModel.state.routes.value.isEmpty) {
      _routeListViewModel.commands.fetchAllRoutes();
    }
  }

  String _currentUserIdentifier() {
    final loggedUser = _userViewModel.state.user.value;
    final authUser = FirebaseAuth.instance.currentUser;

    final cpf = loggedUser?.cpf;
    if (cpf != null && cpf.trim().isNotEmpty) {
      return cpf.trim();
    }

    final email = loggedUser?.email;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }

    return authUser?.email ?? authUser?.uid ?? '';
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

  Map<String, dynamic> _mapRouteToSavedCardData(
    RouteModel route, {
    required String userId,
    required bool isFavorite,
    required Color primaryColor,
  }) {
    final isApproved = userId.isNotEmpty && route.isUserPassenger(userId);
    final isPending = userId.isNotEmpty && route.isUserPending(userId);

    String statusText = 'Favoritada';
    Color statusColor = primaryColor;

    if (isApproved) {
      statusText = 'Vinculado à Linha';
      statusColor = const Color(0xFF15803D);
    } else if (isPending) {
      statusText = 'Solicitação Pendente';
      statusColor = const Color(0xFFD97706);
    }

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
      'vacancies': vacanciesText,
      'status': statusText,
      'statusColor': statusColor,
      'rating': 5.0,
      'isFavorite': isFavorite,
      'image': imageUrl,
    };
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rotas Salvas',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Watch((context) {
                final isLoading =
                    _routeListViewModel.fetchAllRoutesCommand.isExecuting.value;
                final allRoutes = _routeListViewModel.state.routes.value;
                final favIds =
                    _routeListViewModel.state.favoriteRouteIds.value;
                final userId = _currentUserIdentifier();

                final savedRoutes = allRoutes.where((route) {
                  final isFav = favIds.contains(route.id);
                  final isPending =
                      userId.isNotEmpty && route.isUserPending(userId);
                  final isJoined =
                      userId.isNotEmpty && route.isUserPassenger(userId);
                  return isFav || isPending || isJoined;
                }).toList();

                if (isLoading && allRoutes.isEmpty) {
                  return Center(
                    child: AnimatedThreeDots(color: colorScheme.primary),
                  );
                }

                if (savedRoutes.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        _routeListViewModel.commands.fetchAllRoutes(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(32, 90, 32, 100),
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 56,
                          color: colorScheme.secondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma rota salva no momento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Favorite linhas na tela inicial ou solicite vínculo em uma rota para acompanhá-la por aqui.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.secondary,
                            height: 1.4,
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: savedRoutes.length,
                    itemBuilder: (context, index) {
                      final routeModel = savedRoutes[index];
                      final isFav = favIds.contains(routeModel.id);

                      final cardData = _mapRouteToSavedCardData(
                        routeModel,
                        userId: userId,
                        isFavorite: isFav,
                        primaryColor: colorScheme.primary,
                      );

                      return SavedRouteCard(
                        key: ValueKey('saved_${routeModel.id}_fav_$isFav'),
                        route: cardData,
                        onTap: () {
                          context.pushNamed(
                            IndigoRouteNames.routeDetails,
                            extra: cardData,
                          );
                        },
                        onFavoriteTap: () {
                          _routeListViewModel.state.toggleFavorite(
                            routeModel.id,
                          );
                          setState(() {});
                        },
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}