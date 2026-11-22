import '../../../domain/models/company_member_entity.dart';

abstract class ICompanyMemberService {
  Future<List<CompanyMemberModel>> fetchCompanyMembers(String companyCnpj);
  Future<List<CompanyMemberModel>> fetchUserMemberships(String cpfOrUid);
  Future<CompanyMemberModel?> getMemberLink(String companyCnpj, String cpfOrUid);
  Future<CompanyMemberModel> addMember(CompanyMemberModel member);
  Future<void> updateMemberRole({
    required String companyCnpj,
    required String userCpf,
    required String newRole,
  });
  Future<void> removeMember({
    required String companyCnpj,
    required String userCpf,
  });
}