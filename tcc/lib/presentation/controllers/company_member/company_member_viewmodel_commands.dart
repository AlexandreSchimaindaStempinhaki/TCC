import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/models/company_entity.dart';
import '../../../domain/models/company_member_entity.dart';
import '../../../domain/models/route_entity.dart';
import '../../../domain/models/user_entity.dart';
import '../company/company_list_viewmodel.dart';
import '../company/company_viewmodel.dart';
import '../route/route_list_viewmodel.dart';
import '../user/user_viewmodel.dart';
import 'company_member_state_viewmodel.dart';
import 'company_member_viewmodel.dart';

class CompanyMemberViewModelCommands {
  final CompanyMemberViewModel _viewModel;

  CompanyMemberViewModelCommands(this._viewModel);

  String cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String formatCpf(String cpf) {
    final digits = cleanDigits(cpf);
    if (digits.length != 11) return cpf;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
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

  String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return fallback;
  }

  Set<String> _personKeys(String rawId) {
    final keys = <String>{};
    final trimmed = rawId.trim();
    if (trimmed.isNotEmpty) {
      keys.add(trimmed.toLowerCase());
      final digits = cleanDigits(trimmed);
      if (digits.length == 11) keys.add('cpf:$digits');
    }

    final profile = _viewModel.state.userProfilesCache[trimmed];
    if (profile != null) {
      final uid = _firstNonEmpty([profile['uid']]);
      if (uid.isNotEmpty) keys.add('uid:${uid.toLowerCase()}');

      final cpfDigits = cleanDigits(_firstNonEmpty([profile['cpf']]));
      if (cpfDigits.length == 11) keys.add('cpf:$cpfDigits');

      final email = _firstNonEmpty([profile['email']]).toLowerCase();
      if (email.isNotEmpty) keys.add('email:$email');
    }

    return keys;
  }

  CompanyModel? resolveCompany(CompanyModel? widgetCompany) {
    final companyVm = injector.get<CompanyViewModel>();
    return widgetCompany ?? companyVm.state.selectedCompany.value;
  }

  Set<String> allCurrentUserIdentifiers() {
    final ids = <String>{};
    final authUser = FirebaseAuth.instance.currentUser;
    final userVm = injector.get<UserViewModel>();
    final loggedUser = userVm.state.user.value;

    if (authUser != null) {
      if (authUser.uid.trim().isNotEmpty) ids.add(authUser.uid.trim());
      final authEmail = authUser.email;
      if (authEmail != null && authEmail.trim().isNotEmpty) {
        ids.add(authEmail.trim());
        ids.add(authEmail.trim().toLowerCase());
      }
    }

    if (loggedUser != null) {
      if (loggedUser.uid.trim().isNotEmpty) ids.add(loggedUser.uid.trim());
      final cpf = loggedUser.cpf;
      if (cpf != null && cpf.trim().isNotEmpty) {
        ids.add(cpf.trim());
        ids.add(cleanDigits(cpf));
      }
      final email = loggedUser.email;
      if (email.trim().isNotEmpty) {
        ids.add(email.trim());
        ids.add(email.trim().toLowerCase());
      }
    }
    return ids;
  }

  bool matchesIdentifier(String targetId, Set<String> currentUserIds) {
    final trimmed = targetId.trim();
    if (trimmed.isEmpty) return false;
    final cleaned = cleanDigits(trimmed);
    return currentUserIds.contains(trimmed) ||
        currentUserIds.contains(trimmed.toLowerCase()) ||
        (cleaned.isNotEmpty && currentUserIds.contains(cleaned));
  }

  String _classifyRole(String rawRole) {
    final role = rawRole.trim().toLowerCase();
    if ([
      'ceo',
      'owner',
      'dono',
      'proprietario',
      'proprietário',
    ].contains(role)) {
      return 'owner';
    }
    if ([
      'manager',
      'gerente',
      'admin',
      'administrador',
      CompanyRole.admin.toLowerCase(),
    ].contains(role)) {
      return 'manager';
    }
    if ([
      'driver',
      'motorista',
      'condutor',
      CompanyRole.driver.toLowerCase(),
    ].contains(role)) {
      return 'driver';
    }
    return 'passenger';
  }

