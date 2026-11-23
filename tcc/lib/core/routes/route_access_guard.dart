import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/company_entity.dart';
import '../../domain/models/company_member_entity.dart';
import '../../domain/models/route_entity.dart';
import '../../presentation/controllers/company/company_list_viewmodel.dart';
import '../../presentation/controllers/company/company_viewmodel.dart';
import '../../presentation/controllers/company_member/company_member_viewmodel.dart';
import '../../presentation/controllers/user/user_viewmodel.dart';
import '../di/dependency_injection.dart';
import 'home_routes.dart';

enum CompanyAccessRole {
  none,
  passenger,
  driver,
  manager,
  owner,
}

class RouteAccessGuard {
  RouteAccessGuard._();

  static String _cleanDigits(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  static Set<String> _currentUserIdentifiers() {
    final ids = <String>{};

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      if (authUser.uid.trim().isNotEmpty) ids.add(authUser.uid.trim());
      final authEmail = authUser.email?.trim();
      if (authEmail != null && authEmail.isNotEmpty) {
        ids.add(authEmail);
        ids.add(authEmail.toLowerCase());
      }
    }

    try {
      final user = injector.get<UserViewModel>().state.user.value;
      if (user != null) {
        if (user.uid.trim().isNotEmpty) ids.add(user.uid.trim());
        final cpf = user.cpf?.trim();
        if (cpf != null && cpf.isNotEmpty) {
          ids.add(cpf);
          final digits = _cleanDigits(cpf);
          if (digits.isNotEmpty) ids.add(digits);
        }
        final email = user.email.trim();
        if (email.isNotEmpty) {
          ids.add(email);
          ids.add(email.toLowerCase());
        }
      }
    } catch (_) {}

    return ids;
  }

  static bool _matchesUser(String? rawTarget, Set<String> userIds) {
    if (rawTarget == null) return false;
    final trimmed = rawTarget.trim();
    if (trimmed.isEmpty) return false;
    final digits = _cleanDigits(trimmed);
    return userIds.contains(trimmed) ||
        userIds.contains(trimmed.toLowerCase()) ||
        (digits.isNotEmpty && userIds.contains(digits));
  }

  static CompanyAccessRole _parseRole(String? rawRole) {
    final normalized = (rawRole ?? '').trim().toLowerCase();
    if ([
      'ceo',
      'owner',
      'dono',
      'proprietario',
      'proprietário',
    ].contains(normalized)) {
      return CompanyAccessRole.owner;
    }
    if ([
      'manager',
      'gerente',
      'admin',
      'administrador',
      CompanyRole.admin.toLowerCase(),
    ].contains(normalized)) {
      return CompanyAccessRole.manager;
    }
    if ([
      'driver',
      'motorista',
      'condutor',
      CompanyRole.driver.toLowerCase(),
    ].contains(normalized)) {
      return CompanyAccessRole.driver;
    }
    if ([
      'passenger',
      'passageiro',
      CompanyRole.passenger.toLowerCase(),
    ].contains(normalized)) {
      return CompanyAccessRole.passenger;
    }
    return CompanyAccessRole.none;
  }

  static CompanyModel? _resolveTargetCompany({
    CompanyModel? company,
    String? companyCnpj,
  }) {
    if (company != null) return company;

    try {
      final selected =
          injector.get<CompanyViewModel>().state.selectedCompany.value;
      if (selected != null) {
        final targetCnpj = _cleanDigits(companyCnpj ?? '');
        if (targetCnpj.isEmpty || _cleanDigits(selected.cnpj) == targetCnpj) {
          return selected;
        }
      }

      final targetCnpj = _cleanDigits(companyCnpj ?? '');
      if (targetCnpj.isNotEmpty) {
        final listVm = injector.get<CompanyListViewModel>();
        for (final c in listVm.state.ownedCompanies.value) {
          if (_cleanDigits(c.cnpj) == targetCnpj) return c;
        }
        for (final c in listVm.state.memberCompanies.value) {
          if (_cleanDigits(c.cnpj) == targetCnpj) return c;
        }
      }
    } catch (_) {}

    return null;
  }

