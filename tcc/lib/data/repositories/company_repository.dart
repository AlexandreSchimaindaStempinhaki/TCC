import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/company_entity.dart';
import '../services/firebase/i_company_firebase_service.dart';
import 'i_company_repository.dart';

final class CompanyRepositoryImpl implements ICompanyRepository {
  final CompanyService _companyService;

  CompanyRepositoryImpl({required CompanyService companyService})
      : _companyService = companyService;

  @override
  Future<VoidResult> createCompany(CompanyModel company) async {
    try {
      await _companyService.createCompany(company);
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByOwner(String ownerId) async {
    try {
      final companies = await _companyService.fetchCompaniesByOwner(ownerId);
      return Success(companies);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByMember(String memberId) async {
    try {
      final companies = await _companyService.fetchCompaniesByMember(memberId);
      return Success(companies);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<VoidResult> updateCompany(CompanyModel company) async {
    try {
      await _companyService.updateCompany(company);
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }

  @override
  Future<VoidResult> deleteCompany(String cnpj) async {
    try {
      await _companyService.deleteCompany(cnpj);
      return const Success(null);
    } catch (e) {
      return Error(DefaultFailure(e.toString()));
    }
  }
}