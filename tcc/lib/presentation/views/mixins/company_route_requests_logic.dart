import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/route_entity.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/route/route_list_viewmodel.dart';
import '../application/company/company_route_request_view.dart';

mixin CompanyRouteRequestsMixin on State<CompanyRouteRequestsView> {
  late final RouteListViewModel routeListViewModel;
  late final CompanyViewModel companyViewModel;

  final Signal<bool> isLoading = signal(true);
  final Signal<String?> processingKey = signal(null);
  final Map<String, Map<String, dynamic>> userProfilesCache = {};

  static const String fallbackRouteImage =
      'https://ifpr.edu.br/paranagua/wp-content/uploads/sites/20/2021/08/241126748_1632298510296715_3679175102561492871_n.jpg';

  static const Color solidOrange = Color(0xFFD97706);
  static const Color solidGreen = Color(0xFF15803D);
  static const Color solidRed = Color(0xFFDC2626);

  CompanyModel? get targetCompany =>
      widget.company ?? companyViewModel.state.selectedCompany.value;

  String cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String formatCnpj(String cnpj) {
    final digits = cleanDigits(cnpj);
    if (digits.length != 14) return cnpj;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }

  @override
  void initState() {
    super.initState();
    routeListViewModel = injector.get<RouteListViewModel>();
    companyViewModel = injector.get<CompanyViewModel>();
    loadRequests();
  }

  @override
  void dispose() {
    isLoading.dispose();
    processingKey.dispose();
    super.dispose();
  }

  Future<void> loadRequests() async {
    isLoading.value = true;
    final rawCnpj = cleanDigits(targetCompany?.cnpj ?? '');

    if (rawCnpj.isNotEmpty) {
      await routeListViewModel.commands.fetchRoutesByCompany(rawCnpj);
    } else {
      await routeListViewModel.commands.fetchAllRoutes();
    }

    final routes = getCompanyRoutes();
    final allPendingIds = <String>{};
    for (final r in routes) {
      allPendingIds.addAll(r.pendingPassengerIds);
    }

    await _fetchUserProfiles(allPendingIds);

    if (mounted) {
      isLoading.value = false;
    }
  }

  List<RouteModel> getCompanyRoutes() {
    final targetCnpj = cleanDigits(targetCompany?.cnpj ?? '');
    final companyRoutes = routeListViewModel.state.companyRoutes.value;
    final allRoutes = routeListViewModel.state.routes.value;
    final source = companyRoutes.isNotEmpty ? companyRoutes : allRoutes;

    return source.where((route) {
      if (targetCnpj.isNotEmpty &&
          cleanDigits(route.companyCnpj) != targetCnpj) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _fetchUserProfiles(Set<String> userIds) async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    for (final rawId in userIds) {
      final id = rawId.trim();
      if (id.isEmpty || userProfilesCache.containsKey(id)) continue;

      try {
        final cleanCpf = cleanDigits(id);
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
          userProfilesCache[id] = Map<String, dynamic>.from(rawData);
        }
      } catch (_) {}
    }
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        IndigoRouteNames.companyHome,
        extra: targetCompany,
      );
    }
  }

  void showSnackBar(
    String message, {
    Color backgroundColor = solidGreen,
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

  Future<void> confirmAndHandleDecision({
    required RouteModel route,
    required String passengerId,
    required String passengerName,
    required bool approve,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final destination =
        (route.destinationName != null &&
            route.destinationName!.trim().isNotEmpty)
        ? route.destinationName!
        : 'Destino da Rota';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              approve
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: approve ? solidGreen : solidRed,
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                approve ? 'Aprovar Passageiro?' : 'Recusar Solicitação?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          approve
              ? 'Deseja aprovar o vínculo de "$passengerName" na rota com destino a "$destination"?'
              : 'Tem certeza que deseja recusar o pedido de vínculo de "$passengerName" nesta rota?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? solidGreen : solidRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              approve ? 'Sim, Aprovar' : 'Sim, Recusar',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _handleDecision(
      route: route,
      passengerId: passengerId,
      approve: approve,
    );
  }

  Future<void> _handleDecision({
    required RouteModel route,
    required String passengerId,
    required bool approve,
  }) async {
    final actionKey = '${route.id}_$passengerId';
    processingKey.value = actionKey;

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

      routeListViewModel.state.upsertRoute(updatedRoute);

      showSnackBar(
        approve
            ? 'Passageiro aprovado na rota com sucesso!'
            : 'Solicitação recusada.',
        backgroundColor: approve ? solidGreen : solidRed,
      );
    } catch (e) {
      showSnackBar(
        'Erro ao processar solicitação: $e',
        backgroundColor: solidRed,
      );
    } finally {
      if (mounted) {
        processingKey.value = null;
      }
    }
  }

  String resolveRouteImage(RouteModel route, CompanyModel? company) {
    if (route.imageUrl != null && route.imageUrl!.trim().isNotEmpty) {
      return route.imageUrl!.trim();
    }
    if (route.company?.logoUrl != null &&
        route.company!.logoUrl!.trim().isNotEmpty) {
      return route.company!.logoUrl!.trim();
    }
    if (company?.logoUrl != null && company!.logoUrl!.trim().isNotEmpty) {
      return company.logoUrl!.trim();
    }
    return fallbackRouteImage;
  }
}