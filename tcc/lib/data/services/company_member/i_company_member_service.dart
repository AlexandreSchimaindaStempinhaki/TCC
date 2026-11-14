import '../../../domain/models/company_member_entity.dart';

abstract class ICompanyMemberService {
  Future<List<CompanyMemberModel>> fetchCompanyMembers(String cnpjEmpresa);
  Future<List<CompanyMemberModel>> fetchUserMemberships(String cpfOrUid);
  Future<CompanyMemberModel?> getMemberLink(String cnpjEmpresa, String cpfOrUid);
  Future<CompanyMemberModel> addMember(CompanyMemberModel member);
  Future<void> updateMemberRole({
    required String cnpjEmpresa,
    required String cpfPessoa,
    required String newRole,
  });
  Future<void> removeMember({
    required String cnpjEmpresa,
    required String cpfPessoa,
  });
}