import 'dart:io';
import '../../../domain/models/company_entity.dart';

abstract interface class ICompanyRemoteService {
  Future<void> createCompany(CompanyModel company);
  Future<List<CompanyModel>> fetchCompaniesByOwner([String? ownerId]);
  Future<List<CompanyModel>> fetchCompaniesByMember([String? memberId]);
  Future<void> updateCompany(CompanyModel company);
  Future<String> uploadCompanyLogo(String cnpj, File imageFile);
  Future<void> deleteCompany(String cnpj);
}