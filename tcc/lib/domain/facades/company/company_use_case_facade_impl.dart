import '../../../../../core/typedefs/types_defs.dart';
import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/result.dart';
import '../../models/company_entity.dart';
import '../../models/company_review_entity.dart';
import '../../usecases/company/i_company_use_cases.dart';
import 'i_company_use_case_facade.dart';

class CompanyUseCaseFacadeImpl implements ICompanyUseCaseFacade {
  final ICreateCompanyUseCase _createCompanyUseCase;
  final IFetchCompaniesByOwnerUseCase _fetchCompaniesByOwnerUseCase;
  final IFetchCompaniesByMemberUseCase _fetchCompaniesByMemberUseCase;
  final IUpdateCompanyUseCase _updateCompanyUseCase;
  final IUpdateCompanyLogoUseCase _updateCompanyLogoUseCase;
  final IDeleteCompanyUseCase _deleteCompanyUseCase;
  final IFetchCompanyReviewsUseCase _fetchCompanyReviewsUseCase;
  final IShouldPromptFirstTripReviewUseCase _shouldPromptFirstTripReviewUseCase;
  final IDismissFirstTripReviewPromptUseCase
      _dismissFirstTripReviewPromptUseCase;
  final IRateCompanyUseCase _rateCompanyUseCase;

  CompanyUseCaseFacadeImpl({
    required ICreateCompanyUseCase createCompanyUseCase,
    required IFetchCompaniesByOwnerUseCase fetchCompaniesByOwnerUseCase,
    required IFetchCompaniesByMemberUseCase fetchCompaniesByMemberUseCase,
    required IUpdateCompanyUseCase updateCompanyUseCase,
    required IUpdateCompanyLogoUseCase updateCompanyLogoUseCase,
    required IDeleteCompanyUseCase deleteCompanyUseCase,
    required IFetchCompanyReviewsUseCase fetchCompanyReviewsUseCase,
    required IShouldPromptFirstTripReviewUseCase
        shouldPromptFirstTripReviewUseCase,
    required IDismissFirstTripReviewPromptUseCase
        dismissFirstTripReviewPromptUseCase,
    required IRateCompanyUseCase rateCompanyUseCase,
  }) : _createCompanyUseCase = createCompanyUseCase,
       _fetchCompaniesByOwnerUseCase = fetchCompaniesByOwnerUseCase,
       _fetchCompaniesByMemberUseCase = fetchCompaniesByMemberUseCase,
       _updateCompanyUseCase = updateCompanyUseCase,
       _updateCompanyLogoUseCase = updateCompanyLogoUseCase,
       _deleteCompanyUseCase = deleteCompanyUseCase,
       _fetchCompanyReviewsUseCase = fetchCompanyReviewsUseCase,
       _shouldPromptFirstTripReviewUseCase =
           shouldPromptFirstTripReviewUseCase,
       _dismissFirstTripReviewPromptUseCase =
           dismissFirstTripReviewPromptUseCase,
       _rateCompanyUseCase = rateCompanyUseCase;

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
  Future<Result<String, Failure>> updateCompanyLogo(
    UpdateCompanyLogoParams params,
  ) {
    return _updateCompanyLogoUseCase(params);
  }

  @override
  Future<VoidResult> deleteCompany(DeleteCompanyParams params) {
    return _deleteCompanyUseCase(params);
  }

  @override
  Future<Result<List<CompanyReviewModel>, Failure>> fetchCompanyReviews(
    FetchCompanyReviewsParams params,
  ) {
    return _fetchCompanyReviewsUseCase(params);
  }

  @override
  Future<Result<bool, Failure>> shouldPromptFirstTripReview(
    CheckFirstTripReviewParams params,
  ) {
    return _shouldPromptFirstTripReviewUseCase(params);
  }

  @override
  Future<VoidResult> dismissFirstTripReviewPrompt(
    CheckFirstTripReviewParams params,
  ) {
    return _dismissFirstTripReviewPromptUseCase(params);
  }

  @override
  Future<Result<CompanyModel, Failure>> rateCompany(RateCompanyParams params) {
    return _rateCompanyUseCase(params);
  }
}