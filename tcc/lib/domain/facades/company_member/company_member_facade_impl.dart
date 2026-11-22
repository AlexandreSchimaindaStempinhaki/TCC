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
  Future<List<CompanyMemberModel>> fetchCompanyMembers(String companyCnpj) {
    return _fetchCompanyMembersUseCase(companyCnpj);
  }

  @override
  Future<List<CompanyMemberModel>> fetchUserMemberships(String cpfOrUid) {
    return _fetchUserMembershipsUseCase(cpfOrUid);
  }

  @override
  Future<CompanyMemberModel?> getMemberLink(
    String companyCnpj,
    String cpfOrUid,
  ) {
    return _getMemberLinkUseCase(companyCnpj, cpfOrUid);
  }

  @override
  Future<CompanyMemberModel> addMember(CompanyMemberModel member) {
    return _addCompanyMemberUseCase(member);
  }

  @override
  Future<void> changeMemberRole({
    required String companyCnpj,
    required String userCpf,
    required String newRole,
  }) {
    return _changeCompanyMemberRoleUseCase(
      companyCnpj: companyCnpj,
      userCpf: userCpf,
      newRole: newRole,
    );
  }

  @override
  Future<void> removeMember({
    required String companyCnpj,
    required String userCpf,
  }) {
    return _removeCompanyMemberUseCase(
      companyCnpj: companyCnpj,
      userCpf: userCpf,
    );
  }
}