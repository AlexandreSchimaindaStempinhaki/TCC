import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/route_entity.dart';
import '../../controllers/company/company_list_viewmodel.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/route/route_list_viewmodel.dart';
import '../../controllers/route/route_viewmodel.dart';
import '../../controllers/user/user_viewmodel.dart';
import '../application/routes/create_route_view.dart';
import '../application/routes/route_details_view.dart';

mixin RouteDetailsMixin on State<RouteDetailsView> {
  late final RouteListViewModel routeListViewModel;
  late final RouteViewModel routeViewModel;
  late final UserViewModel userViewModel;
  late final CompanyViewModel companyViewModel;
  late final CompanyListViewModel companyListViewModel;

  final canManageRoute = signal<bool>(false);
  final isCompanyOwner = signal<bool>(false);
  final isCompanyManager = signal<bool>(false);
  final isCompanyDriver = signal<bool>(false);
  final isDeletingRoute = signal<bool>(false);

  @override
  void initState() {
    super.initState();
    routeListViewModel = injector.get<RouteListViewModel>();
    routeViewModel = injector.get<RouteViewModel>();
    userViewModel = injector.get<UserViewModel>();
    companyViewModel = injector.get<CompanyViewModel>();
    companyListViewModel = injector.get<CompanyListViewModel>();

    _checkManagementPermissions();
  }

  @override
  void dispose() {
    canManageRoute.dispose();
    isCompanyOwner.dispose();
    isCompanyManager.dispose();
    isCompanyDriver.dispose();
    isDeletingRoute.dispose();
    super.dispose();
  }

  int? get routeId => (widget.route['id'] as num?)?.toInt();

  String cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String currentUserIdentifier() {
    final loggedUser = userViewModel.state.user.value;
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

  Set<String> allCurrentUserIdentifiers() {
    final ids = <String>{};
    final authUser = FirebaseAuth.instance.currentUser;
    final loggedUser = userViewModel.state.user.value;

    if (authUser != null) {
      if (authUser.uid.trim().isNotEmpty) {
        ids.add(authUser.uid.trim());
      }
      final authEmail = authUser.email;
      if (authEmail != null && authEmail.trim().isNotEmpty) {
        ids.add(authEmail.trim());
        ids.add(authEmail.trim().toLowerCase());
      }
    }

    if (loggedUser != null) {
      final cpf = loggedUser.cpf;
      if (cpf != null && cpf.trim().isNotEmpty) {
        ids.add(cpf.trim());
        ids.add(cleanDigits(cpf));
      }

      final email = loggedUser.email;
      if (email != null && email.trim().isNotEmpty) {
        ids.add(email.trim());
        ids.add(email.trim().toLowerCase());
      }
    }

    return ids;
  }

  RouteModel? findReactiveRoute() {
    final id = routeId;
    if (id != null) {
      for (final r in routeListViewModel.state.routes.value) {
        if (r.id == id) return r;
      }
      for (final r in routeListViewModel.state.companyRoutes.value) {
        if (r.id == id) return r;
      }
    }
    final rawModel = widget.route['routeModel'];
    return rawModel is RouteModel ? rawModel : null;
  }

  String formatShift(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$h:$m';

    if (dt.hour >= 5 && dt.hour < 12) return 'Manhã ($timeStr)';
    if (dt.hour >= 12 && dt.hour < 18) return 'Tarde ($timeStr)';
    if (dt.hour >= 18) return 'Noite ($timeStr)';
    return 'Madrugada ($timeStr)';
  }

  List<String> resolveShifts(RouteModel? reactiveRoute) {
    if (reactiveRoute != null && reactiveRoute.schedules.isNotEmpty) {
      final sorted = List<DateTime>.from(reactiveRoute.schedules)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );
      return sorted.map(formatShift).toList();
    }
    return List<String>.from(
      widget.route['shifts'] ?? ['Manhã (07:00)', 'Noite (18:00)'],
    );
  }

  Future<CompanyModel?> _resolveCompany(RouteModel? reactiveRoute) async {
    final rawCnpj =
        reactiveRoute?.companyCnpj ??
        (widget.route['companyCnpj'] as String?) ??
        '';
    final targetCnpj = cleanDigits(rawCnpj);

    CompanyModel? company =
        reactiveRoute?.company ??
        (widget.route['company'] is CompanyModel
            ? widget.route['company'] as CompanyModel
            : null);

    if (company == null && targetCnpj.isNotEmpty) {
      final knownCompanies = [
        ...companyListViewModel.state.ownedCompanies.value,
        ...companyListViewModel.state.memberCompanies.value,
      ];
      for (final c in knownCompanies) {
        if (cleanDigits(c.cnpj) == targetCnpj) {
          company = c;
          break;
        }
      }
    }

    if (company == null && targetCnpj.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('companies')
            .doc(targetCnpj)
            .get();
        if (doc.exists && doc.data() != null) {
          company = CompanyModel.fromMap(doc.data()!);
        }
      } catch (_) {}
    }

    return company;
  }

  bool _isOwnerRole(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    return role == 'ceo' ||
        role == 'owner' ||
        role == 'dono' ||
        role == 'proprietario';
  }

  bool _isManagerRole(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    return role == 'manager' ||
        role == 'gerente' ||
        role == 'admin' ||
        role == 'administrador';
  }

  bool _isDriverRole(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    return role == 'driver' ||
        role == 'motorista' ||
        role == 'condutor';
  }

  Future<void> _checkManagementPermissions() async {
    final userIds = allCurrentUserIdentifiers();
    if (userIds.isEmpty) {
      canManageRoute.value = false;
      isCompanyOwner.value = false;
      isCompanyManager.value = false;
      isCompanyDriver.value = false;
      return;
    }

    final reactiveRoute = findReactiveRoute();
    if (reactiveRoute != null &&
        userIds.any((id) => reactiveRoute.isUserDriver(id))) {
      isCompanyDriver.value = true;
    }

    final rawCnpj =
        reactiveRoute?.companyCnpj ??
        (widget.route['companyCnpj'] as String?) ??
        '';
    final targetCnpj = cleanDigits(rawCnpj);

    if (targetCnpj.isNotEmpty) {
      final isOwnedInMemory = companyListViewModel.state.ownedCompanies.value
          .any((c) => cleanDigits(c.cnpj) == targetCnpj);
      if (isOwnedInMemory) {
        isCompanyOwner.value = true;
        canManageRoute.value = true;
        return;
      }
    }

    final company = await _resolveCompany(reactiveRoute);
    if (company != null && company.ownerId.trim().isNotEmpty) {
      final ownerClean = cleanDigits(company.ownerId);
      if (userIds.contains(company.ownerId.trim()) ||
          (ownerClean.isNotEmpty && userIds.contains(ownerClean))) {
        if (mounted) {
          isCompanyOwner.value = true;
          canManageRoute.value = true;
        }
        return;
      }
    }

    if (targetCnpj.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('company_members')
          .where('companyCnpj', isEqualTo: targetCnpj)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final memberUserId =
            (data['userId'] ?? data['cpf'] ?? data['email'] ?? '')
                .toString()
                .trim();
        final memberClean = cleanDigits(memberUserId);
        final role = (data['role'] ?? data['cargo'] ?? '').toString();

        final matchesUser =
            userIds.contains(memberUserId) ||
            userIds.contains(memberUserId.toLowerCase()) ||
            (memberClean.isNotEmpty && userIds.contains(memberClean));

        if (!matchesUser) continue;

        if (_isOwnerRole(role)) {
          if (mounted) {
            isCompanyOwner.value = true;
            canManageRoute.value = true;
          }
          return;
        }

        if (_isManagerRole(role)) {
          if (mounted) {
            isCompanyManager.value = true;
            canManageRoute.value = true;
          }
          return;
        }

        if (_isDriverRole(role)) {
          if (mounted) {
            isCompanyDriver.value = true;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> openCompanyHome(
    BuildContext context,
    RouteModel? reactiveRoute,
  ) async {
    final rawCnpj =
        reactiveRoute?.companyCnpj ??
        (widget.route['companyCnpj'] as String?) ??
        '';

    CompanyModel? company = await _resolveCompany(reactiveRoute);

    company ??= CompanyModel.fromMap({
      'cnpj': rawCnpj,
      'name':
          (widget.route['companyName'] as String?) ?? 'Empresa de Transporte',
      'email': '',
      'phone': '',
      'ownerId': '',
      'logoUrl': widget.route['image'] as String?,
    });

    companyViewModel.state.setSelectedCompany(company);

    if (!context.mounted) return;
    await context.pushNamed(
      IndigoRouteNames.companyHome,
      extra: company,
    );

    if (mounted) {
      await routeListViewModel.commands.fetchAllRoutes();
      await _checkManagementPermissions();
    }
  }

  Future<void> openEditRoute(
    BuildContext context,
    RouteModel? reactiveRoute,
  ) async {
    final routeToEdit = reactiveRoute;
    if (routeToEdit == null) {
      showTopSnackBar(
        context,
        'Dados completos da rota não encontrados para edição.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final company = await _resolveCompany(routeToEdit);
    if (!context.mounted) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateRouteView(
          company: company ?? routeToEdit.company,
          initialRoute: routeToEdit,
        ),
      ),
    );

    if (changed == true && mounted) {
      final cnpj = cleanDigits(routeToEdit.companyCnpj);
      if (cnpj.isNotEmpty) {
        await routeListViewModel.commands.fetchRoutesByCompany(cnpj);
      }
      await routeListViewModel.commands.fetchAllRoutes();
      setState(() {});
    }
  }

  Future<void> confirmAndDeleteRoute(
    BuildContext context,
    RouteModel? reactiveRoute,
  ) async {
    final id = reactiveRoute?.id ?? routeId;
    if (id == null) return;

    final colorScheme = Theme.of(context).colorScheme;
    final routeDestination =
        reactiveRoute?.destinationName ??
        (widget.route['destination'] as String?) ??
        'esta rota';

    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber.shade700,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Excluir Rota?')),
          ],
        ),
        content: Text(
          'Deseja excluir a rota com destino a "$routeDestination"?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (firstConfirm != true || !context.mounted) return;

    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.delete_forever_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(width: 8),
            Expanded(child: Text('Confirmar Exclusão')),
          ],
        ),
        content: const Text(
          'Esta ação é permanente e removerá a rota e todos os vínculos de passageiros. Confirmar exclusão?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sim, Excluir'),
          ),
        ],
      ),
    );

    if (secondConfirm != true || !context.mounted) return;

    try {
      isDeletingRoute.value = true;
      bool deleted = false;

      try {
        deleted = await routeListViewModel.commands.deleteRouteFromList(id);
      } catch (_) {
        await FirebaseFirestore.instance
            .collection('routes')
            .doc(id.toString())
            .delete();
        routeListViewModel.state.removeRouteById(id);
        deleted = true;
      }

      if (!context.mounted) return;

      if (deleted) {
        showTopSnackBar(context, 'Rota excluída com sucesso!');
        handleBack(context);
      } else {
        showTopSnackBar(
          context,
          routeListViewModel.state.message.value ??
              'Não foi possível excluir a rota.',
          backgroundColor: Colors.redAccent,
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopSnackBar(
          context,
          'Erro ao excluir rota: $e',
          backgroundColor: Colors.redAccent,
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) {
        isDeletingRoute.value = false;
      }
    }
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.goNamed(IndigoRouteNames.home);
    }
  }

  void showTopSnackBar(
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

  Future<void> handleJoinAction(
    BuildContext context, {
    required bool isOwner,
    required bool isManager,
    required bool isDriver,
    required bool isPending,
    required bool isApproved,
  }) async {
    if (isOwner) {
      showTopSnackBar(
        context,
        'Você é o dono dessa empresa!',
        backgroundColor: Colors.black87,
        icon: Icons.verified_rounded,
      );
      return;
    }

    if (isManager) {
      showTopSnackBar(
        context,
        'Você já está vinculado a esta rota como gerente!',
        backgroundColor: Colors.black87,
        icon: Icons.verified_rounded,
      );
      return;
    }

    if (isDriver) {
      showTopSnackBar(
        context,
        'Você já está vinculado a esta rota como motorista!',
        backgroundColor: Colors.black87,
        icon: Icons.verified_rounded,
      );
      return;
    }

    final id = routeId;
    if (id == null) {
      showTopSnackBar(
        context,
        'Solicitação de vínculo enviada com sucesso!',
      );
      return;
    }

    if (isApproved) {
      showTopSnackBar(
        context,
        'Você já faz parte desta rota!',
        backgroundColor: Colors.black87,
        icon: Icons.verified_rounded,
      );
      return;
    }

    final userId = currentUserIdentifier();
    if (userId.isEmpty) {
      showTopSnackBar(
        context,
        'Faça login para solicitar vínculo com a rota.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    if (isPending) {
      final canceled = await routeListViewModel.commands.cancelJoinRequest(
        id,
        userId,
      );
      if (!context.mounted) return;
      showTopSnackBar(
        context,
        canceled
            ? 'Solicitação de vínculo cancelada.'
            : (routeListViewModel.state.message.value ??
                'Erro ao cancelar solicitação.'),
        backgroundColor: canceled ? Colors.black87 : Colors.redAccent,
        icon: canceled
            ? Icons.info_outline_rounded
            : Icons.error_outline_rounded,
      );
    } else {
      final requested = await routeListViewModel.commands.requestToJoinRoute(
        id,
        userId,
      );
      if (!context.mounted) return;
      showTopSnackBar(
        context,
        requested
            ? 'Solicitação de vínculo enviada com sucesso!'
            : (routeListViewModel.state.message.value ??
                'Erro ao enviar solicitação.'),
        backgroundColor: requested ? Colors.green : Colors.redAccent,
        icon: requested
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
      );
    }
  }
}