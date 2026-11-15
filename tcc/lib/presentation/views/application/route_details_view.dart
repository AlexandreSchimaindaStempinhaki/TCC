import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/account_option.dart';
import 'package:tcc/presentation/widgets/animated_three_dots.dart';
import 'package:tcc/presentation/widgets/route_itinerary_card.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/route_entity.dart';
import '../../controllers/company/company_list_viewmodel.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/route/route_list_viewmodel.dart';
import '../../controllers/user/user_viewmodel.dart';

class RouteDetailsView extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailsView({super.key, required this.route});

  @override
  State<RouteDetailsView> createState() => _RouteDetailsViewState();
}

class _RouteDetailsViewState extends State<RouteDetailsView> {
  late final RouteListViewModel _routeListViewModel;
  late final UserViewModel _userViewModel;
  late final CompanyViewModel _companyViewModel;
  late final CompanyListViewModel _companyListViewModel;

  @override
  void initState() {
    super.initState();
    _routeListViewModel = injector.get<RouteListViewModel>();
    _userViewModel = injector.get<UserViewModel>();
    _companyViewModel = injector.get<CompanyViewModel>();
    _companyListViewModel = injector.get<CompanyListViewModel>();
  }

  int? get _routeId => (widget.route['id'] as num?)?.toInt();

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

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

  RouteModel? _findReactiveRoute() {
    final id = _routeId;
    if (id != null) {
      for (final r in _routeListViewModel.state.routes.value) {
        if (r.id == id) return r;
      }
      for (final r in _routeListViewModel.state.companyRoutes.value) {
        if (r.id == id) return r;
      }
    }
    final rawModel = widget.route['routeModel'];
    return rawModel is RouteModel ? rawModel : null;
  }

  Future<void> _openCompanyHome(
    BuildContext context,
    RouteModel? reactiveRoute,
  ) async {
    final rawCnpj =
        reactiveRoute?.companyCnpj ??
        (widget.route['companyCnpj'] as String?) ??
        '';
    final targetCnpj = _cleanDigits(rawCnpj);

    CompanyModel? company =
        reactiveRoute?.company ??
        (widget.route['company'] is CompanyModel
            ? widget.route['company'] as CompanyModel
            : null);

    // Procura nas listas de empresas já carregadas caso não venha acoplada na rota
    if (company == null && targetCnpj.isNotEmpty) {
      final knownCompanies = [
        ..._companyListViewModel.state.ownedCompanies.value,
        ..._companyListViewModel.state.memberCompanies.value,
      ];
      for (final c in knownCompanies) {
        if (_cleanDigits(c.cnpj) == targetCnpj) {
          company = c;
          break;
        }
      }
    }

    // Fallback seguro garantindo um CompanyModel válido para a CompanyHomeView
    company ??= CompanyModel.fromMap({
      'cnpj': rawCnpj,
      'name':
          (widget.route['companyName'] as String?) ?? 'Empresa de Transporte',
      'email': '',
      'phone': '',
      'ownerId': '',
      'logoUrl': widget.route['image'] as String?,
    });

    _companyViewModel.state.setSelectedCompany(company);

    await context.pushNamed(
      IndigoRouteNames.companyHome,
      extra: company,
    );

    if (mounted) {
      await _routeListViewModel.commands.fetchAllRoutes();
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(IndigoRouteNames.home);
    }
  }

  void _showTopSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.green,
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final bottomMargin =
        mediaQuery.size.height - mediaQuery.padding.top - 110;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          elevation: 6,
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.only(
            bottom: bottomMargin > 0 ? bottomMargin : 20,
            left: 20,
            right: 20,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _handleJoinAction(
    BuildContext context, {
    required bool isPending,
    required bool isApproved,
  }) async {
    final routeId = _routeId;
    if (routeId == null) {
      _showTopSnackBar(
        context,
        'Solicitação de vínculo enviada com sucesso!',
      );
      return;
    }

    if (isApproved) {
      _showTopSnackBar(
        context,
        'Você já faz parte desta rota!',
        backgroundColor: Colors.black87,
        icon: Icons.verified_rounded,
      );
      return;
    }

    final userId = _currentUserIdentifier();
    if (userId.isEmpty) {
      _showTopSnackBar(
        context,
        'Faça login para solicitar vínculo com a rota.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (isPending) {
      final canceled = await _routeListViewModel.commands.cancelJoinRequest(
        routeId,
        userId,
      );
      if (!context.mounted) return;
      _showTopSnackBar(
        context,
        canceled
            ? 'Solicitação de vínculo cancelada.'
            : (_routeListViewModel.state.message.value ??
                'Erro ao cancelar solicitação.'),
        backgroundColor: canceled ? Colors.black87 : Colors.redAccent,
        icon: canceled
            ? Icons.info_outline_rounded
            : Icons.error_outline_rounded,
      );
    } else {
      final requested = await _routeListViewModel.commands.requestToJoinRoute(
        routeId,
        userId,
      );
      if (!context.mounted) return;
      _showTopSnackBar(
        context,
        requested
            ? 'Solicitação de vínculo enviada com sucesso!'
            : (_routeListViewModel.state.message.value ??
                'Erro ao enviar solicitação.'),
        backgroundColor: requested ? Colors.green : Colors.redAccent,
        icon: requested
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<String> shifts = List<String>.from(
      widget.route['shifts'] ?? ['Manhã (07:00)', 'Noite (18:00)'],
    );

    return Watch((context) {
      final reactiveRoute = _findReactiveRoute();
      final routeId = _routeId;
      final isFavorite = routeId != null
          ? _routeListViewModel.state.isFavorite(routeId)
          : ((widget.route['isFavorite'] as bool?) ?? false);

      final userId = _currentUserIdentifier();
      final isApproved =
          reactiveRoute != null &&
          userId.isNotEmpty &&
          reactiveRoute.isUserPassenger(userId);
      final isPending =
          reactiveRoute != null &&
          userId.isNotEmpty &&
          reactiveRoute.isUserPending(userId);

      final isExecutingAction =
          _routeListViewModel.requestToJoinRouteCommand.isExecuting.value ||
          _routeListViewModel.cancelJoinRequestCommand.isExecuting.value;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
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
                    onPressed: () => _handleBack(context),
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
                        if (routeId != null) {
                          _routeListViewModel.state.toggleFavorite(routeId);
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
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      (widget.route['image'] as String?) ?? '',
                      fit: BoxFit.cover,
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
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CABEÇALHO DA EMPRESA E AVALIAÇÃO
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

                    // OPÇÕES PADRONIZADAS (EMPRESA E MAPA)
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
                            icon: Icons.storefront_rounded,
                            title: 'Visualizar Página da Empresa',
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _openCompanyHome(
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
                              context.pushNamed(
                                IndigoRouteNames.routeMap,
                                extra: widget.route,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ITINERÁRIO E TURNOS
                    _buildOuterSectionTitle(context, 'Itinerário e Turnos'),
                    RouteItineraryCard(
                      origin: (widget.route['origin'] as String?) ?? '',
                      destination:
                          (widget.route['destination'] as String?) ?? '',
                      operatingDays:
                          (widget.route['operatingDays'] as String?) ??
                          'Segunda a Sexta',
                      shifts: shifts,
                    ),
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
                    : () => _handleJoinAction(
                        context,
                        isPending: isPending,
                        isApproved: isApproved,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApproved
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
                        isApproved
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