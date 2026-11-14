import '../../models/company_member_entity.dart';
import '../../usecases/company_member/i_company_member_usecases.dart';
import 'i_company_member_facade.dart';

class CompanyMemberFacadeImpl implements ICompanyMemberFacade {
  final IFetchCompanyMembersUseCase _fetchCompanyMembersUseCase;
  final IFetchUserMembershipsUseCase _fetchUserMembershipsUseCase;
  final IGetMemberLinkUseCase _getMemberLinkUseCase;
  final IAddCompanyMemberUseCase _addCompanyMemberUseCase;
  final IChangeCompanyMemberRoleUseCase _changeCompanyMemberRoleUseCase;
  final IRemoveCompanyMemberUseCase _removeCompanyMemberUseCase;

  CompanyMemberFacadeImpl({
    required IFetchCompanyMembersUseCase fetchCompanyMembersUseCase,
    required IFetchUserMembershipsUseCase fetchUserMembershipsUseCase,
    required IGetMemberLinkUseCase getMemberLinkUseCase,
    required IAddCompanyMemberUseCase addCompanyMemberUseCase,
    required IChangeCompanyMemberRoleUseCase changeCompanyMemberRoleUseCase,
    required IRemoveCompanyMemberUseCase removeCompanyMemberUseCase,
  })  : _fetchCompanyMembersUseCase = fetchCompanyMembersUseCase,
        _fetchUserMembershipsUseCase = fetchUserMembershipsUseCase,
        _getMemberLinkUseCase = getMemberLinkUseCase,
        _addCompanyMemberUseCase = addCompanyMemberUseCase,
        _changeCompanyMemberRoleUseCase = changeCompanyMemberRoleUseCase,
        _removeCompanyMemberUseCase = removeCompanyMemberUseCase;

  @override
  Future<List<CompanyMemberModel>> fetchCompanyMembers(String cnpjEmpresa) {
    return _fetchCompanyMembersUseCase(cnpjEmpresa);
  }

  @override
  Future<List<CompanyMemberModel>> fetchUserMemberships(String cpfOrUid) {
    return _fetchUserMembershipsUseCase(cpfOrUid);
  }

  @override
  Future<CompanyMemberModel?> getMemberLink(
    String cnpjEmpresa,
    String cpfOrUid,
  ) {
    return _getMemberLinkUseCase(cnpjEmpresa, cpfOrUid);
  }

  @override
  Future<CompanyMemberModel> addMember(CompanyMemberModel member) {
    return _addCompanyMemberUseCase(member);
  }

  @override
  Future<void> changeMemberRole({
    required String cnpjEmpresa,
    required String cpfPessoa,
    required String newRole,
  }) {
    return _changeCompanyMemberRoleUseCase(
      cnpjEmpresa: cnpjEmpresa,
      cpfPessoa: cpfPessoa,
      newRole: newRole,
    );
  }

  @override
  Future<void> removeMember({
    required String cnpjEmpresa,
    required String cpfPessoa,
  }) {
    return _removeCompanyMemberUseCase(
      cnpjEmpresa: cnpjEmpresa,
      cpfPessoa: cpfPessoa,
    );
  }
}