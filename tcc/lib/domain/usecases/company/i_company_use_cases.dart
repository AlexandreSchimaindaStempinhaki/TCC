import '../../../../../core/typedefs/types_defs.dart';
import '../../../../../core/patterns/i_usecases.dart';
import '../../../../core/failure/failure.dart';
import '../../../../core/patterns/result.dart';
import '../../models/company_entity.dart';
import '../../models/company_review_entity.dart';

abstract interface class ICreateCompanyUseCase
    implements IUseCase<VoidResult, CreateCompanyParams> {}

abstract interface class IFetchCompaniesByOwnerUseCase
    implements
        IUseCase<
          Result<List<CompanyModel>, Failure>,
          FetchCompaniesByOwnerParams> {}

abstract interface class IFetchCompaniesByMemberUseCase
    implements
        IUseCase<
          Result<List<CompanyModel>, Failure>,
          FetchCompaniesByMemberParams> {}

abstract interface class IUpdateCompanyUseCase
    implements IUseCase<VoidResult, UpdateCompanyParams> {}

abstract interface class IUpdateCompanyLogoUseCase
    implements IUseCase<Result<String, Failure>, UpdateCompanyLogoParams> {}

abstract interface class IDeleteCompanyUseCase
    implements IUseCase<VoidResult, DeleteCompanyParams> {}

abstract interface class IFetchCompanyReviewsUseCase
    implements
        IUseCase<
          Result<List<CompanyReviewModel>, Failure>,
          FetchCompanyReviewsParams> {}

abstract interface class IShouldPromptFirstTripReviewUseCase
    implements IUseCase<Result<bool, Failure>, CheckFirstTripReviewParams> {}

abstract interface class IDismissFirstTripReviewPromptUseCase
    implements IUseCase<VoidResult, CheckFirstTripReviewParams> {}

abstract interface class IRateCompanyUseCase
    implements IUseCase<Result<CompanyModel, Failure>, RateCompanyParams> {}
