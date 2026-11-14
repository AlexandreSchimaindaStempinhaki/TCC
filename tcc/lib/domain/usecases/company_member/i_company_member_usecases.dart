import '../../models/company_member_entity.dart';

abstract class IFetchCompanyMembersUseCase {
  Future<List<CompanyMemberModel>> call(String cnpjEmpresa);
}

abstract class IFetchUserMembershipsUseCase {
  Future<List<CompanyMemberModel>> call(String cpfOrUid);
}

abstract class IGetMemberLinkUseCase {
  Future<CompanyMemberModel?> call(String cnpjEmpresa, String cpfOrUid);
}

abstract class IAddCompanyMemberUseCase {
  Future<CompanyMemberModel> call(CompanyMemberModel member);
}

abstract class IChangeCompanyMemberRoleUseCase {
  Future<void> call({
    required String cnpjEmpresa,
    required String cpfPessoa,
    required String newRole,
  });
}

abstract class IRemoveCompanyMemberUseCase {
  Future<void> call({
    required String cnpjEmpresa,
    required String cpfPessoa,
  });
}