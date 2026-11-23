import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/company_routes.dart';
import '../../../../core/routes/home_routes.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../../domain/models/user_entity.dart';
import '../../../controllers/company/company_list_viewmodel.dart';
import '../../../controllers/company/company_viewmodel.dart';
import '../../../controllers/company_member/company_member_viewmodel.dart';
import '../../../controllers/route/route_list_viewmodel.dart';
import '../../../controllers/user/user_viewmodel.dart';
import '../../application/company/company_home_view.dart';

mixin CompanyHomeMixin on State<CompanyHomeView> {
  late final CompanyViewModel companyViewModel;
  late final CompanyListViewModel companyListViewModel;
  late final CompanyMemberViewModel companyMemberViewModel;
  late final RouteListViewModel routeListViewModel;
  late final UserViewModel userViewModel;

  final Signal<bool> isInitialLoading = signal(true);
  final Signal<bool> isCompanyOwnerSignal = signal(false);
  final Signal<bool> isCompanyManagerSignal = signal(false);
  final Signal<int> totalMembersCount = signal(0);
  final Signal<bool> _isDeletingSignal = signal(false);

  bool get isDeleting => _isDeletingSignal.value;

  String cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    companyViewModel = injector.get<CompanyViewModel>();
    companyListViewModel = injector.get<CompanyListViewModel>();
    companyMemberViewModel = injector.get<CompanyMemberViewModel>();
    routeListViewModel = injector.get<RouteListViewModel>();
    userViewModel = injector.get<UserViewModel>();

    _initializeCompanyHome();
  }

  @override
  void dispose() {
    isInitialLoading.dispose();
    isCompanyOwnerSignal.dispose();
    isCompanyManagerSignal.dispose();
    totalMembersCount.dispose();
    _isDeletingSignal.dispose();
    super.dispose();
  }

  Future<void> _initializeCompanyHome() async {
    isInitialLoading.value = true;

    final initial = widget.initialCompany;
    if (initial != null) {
      companyViewModel.state.setSelectedCompany(initial);
    }

    final currentCompany =
        companyViewModel.state.selectedCompany.value ?? initial;

    await _loadCompanyRoleAndMembersCount(currentCompany);

    if (mounted) {
      isInitialLoading.value = false;
    }
  }

  Future<void> refreshCompanyData() async {
    final currentCompany =
        companyViewModel.state.selectedCompany.value ?? widget.initialCompany;
    await _loadCompanyRoleAndMembersCount(currentCompany);
  }

  Set<String> _allCurrentUserIdentifiers() {
    final ids = <String>{};
    final loggedUser = userViewModel.state.user.value;

    if (loggedUser != null) {
      if (loggedUser.uid.trim().isNotEmpty) {
        ids.add(loggedUser.uid.trim());
      }

      final cpf = loggedUser.cpf;
      if (cpf != null && cpf.trim().isNotEmpty) {
        ids.add(cpf.trim());
        final cleanCpf = cleanDigits(cpf);
        if (cleanCpf.isNotEmpty) ids.add(cleanCpf);
      }

      if (loggedUser.email.trim().isNotEmpty) {
        ids.add(loggedUser.email.trim());
        ids.add(loggedUser.email.trim().toLowerCase());
      }
    }

    return ids;
  }

  bool _matchesUser(String? rawTargetId, Set<String> currentUserIds) {
    if (rawTargetId == null) return false;
    final trimmed = rawTargetId.trim();
    if (trimmed.isEmpty) return false;
    final cleaned = cleanDigits(trimmed);

    return currentUserIds.contains(trimmed) ||
        currentUserIds.contains(trimmed.toLowerCase()) ||
        (cleaned.length == 11 && currentUserIds.contains(cleaned));
  }

  bool _matchesUserModel(UserModel? user, Set<String> currentUserIds) {
    if (user == null) return false;
    return _matchesUser(user.uid, currentUserIds) ||
        _matchesUser(user.cpf, currentUserIds) ||
        _matchesUser(user.email, currentUserIds);
  }

  Future<void> _loadCompanyRoleAndMembersCount(CompanyModel? company) async {
    isCompanyOwnerSignal.value = false;
    isCompanyManagerSignal.value = false;

    if (company == null) {
      totalMembersCount.value = 0;
      return;
    }

    final rawCnpj = cleanDigits(company.cnpj);

    try {
      await userViewModel.commands.fetchUser().timeout(
        const Duration(seconds: 6),
      );
    } catch (_) {}

    if (!mounted) return;

    bool membersLoaded = false;

    await Future.wait([
      companyMemberViewModel.commands
          .loadCompanyMembersDetailed(company)
          .timeout(const Duration(seconds: 6))
          .then((_) => membersLoaded = true)
          .catchError((_) {}),
      if (rawCnpj.isNotEmpty)
        routeListViewModel.commands
            .fetchRoutesByCompany(rawCnpj)
            .timeout(const Duration(seconds: 6))
            .catchError((_) {}),
    ]);

    if (!mounted) return;

    totalMembersCount.value = _computeTotalMembersCount(
      company,
      includeDetailedMembers: membersLoaded,
    );

    final userIds = _allCurrentUserIdentifiers();
    if (userIds.isEmpty) return;

    if (_matchesUser(company.ownerId, userIds)) {
      isCompanyOwnerSignal.value = true;
      return;
    }

    if (rawCnpj.isNotEmpty) {
      final ownedInMemory = companyListViewModel.state.ownedCompanies.value.any(
        (c) => cleanDigits(c.cnpj) == rawCnpj && _matchesUser(c.ownerId, userIds),
      );
      if (ownedInMemory) {
        isCompanyOwnerSignal.value = true;
        return;
      }
    }

    if (membersLoaded) {
      final owners = companyMemberViewModel.state.ownersList.value;
      final managers = companyMemberViewModel.state.managersList.value;

      if (owners.any((m) => _matchesUserModel(m.userModel, userIds))) {
        isCompanyOwnerSignal.value = true;
        return;
      }

      if (managers.any((m) => _matchesUserModel(m.userModel, userIds))) {
        isCompanyManagerSignal.value = true;
      }
    }
  }

  int _computeTotalMembersCount(
    CompanyModel company, {
    required bool includeDetailedMembers,
  }) {
    final aliasToPerson = <String, int>{};
    int nextPersonId = 0;

    List<String> variantsForRaw(String? raw) {
      if (raw == null) return const [];
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const [];
      final lower = trimmed.toLowerCase();
      final digits = cleanDigits(trimmed);
      return <String>{
        trimmed,
        lower,
        if (digits.length == 11) digits,
      }.toList();
    }

    void registerPersonAliases(Iterable<String?> rawValues) {
      final allVariants = <String>{};
      for (final raw in rawValues) {
        allVariants.addAll(variantsForRaw(raw));
      }
      if (allVariants.isEmpty) return;

      final matchedIds = <int>{};
      for (final v in allVariants) {
        final found = aliasToPerson[v];
        if (found != null) matchedIds.add(found);
      }

      final int personId;
      if (matchedIds.isEmpty) {
        personId = nextPersonId++;
      } else {
        personId = matchedIds.first;
        if (matchedIds.length > 1) {
          for (final entry in aliasToPerson.entries.toList()) {
            if (matchedIds.contains(entry.value)) {
              aliasToPerson[entry.key] = personId;
            }
          }
        }
      }

      for (final v in allVariants) {
        aliasToPerson[v] = personId;
      }
    }

    if (includeDetailedMembers) {
      final detailedMembers = [
        ...companyMemberViewModel.state.ownersList.value,
        ...companyMemberViewModel.state.managersList.value,
        ...companyMemberViewModel.state.driversList.value,
        ...companyMemberViewModel.state.passengersList.value,
      ];

      for (final member in detailedMembers) {
        final u = member.userModel;
        if (u != null) {
          registerPersonAliases([u.uid, u.cpf, u.email]);
        } else if (member.name.trim().isNotEmpty) {
          registerPersonAliases(['name:${member.name.trim().toLowerCase()}']);
        }
      }
    }

    registerPersonAliases([company.ownerId]);
    for (final memberId in company.memberIds) {
      registerPersonAliases([memberId]);
    }

    final rawCnpj = cleanDigits(company.cnpj);
    final companyRoutes = routeListViewModel.state.companyRoutes.value.where(
      (r) => cleanDigits(r.companyCnpj) == rawCnpj,
    );

    for (final route in companyRoutes) {
      if (route.driverId != null && route.driverId!.trim().isNotEmpty) {
        registerPersonAliases([route.driverId]);
      }
      for (final passengerId in route.passengerIds) {
        registerPersonAliases([passengerId]);
      }
    }

    return aliasToPerson.values.toSet().length;
  }

  bool isCompanyOwner(CompanyModel? company) {
    final ownerSignalVal = isCompanyOwnerSignal.value;
    if (company == null) return false;

    final userIds = _allCurrentUserIdentifiers();
    if (userIds.isEmpty) return false;

    if (_matchesUser(company.ownerId, userIds)) {
      return true;
    }

    return ownerSignalVal;
  }

  bool canManageCompanyRoutes(CompanyModel? company) {
    final managerSignalVal = isCompanyManagerSignal.value;
    if (company == null) return false;

    return isCompanyOwner(company) || managerSignalVal;
  }

  String formatCnpj(String cnpj) {
    final digits = cleanDigits(cnpj);
    if (digits.length != 14) return cnpj;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12, 14)}';
  }

  String formatPhone(String phone) {
    final digits = cleanDigits(phone);
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6, 10)}';
    }
    return phone;
  }

  Future<void> copyToClipboard(
    BuildContext context,
    String label,
    String value,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$label copiado para a área de transferência!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$feature estará disponível em breve!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(HomeRouteNames.linkedCompanies);
    }
  }

  Future<void> openCreateRoute(
    BuildContext context,
    CompanyModel company,
  ) async {
    if (!canManageCompanyRoutes(company)) return;

    await context.pushNamed(
      CompanyRouteNames.createRoute,
      extra: company,
    );
    if (mounted) {
      await refreshCompanyData();
    }
  }

  Future<void> openEditCompany(CompanyModel company) async {
    if (!isCompanyOwner(company)) return;

    await context.pushNamed(
      CompanyRouteNames.createCompany,
      extra: company,
    );
    if (mounted) {
      await refreshCompanyData();
    }
  }

  Future<void> confirmAndDeleteCompany(
    BuildContext context,
    CompanyModel company,
  ) async {
    if (!isCompanyOwner(company)) return;

    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
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
            Expanded(child: Text('Excluir Empresa?')),
          ],
        ),
        content: Text(
          'Esta ação é permanente e excluirá a empresa "${company.name}" e seus dados vinculados. Deseja confirmar?',
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

    if (confirmed != true || !context.mounted) return;

    try {
      _isDeletingSignal.value = true;
      final rawCnpj = cleanDigits(company.cnpj);

      await companyViewModel.commands.deleteCompany(rawCnpj);

      if (!context.mounted) return;
      handleBack(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir empresa: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        _isDeletingSignal.value = false;
      }
    }
  }
}