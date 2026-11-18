import '../../../../../core/typedefs/types_defs.dart';
import '../../../../core/failure/failure.dart' show Failure, DefaultFailure;
import '../../../../core/patterns/result.dart';
import '../../models/company_entity.dart';
import '../../models/company_review_entity.dart';
import '../../../data/repositories/company/i_company_repository.dart';
import 'i_company_use_cases.dart';

final class CreateCompanyUseCase implements ICreateCompanyUseCase {
  final ICompanyRepository _companyRepository;

  CreateCompanyUseCase({required ICompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  @override
  Future<VoidResult> call(CreateCompanyParams params) async {
    return _companyRepository.createCompany(params.company);
  }
}

final class FetchCompaniesByOwnerUseCase
    implements IFetchCompaniesByOwnerUseCase {
  final ICompanyRepository _companyRepository;

  FetchCompaniesByOwnerUseCase({required ICompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  @override
  Future<Result<List<CompanyModel>, Failure>> call(
    FetchCompaniesByOwnerParams params,
  ) async {
    return _companyRepository.fetchCompaniesByOwner(params.ownerId);
  }
}

final class FetchCompaniesByMemberUseCase
    implements IFetchCompaniesByMemberUseCase {
  final ICompanyRepository _companyRepository;

  FetchCompaniesByMemberUseCase({required ICompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  @override
  Future<Result<List<CompanyModel>, Failure>> call(
    FetchCompaniesByMemberParams params,
  ) async {
    return _companyRepository.fetchCompaniesByMember(params.memberId);
  }
}

final class UpdateCompanyUseCase implements IUpdateCompanyUseCase {
  final ICompanyRepository _companyRepository;

  UpdateCompanyUseCase({required ICompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  @override
  Future<VoidResult> call(UpdateCompanyParams params) async {
    return _companyRepository.updateCompany(params.company);
  }
}

final class UpdateCompanyLogoUseCase implements IUpdateCompanyLogoUseCase {
  final ICompanyRepository _companyRepository;

  UpdateCompanyLogoUseCase({required ICompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  @override
  Future<Result<String, Failure>> call(UpdateCompanyLogoParams params) async {
    if (!params.imageFile.existsSync()) {
      return Error(
        DefaultFailure('O arquivo de imagem selecionado não foi encontrado.'),
      );
    }
    return _companyRepository.updateCompanyLogo(params.cnpj, params.imageFile);
  }
}

final class DeleteCompanyUseCase implements IDeleteCompanyUseCase {
  final ICompanyRepository _companyRepository;

  DeleteCompanyUseCase({required ICompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  @override
  Future<VoidResult> call(DeleteCompanyParams params) async {
    return _companyRepository.deleteCompany(params.cnpj);
  }
}

final class FetchCompanyReviewsUseCase implements IFetchCompanyReviewsUseCase {
  final ICompanyRepository _companyRepository;

  FetchCompanyReviewsUseCase({required ICompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  @override
  Future<Result<List<CompanyReviewModel>, Failure>> call(
    FetchCompanyReviewsParams params,
  ) async {
    return _companyRepository.fetchCompanyReviews(params.cnpj);
  }
}

final class ShouldPromptFirstTripReviewUseCase
    implements IShouldPromptFirstTripReviewUseCase {
  final ICompanyRepository _companyRepository;

  ShouldPromptFirstTripReviewUseCase({
    required ICompanyRepository companyRepository,
  }) : _companyRepository = companyRepository;

  @override
  Future<Result<bool, Failure>> call(CheckFirstTripReviewParams params) async {
    return _companyRepository.shouldPromptFirstTripReview(
      cnpj: params.cnpj,
      userId: params.userId,
    );
  }
}

final class DismissFirstTripReviewPromptUseCase
    implements IDismissFirstTripReviewPromptUseCase {
  final ICompanyRepository _companyRepository;

  DismissFirstTripReviewPromptUseCase({
    required ICompanyRepository companyRepository,
  }) : _companyRepository = companyRepository;

  @override
  Future<VoidResult> call(CheckFirstTripReviewParams params) async {
    return _companyRepository.dismissFirstTripReviewPrompt(
      cnpj: params.cnpj,
      userId: params.userId,
    );
  }
}

final class RateCompanyUseCase implements IRateCompanyUseCase {
  final ICompanyRepository _companyRepository;

  RateCompanyUseCase({required ICompanyRepository companyRepository})
    : _companyRepository = companyRepository;

  @override
  Future<Result<CompanyModel, Failure>> call(RateCompanyParams params) async {
    if (params.rating < 1.0 || params.rating > 5.0) {
      return Error(
        DefaultFailure('A nota da avaliação deve ser entre 1 e 5 estrelas.'),
      );
    }
    return _companyRepository.rateCompany(
      cnpj: params.cnpj,
      userId: params.userId,
      userName: params.userName,
      userPhotoUrl: params.userPhotoUrl,
      rating: params.rating,
      description: params.description,
    );
  }
}