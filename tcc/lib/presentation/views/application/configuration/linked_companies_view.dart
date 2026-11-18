import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tcc/presentation/widgets/animated_three_dots.dart';
import 'package:tcc/presentation/widgets/linked_company_card.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routes/indigo_routes.dart';
import '../../../../domain/models/company_entity.dart';
import '../../../controllers/company/company_viewmodel.dart';
import '../../../controllers/user/user_viewmodel.dart';

class LinkedCompanyItem {
  final CompanyModel company;
  final String role;

  const LinkedCompanyItem({
    required this.company,
    required this.role,
  });
}

class LinkedCompaniesView extends StatefulWidget {
  const LinkedCompaniesView({super.key});

  @override
  State<LinkedCompaniesView> createState() => _LinkedCompaniesViewState();
}

class _LinkedCompaniesViewState extends State<LinkedCompaniesView> {
  late final UserViewModel _userViewModel;
  late final CompanyViewModel _companyViewModel;

  final _isLoading = signal<bool>(true);
  final _linkedItems = signal<List<LinkedCompanyItem>>([]);

  @override
  void initState() {
    super.initState();
    _userViewModel = injector.get<UserViewModel>();
    _companyViewModel = injector.get<CompanyViewModel>();
    _loadLinkedCompanies();
  }

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _normalizeRoleLabel(String rawRole) {
    final lower = rawRole.trim().toLowerCase();
    if (lower.contains('ceo') ||
        lower.contains('dono') ||
        lower.contains('propriet') ||
        lower.contains('owner')) {
      return 'CEO';
    }
    if (lower.contains('gerente') ||
        lower.contains('admin') ||
        lower.contains('gestor') ||
        lower.contains('manager')) {
      return 'Gerente';
    }
    if (lower.contains('motorista') || lower.contains('driver')) {
      return 'Motorista';
    }
    return 'Passageiro';
  }

  int _rolePriority(String role) {
    switch (role) {
      case 'CEO':
        return 4;
      case 'Gerente':
        return 3;
      case 'Motorista':
        return 2;
      default:
        return 1; // Passageiro
    }
  }

  void _openCompanyHome(CompanyModel company) {
    // 1. Define a empresa selecionada no estado global da CompanyViewModel
    _companyViewModel.state.setSelectedCompany(company);

    // 2. Navega para a home da empresa (passando company no extra caso a rota utilize)
    context.pushNamed(
      IndigoRouteNames.companyHome,
      extra: company,
    );
  }

