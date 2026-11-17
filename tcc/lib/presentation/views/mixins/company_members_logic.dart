import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/core/di/dependency_injection.dart';
import 'package:tcc/core/routes/indigo_routes.dart';
import 'package:tcc/domain/models/company_entity.dart';
import 'package:tcc/domain/models/route_entity.dart';
import 'package:tcc/domain/models/user_entity.dart';
import 'package:tcc/presentation/controllers/company/company_list_viewmodel.dart';
import 'package:tcc/presentation/controllers/company/company_viewmodel.dart';
import 'package:tcc/presentation/controllers/route/route_list_viewmodel.dart';
import 'package:tcc/presentation/controllers/user/user_viewmodel.dart';
import 'package:tcc/presentation/views/application/configuration/company_members_view.dart';
import 'package:tcc/presentation/views/application/configuration/manage_member_role_view.dart';
import 'package:tcc/presentation/widgets/member_action_dialog.dart';

class CompanyMemberItem {
  final String id;
  final String name;
  final String photoUrl;
  final String roleCategory;
  final UserModel userModel;

  const CompanyMemberItem({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.roleCategory,
    required this.userModel,
  });
}

mixin CompanyMembersMixin on State<CompanyMembersView> {
  late final CompanyViewModel companyViewModel;
  late final CompanyListViewModel companyListViewModel;
  late final RouteListViewModel routeListViewModel;
  late final UserViewModel userViewModel;

  final TextEditingController searchController = TextEditingController();
  final Signal<String> searchQuery = signal('');
  final Signal<int> selectedFilterIndex = signal(0);
  final Signal<bool> isLoading = signal(true);
  final Signal<bool> canViewPassengers = signal(false);
  final Signal<bool> isCurrentUserOwner = signal(false);
  final Signal<bool> isCurrentUserManager = signal(false);

  final Signal<List<CompanyMemberItem>> ownersList = signal([]);
  final Signal<List<CompanyMemberItem>> managersList = signal([]);
  final Signal<List<CompanyMemberItem>> driversList = signal([]);
  final Signal<List<CompanyMemberItem>> passengersList = signal([]);

  final Map<String, Map<String, dynamic>> _userProfilesCache = {};

  CompanyModel? get targetCompany =>
      widget.company ?? companyViewModel.state.selectedCompany.value;

  String cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    companyViewModel = injector.get<CompanyViewModel>();
    companyListViewModel = injector.get<CompanyListViewModel>();
    routeListViewModel = injector.get<RouteListViewModel>();
    userViewModel = injector.get<UserViewModel>();

    if (widget.initialShowPassengers) {
      selectedFilterIndex.value = 4;
    }

    loadMembersData();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchQuery.dispose();
    selectedFilterIndex.dispose();
    isLoading.dispose();
    canViewPassengers.dispose();
    isCurrentUserOwner.dispose();
    isCurrentUserManager.dispose();
    ownersList.dispose();
    managersList.dispose();
    driversList.dispose();
    passengersList.dispose();
    super.dispose();
  }

  void handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(IndigoRouteNames.companyHome, extra: targetCompany);
    }
  }

  void openMemberProfile(BuildContext context, CompanyMemberItem item) {
    context.pushNamed(IndigoRouteNames.profile, extra: item.userModel);
  }

  Future<void> openManageMemberRole(
    BuildContext context,
    CompanyMemberItem item,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ManageMemberRoleView(
          company: targetCompany,
          memberId: item.id,
          userModel: item.userModel,
          currentRoleCategory: item.roleCategory,
          isCurrentUserOwner: isCurrentUserOwner.value,
          isCurrentUserManager: isCurrentUserManager.value,
        ),
      ),
    );

    if (updated == true && mounted) {
      await loadMembersData();
    }
  }

  Future<void> showRoleManagementSheet(
    BuildContext context,
    CompanyMemberItem item,
  ) async {
    await openManageMemberRole(context, item);
  }

  void handleMemberTap(BuildContext context, CompanyMemberItem item) {
    final canEdit = canManageMemberRole(item);

    showDialog(
      context: context,
      builder: (_) => MemberActionDialog(
        name: item.name,
        photoUrl: item.photoUrl,
        canEditRole: canEdit,
        onViewProfile: () => openMemberProfile(context, item),
        onEditRole: () => openManageMemberRole(context, item),
      ),
    );
  }

  String _normalizeText(String input) {
    const withAccents = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
    const withoutAccents = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
    var result = input.trim().toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
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

  bool _matchesIdentifier(String targetId, Set<String> currentUserIds) {
    final trimmed = targetId.trim();
    if (trimmed.isEmpty) return false;
    final cleaned = cleanDigits(trimmed);

    return currentUserIds.contains(trimmed) ||
        currentUserIds.contains(trimmed.toLowerCase()) ||
        (cleaned.isNotEmpty && currentUserIds.contains(cleaned));
  }

  String _classifyRole(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    if (role == 'ceo' ||
        role == 'owner' ||
        role == 'dono' ||
        role == 'proprietario' ||
        role == 'proprietário') {
      return 'owner';
    }
    if (role == 'manager' ||
        role == 'gerente' ||
        role == 'admin' ||
        role == 'administrador') {
      return 'manager';
    }
    if (role == 'driver' || role == 'motorista' || role == 'condutor') {
      return 'driver';
    }
    return 'passenger';
  }

  bool canManageMemberRole(CompanyMemberItem item) {
    if (item.roleCategory == 'owner') return false;

    final currentUserIds = _allCurrentUserIdentifiers();
    if (_matchesIdentifier(item.id, currentUserIds)) return false;

    if (isCurrentUserOwner.value) {
      return item.roleCategory == 'manager' ||
          item.roleCategory == 'driver' ||
          item.roleCategory == 'passenger';
    }

    if (isCurrentUserManager.value) {
      return item.roleCategory == 'driver' || item.roleCategory == 'passenger';
    }

    return false;
  }

  Future<void> loadMembersData() async {
    isLoading.value = true;

    final company = targetCompany;
    final rawCnpj = cleanDigits(company?.cnpj ?? '');
    final currentUserIds = _allCurrentUserIdentifiers();

    if (rawCnpj.isNotEmpty) {
      await routeListViewModel.commands.fetchRoutesByCompany(rawCnpj);
    } else {
      await routeListViewModel.commands.fetchAllRoutes();
    }

    final companyRoutes = _resolveCompanyRoutes(rawCnpj);

    final ownerIds = <String>{};
    final managerIds = <String>{};
    final driverIds = <String>{};
    final passengerIds = <String>{};

    if (company != null && company.ownerId.trim().isNotEmpty) {
      ownerIds.add(company.ownerId.trim());
    }

    if (rawCnpj.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('company_members')
            .where('companyCnpj', isEqualTo: rawCnpj)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final memberId =
              (data['userId'] ?? data['cpf'] ?? data['email'] ?? '')
                  .toString()
                  .trim();
          if (memberId.isEmpty) continue;

          final roleStr = (data['role'] ?? data['cargo'] ?? 'driver')
              .toString();
          final category = _classifyRole(roleStr);

          if (category == 'owner') {
            ownerIds.add(memberId);
          } else if (category == 'manager') {
            managerIds.add(memberId);
          } else if (category == 'driver') {
            driverIds.add(memberId);
          } else {
            passengerIds.add(memberId);
          }
        }
      } catch (_) {}
    }

    if (company != null) {
      for (final rawMemberId in company.memberIds) {
        final id = rawMemberId.trim();
        if (id.isEmpty) continue;
        if (!ownerIds.contains(id) &&
            !managerIds.contains(id) &&
            !driverIds.contains(id) &&
            !passengerIds.contains(id)) {
          driverIds.add(id);
        }
      }
    }

    for (final route in companyRoutes) {
      final dId = route.driverId?.trim() ?? '';
      if (dId.isNotEmpty &&
          !ownerIds.contains(dId) &&
          !managerIds.contains(dId)) {
        driverIds.add(dId);
      }

      for (final pId in route.passengerIds) {
        final cleanPId = pId.trim();
        if (cleanPId.isNotEmpty) {
          passengerIds.add(cleanPId);
        }
      }
    }

    bool loggedOwner = false;
    bool loggedManager = false;
    bool loggedDriver = false;

    if (rawCnpj.isNotEmpty &&
        companyListViewModel.state.ownedCompanies.value.any(
          (c) => cleanDigits(c.cnpj) == rawCnpj,
        )) {
      loggedOwner = true;
    }

    for (final id in ownerIds) {
      if (_matchesIdentifier(id, currentUserIds)) {
        loggedOwner = true;
        break;
      }
    }

    if (!loggedOwner) {
      for (final id in managerIds) {
        if (_matchesIdentifier(id, currentUserIds)) {
          loggedManager = true;
          break;
        }
      }
    }

    if (!loggedOwner && !loggedManager) {
      for (final id in driverIds) {
        if (_matchesIdentifier(id, currentUserIds)) {
          loggedDriver = true;
          break;
        }
      }
    }

    isCurrentUserOwner.value = loggedOwner;
    isCurrentUserManager.value = loggedManager;

    final bool userIsAuthorizedStaff =
        loggedOwner || loggedManager || loggedDriver;
    canViewPassengers.value = userIsAuthorizedStaff;

    if (!userIsAuthorizedStaff && selectedFilterIndex.value == 4) {
      selectedFilterIndex.value = 0;
    }

    final allIdsToFetch = <String>{
      ...ownerIds,
      ...managerIds,
      ...driverIds,
      if (userIsAuthorizedStaff) ...passengerIds,
    };

    await _fetchUserProfiles(allIdsToFetch);

    ownersList.value = ownerIds
        .map((id) => _buildMemberItem(id: id, roleCategory: 'owner'))
        .toList();

    managersList.value = managerIds
        .where((id) => !ownerIds.contains(id))
        .map((id) => _buildMemberItem(id: id, roleCategory: 'manager'))
        .toList();

    driversList.value = driverIds
        .where((id) => !ownerIds.contains(id) && !managerIds.contains(id))
        .map((id) => _buildMemberItem(id: id, roleCategory: 'driver'))
        .toList();

    if (userIsAuthorizedStaff) {
      passengersList.value = passengerIds
          .where(
            (id) =>
                !ownerIds.contains(id) &&
                !managerIds.contains(id) &&
                !driverIds.contains(id),
          )
          .map((id) => _buildMemberItem(id: id, roleCategory: 'passenger'))
          .toList();
    } else {
      passengersList.value = [];
    }

    if (mounted) {
      isLoading.value = false;
    }
  }

  List<RouteModel> _resolveCompanyRoutes(String targetCnpj) {
    final companyRoutes = routeListViewModel.state.companyRoutes.value;
    final allRoutes = routeListViewModel.state.routes.value;
    final source = companyRoutes.isNotEmpty ? companyRoutes : allRoutes;

    return source.where((r) {
      if (targetCnpj.isNotEmpty && cleanDigits(r.companyCnpj) != targetCnpj) {
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
          final mapData = Map<String, dynamic>.from(rawData);
          mapData['uid'] ??= doc?.id ?? id;
          _userProfilesCache[id] = mapData;
        }
      } catch (_) {}
    }
  }

  CompanyMemberItem _buildMemberItem({
    required String id,
    required String roleCategory,
  }) {
    final profile = _userProfilesCache[id.trim()] ?? <String, dynamic>{};

    final uid = (profile['uid'] ?? id.trim()).toString();
    final name =
        (profile['name'] ??
                (roleCategory == 'owner' ? 'Proprietário' : 'Usuário'))
            .toString();
    final email = (profile['email'] ?? '').toString();
    final rawCpf = (profile['cpf'] ?? cleanDigits(id)).toString().trim();
    final rawPhone = (profile['phone'] ?? '').toString().trim();
    final rawPhotoUrl = (profile['photoUrl'] ?? '').toString().trim();
    final rawDriverLicense = (profile['driverLicense'] ?? '').toString().trim();

    DateTime? birthDate;
    final rawBirthDate = profile['birthDate'];
    if (rawBirthDate is Timestamp) {
      birthDate = rawBirthDate.toDate();
    } else if (rawBirthDate is DateTime) {
      birthDate = rawBirthDate;
    } else if (rawBirthDate is String && rawBirthDate.trim().isNotEmpty) {
      birthDate = DateTime.tryParse(rawBirthDate.trim());
    }

    final boardingPoint = profile['boardingPoint'] is GeoPoint
        ? profile['boardingPoint'] as GeoPoint
        : null;

    final disembarkationPoint = profile['disembarkationPoint'] is GeoPoint
        ? profile['disembarkationPoint'] as GeoPoint
        : null;

    final resolvedUser = UserModel(
      uid: uid,
      name: name,
      email: email,
      cpf: rawCpf.isNotEmpty ? rawCpf : null,
      phone: rawPhone.isNotEmpty ? rawPhone : null,
      birthDate: birthDate,
      boardingPoint: boardingPoint,
      disembarkationPoint: disembarkationPoint,
      driverLicense: rawDriverLicense.isNotEmpty ? rawDriverLicense : null,
      photoUrl: rawPhotoUrl.isNotEmpty ? rawPhotoUrl : null,
    );

    return CompanyMemberItem(
      id: id,
      name: name,
      photoUrl: rawPhotoUrl,
      roleCategory: roleCategory,
      userModel: resolvedUser,
    );
  }

  List<CompanyMemberItem> filterItems(
    List<CompanyMemberItem> items,
    String rawQuery,
  ) {
    final q = _normalizeText(rawQuery);
    if (q.isEmpty) return items;

    return items.where((item) {
      return _normalizeText(item.name).contains(q);
    }).toList();
  }
}