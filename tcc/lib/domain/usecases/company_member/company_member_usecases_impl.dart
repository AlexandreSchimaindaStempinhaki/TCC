import '../../models/company_member_entity.dart';
import '../../../data/repositories/company_member/i_company_member_repository.dart';
import 'i_company_member_usecases.dart';

class FetchCompanyMembersUseCaseImpl implements IFetchCompanyMembersUseCase {
  final ICompanyMemberRepository _repository;

  FetchCompanyMembersUseCaseImpl(this._repository);

  @override
  Future<List<CompanyMemberModel>> call(String companyCnpj) {
    if (companyCnpj.trim().isEmpty) {
      throw Exception('CNPJ da empresa inválido.');
    }
    return _repository.fetchCompanyMembers(companyCnpj);
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
  Future<CompanyMemberModel?> call(String companyCnpj, String cpfOrUid) {
    if (companyCnpj.trim().isEmpty || cpfOrUid.trim().isEmpty) {
      return Future.value(null);
    }
    return _repository.getMemberLink(companyCnpj, cpfOrUid);
  }
}

class AddCompanyMemberUseCaseImpl implements IAddCompanyMemberUseCase {
  final ICompanyMemberRepository _repository;

  AddCompanyMemberUseCaseImpl(this._repository);

  @override
  Future<CompanyMemberModel> call(CompanyMemberModel member) {
    if (member.companyCnpj.trim().isEmpty || member.userCpf.trim().isEmpty) {
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
    required String companyCnpj,
    required String userCpf,
    required String newRole,
  }) {
    if (newRole.trim().isEmpty) {
      throw Exception('O novo cargo não pode ser vazio.');
    }
    return _repository.updateMemberRole(
      companyCnpj: companyCnpj,
      userCpf: userCpf,
      newRole: newRole,
    );
  }
}

class RemoveCompanyMemberUseCaseImpl implements IRemoveCompanyMemberUseCase {
  final ICompanyMemberRepository _repository;

  RemoveCompanyMemberUseCaseImpl(this._repository);

  @override
  Future<void> call({
    required String companyCnpj,
    required String userCpf,
  }) {
    return _repository.removeMember(
      companyCnpj: companyCnpj,
      userCpf: userCpf,
    );
  }
}