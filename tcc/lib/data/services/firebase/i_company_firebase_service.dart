import '../../../domain/models/company_entity.dart';

abstract class CompanyService {
  Future<void> createCompany(CompanyModel company);
  Future<List<CompanyModel>> fetchCompaniesByOwner(String ownerId);
  Future<List<CompanyModel>> fetchCompaniesByMember(String memberId);
  Future<void> updateCompany(CompanyModel company);
  Future<void> deleteCompany(String companyId);
}