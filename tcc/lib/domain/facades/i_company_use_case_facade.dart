import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/company_entity.dart';

abstract interface class ICompanyUseCaseFacade {
  Future<VoidResult> createCompany(CreateCompanyParams params);
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByOwner(
    FetchCompaniesByOwnerParams params,
  );
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByMember(
    FetchCompaniesByMemberParams params,
  );
  Future<VoidResult> updateCompany(UpdateCompanyParams params);
  Future<VoidResult> deleteCompany(DeleteCompanyParams params);
}