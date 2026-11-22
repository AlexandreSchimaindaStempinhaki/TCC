import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tcc/data/services/firestore_cascade_delete_helper.dart';

import '../../../domain/models/company_member_entity.dart';
import '../../../domain/models/user_entity.dart';
import 'i_company_member_service.dart';

class CompanyMemberServiceImpl implements ICompanyMemberService {
  final FirebaseFirestore _firestore;

  CompanyMemberServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _linksCollection =>
      _firestore.collection('vinculos_empresa');

  CollectionReference get _usersCollection => _firestore.collection('users');

  CollectionReference get _companiesCollection =>
      _firestore.collection('companies');

  // Converte qualquer retorno de doc.data() (mesmo Object?) com segurança para Map<String, dynamic>
  Map<String, dynamic>? _asMap(Object? rawData) {
    if (rawData == null) return null;
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    return null;
  }

  // Instancia o UserModel adaptando caso seu fromMap receba (map, id) ou apenas (map)
  UserModel _parseUserModel(Map<String, dynamic> data, String docId) {
    final dynamic parser = UserModel.fromMap;
    try {
      return parser(data, docId) as UserModel;
    } on NoSuchMethodError {
      return parser(data) as UserModel;
    }
  }

  String _cleanDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  String _buildDocId(String cnpj, String cpfOrUid) {
    final cleanCnpj = _cleanDigits(cnpj);
    final cleanUser = _cleanDigits(cpfOrUid).isNotEmpty
        ? _cleanDigits(cpfOrUid)
        : cpfOrUid.trim();
    return '${cleanCnpj}_$cleanUser';
  }

  Future<UserModel?> _fetchUserProfile(String cpfOrUid) async {
    try {
      // 1. Busca direta pelo ID do documento
      final directDoc = await _usersCollection.doc(cpfOrUid).get();
      final directData = _asMap(directDoc.data());
      if (directDoc.exists && directData != null) {
        return _parseUserModel(directData, directDoc.id);
      }

      // 2. Busca pelo campo 'cpf'
      final byCpf = await _usersCollection
          .where('cpf', isEqualTo: cpfOrUid)
          .limit(1)
          .get();
      if (byCpf.docs.isNotEmpty) {
        final doc = byCpf.docs.first;
        final docData = _asMap(doc.data());
        if (docData != null) {
          return _parseUserModel(docData, doc.id);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _syncCompanyMemberArray({
    required String companyCnpj,
    required String userCpf,
    required bool isAdding,
  }) async {
    final cleanCnpj = _cleanDigits(companyCnpj);
    final docRef = _companiesCollection.doc(cleanCnpj);
    final snapshot = await docRef.get();

    final updateData = <String, dynamic>{
      'listaIdMembros': isAdding
          ? FieldValue.arrayUnion([userCpf])
          : FieldValue.arrayRemove([userCpf]),
      'memberIds': isAdding
          ? FieldValue.arrayUnion([userCpf])
          : FieldValue.arrayRemove([userCpf]),
    };

    if (snapshot.exists) {
      await docRef.update(updateData);
      return;
    }

    final query = await _companiesCollection
        .where('cnpj', isEqualTo: companyCnpj)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update(updateData);
    }
  }

  @override
  Future<List<CompanyMemberModel>> fetchCompanyMembers(
    String companyCnpj,
  ) async {
    final cleanCnpj = _cleanDigits(companyCnpj);
    final targets = {companyCnpj, cleanCnpj}.where((e) => e.isNotEmpty).toList();
    if (targets.isEmpty) return [];

    final results = await Future.wait([
      _linksCollection.where('companyCnpj', whereIn: targets).get(),
      _linksCollection.where('cnpj_empresa', whereIn: targets).get(),
    ]);

    final docsById = <String, QueryDocumentSnapshot>{};
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        docsById[doc.id] = doc;
      }
    }

    final List<CompanyMemberModel> members = [];

    for (final doc in docsById.values) {
      final data = _asMap(doc.data());
      if (data == null) continue;

      final userCpf =
          (data['userCpf'] ?? data['cpf_pessoa']) as String? ?? '';
      final userProfile = userCpf.isNotEmpty
          ? await _fetchUserProfile(userCpf)
          : null;

      members.add(
        CompanyMemberModel.fromMap(
          data,
          documentId: doc.id,
          user: userProfile,
        ),
      );
    }

    return members;
  }

  @override
  Future<List<CompanyMemberModel>> fetchUserMemberships(String cpfOrUid) async {
    final results = await Future.wait([
      _linksCollection.where('userCpf', isEqualTo: cpfOrUid).get(),
      _linksCollection.where('cpf_pessoa', isEqualTo: cpfOrUid).get(),
    ]);

    final docsById = <String, QueryDocumentSnapshot>{};
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        docsById[doc.id] = doc;
      }
    }

