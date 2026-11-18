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
import '../../controllers/user/user_viewmodel.dart';
import '../application/routes/my_routes_view.dart';

class JoinedRouteItem {
  final RouteModel route;
  final CompanyModel? company;
  final String roleBadge; // 'Passageiro', 'Motorista', 'Gerente' ou 'CEO'
  final bool isPassenger;
  final bool isStaff;

  const JoinedRouteItem({
    required this.route,
    required this.company,
    required this.roleBadge,
    required this.isPassenger,
    required this.isStaff,
  });
}

mixin MyRoutesMixin on State<MyRoutesView> {
  late final RouteListViewModel routeListViewModel;
  late final CompanyListViewModel companyListViewModel;
  late final CompanyViewModel companyViewModel;
  late final UserViewModel userViewModel;

  final isLoading = signal<bool>(true);
  final searchQuery = signal<String>('');
  final joinedRoutes = signal<List<JoinedRouteItem>>([]);

  final TextEditingController searchController = TextEditingController();

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _normalizeText(String input) {
    const withAccents = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
    var result = input.trim().toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  Set<String> _currentUserIdentifiers() {
    final ids = <String>{};
    final authUser = FirebaseAuth.instance.currentUser;
    final loggedUser = userViewModel.state.user.value;

    if (authUser != null) {
      if (authUser.uid.trim().isNotEmpty) ids.add(authUser.uid.trim());
      if (authUser.email != null && authUser.email!.trim().isNotEmpty) {
        ids.add(authUser.email!.trim());
        ids.add(authUser.email!.trim().toLowerCase());
      }
    }

    if (loggedUser != null) {
      if (loggedUser.uid.trim().isNotEmpty) ids.add(loggedUser.uid.trim());
      final cpf = loggedUser.cpf ?? '';
      if (cpf.trim().isNotEmpty) {
        ids.add(cpf.trim());
        ids.add(_cleanDigits(cpf));
      }
      if (loggedUser.email.trim().isNotEmpty) {
        ids.add(loggedUser.email.trim());
        ids.add(loggedUser.email.trim().toLowerCase());
      }
    }
    return ids;
  }

  bool _matchesUser(String? rawTarget, Set<String> userIds) {
    if (rawTarget == null) return false;
    final trimmed = rawTarget.trim();
    if (trimmed.isEmpty) return false;
    final cleaned = _cleanDigits(trimmed);
    return userIds.contains(trimmed) ||
        userIds.contains(trimmed.toLowerCase()) ||
        (cleaned.isNotEmpty && userIds.contains(cleaned));
  }

  List<JoinedRouteItem> get filteredJoinedRoutes {
    final query = _normalizeText(searchQuery.value);

    return joinedRoutes.value.where((item) {
      if (query.isEmpty) return true;

      final origin = _normalizeText(item.route.originName ?? '');
      final destination = _normalizeText(item.route.destinationName ?? '');
      final companyName = _normalizeText(
        item.company?.name ?? item.route.company?.name ?? '',
      );
      final routeIdStr = 'rota ${item.route.id}';

      return origin.contains(query) ||
          destination.contains(query) ||
          companyName.contains(query) ||
          routeIdStr.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    routeListViewModel = injector.get<RouteListViewModel>();
    companyListViewModel = injector.get<CompanyListViewModel>();
    companyViewModel = injector.get<CompanyViewModel>();
    userViewModel = injector.get<UserViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadMyRoutes();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    isLoading.dispose();
    searchQuery.dispose();
    joinedRoutes.dispose();
    super.dispose();
  }

  Future<void> loadMyRoutes() async {
    isLoading.value = true;

    try {
      if (userViewModel.state.user.value == null) {
        await userViewModel.commands.fetchUser();
      }

      await Future.wait([
        routeListViewModel.commands.fetchAllRoutes(),
        companyListViewModel.commands.fetchOwnedCompanies(),
        companyListViewModel.commands.fetchMemberCompanies(),
      ]);

      final userIds = _currentUserIdentifiers();

      final companiesByCnpj = <String, CompanyModel>{};
      for (final c in [
        ...companyListViewModel.state.ownedCompanies.value,
        ...companyListViewModel.state.memberCompanies.value,
        ...companyViewModel.state.companies.value,
      ]) {
        final clean = _cleanDigits(c.cnpj);
        if (clean.isNotEmpty) companiesByCnpj[clean] = c;
      }

      final staffCompanyRoles = <String, String>{};

      for (final entry in companiesByCnpj.entries) {
        final comp = entry.value;
        if (_matchesUser(comp.ownerId, userIds)) {
          staffCompanyRoles[entry.key] = 'CEO';
        } else if (comp.memberIds.any((id) => _matchesUser(id, userIds))) {
          staffCompanyRoles.putIfAbsent(entry.key, () => 'Equipe');
        }
      }

      try {
        final membersSnap = await FirebaseFirestore.instance
            .collection('company_members')
            .get();

        for (final doc in membersSnap.docs) {
          final data = doc.data();
          final memberId =
              (data['userId'] ??
                      data['cpf'] ??
                      data['cpfPessoa'] ??
                      data['email'] ??
                      '')
                  .toString();

          if (!_matchesUser(memberId, userIds)) continue;

          final rawCnpj = _cleanDigits(
            (data['companyCnpj'] ?? data['cnpjEmpresa'] ?? '').toString(),
          );
          if (rawCnpj.isEmpty) continue;

          final rawRole = (data['role'] ?? data['cargo'] ?? '')
              .toString()
              .toLowerCase();

          if ([
            'ceo',
            'owner',
            'dono',
            'proprietario',
            'proprietário',
          ].contains(rawRole)) {
            staffCompanyRoles[rawCnpj] = 'CEO';
          } else if ([
            'manager',
            'gerente',
            'admin',
            'administrador',
          ].contains(rawRole)) {
            if (staffCompanyRoles[rawCnpj] != 'CEO') {
              staffCompanyRoles[rawCnpj] = 'Gerente';
            }
          } else if (['driver', 'motorista', 'condutor'].contains(rawRole)) {
            staffCompanyRoles.putIfAbsent(rawCnpj, () => 'Motorista');
          }
        }
      } catch (_) {}

      final allRoutes = routeListViewModel.state.routes.value;

      final missingCnpjs = allRoutes
          .map((r) => _cleanDigits(r.companyCnpj))
          .where(
            (cnpj) => cnpj.isNotEmpty && !companiesByCnpj.containsKey(cnpj),
          )
          .toSet();

      if (missingCnpjs.isNotEmpty) {
        try {
          final compSnap = await FirebaseFirestore.instance
              .collection('companies')
              .get();
          for (final doc in compSnap.docs) {
            final data = doc.data();
            final cnpj = _cleanDigits((data['cnpj'] ?? doc.id).toString());
            if (cnpj.isEmpty || companiesByCnpj.containsKey(cnpj)) continue;

            final comp = CompanyModel(
              cnpj: cnpj,
              name: (data['name'] ?? data['nome'] ?? 'Empresa').toString(),
              email: (data['email'] ?? '').toString(),
              phone: (data['phone'] ?? data['telefone'] ?? '').toString(),
              ownerId: (data['ownerId'] ?? '').toString(),
              logoUrl: data['logoUrl']?.toString(),
              memberIds: (data['memberIds'] is List)
                  ? List<String>.from(
                      (data['memberIds'] as List).map((e) => e.toString()),
                    )
                  : const [],
              rating: ((data['rating'] ?? 0.0) as num).toDouble(),
              ratingCount: ((data['ratingCount'] ?? 0) as num).toInt(),
            );
            companiesByCnpj[cnpj] = comp;

            if (_matchesUser(comp.ownerId, userIds)) {
              staffCompanyRoles[cnpj] = 'CEO';
            } else if (comp.memberIds.any((id) => _matchesUser(id, userIds))) {
              staffCompanyRoles.putIfAbsent(cnpj, () => 'Motorista');
            }
          }
        } catch (_) {}
      }

      for (final route in allRoutes) {
        if (_matchesUser(route.driverId, userIds)) {
          final cnpj = _cleanDigits(route.companyCnpj);
          if (cnpj.isNotEmpty) {
            staffCompanyRoles.putIfAbsent(cnpj, () => 'Motorista');
          }
        }
      }

      final result = <JoinedRouteItem>[];

      for (final route in allRoutes) {
        final cleanCnpj = _cleanDigits(route.companyCnpj);
        final company = companiesByCnpj[cleanCnpj] ?? route.company;

        final isPassengerInRoute = route.passengerIds.any(
          (pId) => _matchesUser(pId, userIds),
        );
        final isDirectDriver = _matchesUser(route.driverId, userIds);
        final companyRole = staffCompanyRoles[cleanCnpj];
        final isCompanyStaff = companyRole != null || isDirectDriver;

        if (!isPassengerInRoute && !isCompanyStaff) continue;

        String badge = 'Passageiro';
        if (companyRole == 'CEO') {
          badge = 'CEO';
        } else if (companyRole == 'Gerente') {
          badge = 'Gerente';
        } else if (isDirectDriver || companyRole == 'Motorista') {
          badge = 'Motorista';
        } else if (companyRole != null) {
          badge = companyRole;
        }

        result.add(
          JoinedRouteItem(
            route: route,
            company: company,
            roleBadge: badge,
            isPassenger: isPassengerInRoute,
            isStaff: isCompanyStaff,
          ),
        );
      }

      joinedRoutes.value = result;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openRouteDetails(
    BuildContext context,
    JoinedRouteItem item,
  ) async {
    await context.pushNamed(
      IndigoRouteNames.routeEntered,
      extra: {
        'route': item.route,
        'company': item.company,
        'roleBadge': item.roleBadge,
      },
    );
    if (mounted) {
      await loadMyRoutes();
    }
  }
}
