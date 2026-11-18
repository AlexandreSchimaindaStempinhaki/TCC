import '../../../../../core/typedefs/types_defs.dart';
import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/result.dart';
import '../../models/company_entity.dart';
import '../../models/company_review_entity.dart';

abstract interface class ICompanyUseCaseFacade {
  Future<VoidResult> createCompany(CreateCompanyParams params);
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByOwner(
    FetchCompaniesByOwnerParams params,
  );
  Future<Result<List<CompanyModel>, Failure>> fetchCompaniesByMember(
    FetchCompaniesByMemberParams params,
  );
  Future<VoidResult> updateCompany(UpdateCompanyParams params);
  Future<Result<String, Failure>> updateCompanyLogo(
    UpdateCompanyLogoParams params,
  );
  Future<VoidResult> deleteCompany(DeleteCompanyParams params);

  Future<Result<List<CompanyReviewModel>, Failure>> fetchCompanyReviews(
    FetchCompanyReviewsParams params,
  );
  Future<Result<bool, Failure>> shouldPromptFirstTripReview(
    CheckFirstTripReviewParams params,
  );
  Future<VoidResult> dismissFirstTripReviewPrompt(
    CheckFirstTripReviewParams params,
  );
  Future<Result<CompanyModel, Failure>> rateCompany(RateCompanyParams params);
}