  bool canManageMemberRole(CompanyMemberItem item) {
    if (item.roleCategory == 'owner') return false;
    final currentUserIds = allCurrentUserIdentifiers();
    if (matchesIdentifier(item.id, currentUserIds)) return false;

    if (_viewModel.state.isCurrentUserOwner.value) {
      return ['manager', 'driver', 'passenger'].contains(item.roleCategory);
    }
    if (_viewModel.state.isCurrentUserManager.value) {
      return ['driver', 'passenger'].contains(item.roleCategory);
    }
    return false;
  }

  List<CompanyMemberItem> filterItems(
    List<CompanyMemberItem> items,
    String rawQuery,
  ) {
    final q = _normalizeText(rawQuery);
    if (q.isEmpty) return items;
    return items
        .where((item) => _normalizeText(item.name).contains(q))
        .toList();
  }

  Future<void> fetchCompanyMembers(String companyCnpj) async {
    _viewModel.state.clearMessage();
    try {
      final result = await _viewModel.fetchCompanyMembersCommand.execute(
        companyCnpj,
      );
      _viewModel.state.members.value = result;
    } catch (e) {
      _viewModel.state.message.value =
          'Erro ao carregar membros da empresa: $e';
    }
  }

  Future<void> fetchUserMemberships(String cpfOrUid) async {
    _viewModel.state.clearMessage();
    try {
      final result = await _viewModel.fetchUserMembershipsCommand.execute(
        cpfOrUid,
      );
      _viewModel.state.userMemberships.value = result;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao carregar seus vínculos: $e';
    }
  }

  Future<CompanyMemberModel?> loadCurrentUserRole({
    required String companyCnpj,
    required String cpfOrUid,
  }) async {
    try {
      final link = await _viewModel.getMemberLinkCommand.execute(
        companyCnpj,
        cpfOrUid,
      );
      _viewModel.state.currentUserLink.value = link;
      return link;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao verificar permissão: $e';
      return null;
    }
  }

  Future<bool> addMember({
    required String companyCnpj,
    required String userCpf,
    String role = CompanyRole.passenger,
  }) async {
    _viewModel.state.clearMessage();
    try {
      final newMember = CompanyMemberModel(
        id: '${companyCnpj}_$userCpf',
        userCpf: userCpf,
        companyCnpj: companyCnpj,
        role: role,
        joinedAt: DateTime.now(),
      );

      final created = await _viewModel.addCompanyMemberCommand.execute(
        newMember,
      );

      final currentList = _viewModel.state.members.value;
      final exists = currentList.any((m) => m.userCpf == userCpf);
      if (exists) {
        _viewModel.state.members.value = currentList
            .map((m) => m.userCpf == userCpf ? created : m)
            .toList();
      } else {
        _viewModel.state.members.value = [...currentList, created];
      }

      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao vincular membro: $e';
      return false;
    }
  }

  Future<bool> changeMemberRole({
    required String companyCnpj,
    required String userCpf,
    required String newRole,
  }) async {
    _viewModel.state.clearMessage();
    try {
      await _viewModel.changeCompanyMemberRoleCommand.execute(
        companyCnpj: companyCnpj,
        userCpf: userCpf,
        newRole: newRole,
      );

      _viewModel.state.members.value = _viewModel.state.members.value.map((m) {
        if (m.userCpf == userCpf) {
          return m.copyWith(role: newRole);
        }
        return m;
      }).toList();

      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao alterar cargo: $e';
      return false;
    }
  }

  Future<bool> removeMember({
    required String companyCnpj,
    required String userCpf,
  }) async {
    _viewModel.state.clearMessage();
    try {
      await _viewModel.removeCompanyMemberCommand.execute(
        companyCnpj: companyCnpj,
        userCpf: userCpf,
      );

      _viewModel.state.members.value = _viewModel.state.members.value
          .where((m) => m.userCpf != userCpf)
          .toList();

      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao remover membro: $e';
      return false;
    }
  }

