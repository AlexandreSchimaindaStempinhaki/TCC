import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/route_entity.dart';
import '../../../domain/models/user_entity.dart';
import '../../controllers/company/company_list_viewmodel.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/company_member/company_member_state_viewmodel.dart';
import '../../controllers/company_member/company_member_viewmodel.dart';
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
  late final CompanyMemberViewModel companyMemberViewModel;

  final canManageRoute = signal<bool>(false);
  final isCompanyOwner = signal<bool>(false);
  final isCompanyManager = signal<bool>(false);
  final isCompanyDriver = signal<bool>(false);
  final isDeletingRoute = signal<bool>(false);
  final isCheckingPermissions = signal<bool>(true);

  EffectCleanup? _userSyncEffect;
  int _permissionCheckSeq = 0;
  bool _isSyncingUser = false;

  @override
  void initState() {
    super.initState();
    routeListViewModel = injector.get<RouteListViewModel>();
    routeViewModel = injector.get<RouteViewModel>();
    userViewModel = injector.get<UserViewModel>();
    companyViewModel = injector.get<CompanyViewModel>();
    companyListViewModel = injector.get<CompanyListViewModel>();
    companyMemberViewModel = injector.get<CompanyMemberViewModel>();

    // Reavalia permissões caso o perfil mude depois do carregamento inicial
    var isFirstEffectRun = true;
    _userSyncEffect = effect(() {
      final _ = userViewModel.state.user.value;
      if (isFirstEffectRun) {
        isFirstEffectRun = false;
        return;
      }
      untracked(() {
        if (!mounted || _isSyncingUser) return;
        _checkManagementPermissions();
      });
    });

    _syncUserAndCheckPermissions(forceFetchUser: true);
  }

  @override
  void dispose() {
    _userSyncEffect?.call();
    canManageRoute.dispose();
    isCompanyOwner.dispose();
    isCompanyManager.dispose();
    isCompanyDriver.dispose();
    isDeletingRoute.dispose();
    isCheckingPermissions.dispose();
    super.dispose();
  }

  int? get routeId => (widget.route['id'] as num?)?.toInt();

  String cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  void _resetPermissions() {
    canManageRoute.value = false;
    isCompanyOwner.value = false;
    isCompanyManager.value = false;
    isCompanyDriver.value = false;
  }

  Future<void> _syncUserAndCheckPermissions({
    bool forceFetchUser = false,
  }) async {
    final requestSeq = ++_permissionCheckSeq;
    _isSyncingUser = true;
    isCheckingPermissions.value = true;
    _resetPermissions();

    try {
      if (forceFetchUser || userViewModel.state.user.value == null) {
        try {
          await userViewModel.commands.fetchUser().timeout(
            const Duration(seconds: 6),
          );
        } catch (_) {}
      }

      if (!mounted || requestSeq != _permissionCheckSeq) return;
      await _checkManagementPermissions(requestSeq: requestSeq);
    } finally {
      if (requestSeq == _permissionCheckSeq) {
        _isSyncingUser = false;
        if (mounted) {
          isCheckingPermissions.value = false;
        }
      }
    }
  }

  String currentUserIdentifier() {
    final loggedUser = userViewModel.state.user.value;
    if (loggedUser == null) return '';

    final cpf = loggedUser.cpf;
    if (cpf != null && cpf.trim().isNotEmpty) {
      return cpf.trim();
    }

    if (loggedUser.email.trim().isNotEmpty) {
      return loggedUser.email.trim();
    }

    return loggedUser.uid.trim();
  }

  Set<String> allCurrentUserIdentifiers() {
    final ids = <String>{};
    final loggedUser = userViewModel.state.user.value;

    if (loggedUser != null) {
      if (loggedUser.uid.trim().isNotEmpty) {
        ids.add(loggedUser.uid.trim());
      }

      final cpf = loggedUser.cpf;
      if (cpf != null && cpf.trim().isNotEmpty) {
        ids.add(cpf.trim());
        final cleanedCpf = cleanDigits(cpf);
        if (cleanedCpf.isNotEmpty) ids.add(cleanedCpf);
      }

      if (loggedUser.email.trim().isNotEmpty) {
        ids.add(loggedUser.email.trim());
        ids.add(loggedUser.email.trim().toLowerCase());
      }
    }

    return ids;
  }

  bool _matchesUserIds(String rawId, Set<String> userIds) {
    final trimmed = rawId.trim();
    if (trimmed.isEmpty) return false;
    final cleaned = cleanDigits(trimmed);
    return userIds.contains(trimmed) ||
        userIds.contains(trimmed.toLowerCase()) ||
        (cleaned.length == 11 && userIds.contains(cleaned));
  }

  bool _matchesMemberUser(UserModel? user, Set<String> userIds) {
    if (user == null) return false;
    return _matchesUserIds(user.uid, userIds) ||
        _matchesUserIds(user.cpf ?? '', userIds) ||
        _matchesUserIds(user.email, userIds);
  }

  RouteModel? findReactiveRoute() {
    final id = routeId;
    if (id != null) {
      final singleLoaded = routeViewModel.state.route.value;
      if (singleLoaded != null && singleLoaded.id == id) {
        return singleLoaded;
      }
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

    // Busca via ViewModel -> Service (getRouteById já retorna a CompanyModel anexada)
    if (company == null && routeId != null) {
      try {
        final fetchedRoute = await routeViewModel.commands
            .fetchRouteById(routeId!, loadMembers: false)
            .timeout(const Duration(seconds: 5));
        company = fetchedRoute?.company;
      } catch (_) {}
    }

    return company;
  }

  Future<void> _checkManagementPermissions({int? requestSeq}) async {
    final seq = requestSeq ?? ++_permissionCheckSeq;

    try {
      final userIds = allCurrentUserIdentifiers();
      if (userIds.isEmpty) {
        _resetPermissions();
        return;
      }

      bool nextOwner = false;
      bool nextManager = false;
      bool nextDriver = false;

      final reactiveRoute = findReactiveRoute();
      if (reactiveRoute != null &&
          userIds.any((id) => reactiveRoute.isUserDriver(id))) {
        nextDriver = true;
      }

      final rawCnpj =
          reactiveRoute?.companyCnpj ??
          (widget.route['companyCnpj'] as String?) ??
          '';
      final targetCnpj = cleanDigits(rawCnpj);

      // Só considera dono em memória se o ownerId bater com o usuário recém-carregado
      if (targetCnpj.isNotEmpty) {
        final isOwnedByCurrentUser = companyListViewModel
            .state
            .ownedCompanies
            .value
            .any(
              (c) =>
                  cleanDigits(c.cnpj) == targetCnpj &&
                  _matchesUserIds(c.ownerId, userIds),
            );
        if (isOwnedByCurrentUser) {
          if (mounted && seq == _permissionCheckSeq) {
            isCompanyOwner.value = true;
            isCompanyManager.value = false;
            isCompanyDriver.value = nextDriver;
            canManageRoute.value = true;
          }
          return;
        }
      }

      final company = await _resolveCompany(reactiveRoute);
      if (!mounted || seq != _permissionCheckSeq) return;

      if (company != null && _matchesUserIds(company.ownerId, userIds)) {
        isCompanyOwner.value = true;
        isCompanyManager.value = false;
        isCompanyDriver.value = nextDriver;
        canManageRoute.value = true;
        return;
      }

      // Valida vínculos da empresa exclusivamente pelo CompanyMemberViewModel -> Service
      if (company != null) {
        try {
          await companyMemberViewModel.commands
              .loadCompanyMembersDetailed(company)
              .timeout(const Duration(seconds: 5));

          if (!mounted || seq != _permissionCheckSeq) return;

          final owners = companyMemberViewModel.state.ownersList.value;
          final managers = companyMemberViewModel.state.managersList.value;
          final drivers = companyMemberViewModel.state.driversList.value;

          if (owners.any((m) => _matchesMemberUser(m.userModel, userIds))) {
            nextOwner = true;
          }
          if (managers.any((m) => _matchesMemberUser(m.userModel, userIds))) {
            nextManager = true;
          }
          if (drivers.any((m) => _matchesMemberUser(m.userModel, userIds))) {
            nextDriver = true;
          }
        } catch (_) {}
      }

      if (!mounted || seq != _permissionCheckSeq) return;

      isCompanyOwner.value = nextOwner;
      isCompanyManager.value = nextManager;
      isCompanyDriver.value = nextDriver;
      canManageRoute.value = nextOwner || nextManager;
    } finally {
      if (mounted && seq == _permissionCheckSeq) {
        isCheckingPermissions.value = false;
      }
    }
  }

  // =========================================================================
  //   VALIDAÇÃO DE CADASTRO COMPLETO ANTES DE ENTRAR NA ROTA
  // =========================================================================
  bool _hasCompleteAddress(UserModel user) {
    final addr = user.address;
    if (addr == null) return false;
    final map = addr.toMap();

    String read(List<String> keys) {
      for (final k in keys) {
        final v = map[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
      return '';
    }

    final city = read(['city', 'cidade']);
    final neighborhood = read(['neighborhood', 'bairro']);
    final street = read(['street', 'rua', 'logradouro']);
    final number = read(['number', 'numero']);

    return city.isNotEmpty &&
        neighborhood.isNotEmpty &&
        street.isNotEmpty &&
        number.isNotEmpty;
  }

  ({
    List<String> personalMissing,
    List<String> locationMissing,
    bool missingAddress,
    bool missingBoarding,
    bool missingDisembarkation,
  })
  _checkMissingProfileData(UserModel user) {
    final personalMissing = <String>[];
    final locationMissing = <String>[];

    if (user.photoUrl == null || user.photoUrl!.trim().isEmpty) {
      personalMissing.add('Foto de perfil');
    }
    if (user.name.trim().isEmpty) {
      personalMissing.add('Nome completo');
    }
    if (user.email.trim().isEmpty) {
      personalMissing.add('E-mail');
    }
    if (cleanDigits(user.cpf ?? '').length != 11) {
      personalMissing.add('CPF');
    }
    if (cleanDigits(user.phone ?? '').length < 10) {
      personalMissing.add('Telefone');
    }
    if (user.birthDate == null) {
      personalMissing.add('Data de nascimento');
    }

    final missingAddress = !_hasCompleteAddress(user);
    final missingBoarding = user.boardingPoint == null;
    final missingDisembarkation = user.disembarkationPoint == null;

    if (missingAddress) {
      locationMissing.add('Endereço completo');
    }
    if (missingBoarding) {
      locationMissing.add('Localização do ponto de embarque');
    }
    if (missingDisembarkation) {
      locationMissing.add('Localização do ponto de desembarque');
    }

    return (
      personalMissing: personalMissing,
      locationMissing: locationMissing,
      missingAddress: missingAddress,
      missingBoarding: missingBoarding,
      missingDisembarkation: missingDisembarkation,
    );
  }

  Future<void> _showIncompleteProfileDialog(
    BuildContext context, {
    required List<String> personalMissing,
    required List<String> locationMissing,
    required bool missingAddress,
    required bool missingBoarding,
    required bool missingDisembarkation,
  }) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allMissing = [...personalMissing, ...locationMissing];

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.assignment_late_outlined,
              color: Colors.amber.shade700,
              size: 26,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Complete seu cadastro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para solicitar entrada em uma rota, todos os seus dados e pontos no mapa precisam estar preenchidos:',
                style: TextStyle(
                  fontSize: 13.5,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              ...allMissing.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 17,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Agora não',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          if (personalMissing.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop('profile'),
              child: const Text(
                'Completar Perfil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else if (missingAddress)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop('address'),
              child: const Text(
                'Configurar Endereço',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else if (missingBoarding || missingDisembarkation)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop('geolocation'),
              child: Text(
                missingBoarding
                    ? 'Definir Embarque'
                    : 'Definir Desembarque',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );

    if (!context.mounted || action == null) return;

    if (action == 'profile') {
      await context.pushNamed(IndigoRouteNames.editProfile);
    } else if (action == 'address') {
      await context.pushNamed(IndigoRouteNames.manageAddress);
    } else if (action == 'geolocation') {
      await context.pushNamed(
        IndigoRouteNames.manageGeolocation,
        extra: {'isBoarding': missingBoarding},
      );
    }

    if (mounted) {
      await _syncUserAndCheckPermissions(forceFetchUser: true);
    }
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
    await context.pushNamed(IndigoRouteNames.companyHome, extra: company);

    if (mounted) {
      await routeListViewModel.commands.fetchAllRoutes();
      await _syncUserAndCheckPermissions();
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
        deleted = await routeViewModel.commands.deleteRoute(id);
        if (deleted) {
          routeListViewModel.state.removeRouteById(id);
        }
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

    if (isPending) {
      final userId = currentUserIdentifier();
      if (userId.isEmpty) {
        showTopSnackBar(
          context,
          'Faça login para gerenciar sua solicitação.',
          backgroundColor: Colors.redAccent,
          icon: Icons.error_outline_rounded,
        );
        return;
      }

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
      return;
    }

    // Garante que estamos validando o perfil atualizado da conta logada via ViewModel -> Service
    var user = userViewModel.state.user.value;
    if (user == null) {
      try {
        await userViewModel.commands.fetchUser().timeout(
          const Duration(seconds: 6),
        );
      } catch (_) {}
      if (!context.mounted) return;
      user = userViewModel.state.user.value;
    }

    if (user == null) {
      showTopSnackBar(
        context,
        'Faça login para solicitar vínculo com a rota.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    // Verifica todos os dados pessoais + endereço + pontos de embarque e desembarque
    final validation = _checkMissingProfileData(user);
    if (validation.personalMissing.isNotEmpty ||
        validation.locationMissing.isNotEmpty) {
      await _showIncompleteProfileDialog(
        context,
        personalMissing: validation.personalMissing,
        locationMissing: validation.locationMissing,
        missingAddress: validation.missingAddress,
        missingBoarding: validation.missingBoarding,
        missingDisembarkation: validation.missingDisembarkation,
      );
      return;
    }

    final userId = currentUserIdentifier();
    if (userId.isEmpty) {
      showTopSnackBar(
        context,
        'Não foi possível identificar sua conta.',
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
      return;
    }

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