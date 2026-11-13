import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/company_entity.dart';
import '../usecases/i_company_use_cases.dart';
import 'i_company_use_case_facade.dart';

class CompanyUseCaseFacadeImpl implements ICompanyUseCaseFacade {
  final ICreateCompanyUseCase _createCompanyUseCase;
  final IFetchCompaniesByOwnerUseCase _fetchCompaniesByOwnerUseCase;
  final IFetchCompaniesByMemberUseCase _fetchCompaniesByMemberUseCase;
  final IUpdateCompanyUseCase _updateCompanyUseCase;
  final IDeleteCompanyUseCase _deleteCompanyUseCase;

  CompanyUseCaseFacadeImpl({
    required ICreateCompanyUseCase createCompanyUseCase,
    required IFetchCompaniesByOwnerUseCase fetchCompaniesByOwnerUseCase,
    required IFetchCompaniesByMemberUseCase fetchCompaniesByMemberUseCase,
    required IUpdateCompanyUseCase updateCompanyUseCase,
    required IDeleteCompanyUseCase deleteCompanyUseCase,
  }) : _createCompanyUseCase = createCompanyUseCase,
       _fetchCompaniesByOwnerUseCase = fetchCompaniesByOwnerUseCase,
       _fetchCompaniesByMemberUseCase = fetchCompaniesByMemberUseCase,
       _updateCompanyUseCase = updateCompanyUseCase,
       _deleteCompanyUseCase = deleteCompanyUseCase;

  @override
  Future<VoidResult> createCompany(CreateCompanyParams params) {
    return _createCompanyUseCase(params);
  }

  @override
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByOwner(
    FetchCompaniesByOwnerParams params,
  ) {
    return _fetchCompaniesByOwnerUseCase(params);
  }

  @override
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByMember(
    FetchCompaniesByMemberParams params,
  ) {
    return _fetchCompaniesByMemberUseCase(params);
  }

  @override
  Future<VoidResult> updateCompany(UpdateCompanyParams params) {
    return _updateCompanyUseCase(params);
  }

  @override
  Future<VoidResult> deleteCompany(DeleteCompanyParams params) {
    return _deleteCompanyUseCase(params);
  }
}