  Future<void> loadCompanyMembersDetailed(CompanyModel? widgetCompany) async {
    _viewModel.state.isLoading.value = true;
    _viewModel.state.clearMessage();

    final routeListVm = injector.get<RouteListViewModel>();
    final companyListVm = injector.get<CompanyListViewModel>();

    final company = resolveCompany(widgetCompany);
    final rawCnpj = cleanDigits(company?.cnpj ?? '');
    final currentUserIds = allCurrentUserIdentifiers();

    if (rawCnpj.isNotEmpty) {
      await routeListVm.commands.fetchRoutesByCompany(rawCnpj);
      await fetchCompanyMembers(rawCnpj);
    } else {
      await routeListVm.commands.fetchAllRoutes();
    }

    final companyRoutes = _resolveCompanyRoutes(routeListVm, rawCnpj);

    final ownerIds = <String>{};
    final managerIds = <String>{};
    final driverIds = <String>{};
    final passengerIds = <String>{};

    if (company != null && company.ownerId.trim().isNotEmpty) {
      ownerIds.add(company.ownerId.trim());
    }

    // 1. Membros vindos da Facade/ViewModel
    for (final member in _viewModel.state.members.value) {
      final id = member.userCpf.trim();
      if (id.isEmpty) continue;
      final category = _classifyRole(member.role);
      if (category == 'owner') {
        ownerIds.add(id);
      } else if (category == 'manager') {
        managerIds.add(id);
      } else if (category == 'driver') {
        driverIds.add(id);
      } else {
        passengerIds.add(id);
      }
    }

    // 2. Fallback de leitura direta na coleção company_members (compatibilidade de campos)
    if (rawCnpj.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('company_members')
            .where('companyCnpj', isEqualTo: rawCnpj)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final memberId =
              (data['userCpf'] ??
                      data['userId'] ??
                      data['cpf'] ??
                      data['cpfPessoa'] ??
                      data['email'] ??
                      '')
                  .toString()
                  .trim();
          if (memberId.isEmpty) continue;

          final roleStr =
              (data['role'] ?? data['cargo'] ?? 'driver').toString();
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
        companyListVm.state.ownedCompanies.value.any(
          (c) => cleanDigits(c.cnpj) == rawCnpj,
        )) {
      loggedOwner = true;
    }

    for (final id in ownerIds) {
      if (matchesIdentifier(id, currentUserIds)) {
        loggedOwner = true;
        break;
      }
    }

    if (!loggedOwner) {
      for (final id in managerIds) {
        if (matchesIdentifier(id, currentUserIds)) {
          loggedManager = true;
          break;
        }
      }
    }

    if (!loggedOwner && !loggedManager) {
      for (final id in driverIds) {
        if (matchesIdentifier(id, currentUserIds)) {
          loggedDriver = true;
          break;
        }
      }
    }

    _viewModel.state.isCurrentUserOwner.value = loggedOwner;
    _viewModel.state.isCurrentUserManager.value = loggedManager;

    final userIsAuthorizedStaff = loggedOwner || loggedManager || loggedDriver;
    _viewModel.state.canViewPassengers.value = userIsAuthorizedStaff;

    if (!userIsAuthorizedStaff &&
        _viewModel.state.selectedFilterIndex.value == 4) {
      _viewModel.state.selectedFilterIndex.value = 0;
    }

    final allIdsToFetch = <String>{
      ...ownerIds,
      ...managerIds,
      ...driverIds,
      if (userIsAuthorizedStaff) ...passengerIds,
    };

    await _fetchUserProfiles(allIdsToFetch);

    // Deduplica cada pessoa pelo perfil real (CPF, UID e e-mail) mantendo apenas o cargo mais alto
    final seenPersonKeys = <String>{};

    List<CompanyMemberItem> buildUniqueRoleList(
      Set<String> ids,
      String roleCategory,
    ) {
      final result = <CompanyMemberItem>[];
      for (final id in ids) {
        final keys = _personKeys(id);
        if (keys.any(seenPersonKeys.contains)) continue;
        seenPersonKeys.addAll(keys);
        result.add(_buildMemberItem(id: id, roleCategory: roleCategory));
      }
      return result;
    }

    _viewModel.state.ownersList.value = buildUniqueRoleList(ownerIds, 'owner');
    _viewModel.state.managersList.value = buildUniqueRoleList(
      managerIds,
      'manager',
    );
    _viewModel.state.driversList.value = buildUniqueRoleList(
      driverIds,
      'driver',
    );
    _viewModel.state.passengersList.value = userIsAuthorizedStaff
        ? buildUniqueRoleList(passengerIds, 'passenger')
        : [];

    _viewModel.state.isLoading.value = false;
  }

