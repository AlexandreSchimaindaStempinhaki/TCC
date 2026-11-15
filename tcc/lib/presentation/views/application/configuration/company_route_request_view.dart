import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/route_entity.dart';
import '../../../controllers/company/company_viewmodel.dart';
import '../../../controllers/route/route_list_viewmodel.dart';
import '../../../widgets/animated_three_dots.dart';

class CompanyRouteRequestsView extends StatefulWidget {
  final CompanyModel? company;

  const CompanyRouteRequestsView({
    super.key,
    this.company,
  });

  @override
  State<CompanyRouteRequestsView> createState() =>
      _CompanyRouteRequestsViewState();
}

class _CompanyRouteRequestsViewState extends State<CompanyRouteRequestsView> {
  late final RouteListViewModel _routeListViewModel;
  late final CompanyViewModel _companyViewModel;

  final Signal<bool> _isLoading = signal(true);
  final Signal<String?> _processingKey = signal(null);
  final Map<String, Map<String, dynamic>> _userProfilesCache = {};

  CompanyModel? get _targetCompany =>
      widget.company ?? _companyViewModel.state.selectedCompany.value;

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    _routeListViewModel = injector.get<RouteListViewModel>();
    _companyViewModel = injector.get<CompanyViewModel>();
    _loadRequests();
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _processingKey.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    _isLoading.value = true;
    final rawCnpj = _cleanDigits(_targetCompany?.cnpj ?? '');

    if (rawCnpj.isNotEmpty) {
      await _routeListViewModel.commands.fetchRoutesByCompany(rawCnpj);
    } else {
      await _routeListViewModel.commands.fetchAllRoutes();
    }

    final routes = _getCompanyRoutes();
    final allPendingIds = <String>{};
    for (final r in routes) {
      allPendingIds.addAll(r.pendingPassengerIds);
    }

    await _fetchUserProfiles(allPendingIds);

