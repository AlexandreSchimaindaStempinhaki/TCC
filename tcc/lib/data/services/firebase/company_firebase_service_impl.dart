import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/models/company_entity.dart';
import 'i_company_firebase_service.dart';

class CompanyServiceImpl implements CompanyService {
  final FirebaseFirestore _firestore;

  CompanyServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _companiesRef =>
      _firestore.collection('companies');

  @override
  Future<void> createCompany(CompanyModel company) async {
    try {
      final docRef = _companiesRef.doc(company.cnpj);

      final companyToSave = company.copyWith(id: company.cnpj);
      
      await docRef.set(companyToSave.toMap());
    } catch (e) {
      throw Exception('Erro ao criar empresa: $e');
    }
  }

  @override
  Future<List<CompanyModel>> fetchCompaniesByOwner(String ownerId) async {
    try {
      final snapshot = await _companiesRef
          .where('ownerId', isEqualTo: ownerId)
          .get();

      return snapshot.docs
          .map((doc) => CompanyModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar empresas do proprietário: $e');
    }
  }

  @override
  Future<List<CompanyModel>> fetchCompaniesByMember(String memberId) async {
    try {
      final snapshot = await _companiesRef
          .where('memberIds', arrayContains: memberId)
          .get();

      return snapshot.docs
          .map((doc) => CompanyModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id, // O doc.id agora será o próprio CNPJ
              ))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar empresas do membro: $e');
    }
  }

  @override
  Future<void> updateCompany(CompanyModel company) async {
    try {
      await _companiesRef.doc(company.cnpj).update(company.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar empresa: $e');
    }
  }

  @override
  Future<void> deleteCompany(String cnpj) async {
    try {
      // Deleta usando o CNPJ como referência
      await _companiesRef.doc(cnpj).delete();
    } catch (e) {
      throw Exception('Erro ao excluir empresa: $e');
    }
  }
}