  Future<void> _loadLinkedCompanies() async {
    _isLoading.value = true;

    try {
      final firestore = FirebaseFirestore.instance;
      final authUser = FirebaseAuth.instance.currentUser;
      final authUid = authUser?.uid ?? '';
      final authEmail = authUser?.email ?? '';

      if (_userViewModel.state.user.value == null) {
        await _userViewModel.commands.fetchUser();
      }
      final currentUser = _userViewModel.state.user.value;

      final candidateStrings = <String>{};
      final candidateDigits = <String>{};

      void addCandidate(dynamic raw) {
        if (raw == null) return;
        final str = raw.toString().trim();
        if (str.isEmpty) return;
        candidateStrings.add(str.toLowerCase());
        final digits = _cleanDigits(str);
        if (digits.length >= 8) {
          candidateDigits.add(digits);
          candidateStrings.add(digits);
        }
      }

      addCandidate(authUid);
      addCandidate(authEmail);
      addCandidate(currentUser?.uid);
      addCandidate(currentUser?.cpf);
      addCandidate(currentUser?.email);
      addCandidate(currentUser?.name);

      final usersSnap = await firestore.collection('users').get();
      for (final uDoc in usersSnap.docs) {
        final uData = uDoc.data();
        final docUid = (uData['uid'] ?? '').toString().trim();
        final docEmail = (uData['email'] ?? '').toString().trim().toLowerCase();
        final docCpf = (uData['cpf'] ?? '').toString().trim();

        if (uDoc.id == authUid ||
            (authUid.isNotEmpty && docUid == authUid) ||
            (authEmail.isNotEmpty && docEmail == authEmail.toLowerCase()) ||
            (currentUser?.cpf != null &&
                _cleanDigits(docCpf).isNotEmpty &&
                _cleanDigits(docCpf) == _cleanDigits(currentUser!.cpf!))) {
          addCandidate(uDoc.id);
          addCandidate(docUid);
          addCandidate(docCpf);
          addCandidate(docEmail);
        }
      }

      bool matchesCurrentUser(dynamic value) {
        if (value == null) return false;
        if (value is Map) {
          return matchesCurrentUser(
            value['uid'] ??
                value['userId'] ??
                value['id'] ??
                value['cpf'] ??
                value['cpf_pessoa'] ??
                value['cpfPessoa'] ??
                value['email'],
          );
        }
        final str = value.toString().trim();
        if (str.isEmpty) return false;
        if (candidateStrings.contains(str.toLowerCase())) return true;

        final digits = _cleanDigits(str);
        if (digits.length >= 8 && candidateDigits.contains(digits)) {
          return true;
        }
        for (final token in candidateDigits) {
          if (token.length >= 9 && digits.contains(token)) return true;
        }
        for (final token in candidateStrings) {
          if (token.length >= 10 && str.toLowerCase().contains(token)) {
            return true;
          }
        }
        return false;
      }

      final roleByCnpj = <String, String>{};

      void registerRoleForCnpj(dynamic rawCnpj, String role) {
        if (rawCnpj == null) return;
        final clean = _cleanDigits(rawCnpj.toString());
        final key = clean.isNotEmpty ? clean : rawCnpj.toString().trim();
        if (key.isEmpty) return;

        final existing = roleByCnpj[key];
        if (existing == null || _rolePriority(role) > _rolePriority(existing)) {
          roleByCnpj[key] = role;
        }
      }

      void inspectMemberMap(
        Map<String, dynamic> map, {
        String? docId,
        String? fallbackCnpj,
      }) {
        final personField =
            map['cpf_pessoa'] ??
            map['cpfPessoa'] ??
            map['userId'] ??
            map['uid'] ??
            map['cpf'] ??
            map['id_pessoa'] ??
            map['memberId'] ??
            map['email'] ??
            map['user'];

        final docParts = (docId ?? '').split('_');
        final suffixId =
            docParts.length > 1 ? docParts.sublist(1).join('_') : (docId ?? '');

        if (matchesCurrentUser(personField) ||
            matchesCurrentUser(suffixId) ||
            matchesCurrentUser(docId)) {
          final rawCnpj =
              map['cnpj_empresa'] ??
              map['cnpjEmpresa'] ??
              map['companyCnpj'] ??
              map['cnpj'] ??
              fallbackCnpj ??
              docParts.first;

          final rawCargo = (map['cargo'] ??
                  map['role'] ??
                  map['funcao'] ??
                  map['type'] ??
                  map['status'] ??
                  'Passageiro')
              .toString();

          final normalizedRole = _normalizeRoleLabel(rawCargo);
          registerRoleForCnpj(rawCnpj, normalizedRole);
        }
      }

      for (final colName in [
        'company_members',
        'vinculo_empresa',
        'vinculos_empresa',
        'members',
      ]) {
        try {
          final snap = await firestore.collection(colName).get();
          for (final doc in snap.docs) {
            final rawData = doc.data();
            if (rawData is Map) {
              inspectMemberMap(
                Map<String, dynamic>.from(rawData),
                docId: doc.id,
              );
            }
          }
        } catch (_) {}
      }

      final routesSnap = await firestore.collection('routes').get();
      for (final doc in routesSnap.docs) {
        final rawData = doc.data();
        if (rawData is! Map) continue;
        final map = Map<String, dynamic>.from(rawData);

        final cnpj =
            map['companyCnpj'] ?? map['cnpj_empresa'] ?? map['cnpjEmpresa'];
        final driver = map['driverId'] ?? map['cpfMotorista'];
        final passengers =
            (map['passengerIds'] ?? map['listaIdPassageiros']) as List? ?? [];
        final confirmed =
            (map['confirmedPassengerIds'] ?? map['listaIdConfirmados'])
                as List? ??
            [];

        if (matchesCurrentUser(driver)) {
          registerRoleForCnpj(cnpj, 'Motorista');
        } else if (passengers.any(matchesCurrentUser) ||
            confirmed.any(matchesCurrentUser)) {
          registerRoleForCnpj(cnpj, 'Passageiro');
        }
      }

      final companiesSnap = await firestore.collection('companies').get();
      final items = <LinkedCompanyItem>[];

      for (final doc in companiesSnap.docs) {
        final rawData = doc.data();
        if (rawData is! Map) continue;
        final map = Map<String, dynamic>.from(rawData);
        final company = CompanyModel.fromMap(map, doc.id);

        final cleanCnpj = _cleanDigits(company.cnpj);
        final cleanDocId = _cleanDigits(doc.id);
        final key = cleanCnpj.isNotEmpty
            ? cleanCnpj
            : (cleanDocId.isNotEmpty ? cleanDocId : doc.id);

        final managersList =
            (map['managerIds'] ??
                    map['adminIds'] ??
                    map['gerentes'] ??
                    map['admins'] ??
                    map['managers'])
                as List? ??
            [];
        if (managersList.any(matchesCurrentUser)) {
          registerRoleForCnpj(key, 'Gerente');
        }

        final driversList =
            (map['driverIds'] ?? map['motoristas'] ?? map['drivers'])
                as List? ??
            [];
        if (driversList.any(matchesCurrentUser)) {
          registerRoleForCnpj(key, 'Motorista');
        }

        final embeddedRoles =
            map['memberRoles'] ?? map['roles'] ?? map['cargos'] ?? map['members'];
        if (embeddedRoles is Map) {
          embeddedRoles.forEach((k, v) {
            if (matchesCurrentUser(k)) {
              registerRoleForCnpj(key, _normalizeRoleLabel(v.toString()));
            } else if (v is Map) {
              inspectMemberMap(
                Map<String, dynamic>.from(v),
                docId: k.toString(),
                fallbackCnpj: key,
              );
            }
          });
        } else if (embeddedRoles is List) {
          for (final item in embeddedRoles) {
            if (item is Map) {
              inspectMemberMap(
                Map<String, dynamic>.from(item),
                fallbackCnpj: key,
              );
            }
          }
        }

        for (final subCol in ['members', 'company_members']) {
          try {
            final subSnap = await doc.reference.collection(subCol).get();
            for (final subDoc in subSnap.docs) {
              inspectMemberMap(
                Map<String, dynamic>.from(subDoc.data()),
                docId: subDoc.id,
                fallbackCnpj: key,
              );
            }
          } catch (_) {}
        }

        final isOwner = matchesCurrentUser(company.ownerId);
        final inMemberIds = company.memberIds.any(matchesCurrentUser);
        final roleFromLinks =
            roleByCnpj[key] ??
            roleByCnpj[company.cnpj] ??
            roleByCnpj[doc.id];

        if (isOwner) {
          items.add(LinkedCompanyItem(company: company, role: 'CEO'));
        } else if (roleFromLinks != null) {
          items.add(LinkedCompanyItem(company: company, role: roleFromLinks));
        } else if (inMemberIds) {
          items.add(LinkedCompanyItem(company: company, role: 'Passageiro'));
        }
      }

      items.sort(
        (a, b) => _rolePriority(b.role).compareTo(_rolePriority(a.role)),
      );

      _linkedItems.value = items;
    } catch (e) {
      debugPrint('Erro ao carregar empresas vinculadas: $e');
    } finally {
      if (mounted) {
        _isLoading.value = false;
      }
    }
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _linkedItems.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Empresas Vinculadas',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Watch((context) {
        if (_isLoading.value) {
          return Center(
            child: AnimatedThreeDots(color: colorScheme.onSurface),
          );
        }

        final items = _linkedItems.value;

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.domain_disabled_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.45),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma empresa vinculada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quando você entrar em uma rota ou criar uma empresa, ela aparecerá aqui com o seu respectivo cargo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadLinkedCompanies,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return LinkedCompanyCard(
                company: item.company,
                role: item.role,
                onTap: () => _openCompanyHome(item.company),
              );
            },
          ),
        );
      }),
    );
  }
}