    final List<CompanyMemberModel> memberships = [];

    for (final doc in docsById.values) {
      final data = _asMap(doc.data());
      if (data == null) continue;

      memberships.add(CompanyMemberModel.fromMap(data, documentId: doc.id));
    }

    return memberships;
  }

  @override
  Future<CompanyMemberModel?> getMemberLink(
    String companyCnpj,
    String cpfOrUid,
  ) async {
    final docId = _buildDocId(companyCnpj, cpfOrUid);
    final doc = await _linksCollection.doc(docId).get();
    final directData = _asMap(doc.data());

    if (doc.exists && directData != null) {
      final userProfile = await _fetchUserProfile(cpfOrUid);
      return CompanyMemberModel.fromMap(
        directData,
        documentId: doc.id,
        user: userProfile,
      );
    }

    var query = await _linksCollection
        .where('companyCnpj', isEqualTo: companyCnpj)
        .where('userCpf', isEqualTo: cpfOrUid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      query = await _linksCollection
          .where('cnpj_empresa', isEqualTo: companyCnpj)
          .where('cpf_pessoa', isEqualTo: cpfOrUid)
          .limit(1)
          .get();
    }

    if (query.docs.isNotEmpty) {
      final found = query.docs.first;
      final foundData = _asMap(found.data());
      if (foundData != null) {
        final userProfile = await _fetchUserProfile(cpfOrUid);
        return CompanyMemberModel.fromMap(
          foundData,
          documentId: found.id,
          user: userProfile,
        );
      }
    }

    return null;
  }

  @override
  Future<CompanyMemberModel> addMember(CompanyMemberModel member) async {
    final docId = _buildDocId(member.companyCnpj, member.userCpf);
    final modelToSave = member.copyWith(id: docId);

    await _linksCollection.doc(docId).set(modelToSave.toMap());

    if (member.role != CompanyRole.pending) {
      await _syncCompanyMemberArray(
        companyCnpj: member.companyCnpj,
        userCpf: member.userCpf,
        isAdding: true,
      );
    }

    final userProfile = await _fetchUserProfile(member.userCpf);
    return modelToSave.copyWith(user: userProfile);
  }

  @override
  Future<void> updateMemberRole({
    required String companyCnpj,
    required String userCpf,
    required String newRole,
  }) async {
    final docId = _buildDocId(companyCnpj, userCpf);
    final docRef = _linksCollection.doc(docId);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({'role': newRole});
    } else {
      var query = await _linksCollection
          .where('companyCnpj', isEqualTo: companyCnpj)
          .where('userCpf', isEqualTo: userCpf)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        query = await _linksCollection
            .where('cnpj_empresa', isEqualTo: companyCnpj)
            .where('cpf_pessoa', isEqualTo: userCpf)
            .limit(1)
            .get();
      }

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'role': newRole});
      } else {
        throw Exception('Vínculo do membro não encontrado.');
      }
    }

    if (newRole != CompanyRole.pending) {
      await _syncCompanyMemberArray(
        companyCnpj: companyCnpj,
        userCpf: userCpf,
        isAdding: true,
      );
    }
  }

  @override
  Future<void> removeMember({
    required String companyCnpj,
    required String userCpf,
  }) async {
    final cascade = FirestoreCascadeDeleteHelper(_firestore);
    await cascade.removeCompanyMember(
      cnpjEmpresa: companyCnpj,
      cpfPessoa: userCpf,
    );
  }
}