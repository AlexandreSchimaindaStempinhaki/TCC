import 'package:signals_flutter/signals_flutter.dart';
import '../../../domain/facades/company_member/i_company_member_facade.dart';
import '../../../domain/models/company_member_entity.dart';

class FetchCompanyMembersCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  FetchCompanyMembersCommand(this._facade);

  Future<List<CompanyMemberModel>> execute(String cnpjEmpresa) async {
    isExecuting.value = true;
    try {
      return await _facade.fetchCompanyMembers(cnpjEmpresa);
    } finally {
      isExecuting.value = false;
    }
  }
}

class FetchUserMembershipsCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  FetchUserMembershipsCommand(this._facade);

  Future<List<CompanyMemberModel>> execute(String cpfOrUid) async {
    isExecuting.value = true;
    try {
      return await _facade.fetchUserMemberships(cpfOrUid);
    } finally {
      isExecuting.value = false;
    }
  }
}

class GetMemberLinkCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  GetMemberLinkCommand(this._facade);

  Future<CompanyMemberModel?> execute(
    String cnpjEmpresa,
    String cpfOrUid,
  ) async {
    isExecuting.value = true;
    try {
      return await _facade.getMemberLink(cnpjEmpresa, cpfOrUid);
    } finally {
      isExecuting.value = false;
    }
  }
}

class AddCompanyMemberCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  AddCompanyMemberCommand(this._facade);

  Future<CompanyMemberModel> execute(CompanyMemberModel member) async {
    isExecuting.value = true;
    try {
      return await _facade.addMember(member);
    } finally {
      isExecuting.value = false;
    }
  }
}

class ChangeCompanyMemberRoleCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  ChangeCompanyMemberRoleCommand(this._facade);

  Future<void> execute({
    required String cnpjEmpresa,
    required String cpfPessoa,
    required String newRole,
  }) async {
    isExecuting.value = true;
    try {
      await _facade.changeMemberRole(
        cnpjEmpresa: cnpjEmpresa,
        cpfPessoa: cpfPessoa,
        newRole: newRole,
      );
    } finally {
      isExecuting.value = false;
    }
  }
}

class RemoveCompanyMemberCommand {
  final ICompanyMemberFacade _facade;
  final isExecuting = signal(false);

  RemoveCompanyMemberCommand(this._facade);

  Future<void> execute({
    required String cnpjEmpresa,
    required String cpfPessoa,
  }) async {
    isExecuting.value = true;
    try {
      await _facade.removeMember(
        cnpjEmpresa: cnpjEmpresa,
        cpfPessoa: cpfPessoa,
      );
    } finally {
      isExecuting.value = false;
    }
  }
}