  static bool get hasValidDriverLicense {
    try {
      final cnh = injector.get<UserViewModel>().state.user.value?.driverLicense;
      return cnh != null && cnh.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Resolve o maior nível de acesso do usuário logado para uma empresa/rota.
  static CompanyAccessRole resolveRole({
    CompanyModel? company,
    String? companyCnpj,
    RouteModel? route,
  }) {
    final userIds = _currentUserIdentifiers();
    if (userIds.isEmpty) return CompanyAccessRole.none;

    final resolvedCompany = _resolveTargetCompany(
      company: company ?? route?.company,
      companyCnpj: companyCnpj ?? route?.companyCnpj,
    );
    final targetCnpj = _cleanDigits(
      companyCnpj ?? resolvedCompany?.cnpj ?? route?.companyCnpj ?? '',
    );

    // 1. Dono (CEO)
    if (resolvedCompany != null &&
        _matchesUser(resolvedCompany.ownerId, userIds)) {
      return CompanyAccessRole.owner;
    }

    try {
      final listVm = injector.get<CompanyListViewModel>();
      if (targetCnpj.isNotEmpty &&
          listVm.state.ownedCompanies.value.any(
            (c) => _cleanDigits(c.cnpj) == targetCnpj,
          )) {
        return CompanyAccessRole.owner;
      }
    } catch (_) {}

    // 2. Vínculos carregados no CompanyMemberViewModel (Gerente / Motorista / Passageiro)
    CompanyAccessRole highestLinkRole = CompanyAccessRole.none;
    try {
      final memberVm = injector.get<CompanyMemberViewModel>();
      final selectedCnpj = _cleanDigits(
        injector.get<CompanyViewModel>().state.selectedCompany.value?.cnpj ??
            '',
      );
      final isSelectedContext =
          targetCnpj.isEmpty ||
          (selectedCnpj.isNotEmpty && selectedCnpj == targetCnpj);

      if (isSelectedContext) {
        if (memberVm.state.isCurrentUserOwner.value) {
          return CompanyAccessRole.owner;
        }
        if (memberVm.state.isCurrentUserManager.value) {
          highestLinkRole = CompanyAccessRole.manager;
        }
      }

      final allLinks = <CompanyMemberModel>[
        if (memberVm.state.currentUserLink.value != null)
          memberVm.state.currentUserLink.value!,
        ...memberVm.state.userMemberships.value,
        ...memberVm.state.members.value,
      ];

      for (final link in allLinks) {
        final linkCnpj = _cleanDigits(link.companyCnpj);
        final matchesCompany = targetCnpj.isEmpty || linkCnpj == targetCnpj;
        if (!matchesCompany) continue;
        if (!_matchesUser(link.userCpf, userIds)) continue;

        final parsed = _parseRole(link.role);
        if (parsed.index > highestLinkRole.index) {
          highestLinkRole = parsed;
        }
      }
    } catch (_) {}

    if (highestLinkRole.index >= CompanyAccessRole.manager.index) {
      return highestLinkRole;
    }

    // 3. Motorista / Equipe pela empresa ou pela rota
    if (route != null && _matchesUser(route.driverId, userIds)) {
      return CompanyAccessRole.driver;
    }
    if (resolvedCompany != null &&
        resolvedCompany.memberIds.any((id) => _matchesUser(id, userIds))) {
      return CompanyAccessRole.driver;
    }

    if (highestLinkRole == CompanyAccessRole.driver) {
      return CompanyAccessRole.driver;
    }

    // 4. Passageiro da rota ou vínculo de passageiro
    if (route != null &&
        route.passengerIds.any((id) => _matchesUser(id, userIds))) {
      return CompanyAccessRole.passenger;
    }

    return highestLinkRole;
  }

  static bool isOwner({CompanyModel? company, String? companyCnpj}) {
    return resolveRole(company: company, companyCnpj: companyCnpj) ==
        CompanyAccessRole.owner;
  }

  static bool isOwnerOrManager({
    CompanyModel? company,
    String? companyCnpj,
    RouteModel? route,
  }) {
    final role = resolveRole(
      company: company,
      companyCnpj: companyCnpj,
      route: route,
    );
    return role == CompanyAccessRole.owner || role == CompanyAccessRole.manager;
  }

  static bool isCompanyStaff({
    CompanyModel? company,
    String? companyCnpj,
    RouteModel? route,
  }) {
    final role = resolveRole(
      company: company,
      companyCnpj: companyCnpj,
      route: route,
    );
    return role == CompanyAccessRole.owner ||
        role == CompanyAccessRole.manager ||
        role == CompanyAccessRole.driver;
  }

  static bool canDriveRoute({
    CompanyModel? company,
    String? companyCnpj,
    RouteModel? route,
  }) {
    return isCompanyStaff(
          company: company,
          companyCnpj: companyCnpj,
          route: route,
        ) &&
        hasValidDriverLicense;
  }

  static bool canAccessRouteOperation({
    required RouteModel route,
    CompanyModel? company,
  }) {
    final role = resolveRole(
      company: company ?? route.company,
      companyCnpj: route.companyCnpj,
      route: route,
    );
    return role != CompanyAccessRole.none;
  }

  // ==================== REDIRECT HELPERS PARA O GO_ROUTER ====================

  static String? requireOwner({
    CompanyModel? company,
    String? companyCnpj,
    String fallback = HomePaths.home,
  }) {
    return isOwner(company: company, companyCnpj: companyCnpj)
        ? null
        : fallback;
  }

  static String? requireOwnerOrManager({
    CompanyModel? company,
    String? companyCnpj,
    RouteModel? route,
    String fallback = HomePaths.home,
  }) {
    return isOwnerOrManager(
      company: company,
      companyCnpj: companyCnpj,
      route: route,
    )
        ? null
        : fallback;
  }

  static String? requireCompanyStaff({
    CompanyModel? company,
    String? companyCnpj,
    RouteModel? route,
    String fallback = HomePaths.home,
  }) {
    return isCompanyStaff(
      company: company,
      companyCnpj: companyCnpj,
      route: route,
    )
        ? null
        : fallback;
  }

  static String? requireDriverWithLicense({
    CompanyModel? company,
    String? companyCnpj,
    RouteModel? route,
    String fallback = HomePaths.home,
  }) {
    return canDriveRoute(
      company: company,
      companyCnpj: companyCnpj,
      route: route,
    )
        ? null
        : fallback;
  }

  static String? requireRouteParticipant({
    required RouteModel? route,
    CompanyModel? company,
    String fallback = HomePaths.myRoutes,
  }) {
    if (route == null) return fallback;
    return canAccessRouteOperation(route: route, company: company)
        ? null
        : fallback;
  }

  static String? requireExtraMap(
    GoRouterState state, {
    List<String> requiredKeys = const [],
    String fallback = HomePaths.home,
  }) {
    final extra = state.extra;
    if (extra is! Map<String, dynamic>) return fallback;
    for (final key in requiredKeys) {
      if (!extra.containsKey(key) || extra[key] == null) {
        return fallback;
      }
    }
    return null;
  }
}