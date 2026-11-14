import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../domain/models/company_entity.dart';
import 'i_company_firebase_service.dart';

final class CompanyRemoteServiceImpl implements ICompanyRemoteService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String cloudName = 'db37erprw';
  final String uploadPreset = 'tcc_pics';

  CompanyRemoteServiceImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String get _currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Nenhum usuário autenticado no Firebase Auth.');
    }
    return uid;
  }

  CollectionReference get _companiesRef => _firestore.collection('companies');

  @override
  Future<void> createCompany(CompanyModel company) async {
    try {
      final uid = _currentUid;
      final cleanCnpj = company.cnpj.replaceAll(RegExp(r'\D'), '');

      final docRef = _companiesRef.doc(cleanCnpj);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        throw Exception('Já existe uma empresa cadastrada com este CNPJ.');
      }

      final companyToSave = company.copyWith(
        cnpj: cleanCnpj,
        ownerId: uid,
        memberIds: {uid, ...company.memberIds}.toList(),
      );

      await docRef.set(companyToSave.toMap());
    } catch (e) {
      throw Exception('Erro ao criar empresa: $e');
    }
  }

  @override
  Future<List<CompanyModel>> fetchCompaniesByOwner([String? ownerId]) async {
    try {
      final targetOwnerId = (ownerId != null && ownerId.isNotEmpty)
          ? ownerId
          : _currentUid;

      final snapshot = await _companiesRef
          .where('ownerId', isEqualTo: targetOwnerId)
          .get();

      return snapshot.docs
          .map(
            (doc) => CompanyModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar empresas do proprietário: $e');
    }
  }

  @override
  Future<List<CompanyModel>> fetchCompaniesByMember([String? memberId]) async {
    try {
      final targetMemberId = (memberId != null && memberId.isNotEmpty)
          ? memberId
          : _currentUid;

      final snapshot = await _companiesRef
          .where('memberIds', arrayContains: targetMemberId)
          .get();

      return snapshot.docs
          .map(
            (doc) => CompanyModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar empresas do membro: $e');
    }
  }

  @override
  Future<void> updateCompany(CompanyModel company) async {
    try {
      final cleanCnpj = company.cnpj.replaceAll(RegExp(r'\D'), '');
      await _companiesRef
          .doc(cleanCnpj)
          .set(company.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Erro ao atualizar empresa: $e');
    }
  }

  @override
  Future<String> uploadCompanyLogo(String cnpj, File imageFile) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonMap = jsonDecode(responseData);
      final String secureUrl = jsonMap['secure_url'];

      await _companiesRef.doc(cleanCnpj).update({'logoUrl': secureUrl});

      return secureUrl;
    } else {
      throw Exception(
        'Falha ao fazer upload da logo. Status: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteCompany(String cnpj) async {
    try {
      final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
      await _companiesRef.doc(cleanCnpj).delete();
    } catch (e) {
      throw Exception('Erro ao excluir empresa: $e');
    }
  }
}