    if (mounted) {
      _isLoading.value = false;
    }
  }

  List<RouteModel> _getCompanyRoutes() {
    final targetCnpj = _cleanDigits(_targetCompany?.cnpj ?? '');
    final companyRoutes = _routeListViewModel.state.companyRoutes.value;
    final allRoutes = _routeListViewModel.state.routes.value;
    final source = companyRoutes.isNotEmpty ? companyRoutes : allRoutes;

    return source.where((route) {
      if (targetCnpj.isNotEmpty &&
          _cleanDigits(route.companyCnpj) != targetCnpj) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _fetchUserProfiles(Set<String> userIds) async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    for (final rawId in userIds) {
      final id = rawId.trim();
      if (id.isEmpty || _userProfilesCache.containsKey(id)) continue;

      try {
        final cleanCpf = _cleanDigits(id);
        DocumentSnapshot? doc;

        if (cleanCpf.isNotEmpty) {
          final byCpfDoc = await usersRef.doc(cleanCpf).get();
          if (byCpfDoc.exists) doc = byCpfDoc;
        }

        if (doc == null) {
          final byRawDoc = await usersRef.doc(id).get();
          if (byRawDoc.exists) doc = byRawDoc;
        }

        if (doc == null && cleanCpf.isNotEmpty) {
          final queryByCpf = await usersRef
              .where('cpf', isEqualTo: cleanCpf)
              .limit(1)
              .get();
          if (queryByCpf.docs.isNotEmpty) {
            doc = queryByCpf.docs.first;
          }
        }

        if (doc == null) {
          final queryByEmail = await usersRef
              .where('email', isEqualTo: id)
              .limit(1)
              .get();
          if (queryByEmail.docs.isNotEmpty) {
            doc = queryByEmail.docs.first;
          }
        }

        final rawData = doc?.data();
        if (rawData is Map) {
          _userProfilesCache[id] = Map<String, dynamic>.from(rawData);
        }
      } catch (_) {}
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        IndigoRouteNames.companyHome,
        extra: _targetCompany,
      );
    }
  }

  void _showSnackBar(
    String message, {
    Color backgroundColor = Colors.green,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleDecision({
    required RouteModel route,
    required String passengerId,
    required bool approve,
  }) async {
    final actionKey = '${route.id}_$passengerId';
    _processingKey.value = actionKey;

    try {
      final updatedPending = List<String>.from(route.pendingPassengerIds)
        ..remove(passengerId);
      final updatedPassengers = List<String>.from(route.passengerIds);

      if (approve && !updatedPassengers.contains(passengerId)) {
        updatedPassengers.add(passengerId);
      }

      final updatedRoute = route.copyWith(
        pendingPassengerIds: updatedPending,
        passengerIds: updatedPassengers,
      );

      await FirebaseFirestore.instance
          .collection('routes')
          .doc(route.id.toString())
          .update({
            'pendingPassengerIds': updatedPending,
            'passengerIds': updatedPassengers,
          });

      _routeListViewModel.state.upsertRoute(updatedRoute);

      _showSnackBar(
        approve
            ? 'Passageiro aprovado na rota com sucesso!'
            : 'Solicitação recusada.',
        backgroundColor: approve ? Colors.green : Colors.black87,
      );
    } catch (e) {
      _showSnackBar(
        'Erro ao processar solicitação: $e',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        _processingKey.value = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
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
              'Solicitações de Vínculo',
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
      body: Watch((context) {
        final loading = _isLoading.value;
        final currentProcessing = _processingKey.value;
        final routesWithRequests = _getCompanyRoutes()
            .where((r) => r.pendingPassengerIds.isNotEmpty)
            .toList();

        if (loading) {
          return Center(
            child: AnimatedThreeDots(color: colorScheme.primary),
          );
        }

        if (routesWithRequests.isEmpty) {
          return RefreshIndicator(
            onRefresh: _loadRequests,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(32, 100, 32, 60),
              children: [
                Icon(
                  Icons.how_to_reg_rounded,
                  size: 60,
                  color: colorScheme.secondary.withOpacity(0.45),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma solicitação pendente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quando passageiros solicitarem vínculo nas rotas desta empresa, os pedidos aparecerão aqui para aprovação.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadRequests,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            itemCount: routesWithRequests.length,
            itemBuilder: (context, index) {
              final route = routesWithRequests[index];
              final origin =
                  (route.originName != null &&
                      route.originName!.trim().isNotEmpty)
                  ? route.originName!
                  : 'Origem cadastrada';
              final destination =
                  (route.destinationName != null &&
                      route.destinationName!.trim().isNotEmpty)
                  ? route.destinationName!
                  : 'Destino cadastrado';

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.onSurface.withOpacity(0.22)
                        : colorScheme.onSurface.withOpacity(0.14),
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.route_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$origin ➔ $destination',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${route.pendingPassengerIds.length} ${route.pendingPassengerIds.length == 1 ? 'solicitação pendente' : 'solicitações pendentes'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.6),
                    ),
                    ...route.pendingPassengerIds.map((passengerId) {
                      final profile = _userProfilesCache[passengerId.trim()];
                      final displayName =
                          (profile?['nome'] ??
                                  profile?['name'] ??
                                  'Passageiro')
                              .toString();
                      final displayEmail =
                          (profile?['email'] ?? '').toString();
                      final displayPhoto =
                          (profile?['fotoUrl'] ?? profile?['photoUrl'] ?? '')
                              .toString();
                      final isBusy =
                          currentProcessing == '${route.id}_$passengerId';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: colorScheme.onSurface
                                  .withOpacity(0.1),
                              backgroundImage: displayPhoto.isNotEmpty
                                  ? NetworkImage(displayPhoto)
                                  : null,
                              child: displayPhoto.isEmpty
                                  ? Icon(
                                      Icons.person_rounded,
                                      color: colorScheme.onSurface,
                                      size: 22,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    displayEmail.isNotEmpty
                                        ? '$displayEmail • ID: $passengerId'
                                        : 'Identificador: $passengerId',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isBusy)
                              SizedBox(
                                width: 48,
                                child: Center(
                                  child: AnimatedThreeDots(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Recusar',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.redAccent
                                          .withOpacity(0.12),
                                    ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () => _handleDecision(
                                      route: route,
                                      passengerId: passengerId,
                                      approve: false,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    tooltip: 'Aprovar',
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF15803D,
                                      ).withOpacity(0.15),
                                    ),
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF15803D),
                                      size: 20,
                                    ),
                                    onPressed: () => _handleDecision(
                                      route: route,
                                      passengerId: passengerId,
                                      approve: true,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}