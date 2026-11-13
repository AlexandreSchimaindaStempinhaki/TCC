import '../../../../core/failure/failure.dart';
import '../../../../core/typedefs/types_defs.dart';
import '../../../../core/patterns/command.dart';
import '../../../../core/patterns/result.dart';
import '../../domain/facades/i_company_use_case_facade.dart';
import '../../domain/models/company_entity.dart';
import '../../domain/usecases/i_company_use_cases.dart';

final class CreateCompanyCommand
    extends ParameterizedCommand<void, Failure, CreateCompanyParams> {
  final ICompanyUseCaseFacade _companyUseCaseFacade;

  CreateCompanyCommand(this._companyUseCaseFacade);

  @override
  Future<VoidResult> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros de criação de empresa inválidos.'),
      );
    }
    return await _companyUseCaseFacade.createCompany(parameter!);
  }
}

final class FetchCompaniesByOwnerCommand
    extends ParameterizedCommand<List<CompanyModel>, Failure, FetchCompaniesByOwnerParams> {
  final ICompanyUseCaseFacade _companyUseCaseFacade;

  FetchCompaniesByOwnerCommand(this._companyUseCaseFacade);

  @override
  Future<Result<List<CompanyModel>, Failure>> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros inválidos para buscar empresas do proprietário.'),
      );
    }
    return await _companyUseCaseFacade.fetchCompaniesByOwner(parameter!);
  }
}

final class FetchCompaniesByMemberCommand
    extends ParameterizedCommand<List<CompanyModel>, Failure, FetchCompaniesByMemberParams> {
  final ICompanyUseCaseFacade _companyUseCaseFacade;

  FetchCompaniesByMemberCommand(this._companyUseCaseFacade);

  @override
  Future<Result<List<CompanyModel>, Failure>> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros inválidos para buscar empresas do membro.'),
      );
    }
    return await _companyUseCaseFacade.fetchCompaniesByMember(parameter!);
  }
}

final class UpdateCompanyCommand
    extends ParameterizedCommand<void, Failure, UpdateCompanyParams> {
  final ICompanyUseCaseFacade _companyUseCaseFacade;

  UpdateCompanyCommand(this._companyUseCaseFacade);

  @override
  Future<VoidResult> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros de atualização de empresa inválidos.'),
      );
    }
    return await _companyUseCaseFacade.updateCompany(parameter!);
  }
}

final class UpdateCompanyLogoCommand
    extends ParameterizedCommand<String, Failure, UpdateCompanyLogoParams> {
  final ICompanyUseCaseFacade _companyUseCaseFacade;

  UpdateCompanyLogoCommand(this._companyUseCaseFacade);

  @override
  Future<Result<String, Failure>> execute() async {
    if (parameter == null || !parameter!.imageFile.existsSync()) {
      return Error(
        InvalidInputFailure('Arquivo de imagem inválido ou não fornecido.'),
      );
    }
    return await _companyUseCaseFacade.updateCompanyLogo(parameter!);
  }
}

final class DeleteCompanyCommand
    extends ParameterizedCommand<void, Failure, DeleteCompanyParams> {
  final ICompanyUseCaseFacade _companyUseCaseFacade;

  DeleteCompanyCommand(this._companyUseCaseFacade);

  @override
  Future<VoidResult> execute() async {
    if (parameter == null) {
      return Error(
        InvalidInputFailure('Parâmetros inválidos para exclusão da empresa.'),
      );
    }
    return await _companyUseCaseFacade.deleteCompany(parameter!);
  }
}