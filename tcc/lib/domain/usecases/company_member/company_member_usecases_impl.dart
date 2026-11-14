import '../../models/company_member_entity.dart';
import '../../../data/repositories/company_member/i_company_member_repository.dart';
import 'i_company_member_usecases.dart';

class FetchCompanyMembersUseCaseImpl implements IFetchCompanyMembersUseCase {
  final ICompanyMemberRepository _repository;

  FetchCompanyMembersUseCaseImpl(this._repository);

  @override
  Future<List<CompanyMemberModel>> call(String cnpjEmpresa) {
    if (cnpjEmpresa.trim().isEmpty) {
      throw Exception('CNPJ da empresa inválido.');
    }
    return _repository.fetchCompanyMembers(cnpjEmpresa);
  }
}

class FetchUserMembershipsUseCaseImpl implements IFetchUserMembershipsUseCase {
  final ICompanyMemberRepository _repository;

  FetchUserMembershipsUseCaseImpl(this._repository);

  @override
  Future<List<CompanyMemberModel>> call(String cpfOrUid) {
    if (cpfOrUid.trim().isEmpty) {
      throw Exception('Identificador do usuário inválido.');
    }
    return _repository.fetchUserMemberships(cpfOrUid);
  }
}

class GetMemberLinkUseCaseImpl implements IGetMemberLinkUseCase {
  final ICompanyMemberRepository _repository;

  GetMemberLinkUseCaseImpl(this._repository);

  @override
  Future<CompanyMemberModel?> call(String cnpjEmpresa, String cpfOrUid) {
    if (cnpjEmpresa.trim().isEmpty || cpfOrUid.trim().isEmpty) {
      return Future.value(null);
    }
    return _repository.getMemberLink(cnpjEmpresa, cpfOrUid);
  }
}

class AddCompanyMemberUseCaseImpl implements IAddCompanyMemberUseCase {
  final ICompanyMemberRepository _repository;

  AddCompanyMemberUseCaseImpl(this._repository);

  @override
  Future<CompanyMemberModel> call(CompanyMemberModel member) {
    if (member.cnpjEmpresa.trim().isEmpty || member.cpfPessoa.trim().isEmpty) {
      throw Exception('CNPJ da empresa e CPF do usuário são obrigatórios.');
    }
    return _repository.addMember(member);
  }
}

class ChangeCompanyMemberRoleUseCaseImpl
    implements IChangeCompanyMemberRoleUseCase {
  final ICompanyMemberRepository _repository;

  ChangeCompanyMemberRoleUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required String cnpjEmpresa,
    required String cpfPessoa,
    required String newRole,
  }) {
    if (newRole.trim().isEmpty) {
      throw Exception('O novo cargo não pode ser vazio.');
    }
    return _repository.updateMemberRole(
      cnpjEmpresa: cnpjEmpresa,
      cpfPessoa: cpfPessoa,
      newRole: newRole,
    );
  }
}

class RemoveCompanyMemberUseCaseImpl implements IRemoveCompanyMemberUseCase {
  final ICompanyMemberRepository _repository;

  RemoveCompanyMemberUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required String cnpjEmpresa,
    required String cpfPessoa,
  }) {
    return _repository.removeMember(
      cnpjEmpresa: cnpjEmpresa,
      cpfPessoa: cpfPessoa,
    );
  }
}