import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/account/account_option.dart';
import 'package:tcc/presentation/widgets/feedback/animated_three_dots.dart';
import 'package:tcc/presentation/widgets/routes/route_itinerary_card.dart';

import '../../../../core/routes/home_routes.dart';
import '../../mixins/routes/route_details_logic.dart';

class RouteDetailsView extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailsView({super.key, required this.route});

  @override
  State<RouteDetailsView> createState() => _RouteDetailsViewState();
}

class _RouteDetailsViewState extends State<RouteDetailsView>
    with RouteDetailsMixin {
  Widget _buildOuterSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildHeaderImage(String imageUrl, ColorScheme colorScheme) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: colorScheme.primary.withOpacity(0.1),
        child: Icon(
          Icons.directions_bus_rounded,
          size: 64,
          color: colorScheme.primary,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: colorScheme.primary.withOpacity(0.15),
            ),
          ),
        ),
        Container(
          color: Colors.black.withOpacity(0.28),
        ),
        Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            color: colorScheme.primary.withOpacity(0.1),
            child: Icon(
              Icons.directions_bus_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.45),
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Watch((context) {
      // Garante reconstrução imediata sempre que o perfil carregado mudar
      final _ = userViewModel.state.user.value;

      final reactiveRoute = findReactiveRoute();
      final id = routeId;
      final isFavorite = id != null
          ? routeListViewModel.state.isFavorite(id)
          : ((widget.route['isFavorite'] as bool?) ?? false);

      final checkingPermissions = isCheckingPermissions.value;
      final userIds = allCurrentUserIdentifiers();
      final isOwner = !checkingPermissions && isCompanyOwner.value;
      final isManager = !checkingPermissions && isCompanyManager.value;
      final isDriver =
          !checkingPermissions &&
          (isCompanyDriver.value ||
              (reactiveRoute != null &&
                  userIds.any((uid) => reactiveRoute.isUserDriver(uid))));
      final isPassenger =
          !checkingPermissions &&
          reactiveRoute != null &&
          userIds.any((uid) => reactiveRoute.isUserPassenger(uid));

      final isApproved = isOwner || isManager || isDriver || isPassenger;
      final isPending =
          !checkingPermissions &&
          !isApproved &&
          reactiveRoute != null &&
          userIds.any((uid) => reactiveRoute.isUserPending(uid));

      final isExecutingAction =
          checkingPermissions ||
          routeListViewModel.requestToJoinRouteCommand.isExecuting.value ||
          routeListViewModel.cancelJoinRequestCommand.isExecuting.value ||
          isDeletingRoute.value;

      final hasManageAccess = !checkingPermissions && canManageRoute.value;

      final imageUrl =
          (reactiveRoute?.imageUrl != null &&
              reactiveRoute!.imageUrl!.trim().isNotEmpty)
          ? reactiveRoute.imageUrl!
          : (widget.route['image'] as String?) ?? '';

      final originText =
          (reactiveRoute?.originName != null &&
              reactiveRoute!.originName!.trim().isNotEmpty)
          ? reactiveRoute.originName!
          : (widget.route['origin'] as String?) ?? '';

      final destinationText =
          (reactiveRoute?.destinationName != null &&
              reactiveRoute!.destinationName!.trim().isNotEmpty)
          ? reactiveRoute.destinationName!
          : (widget.route['destination'] as String?) ?? '';

      final operatingDaysText =
          reactiveRoute?.operatingDaysLabel ??
          (widget.route['operatingDays'] as String?) ??
          'Segunda a Sexta';

      final currentShifts = resolveShifts(reactiveRoute);

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              backgroundColor: colorScheme.primary,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => handleBack(context),
                    tooltip: 'Voltar',
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.redAccent : Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (id != null) {
                          routeListViewModel.state.toggleFavorite(id);
                        } else {
                          setState(() {
                            widget.route['isFavorite'] = !isFavorite;
                          });
                        }
                      },
                      tooltip: 'Favoritar',
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeaderImage(imageUrl, colorScheme),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reactiveRoute?.company?.name ??
                                    (widget.route['companyName'] as String?) ??
                                    'Empresa de Transporte',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (widget.route['category'] as String?) ??
                                    'Transporte Contratado',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.route['rating'] ?? 5.0}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Container(
                      clipBehavior: Clip.antiAlias,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AccountOption(
                            icon: Icons.storefront,
                            title: 'Visualizar Página da Empresa',
                            trailing: const Icon(Icons.chevron_right_outlined),
                            onTap: () => openCompanyHome(
                              context,
                              reactiveRoute,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AccountOption(
                            icon: Icons.map_outlined,
                            title: 'Visualizar Trajeto no Mapa',
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              final mapPayload = Map<String, dynamic>.from(
                                widget.route,
                              );
                              if (reactiveRoute != null) {
                                mapPayload['startLatitude'] =
                                    reactiveRoute.origin.latitude;
                                mapPayload['startLongitude'] =
                                    reactiveRoute.origin.longitude;
                                mapPayload['endLatitude'] =
                                    reactiveRoute.destination.latitude;
                                mapPayload['endLongitude'] =
                                    reactiveRoute.destination.longitude;
                                mapPayload['origin'] = originText;
                                mapPayload['destination'] = destinationText;
                              }
                              context.pushNamed(
                                HomeRouteNames.routeMap,
                                extra: mapPayload,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    _buildOuterSectionTitle(context, 'Itinerário e Turnos'),
                    RouteItineraryCard(
                      origin: originText,
                      destination: destinationText,
                      operatingDays: operatingDaysText,
                      shifts: currentShifts,
                    ),

                    if (hasManageAccess) ...[
                      const SizedBox(height: 28),
                      _buildOuterSectionTitle(context, 'Administração'),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            AccountOption(
                              icon: Icons.edit_rounded,
                              title: 'Editar Rota',
                              onTap: () => openEditRoute(
                                context,
                                reactiveRoute,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AccountOption(
                              icon: Icons.delete_outline_rounded,
                              title: 'Excluir Rota',
                              iconColor: Colors.redAccent,
                              textColor: Colors.redAccent,
                              onTap: () => confirmAndDeleteRoute(
                                context,
                                reactiveRoute,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isExecutingAction
                    ? null
                    : () => handleJoinAction(
                        context,
                        isOwner: isOwner,
                        isManager: isManager,
                        isDriver: isDriver,
                        isPending: isPending,
                        isApproved: isApproved,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExecutingAction
                      ? colorScheme.primary.withOpacity(0.75)
                      : isApproved
                      ? Colors.green
                      : isPending
                      ? colorScheme.secondary
                      : colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isExecutingAction
                    ? AnimatedThreeDots(color: colorScheme.onSurface)
                    : Text(
                        isOwner
                            ? 'Você é o dono dessa empresa'
                            : isApproved
                            ? 'Vinculado a esta Linha'
                            : isPending
                            ? 'Cancelar Solicitação Pendente'
                            : 'Solicitar Vínculo com a Linha',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    });
  }
}