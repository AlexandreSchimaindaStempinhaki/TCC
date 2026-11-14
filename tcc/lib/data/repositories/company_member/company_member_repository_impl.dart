import '../../../domain/models/company_member_entity.dart';
import 'i_company_member_repository.dart';
import '../../services/company_member/i_company_member_service.dart';

class CompanyMemberRepositoryImpl implements ICompanyMemberRepository {
  final ICompanyMemberService _service;

  CompanyMemberRepositoryImpl(this._service);

  @override
  Future<List<CompanyMemberModel>> fetchCompanyMembers(String cnpjEmpresa) {
    return _service.fetchCompanyMembers(cnpjEmpresa);
  }

  @override
  Future<List<CompanyMemberModel>> fetchUserMemberships(String cpfOrUid) {
    return _service.fetchUserMemberships(cpfOrUid);
  }

  @override
  Future<CompanyMemberModel?> getMemberLink(
    String cnpjEmpresa,
    String cpfOrUid,
  ) {
    return _service.getMemberLink(cnpjEmpresa, cpfOrUid);
  }

  @override
  Future<CompanyMemberModel> addMember(CompanyMemberModel member) {
    return _service.addMember(member);
  }

  @override
  Future<void> updateMemberRole({
    required String cnpjEmpresa,
    required String cpfPessoa,
    required String newRole,
  }) {
    return _service.updateMemberRole(
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
    return _service.removeMember(
      cnpjEmpresa: cnpjEmpresa,
      cpfPessoa: cpfPessoa,
    );
  }
}