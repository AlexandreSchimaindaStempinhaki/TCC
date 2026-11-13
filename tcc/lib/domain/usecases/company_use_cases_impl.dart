import '../../../../core/typedefs/types_defs.dart';
import '../../../core/failure/failure.dart';
import '../../../core/patterns/result.dart';
import '../../domain/models/company_entity.dart';
import '../../data/repositories/i_company_repository.dart';
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

final class FetchCompaniesByOwnerUseCase implements IFetchCompaniesByOwnerUseCase {
  final ICompanyRepository _companyRepository;

  FetchCompaniesByOwnerUseCase({required ICompanyRepository companyRepository})
      : _companyRepository = companyRepository;

  @override
  Future<Result<List<CompanyModel>, Failure>> call(FetchCompaniesByOwnerParams params) async {
    return _companyRepository.fetchCompaniesByOwner(params.ownerId);
  }
}

final class FetchCompaniesByMemberUseCase implements IFetchCompaniesByMemberUseCase {
  final ICompanyRepository _companyRepository;

  FetchCompaniesByMemberUseCase({required ICompanyRepository companyRepository})
      : _companyRepository = companyRepository;

  @override
  Future<Result<List<CompanyModel>, Failure>> call(FetchCompaniesByMemberParams params) async {
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

final class DeleteCompanyUseCase implements IDeleteCompanyUseCase {
  final ICompanyRepository _companyRepository;

  DeleteCompanyUseCase({required ICompanyRepository companyRepository})
      : _companyRepository = companyRepository;

  @override
  Future<VoidResult> call(DeleteCompanyParams params) async {
    return _companyRepository.deleteCompany(params.cnpj);
  }
}