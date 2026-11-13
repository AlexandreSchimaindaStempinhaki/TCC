import 'dart:io';
import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/company_entity.dart';

abstract interface class ICompanyRepository {
  Future<VoidResult> createCompany(CompanyModel company);

  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByOwner([String? ownerId]);

  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByMember([String? memberId]);

  Future<VoidResult> updateCompany(CompanyModel company);

  Future<Result<String, Failure>> updateCompanyLogo(String cnpj, File imageFile);

  Future<VoidResult> deleteCompany(String cnpj);
}