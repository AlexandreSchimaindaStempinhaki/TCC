import '../../../domain/models/company_member_entity.dart';
import '../../services/company_member/i_company_member_service.dart';
import 'i_company_member_repository.dart';

class CompanyMemberRepositoryImpl implements ICompanyMemberRepository {
  final ICompanyMemberService _service;

  CompanyMemberRepositoryImpl(this._service);

  @override
  Future<List<CompanyMemberModel>> fetchCompanyMembers(String companyCnpj) {
    return _service.fetchCompanyMembers(companyCnpj);
  }

  @override
  Future<List<CompanyMemberModel>> fetchUserMemberships(String cpfOrUid) {
    return _service.fetchUserMemberships(cpfOrUid);
  }

  @override
  Future<CompanyMemberModel?> getMemberLink(
    String companyCnpj,
    String cpfOrUid,
  ) {
    return _service.getMemberLink(companyCnpj, cpfOrUid);
  }

  @override
  Future<CompanyMemberModel> addMember(CompanyMemberModel member) {
    return _service.addMember(member);
  }

  @override
  Future<void> updateMemberRole({
    required String companyCnpj,
    required String userCpf,
    required String newRole,
  }) {
    return _service.updateMemberRole(
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
    return _service.removeMember(
      companyCnpj: companyCnpj,
      userCpf: userCpf,
    );
  }
}