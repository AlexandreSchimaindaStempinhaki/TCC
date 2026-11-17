import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/routes/indigo_routes.dart';
import '../../../domain/models/company_entity.dart';
import '../../controllers/company/company_list_viewmodel.dart';
import '../../controllers/company/company_viewmodel.dart';
import '../../controllers/user/user_viewmodel.dart';
import '../application/configuration/company_home_view.dart';
import '../application/configuration/create_route_view.dart';

mixin CompanyHomeMixin on State<CompanyHomeView> {
  late final CompanyViewModel companyViewModel;
  late final CompanyListViewModel companyListViewModel;
  late final UserViewModel userViewModel;

  final Signal<bool> isInitialLoading = signal(true);
  final Signal<bool> isCompanyOwnerSignal = signal(false);
  final Signal<bool> isCompanyManagerSignal = signal(false);
  final Signal<bool> _isDeletingSignal = signal(false);

  bool get isDeleting => _isDeletingSignal.value;

  String cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    companyViewModel = injector.get<CompanyViewModel>();
    companyListViewModel = injector.get<CompanyListViewModel>();
    userViewModel = injector.get<UserViewModel>();

    _initializeCompanyHome();
  }

  @override
  void dispose() {
    isInitialLoading.dispose();
    isCompanyOwnerSignal.dispose();
    isCompanyManagerSignal.dispose();
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

    await _evaluateUserRoleInCompany(currentCompany);

    if (mounted) {
      isInitialLoading.value = false;
    }
  }

  Set<String> _allCurrentUserIdentifiers() {
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

  bool _matchesUser(String rawTargetId, Set<String> currentUserIds) {
    final trimmed = rawTargetId.trim();
    if (trimmed.isEmpty) return false;
    final cleaned = cleanDigits(trimmed);

    return currentUserIds.contains(trimmed) ||
        currentUserIds.contains(trimmed.toLowerCase()) ||
        (cleaned.isNotEmpty && currentUserIds.contains(cleaned));
  }

  bool _isOwnerRoleName(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    return role == 'ceo' ||
        role == 'owner' ||
        role == 'dono' ||
        role == 'proprietario' ||
        role == 'proprietário';
  }

  bool _isManagerRoleName(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    return role == 'manager' ||
        role == 'gerente' ||
        role == 'admin' ||
        role == 'administrador';
  }

  Future<void> _evaluateUserRoleInCompany(CompanyModel? company) async {
    isCompanyOwnerSignal.value = false;
    isCompanyManagerSignal.value = false;

    if (company == null) return;

    final userIds = _allCurrentUserIdentifiers();
    if (userIds.isEmpty) return;

    final rawCnpj = cleanDigits(company.cnpj);

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

    if (rawCnpj.isEmpty) return;

    try {
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(rawCnpj)
          .get();

      final companyData = companyDoc.data();
      if (companyData != null) {
        final dbOwnerId = (companyData['ownerId'] ?? '').toString();
        if (_matchesUser(dbOwnerId, userIds)) {
          if (mounted) isCompanyOwnerSignal.value = true;
          return;
        }
      }

      final membersSnapshot = await FirebaseFirestore.instance
          .collection('company_members')
          .where('companyCnpj', isEqualTo: rawCnpj)
          .get();

      for (final doc in membersSnapshot.docs) {
        final data = doc.data();
        final memberUserId =
            (data['userId'] ?? data['cpf'] ?? data['email'] ?? '')
                .toString()
                .trim();
        final role = (data['role'] ?? data['cargo'] ?? '').toString();

        if (!_matchesUser(memberUserId, userIds)) continue;

        if (_isOwnerRoleName(role)) {
          if (mounted) isCompanyOwnerSignal.value = true;
          return;
        }

        if (_isManagerRoleName(role)) {
          if (mounted) isCompanyManagerSignal.value = true;
          return;
        }
      }
    } catch (_) {}
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
      context.goNamed(IndigoRouteNames.myCompanies);
    }
  }

  Future<void> openCreateRoute(
    BuildContext context,
    CompanyModel company,
  ) async {
    if (!canManageCompanyRoutes(company)) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateRouteView(company: company),
      ),
    );
  }

  Future<void> openEditCompany(CompanyModel company) async {
    if (!canManageCompanyRoutes(company)) return;

    await context.pushNamed(
      IndigoRouteNames.createCompany,
      extra: company,
    );
    if (mounted) {
      final updated = companyViewModel.state.selectedCompany.value ?? company;
      await _evaluateUserRoleInCompany(updated);
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

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(rawCnpj)
          .delete();

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