  Future<bool> updateMemberRoleDetailed({
    required CompanyModel? widgetCompany,
    required CompanyMemberItem item,
    required String newRoleCategory,
  }) async {
    final companyVm = injector.get<CompanyViewModel>();
    final company = resolveCompany(widgetCompany);
    final rawCnpj = cleanDigits(company?.cnpj ?? '');
    if (rawCnpj.isEmpty) return false;

    _viewModel.state.isLoading.value = true;

    final mappedRole = newRoleCategory == 'manager'
        ? CompanyRole.admin
        : newRoleCategory == 'driver'
        ? CompanyRole.driver
        : CompanyRole.passenger;

    final memberId = item.id.trim();
    final cleanMemberId = cleanDigits(memberId);
    final targetCpf = (item.userModel.cpf?.trim().isNotEmpty == true)
        ? cleanDigits(item.userModel.cpf!)
        : (cleanMemberId.isNotEmpty ? cleanMemberId : memberId);

    try {
      await changeMemberRole(
        companyCnpj: rawCnpj,
        userCpf: targetCpf,
        newRole: mappedRole,
      );

      final firestore = FirebaseFirestore.instance;
      final membersRef = firestore.collection('company_members');

      final docId = '${rawCnpj}_$targetCpf';
      await membersRef.doc(docId).set({
        'companyCnpj': rawCnpj,
        'cnpjEmpresa': rawCnpj,
        'userId': memberId,
        'userCpf': targetCpf,
        'cpf': targetCpf,
        'cpfPessoa': targetCpf,
        'email': item.userModel.email,
        'role': newRoleCategory,
        'cargo': mappedRole,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (company != null) {
        final updatedMemberIds = List<String>.from(company.memberIds);
        final itemUid = item.userModel.uid.trim();
        final itemEmail = item.userModel.email.trim().toLowerCase();

        bool isSameMember(String raw) {
          final trimmed = raw.trim();
          final digits = cleanDigits(trimmed);
          return trimmed == memberId ||
              (itemUid.isNotEmpty && trimmed == itemUid) ||
              (itemEmail.isNotEmpty && trimmed.toLowerCase() == itemEmail) ||
              (targetCpf.length == 11 && digits == targetCpf) ||
              (cleanMemberId.length == 11 && digits == cleanMemberId);
        }

        if (newRoleCategory == 'manager' || newRoleCategory == 'driver') {
          if (!updatedMemberIds.any(isSameMember)) {
            updatedMemberIds.add(targetCpf.isNotEmpty ? targetCpf : memberId);
          }
        } else {
          updatedMemberIds.removeWhere(isSameMember);
        }

        try {
          await firestore.collection('companies').doc(rawCnpj).update({
            'memberIds': updatedMemberIds,
          });
          companyVm.state.setSelectedCompany(
            company.copyWith(memberIds: updatedMemberIds),
          );
        } catch (_) {}
      }

      await loadCompanyMembersDetailed(widgetCompany);
      return true;
    } catch (e) {
      _viewModel.state.message.value = 'Erro ao atualizar cargo: $e';
      _viewModel.state.isLoading.value = false;
      return false;
    }
  }

  List<RouteModel> _resolveCompanyRoutes(
    RouteListViewModel routeListVm,
    String targetCnpj,
  ) {
    final companyRoutes = routeListVm.state.companyRoutes.value;
    final allRoutes = routeListVm.state.routes.value;
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
    final cache = _viewModel.state.userProfilesCache;

    for (final rawId in userIds) {
      final id = rawId.trim();
      if (id.isEmpty || cache.containsKey(id)) continue;

      try {
        final cleanCpf = cleanDigits(id);
        final looksLikeCpf = cleanCpf.length == 11;
        DocumentSnapshot? doc;

        if (looksLikeCpf) {
          final byCpfDoc = await usersRef.doc(cleanCpf).get();
          if (byCpfDoc.exists) doc = byCpfDoc;
        }

        if (doc == null) {
          final byRawDoc = await usersRef.doc(id).get();
          if (byRawDoc.exists) doc = byRawDoc;
        }

        if (doc == null) {
          final queryByUid = await usersRef
              .where('uid', isEqualTo: id)
              .limit(1)
              .get();
          if (queryByUid.docs.isNotEmpty) doc = queryByUid.docs.first;
        }

        if (doc == null && looksLikeCpf) {
          final queryByCpf = await usersRef
              .where('cpf', isEqualTo: cleanCpf)
              .limit(1)
              .get();
          if (queryByCpf.docs.isNotEmpty) doc = queryByCpf.docs.first;
        }

        if (doc == null && looksLikeCpf) {
          final queryByFormattedCpf = await usersRef
              .where('cpf', isEqualTo: formatCpf(cleanCpf))
              .limit(1)
              .get();
          if (queryByFormattedCpf.docs.isNotEmpty) {
            doc = queryByFormattedCpf.docs.first;
          }
        }

        if (doc == null) {
          final queryByEmail = await usersRef
              .where('email', isEqualTo: id)
              .limit(1)
              .get();
          if (queryByEmail.docs.isNotEmpty) doc = queryByEmail.docs.first;
        }

        final rawData = doc?.data();
        if (rawData is Map) {
          final mapData = Map<String, dynamic>.from(rawData);
          mapData['uid'] ??= doc?.id ?? id;
          cache[id] = mapData;
        }
      } catch (_) {}
    }
  }

  CompanyMemberItem _buildMemberItem({
    required String id,
    required String roleCategory,
  }) {
    final profile =
        _viewModel.state.userProfilesCache[id.trim()] ?? <String, dynamic>{};

    final uid = _firstNonEmpty([profile['uid'], id]);
    final name = _firstNonEmpty(
      [profile['nome'], profile['name']],
      fallback: roleCategory == 'owner' ? 'Proprietário' : 'Usuário',
    );
    final email = _firstNonEmpty([profile['email']]);
    final rawCpf = _firstNonEmpty([
      profile['cpf'],
      cleanDigits(id).length == 11 ? cleanDigits(id) : '',
    ]);
    final rawPhone = _firstNonEmpty([profile['telefone'], profile['phone']]);
    final rawPhotoUrl = _firstNonEmpty([
      profile['fotoUrl'],
      profile['photoUrl'],
    ]);
    final rawDriverLicense = _firstNonEmpty([
      profile['carteiraMotorista'],
      profile['driverLicense'],
    ]);

    DateTime? birthDate;
    final rawBirthDate = profile['dataNascimento'] ?? profile['birthDate'];
    if (rawBirthDate is Timestamp) {
      birthDate = rawBirthDate.toDate();
    } else if (rawBirthDate is DateTime) {
      birthDate = rawBirthDate;
    } else if (rawBirthDate is String && rawBirthDate.trim().isNotEmpty) {
      birthDate = DateTime.tryParse(rawBirthDate.trim());
    }

    final rawBoarding = profile['pontoEmbarque'] ?? profile['boardingPoint'];
    final rawDisembarkation =
        profile['pontoDesembarque'] ?? profile['disembarkationPoint'];

    final resolvedUser = UserModel(
      uid: uid,
      name: name,
      email: email,
      cpf: rawCpf.isNotEmpty ? rawCpf : null,
      phone: rawPhone.isNotEmpty ? rawPhone : null,
      birthDate: birthDate,
      boardingPoint: rawBoarding is GeoPoint ? rawBoarding : null,
      disembarkationPoint:
          rawDisembarkation is GeoPoint ? rawDisembarkation : null,
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
}